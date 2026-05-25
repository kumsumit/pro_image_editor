import 'dart:math';
import 'dart:ui';

import '/core/models/layers/layer_mask.dart';
import '/core/models/retouch/retouch_operation.dart';
import '/plugins/image/src/image/image.dart' as img;

/// Applies non-destructive retouch operations to an image.
img.Image applyRetouchOperations(
  img.Image source,
  List<RetouchOperation> operations,
) {
  if (operations.isEmpty) return source;

  final output = img.Image.from(source);
  for (final operation in operations) {
    if (!operation.mask.enabled || operation.mask.isEmpty) continue;
    for (final frame in output.frames) {
      _applyOperation(frame, operation);
    }
  }
  return output;
}

void _applyOperation(img.Image frame, RetouchOperation operation) {
  final strength = operation.strength.clamp(0.0, 1.0);
  if (strength == 0) return;

  final bounds = _operationBounds(operation.mask, frame);
  final fillColor = operation.type == RetouchOperationType.objectRemoval
      ? _sampleSurroundingColor(frame, operation.mask, bounds)
      : null;

  final sourceSnapshot = img.Image.from(frame, noAnimation: true);

  for (var y = bounds.top; y < bounds.bottom; y++) {
    for (var x = bounds.left; x < bounds.right; x++) {
      final maskValue = _maskValueAt(sourceSnapshot, operation.mask, x, y);
      if (maskValue == 0) continue;

      final target = sourceSnapshot.getPixel(x, y);
      final amount = strength * maskValue;
      late final _Rgba replacement;

      switch (operation.type) {
        case RetouchOperationType.cloneStamp:
          replacement = _sampleOffset(sourceSnapshot, operation, x, y);
          break;
        case RetouchOperationType.healingBrush:
          replacement = _healColor(
            _sampleOffset(sourceSnapshot, operation, x, y),
            _Rgba.fromPixel(target),
          );
          break;
        case RetouchOperationType.objectRemoval:
          replacement = fillColor ?? _Rgba.fromPixel(target);
          break;
      }

      final mixed = _Rgba.mix(_Rgba.fromPixel(target), replacement, amount);
      frame.setPixelRgba(x, y, mixed.r, mixed.g, mixed.b, target.a);
    }
  }
}

_Rgba _sampleOffset(img.Image image, RetouchOperation operation, int x, int y) {
  final sx = (x + operation.sourceOffset.dx).round().clamp(0, image.width - 1);
  final sy = (y + operation.sourceOffset.dy).round().clamp(0, image.height - 1);
  return _Rgba.fromPixel(image.getPixel(sx, sy));
}

_Rgba _healColor(_Rgba source, _Rgba target) {
  final delta = target.luminance - source.luminance;
  return _Rgba(
    (source.r + delta).clamp(0, 255).round(),
    (source.g + delta).clamp(0, 255).round(),
    (source.b + delta).clamp(0, 255).round(),
    source.a,
  );
}

_Rgba? _sampleSurroundingColor(
  img.Image image,
  LayerMask mask,
  _PixelBounds bounds,
) {
  var red = 0.0;
  var green = 0.0;
  var blue = 0.0;
  var alpha = 0.0;
  var count = 0;

  final radius = max(2, _maxFeather(mask).ceil() + 2);
  final left = (bounds.left - radius).clamp(0, image.width - 1);
  final top = (bounds.top - radius).clamp(0, image.height - 1);
  final right = (bounds.right + radius).clamp(0, image.width);
  final bottom = (bounds.bottom + radius).clamp(0, image.height);

  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      if (_maskValueAt(image, mask, x, y) > 0) continue;
      final nearHorizontal = x >= bounds.left && x < bounds.right;
      final nearVertical = y >= bounds.top && y < bounds.bottom;
      if (!nearHorizontal && !nearVertical) continue;

      final pixel = image.getPixel(x, y);
      red += pixel.r;
      green += pixel.g;
      blue += pixel.b;
      alpha += pixel.a;
      count++;
    }
  }

  if (count == 0) return null;
  return _Rgba(
    (red / count).round(),
    (green / count).round(),
    (blue / count).round(),
    (alpha / count).round(),
  );
}

double _maskValueAt(img.Image image, LayerMask mask, int x, int y) {
  var value = 0.0;
  for (final primitive in mask.primitives) {
    final primitiveValue = _primitiveValueAt(image, primitive, x, y);
    switch (primitive.operation) {
      case LayerMaskOperation.add:
        value = max(value, primitiveValue);
        break;
      case LayerMaskOperation.subtract:
        value = max(0, value - primitiveValue);
        break;
      case LayerMaskOperation.intersect:
        value = min(value, primitiveValue);
        break;
    }
  }

  if (mask.inverted) value = 1 - value;
  return (value * mask.opacity).clamp(0.0, 1.0);
}

