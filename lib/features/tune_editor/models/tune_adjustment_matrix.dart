import 'package:flutter/foundation.dart';

import '/core/constants/int_constants.dart';
import '/shared/extensions/num_extension.dart';
import '/shared/utils/parser/double_parser.dart';
import 'advanced_color_adjustments.dart';

export 'advanced_color_adjustments.dart';

/// A class representing the adjustment matrix for a tune adjustment item.
///
/// This class holds the adjustment [id], the [value] of the adjustment, and
/// the corresponding transformation [matrix] that applies the adjustment.
class TuneAdjustmentMatrix {
  /// Creates a [TuneAdjustmentMatrix] instance from a [Map] representation.
  ///
  /// This factory constructor extracts [id], [value], and [matrix] from the
  /// provided [map].
  factory TuneAdjustmentMatrix.fromMap(Map<String, dynamic> map) {
    return TuneAdjustmentMatrix(
      id: map['id']?.toString() ?? '-',
      value: safeParseDouble(map['value']?.toString()),
      matrix: (map['matrix'] as List?)?.map(safeParseDouble).toList() ?? [],
      curves: map['curves'] == null
          ? null
          : CurvesAdjustment.fromMap(Map<String, dynamic>.from(map['curves'])),
      levels: map['levels'] == null
          ? null
          : LevelsAdjustment.fromMap(Map<String, dynamic>.from(map['levels'])),
      hsl: map['hsl'] == null
          ? null
          : HslAdjustment.fromMap(Map<String, dynamic>.from(map['hsl'])),
      colorGrading: map['colorGrading'] == null
          ? null
          : ColorGradingAdjustment.fromMap(
              Map<String, dynamic>.from(map['colorGrading']),
            ),
    );
  }

  /// Creates a [TuneAdjustmentMatrix] with the given [id], [value], and
  /// [matrix].
  ///
  /// - [id] is the unique identifier for the adjustment.
  /// - [value] is the adjustment value.
  /// - [matrix] is a list of doubles representing the matrix transformation.
  const TuneAdjustmentMatrix({
    required this.id,
    required this.value,
    required this.matrix,
    this.curves,
    this.levels,
    this.hsl,
    this.colorGrading,
  });

  /// The unique identifier for the tune adjustment.
  final String id;

  /// The value of the tune adjustment.
  final double value;

  /// The transformation matrix associated with the tune adjustment.
  final List<double> matrix;

  /// Optional editable RGB/per-channel curves data.
  final CurvesAdjustment? curves;

  /// Optional editable RGB/per-channel levels data.
  final LevelsAdjustment? levels;

  /// Optional editable hue/saturation/luminance range data.
  final HslAdjustment? hsl;

  /// Optional editable shadow/midtone/highlight color grading data.
  final ColorGradingAdjustment? colorGrading;

  /// Whether this tune adjustment carries pro color metadata that must be
  /// preserved even when the scalar [value] is zero.
  bool get hasAdvancedAdjustments =>
      curves != null || levels != null || hsl != null || colorGrading != null;

  /// Converts this [TuneAdjustmentMatrix] instance into a [Map] representation.
  ///
  /// The map contains the [id], [value], and [matrix] as key-value pairs.
  Map<String, dynamic> toMap({int maxDecimalPlaces = kMaxSafeDecimalPlaces}) {
    return {
      'id': id,
      'value': value.roundSmart(maxDecimalPlaces),
      'matrix': matrix
          .map((value) => value.roundSmart(maxDecimalPlaces))
          .toList(),
      if (curves != null)
        'curves': curves!.toMap(maxDecimalPlaces: maxDecimalPlaces),
      if (levels != null)
        'levels': levels!.toMap(maxDecimalPlaces: maxDecimalPlaces),
      if (hsl != null) 'hsl': hsl!.toMap(maxDecimalPlaces: maxDecimalPlaces),
      if (colorGrading != null)
        'colorGrading': colorGrading!.toMap(maxDecimalPlaces: maxDecimalPlaces),
    };
  }

  /// Creates a copy of this [TuneAdjustmentMatrix] instance with the same
  /// values.
  ///
  /// The [copy] method allows duplicating the matrix with identical properties.
  TuneAdjustmentMatrix copy() {
    return TuneAdjustmentMatrix(
      id: id,
      value: value,
      matrix: [...matrix],
      curves: curves,
      levels: levels,
      hsl: hsl,
      colorGrading: colorGrading,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TuneAdjustmentMatrix &&
        other.id == id &&
        other.value == value &&
        listEquals(other.matrix, matrix) &&
        other.curves == curves &&
        other.levels == levels &&
        other.hsl == hsl &&
        other.colorGrading == colorGrading;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      value.hashCode ^
      Object.hashAll(matrix) ^
      curves.hashCode ^
      levels.hashCode ^
      hsl.hashCode ^
      colorGrading.hashCode;
}
