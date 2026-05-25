import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '/core/constants/int_constants.dart';
import '/shared/extensions/color_extension.dart';
import '/shared/extensions/num_extension.dart';
import '/shared/utils/parser/bool_parser.dart';
import '/shared/utils/parser/double_parser.dart';
import '/shared/utils/parser/int_parser.dart';

/// The geometric or sampled source for an editor selection.
enum EditorSelectionType {
  /// A rectangular selection.
  rectangle,

  /// An elliptical selection.
  ellipse,

  /// A straight-edge polygon selection.
  polygon,

  /// A freehand/lasso selection.
  lasso,

  /// A selection sampled from a target color and tolerance.
  colorRange,
}

/// A serializable selection primitive shared by selection, masking, and
/// future retouching tools.
class EditorSelection {
  /// Creates an editor selection.
  const EditorSelection({
    required this.type,
    this.bounds,
    this.points = const [],
    this.feather = 0,
    this.inverted = false,
    this.tolerance = 0,
    this.color,
  }) : assert(feather >= 0, 'feather must be greater than or equal to 0'),
       assert(tolerance >= 0, 'tolerance must be greater than or equal to 0');

  /// Creates an editor selection from a serialized map.
  factory EditorSelection.fromMap(Map<String, dynamic> map) {
    final boundsMap = map['bounds'];

    return EditorSelection(
      type: EditorSelectionType.values.firstWhere(
        (item) => item.name == map['type'],
        orElse: () => EditorSelectionType.rectangle,
      ),
      bounds: boundsMap is Map<String, dynamic>
          ? _rectFromMap(boundsMap)
          : boundsMap is Map
          ? _rectFromMap(Map<String, dynamic>.from(boundsMap))
          : null,
      points: _pointsFromMap(map['points']),
      feather: safeParseDouble(map['feather']),
      inverted: safeParseBool(map['inverted']),
      tolerance: safeParseDouble(map['tolerance']),
      color: map['color'] != null ? Color(safeParseInt(map['color'])) : null,
    );
  }

  /// Selection type.
  final EditorSelectionType type;

  /// Optional bounding rectangle for rectangle, ellipse, and sampled
  /// selections.
  final Rect? bounds;

  /// Selection vertices or lasso path points.
  final List<Offset> points;

  /// Feather radius in logical pixels.
  final double feather;

  /// Whether this selection represents the inverse selected area.
  final bool inverted;

  /// Color-range matching tolerance.
  final double tolerance;

  /// Optional sampled color for color-range selections.
  final Color? color;

  /// Whether the selection has no usable geometry or sampled color.
  bool get isEmpty => bounds == null && points.isEmpty && color == null;

  /// Converts this selection to a serializable map.
  Map<String, dynamic> toMap({int maxDecimalPlaces = kMaxSafeDecimalPlaces}) {
    return {
      'type': type.name,
      if (bounds != null) 'bounds': _rectToMap(bounds!, maxDecimalPlaces),
      if (points.isNotEmpty)
        'points': points
            .map((point) => _offsetToMap(point, maxDecimalPlaces))
            .toList(),
      if (feather != 0) 'feather': feather.roundSmart(maxDecimalPlaces),
      if (inverted) 'inverted': inverted,
      if (tolerance != 0) 'tolerance': tolerance.roundSmart(maxDecimalPlaces),
      if (color != null) 'color': color!.toHex(),
    };
  }

  /// Creates a copy of this selection with overridden values.
  EditorSelection copyWith({
    EditorSelectionType? type,
    Rect? bounds,
    List<Offset>? points,
    double? feather,
    bool? inverted,
    double? tolerance,
    Color? color,
  }) {
    return EditorSelection(
      type: type ?? this.type,
      bounds: bounds ?? this.bounds,
      points: points ?? this.points,
      feather: feather ?? this.feather,
      inverted: inverted ?? this.inverted,
      tolerance: tolerance ?? this.tolerance,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EditorSelection &&
        other.type == type &&
        other.bounds == bounds &&
        listEquals(other.points, points) &&
        other.feather == feather &&
        other.inverted == inverted &&
        other.tolerance == tolerance &&
        other.color?.toHex() == color?.toHex();
  }

  @override
  int get hashCode {
    return type.hashCode ^
        bounds.hashCode ^
        points.hashCode ^
        feather.hashCode ^
        inverted.hashCode ^
        tolerance.hashCode ^
        (color?.toHex().hashCode ?? 0);
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