double _primitiveValueAt(
  img.Image image,
  LayerMaskPrimitive primitive,
  int x,
  int y,
) {
  final point = Offset(x + 0.5, y + 0.5);
  final bounds = primitive.bounds;

  switch (primitive.type) {
    case LayerMaskPrimitiveType.rectangle:
      if (bounds == null || !bounds.contains(point)) return 0;
      return _featheredRectValue(bounds, point, primitive.feather);
    case LayerMaskPrimitiveType.oval:
      if (bounds == null) return 0;
      return _ovalValue(bounds, point, primitive.feather);
    case LayerMaskPrimitiveType.polygon:
      if (primitive.points.length < 3) return 0;
      return _pointInPolygon(point, primitive.points) ? 1 : 0;
    case LayerMaskPrimitiveType.path:
      if (primitive.points.length < 2) return 0;
      final radius = max(1.0, primitive.feather);
      return _distanceToPath(point, primitive.points) <= radius ? 1 : 0;
    case LayerMaskPrimitiveType.colorRange:
      final color = primitive.color;
      if (color == null) return 0;
      final pixel = image.getPixel(x, y);
      final distance = sqrt(
        pow(pixel.r - (color.r * 255), 2) +
            pow(pixel.g - (color.g * 255), 2) +
            pow(pixel.b - (color.b * 255), 2),
      );
      final tolerance = primitive.tolerance <= 0 ? 0 : primitive.tolerance;
      return distance <= tolerance ? 1 : 0;
  }
}

double _featheredRectValue(Rect bounds, Offset point, double feather) {
  if (feather <= 0) return 1;
  final distance = min(
    min(point.dx - bounds.left, bounds.right - point.dx),
    min(point.dy - bounds.top, bounds.bottom - point.dy),
  );
  return (distance / feather).clamp(0.0, 1.0);
}

double _ovalValue(Rect bounds, Offset point, double feather) {
  final rx = bounds.width / 2;
  final ry = bounds.height / 2;
  if (rx <= 0 || ry <= 0) return 0;

  final dx = (point.dx - bounds.center.dx) / rx;
  final dy = (point.dy - bounds.center.dy) / ry;
  final distance = sqrt(dx * dx + dy * dy);
  if (distance > 1) return 0;
  if (feather <= 0) return 1;
  return ((1 - distance) * min(rx, ry) / feather).clamp(0.0, 1.0);
}

bool _pointInPolygon(Offset point, List<Offset> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final pi = polygon[i];
    final pj = polygon[j];
    final intersects =
        ((pi.dy > point.dy) != (pj.dy > point.dy)) &&
        (point.dx <
            (pj.dx - pi.dx) * (point.dy - pi.dy) / (pj.dy - pi.dy) + pi.dx);
    if (intersects) inside = !inside;
  }
  return inside;
}

double _distanceToPath(Offset point, List<Offset> path) {
  var minDistance = double.infinity;
  for (var i = 0; i < path.length - 1; i++) {
    minDistance = min(
      minDistance,
      _distanceToSegment(point, path[i], path[i + 1]),
    );
  }
  return minDistance;
}

double _distanceToSegment(Offset point, Offset a, Offset b) {
  final dx = b.dx - a.dx;
  final dy = b.dy - a.dy;
  if (dx == 0 && dy == 0) return (point - a).distance;

  final t =
      (((point.dx - a.dx) * dx + (point.dy - a.dy) * dy) / (dx * dx + dy * dy))
          .clamp(0.0, 1.0);
  return (point - Offset(a.dx + t * dx, a.dy + t * dy)).distance;
}

_PixelBounds _operationBounds(LayerMask mask, img.Image image) {
  Rect? rect;
  for (final primitive in mask.primitives) {
    final primitiveRect = _primitiveBounds(primitive);
    if (primitiveRect == null) continue;
    rect = rect == null ? primitiveRect : rect.expandToInclude(primitiveRect);
  }

  rect ??= Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
  return _PixelBounds(
    rect.left.floor().clamp(0, image.width - 1),
    rect.top.floor().clamp(0, image.height - 1),
    rect.right.ceil().clamp(0, image.width),
    rect.bottom.ceil().clamp(0, image.height),
  );
}

Rect? _primitiveBounds(LayerMaskPrimitive primitive) {
  if (primitive.bounds != null) return primitive.bounds;
  if (primitive.points.isEmpty) return null;

  var left = primitive.points.first.dx;
  var top = primitive.points.first.dy;
  var right = left;
  var bottom = top;
  for (final point in primitive.points.skip(1)) {
    left = min(left, point.dx);
    top = min(top, point.dy);
    right = max(right, point.dx);
    bottom = max(bottom, point.dy);
  }

  final radius = max(1.0, primitive.feather);
  return Rect.fromLTRB(
    left - radius,
    top - radius,
    right + radius,
    bottom + radius,
  );
}

double _maxFeather(LayerMask mask) {
  return mask.primitives.fold<double>(
    0,
    (maxFeather, primitive) => max(maxFeather, primitive.feather),
  );
}

class _PixelBounds {
  const _PixelBounds(this.left, this.top, this.right, this.bottom);

  final int left;
  final int top;
  final int right;
  final int bottom;
}

class _Rgba {
  const _Rgba(this.r, this.g, this.b, this.a);

  factory _Rgba.fromPixel(dynamic pixel) {
    return _Rgba(
      pixel.r.round(),
      pixel.g.round(),
      pixel.b.round(),
      pixel.a.round(),
    );
  }

  final int r;
  final int g;
  final int b;
  final int a;

  double get luminance => 0.2126 * r + 0.7152 * g + 0.0722 * b;

  static _Rgba mix(_Rgba a, _Rgba b, double amount) {
    return _Rgba(
      (a.r + (b.r - a.r) * amount).round().clamp(0, 255),
      (a.g + (b.g - a.g) * amount).round().clamp(0, 255),
      (a.b + (b.b - a.b) * amount).round().clamp(0, 255),
      (a.a + (b.a - a.a) * amount).round().clamp(0, 255),
    );
  }
}
