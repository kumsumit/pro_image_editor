import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '/core/constants/int_constants.dart';
import '/core/models/selections/editor_selection.dart';
import '/shared/extensions/color_extension.dart';
import '/shared/extensions/num_extension.dart';
import '/shared/utils/parser/bool_parser.dart';
import '/shared/utils/parser/double_parser.dart';

/// The geometry stored in a mask primitive.
enum LayerMaskPrimitiveType {
  /// Rectangular mask primitive.
  rectangle,

  /// Oval mask primitive.
  oval,

  /// Straight-edge polygon mask primitive.
  polygon,

  /// Freehand path mask primitive.
  path,

  /// Color-range mask primitive.
  colorRange,
}

/// How a mask primitive contributes to the accumulated mask.
enum LayerMaskOperation {
  /// Adds visible area to the mask.
  add,

  /// Removes visible area from the mask.
  subtract,

  /// Intersects with the existing visible area.
  intersect,
}

/// A serializable piece of a layer mask.
class LayerMaskPrimitive {
  /// Creates a layer mask primitive.
  const LayerMaskPrimitive({
    required this.type,
    this.operation = LayerMaskOperation.add,
    this.bounds,
    this.points = const [],
    this.feather = 0,
    this.opacity = 1,
    this.tolerance = 0,
    this.color,
  }) : assert(feather >= 0, 'feather must be greater than or equal to 0'),
       assert(opacity >= 0 && opacity <= 1, 'opacity must be between 0 and 1'),
       assert(tolerance >= 0, 'tolerance must be greater than or equal to 0');

  /// Creates a primitive from a selection.
  factory LayerMaskPrimitive.fromSelection(
    EditorSelection selection, {
    LayerMaskOperation operation = LayerMaskOperation.add,
  }) {
    return LayerMaskPrimitive(
      type: switch (selection.type) {
        EditorSelectionType.rectangle => LayerMaskPrimitiveType.rectangle,
        EditorSelectionType.ellipse => LayerMaskPrimitiveType.oval,
        EditorSelectionType.polygon => LayerMaskPrimitiveType.polygon,
        EditorSelectionType.lasso => LayerMaskPrimitiveType.path,
        EditorSelectionType.colorRange => LayerMaskPrimitiveType.colorRange,
      },
      operation: operation,
      bounds: selection.bounds,
      points: selection.points,
      feather: selection.feather,
      tolerance: selection.tolerance,
      color: selection.color,
    );
  }

  /// Creates a primitive from a serialized map.
  factory LayerMaskPrimitive.fromMap(Map<String, dynamic> map) {
    final boundsMap = map['bounds'];

    return LayerMaskPrimitive(
      type: LayerMaskPrimitiveType.values.firstWhere(
        (item) => item.name == map['type'],
        orElse: () => LayerMaskPrimitiveType.rectangle,
      ),
      operation: LayerMaskOperation.values.firstWhere(
        (item) => item.name == map['operation'],
        orElse: () => LayerMaskOperation.add,
      ),
      bounds: boundsMap is Map<String, dynamic>
          ? _rectFromMap(boundsMap)
          : boundsMap is Map
          ? _rectFromMap(Map<String, dynamic>.from(boundsMap))
          : null,
      points: _pointsFromMap(map['points']),
      feather: safeParseDouble(map['feather']),
      opacity: safeParseDouble(map['opacity'], fallback: 1),
      tolerance: safeParseDouble(map['tolerance']),
      color: map['color'] != null ? Color(map['color']) : null,
    );
  }

  /// Primitive type.
  final LayerMaskPrimitiveType type;

  /// How this primitive contributes to the mask.
  final LayerMaskOperation operation;

  /// Optional bounding rectangle.
  final Rect? bounds;

  /// Optional path or polygon points.
  final List<Offset> points;

  /// Feather radius in logical pixels.
  final double feather;

  /// Primitive opacity from 0 to 1.
  final double opacity;

  /// Color-range matching tolerance.
  final double tolerance;

  /// Optional sampled color for color-range masks.
  final Color? color;

  /// Whether this primitive has no usable geometry or sampled color.
  bool get isEmpty => bounds == null && points.isEmpty && color == null;

  /// Converts this primitive to a serializable map.
  Map<String, dynamic> toMap({int maxDecimalPlaces = kMaxSafeDecimalPlaces}) {
    return {
      'type': type.name,
      if (operation != LayerMaskOperation.add) 'operation': operation.name,
      if (bounds != null) 'bounds': _rectToMap(bounds!, maxDecimalPlaces),
      if (points.isNotEmpty)
        'points': points
            .map((point) => _offsetToMap(point, maxDecimalPlaces))
            .toList(),
      if (feather != 0) 'feather': feather.roundSmart(maxDecimalPlaces),
      if (opacity != 1) 'opacity': opacity.roundSmart(maxDecimalPlaces),
      if (tolerance != 0) 'tolerance': tolerance.roundSmart(maxDecimalPlaces),
      if (color != null) 'color': color!.toHex(),
    };
  }

  /// Creates a copy of this primitive with overridden values.
  LayerMaskPrimitive copyWith({
    LayerMaskPrimitiveType? type,
    LayerMaskOperation? operation,
    Rect? bounds,
    List<Offset>? points,
    double? feather,
    double? opacity,
    double? tolerance,
    Color? color,
  }) {
    return LayerMaskPrimitive(
      type: type ?? this.type,
      operation: operation ?? this.operation,
      bounds: bounds ?? this.bounds,
      points: points ?? this.points,
      feather: feather ?? this.feather,
      opacity: opacity ?? this.opacity,
      tolerance: tolerance ?? this.tolerance,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LayerMaskPrimitive &&
        other.type == type &&
        other.operation == operation &&
        other.bounds == bounds &&
        listEquals(other.points, points) &&
        other.feather == feather &&
        other.opacity == opacity &&
        other.tolerance == tolerance &&
        other.color?.toHex() == color?.toHex();
  }

  @override
  int get hashCode {
    return type.hashCode ^
        operation.hashCode ^
        bounds.hashCode ^
        points.hashCode ^
        feather.hashCode ^
        opacity.hashCode ^
        tolerance.hashCode ^
        (color?.toHex().hashCode ?? 0);
  }
}

/// A serializable, editable layer mask.
class LayerMask {
  /// Creates a layer mask.
  const LayerMask({
    this.enabled = true,
    this.inverted = false,
    this.opacity = 1,
    this.primitives = const [],
  }) : assert(opacity >= 0 && opacity <= 1, 'opacity must be between 0 and 1');

  /// Creates a mask from a selection.
  factory LayerMask.fromSelection(EditorSelection selection) {
    return LayerMask(
      inverted: selection.inverted,
      primitives: [LayerMaskPrimitive.fromSelection(selection)],
    );
  }

  /// Creates a mask from a serialized map.
  factory LayerMask.fromMap(Map<String, dynamic> map) {
    return LayerMask(
      enabled: safeParseBool(map['enabled'], fallback: true),
      inverted: safeParseBool(map['inverted']),
      opacity: safeParseDouble(map['opacity'], fallback: 1),
      primitives: List.from(
        map['primitives'] ?? [],
      ).map((item) => LayerMaskPrimitive.fromMap(Map.from(item))).toList(),
    );
  }

  /// Whether the mask is active.
  final bool enabled;

  /// Whether the mask result is inverted.
  final bool inverted;

  /// Overall mask opacity from 0 to 1.
  final double opacity;

  /// Editable mask primitives.
  final List<LayerMaskPrimitive> primitives;

  /// Whether this mask has no primitive data.
  bool get isEmpty => primitives.isEmpty;

  /// Converts this mask to a serializable map.
  Map<String, dynamic> toMap({int maxDecimalPlaces = kMaxSafeDecimalPlaces}) {
    return {
      if (!enabled) 'enabled': enabled,
      if (inverted) 'inverted': inverted,
      if (opacity != 1) 'opacity': opacity.roundSmart(maxDecimalPlaces),
      'primitives': primitives
          .map((item) => item.toMap(maxDecimalPlaces: maxDecimalPlaces))
          .toList(),
    };
  }

  /// Creates a copy of this mask with overridden values.
  LayerMask copyWith({
    bool? enabled,
    bool? inverted,
    double? opacity,
    List<LayerMaskPrimitive>? primitives,
  }) {
    return LayerMask(
      enabled: enabled ?? this.enabled,
      inverted: inverted ?? this.inverted,
      opacity: opacity ?? this.opacity,
      primitives: primitives ?? this.primitives,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LayerMask &&
        other.enabled == enabled &&
        other.inverted == inverted &&
        other.opacity == opacity &&
        listEquals(other.primitives, primitives);
  }

  @override
  int get hashCode {
    return enabled.hashCode ^
        inverted.hashCode ^
        opacity.hashCode ^
        primitives.hashCode;
  }
}

Map<String, dynamic> _rectToMap(Rect rect, int maxDecimalPlaces) => {
  'x': rect.left.roundSmart(maxDecimalPlaces),
  'y': rect.top.roundSmart(maxDecimalPlaces),
  'width': rect.width.roundSmart(maxDecimalPlaces),
  'height': rect.height.roundSmart(maxDecimalPlaces),
};

Rect _rectFromMap(Map<String, dynamic> map) => Rect.fromLTWH(
  safeParseDouble(map['x']),
  safeParseDouble(map['y']),
  safeParseDouble(map['width']),
  safeParseDouble(map['height']),
);

Map<String, dynamic> _offsetToMap(Offset offset, int maxDecimalPlaces) => {
  'x': offset.dx.roundSmart(maxDecimalPlaces),
  'y': offset.dy.roundSmart(maxDecimalPlaces),
};

List<Offset> _pointsFromMap(dynamic rawPoints) {
  return List.from(rawPoints ?? []).map((rawPoint) {
    final pointMap = Map<String, dynamic>.from(rawPoint);
    return Offset(
      safeParseDouble(pointMap['x']),
      safeParseDouble(pointMap['y']),
    );
  }).toList();
}
