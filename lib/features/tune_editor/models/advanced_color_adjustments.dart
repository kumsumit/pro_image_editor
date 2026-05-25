import 'dart:math';

import 'package:flutter/foundation.dart';

import '/core/constants/int_constants.dart';
import '/shared/extensions/num_extension.dart';
import '/shared/utils/parser/double_parser.dart';

/// RGB channels that can receive independent pro color adjustments.
enum ColorAdjustmentChannel {
  /// Composite RGB channel.
  rgb,

  /// Red channel.
  red,

  /// Green channel.
  green,

  /// Blue channel.
  blue,
}

/// A single point in a tone curve.
class CurvePoint {
  /// Creates a curve point with normalized input and output values.
  const CurvePoint({required this.input, required this.output});

  /// Creates a curve point from a serialized map.
  factory CurvePoint.fromMap(Map<String, dynamic> map) {
    return CurvePoint(
      input: safeParseDouble(map['input']),
      output: safeParseDouble(map['output']),
    );
  }

  /// Input position from 0 to 1.
  final double input;

  /// Output value from 0 to 1.
  final double output;

  /// Converts this point to a serializable map.
  Map<String, dynamic> toMap({int maxDecimalPlaces = kMaxSafeDecimalPlaces}) {
    return {
      'input': input.roundSmart(maxDecimalPlaces),
      'output': output.roundSmart(maxDecimalPlaces),
    };
  }

  /// Creates a copy of this point with updated values.
  CurvePoint copyWith({double? input, double? output}) {
    return CurvePoint(
      input: input ?? this.input,
      output: output ?? this.output,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurvePoint &&
        other.input == input &&
        other.output == output;
  }

  @override
  int get hashCode => input.hashCode ^ output.hashCode;
}

/// Editable per-channel curves adjustment.
class CurvesAdjustment {
  /// Creates an editable curves adjustment.
  const CurvesAdjustment({
    this.rgb = const [],
    this.red = const [],
    this.green = const [],
    this.blue = const [],
  });

  /// Creates a curves adjustment from a serialized map.
  factory CurvesAdjustment.fromMap(Map<String, dynamic> map) {
    List<CurvePoint> parsePoints(String key) {
      return (map[key] as List<dynamic>? ?? [])
          .map((point) => CurvePoint.fromMap(Map<String, dynamic>.from(point)))
          .toList();
    }

    return CurvesAdjustment(
      rgb: parsePoints('rgb'),
      red: parsePoints('red'),
      green: parsePoints('green'),
      blue: parsePoints('blue'),
    );
  }

  /// Composite RGB curve points.
  final List<CurvePoint> rgb;

  /// Red channel curve points.
  final List<CurvePoint> red;

  /// Green channel curve points.
  final List<CurvePoint> green;

  /// Blue channel curve points.
  final List<CurvePoint> blue;

  /// Whether all curve channels are identity curves.
  bool get isIdentity =>
      _isIdentityCurve(rgb) &&
      _isIdentityCurve(red) &&
      _isIdentityCurve(green) &&
      _isIdentityCurve(blue);

  /// Converts the curves into 8-bit lookup tables for renderer/export use.
  Map<ColorAdjustmentChannel, List<int>> toLuts({int size = 256}) {
    assert(size > 1, 'LUT size must be greater than one.');
    return {
      ColorAdjustmentChannel.rgb: _buildLut(rgb, size),
      ColorAdjustmentChannel.red: _buildLut(red, size),
      ColorAdjustmentChannel.green: _buildLut(green, size),
      ColorAdjustmentChannel.blue: _buildLut(blue, size),
    };
  }

  /// Converts this adjustment to a serializable map.
  Map<String, dynamic> toMap({int maxDecimalPlaces = kMaxSafeDecimalPlaces}) {
    List<Map<String, dynamic>> convert(List<CurvePoint> points) {
      return points
          .map((point) => point.toMap(maxDecimalPlaces: maxDecimalPlaces))
          .toList();
    }

    return {
      if (rgb.isNotEmpty) 'rgb': convert(rgb),
      if (red.isNotEmpty) 'red': convert(red),
      if (green.isNotEmpty) 'green': convert(green),
      if (blue.isNotEmpty) 'blue': convert(blue),
    };
  }

  /// Creates a copy with updated channel points.
  CurvesAdjustment copyWith({
    List<CurvePoint>? rgb,
    List<CurvePoint>? red,
    List<CurvePoint>? green,
    List<CurvePoint>? blue,
  }) {
    return CurvesAdjustment(
      rgb: rgb ?? this.rgb,
      red: red ?? this.red,
      green: green ?? this.green,
      blue: blue ?? this.blue,
    );
  }

  static bool _isIdentityCurve(List<CurvePoint> points) {
    if (points.isEmpty) return true;
    if (points.length != 2) return false;

    final sorted = [...points]..sort((a, b) => a.input.compareTo(b.input));
    return sorted.first.input == 0 &&
        sorted.first.output == 0 &&
        sorted.last.input == 1 &&
        sorted.last.output == 1;
  }

  static List<int> _buildLut(List<CurvePoint> points, int size) {
    final sorted = points.isEmpty
        ? const [
            CurvePoint(input: 0, output: 0),
            CurvePoint(input: 1, output: 1),
          ]
        : ([...points]..sort((a, b) => a.input.compareTo(b.input)));

    return List<int>.generate(size, (index) {
      final input = index / (size - 1);
      final output = _interpolate(sorted, input).clamp(0.0, 1.0);
      return (output * 255).round().clamp(0, 255);
    });
  }

  static double _interpolate(List<CurvePoint> points, double input) {
    if (input <= points.first.input) return points.first.output;
    if (input >= points.last.input) return points.last.output;

    for (var i = 0; i < points.length - 1; i++) {
      final left = points[i];
      final right = points[i + 1];
      if (input < left.input || input > right.input) continue;

      final span = right.input - left.input;
      if (span == 0) return right.output;
      final amount = (input - left.input) / span;
      return left.output + (right.output - left.output) * amount;
    }

    return input;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurvesAdjustment &&
        listEquals(other.rgb, rgb) &&
        listEquals(other.red, red) &&
        listEquals(other.green, green) &&
        listEquals(other.blue, blue);
  }

  @override
  int get hashCode =>
      Object.hashAll(rgb) ^
      Object.hashAll(red) ^
      Object.hashAll(green) ^
      Object.hashAll(blue);
}

/// Per-channel levels configuration.
class ChannelLevels {
  /// Creates a channel levels adjustment with normalized values.
  const ChannelLevels({
    this.inputBlack = 0,
    this.inputWhite = 1,
    this.gamma = 1,
    this.outputBlack = 0,
    this.outputWhite = 1,
  });

  /// Creates levels from a serialized map.
  factory ChannelLevels.fromMap(Map<String, dynamic> map) {
    return ChannelLevels(
      inputBlack: safeParseDouble(map['inputBlack']),
      inputWhite: safeParseDouble(map['inputWhite'], fallback: 1.0),
      gamma: safeParseDouble(map['gamma'], fallback: 1.0),
      outputBlack: safeParseDouble(map['outputBlack']),
      outputWhite: safeParseDouble(map['outputWhite'], fallback: 1.0),
    );
  }

  /// Input black point from 0 to 1.
  final double inputBlack;

  /// Input white point from 0 to 1.
  final double inputWhite;

  /// Midtone gamma. Values below 1 brighten midtones, above 1 darken them.
  final double gamma;

  /// Output black point from 0 to 1.
  final double outputBlack;

  /// Output white point from 0 to 1.
  final double outputWhite;

  /// Whether this level set leaves the channel unchanged.
  bool get isIdentity =>
      inputBlack == 0 &&
      inputWhite == 1 &&
      gamma == 1 &&
      outputBlack == 0 &&
      outputWhite == 1;

  /// Applies these levels to a normalized channel value.
  double transform(double value) {
    final inputRange = max(inputWhite - inputBlack, 0.0001);
    final normalized = ((value - inputBlack) / inputRange).clamp(0.0, 1.0);
    final gammaValue = gamma <= 0 ? 1.0 : gamma;
    final corrected = pow(normalized, 1 / gammaValue).toDouble();
    return outputBlack + corrected * (outputWhite - outputBlack);
  }

  /// Converts this channel to a serializable map.
  Map<String, dynamic> toMap({int maxDecimalPlaces = kMaxSafeDecimalPlaces}) {
    return {
      'inputBlack': inputBlack.roundSmart(maxDecimalPlaces),
      'inputWhite': inputWhite.roundSmart(maxDecimalPlaces),
      'gamma': gamma.roundSmart(maxDecimalPlaces),
      'outputBlack': outputBlack.roundSmart(maxDecimalPlaces),
      'outputWhite': outputWhite.roundSmart(maxDecimalPlaces),
    };
  }

  /// Creates a copy with updated values.
  ChannelLevels copyWith({
    double? inputBlack,
    double? inputWhite,
    double? gamma,
    double? outputBlack,
    double? outputWhite,
  }) {
    return ChannelLevels(
      inputBlack: inputBlack ?? this.inputBlack,
      inputWhite: inputWhite ?? this.inputWhite,
      gamma: gamma ?? this.gamma,
      outputBlack: outputBlack ?? this.outputBlack,
      outputWhite: outputWhite ?? this.outputWhite,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChannelLevels &&
        other.inputBlack == inputBlack &&
        other.inputWhite == inputWhite &&
        other.gamma == gamma &&
        other.outputBlack == outputBlack &&
        other.outputWhite == outputWhite;
  }

  @override
  int get hashCode =>
      inputBlack.hashCode ^
      inputWhite.hashCode ^
      gamma.hashCode ^
      outputBlack.hashCode ^
      outputWhite.hashCode;
}

/// Editable RGB/per-channel levels adjustment.
class LevelsAdjustment {
  /// Creates a levels adjustment.
  const LevelsAdjustment({
    this.rgb = const ChannelLevels(),
    this.red = const ChannelLevels(),
    this.green = const ChannelLevels(),
    this.blue = const ChannelLevels(),
  });

  /// Creates levels from a serialized map.
  factory LevelsAdjustment.fromMap(Map<String, dynamic> map) {
    ChannelLevels parse(String key) {
      return map[key] == null
          ? const ChannelLevels()
          : ChannelLevels.fromMap(Map<String, dynamic>.from(map[key]));
    }

    return LevelsAdjustment(
      rgb: parse('rgb'),
      red: parse('red'),
      green: parse('green'),
      blue: parse('blue'),
    );
  }

  /// Composite RGB levels.
  final ChannelLevels rgb;

  /// Red channel levels.
  final ChannelLevels red;

  /// Green channel levels.
  final ChannelLevels green;

  /// Blue channel levels.
  final ChannelLevels blue;

  /// Whether every channel is identity.
  bool get isIdentity =>
      rgb.isIdentity && red.isIdentity && green.isIdentity && blue.isIdentity;

  /// Converts levels into 8-bit lookup tables for renderer/export use.
  Map<ColorAdjustmentChannel, List<int>> toLuts({int size = 256}) {
    assert(size > 1, 'LUT size must be greater than one.');

    List<int> build(ChannelLevels channel) {
      return List<int>.generate(size, (index) {
        final input = index / (size - 1);
        final output = channel.transform(rgb.transform(input)).clamp(0.0, 1.0);
        return (output * 255).round().clamp(0, 255);
      });
    }

    return {
      ColorAdjustmentChannel.rgb: List<int>.generate(size, (index) {
        final input = index / (size - 1);
        return (rgb.transform(input).clamp(0.0, 1.0) * 255).round().clamp(
          0,
          255,
        );
      }),
      ColorAdjustmentChannel.red: build(red),
      ColorAdjustmentChannel.green: build(green),
      ColorAdjustmentChannel.blue: build(blue),
    };
  }

  /// Produces a ColorFilter matrix for linear levels preview.
  ///
  /// Gamma is nonlinear, so accurate gamma rendering should use [toLuts].
  List<double> toLinearPreviewMatrix() {
    final r = _linearChannel(rgb, red);
    final g = _linearChannel(rgb, green);
    final b = _linearChannel(rgb, blue);

    return [
      r.scale,
      0,
      0,
      0,
      r.offset * 255,
      0,
      g.scale,
      0,
      0,
      g.offset * 255,
      0,
      0,
      b.scale,
      0,
      b.offset * 255,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  /// Converts this levels adjustment to a serializable map.
  Map<String, dynamic> toMap({int maxDecimalPlaces = kMaxSafeDecimalPlaces}) {
    return {
      if (!rgb.isIdentity) 'rgb': rgb.toMap(maxDecimalPlaces: maxDecimalPlaces),
      if (!red.isIdentity) 'red': red.toMap(maxDecimalPlaces: maxDecimalPlaces),
      if (!green.isIdentity)
        'green': green.toMap(maxDecimalPlaces: maxDecimalPlaces),
      if (!blue.isIdentity)
        'blue': blue.toMap(maxDecimalPlaces: maxDecimalPlaces),
    };
  }

  /// Creates a copy with updated channel levels.
  LevelsAdjustment copyWith({
    ChannelLevels? rgb,
    ChannelLevels? red,
    ChannelLevels? green,
    ChannelLevels? blue,
  }) {
    return LevelsAdjustment(
      rgb: rgb ?? this.rgb,
      red: red ?? this.red,
      green: green ?? this.green,
      blue: blue ?? this.blue,
    );
  }

  static _LinearChannel _linearChannel(
    ChannelLevels rgb,
    ChannelLevels channel,
  ) {
    final rgbLinear = _linearParts(rgb);
    final channelLinear = _linearParts(channel);
    return _LinearChannel(
      scale: rgbLinear.scale * channelLinear.scale,
      offset: rgbLinear.offset * channelLinear.scale + channelLinear.offset,
    );
  }

  static _LinearChannel _linearParts(ChannelLevels levels) {
    final inputRange = max(levels.inputWhite - levels.inputBlack, 0.0001);
    final outputRange = levels.outputWhite - levels.outputBlack;
    final scale = outputRange / inputRange;
    final offset = levels.outputBlack - levels.inputBlack * scale;
    return _LinearChannel(scale: scale, offset: offset);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LevelsAdjustment &&
        other.rgb == rgb &&
        other.red == red &&
        other.green == green &&
        other.blue == blue;
  }

  @override
  int get hashCode =>
      rgb.hashCode ^ red.hashCode ^ green.hashCode ^ blue.hashCode;
}

class _LinearChannel {
  const _LinearChannel({required this.scale, required this.offset});

  final double scale;
  final double offset;
}

/// Color ranges used by HSL adjustments.
enum HslColorRange {
  /// Entire image.
  global,

  /// Reds.
  red,

  /// Oranges.
  orange,

  /// Yellows.
  yellow,

  /// Greens.
  green,

  /// Aquas/cyans.
  aqua,

  /// Blues.
  blue,

  /// Purples.
  purple,

  /// Magentas.
  magenta,
}

/// Hue, saturation, and luminance values for one color range.
class HslRangeAdjustment {
  /// Creates an HSL range adjustment.
  const HslRangeAdjustment({
    required this.range,
    this.hue = 0,
    this.saturation = 0,
    this.luminance = 0,
  });

  /// Creates an HSL range adjustment from a serialized map.
  factory HslRangeAdjustment.fromMap(Map<String, dynamic> map) {
    return HslRangeAdjustment(
      range: HslColorRange.values.firstWhere(
        (item) => item.name == map['range'],
        orElse: () => HslColorRange.global,
      ),
      hue: safeParseDouble(map['hue']),
      saturation: safeParseDouble(map['saturation']),
      luminance: safeParseDouble(map['luminance']),
    );
  }

  /// Target HSL color range.
  final HslColorRange range;

  /// Hue shift in normalized turns, where 1 equals a full color wheel.
  final double hue;

  /// Saturation shift from -1 to 1.
  final double saturation;

  /// Luminance shift from -1 to 1.
  final double luminance;

  /// Whether this range leaves pixels unchanged.
  bool get isIdentity => hue == 0 && saturation == 0 && luminance == 0;

  /// Converts this adjustment to a serializable map.
  Map<String, dynamic> toMap({int maxDecimalPlaces = kMaxSafeDecimalPlaces}) {
    return {
      'range': range.name,
      'hue': hue.roundSmart(maxDecimalPlaces),
      'saturation': saturation.roundSmart(maxDecimalPlaces),
      'luminance': luminance.roundSmart(maxDecimalPlaces),
    };
  }

  /// Creates a copy with updated values.
  HslRangeAdjustment copyWith({
    HslColorRange? range,
    double? hue,
    double? saturation,
    double? luminance,
  }) {
    return HslRangeAdjustment(
      range: range ?? this.range,
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      luminance: luminance ?? this.luminance,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HslRangeAdjustment &&
        other.range == range &&
        other.hue == hue &&
        other.saturation == saturation &&
        other.luminance == luminance;
  }

  @override
  int get hashCode =>
      range.hashCode ^ hue.hashCode ^ saturation.hashCode ^ luminance.hashCode;
}

/// Editable HSL adjustment stack.
class HslAdjustment {
  /// Creates an HSL adjustment stack.
  const HslAdjustment({this.ranges = const []});

  /// Creates HSL adjustments from a serialized map.
  factory HslAdjustment.fromMap(Map<String, dynamic> map) {
    return HslAdjustment(
      ranges: (map['ranges'] as List<dynamic>? ?? []).map((item) {
        return HslRangeAdjustment.fromMap(Map<String, dynamic>.from(item));
      }).toList(),
    );
  }

  /// HSL range adjustments.
  final List<HslRangeAdjustment> ranges;

  /// Whether every HSL range is identity.
  bool get isIdentity => ranges.every((item) => item.isIdentity);

  /// Converts this adjustment stack to a serializable map.
  Map<String, dynamic> toMap({int maxDecimalPlaces = kMaxSafeDecimalPlaces}) {
    return {
      'ranges': ranges
          .where((item) => !item.isIdentity)
          .map((item) => item.toMap(maxDecimalPlaces: maxDecimalPlaces))
          .toList(),
    };
  }

  /// Creates a copy with updated ranges.
  HslAdjustment copyWith({List<HslRangeAdjustment>? ranges}) {
    return HslAdjustment(ranges: ranges ?? this.ranges);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HslAdjustment && listEquals(other.ranges, ranges);
  }

  @override
  int get hashCode => Object.hashAll(ranges);
}

/// Tonal wheels used by color grading adjustments.
enum ColorGradingRange {
  /// Shadow wheel.
  shadows,

  /// Midtone wheel.
  midtones,

  /// Highlight wheel.
  highlights,
}

/// One color-grading wheel value.
class ColorGradingWheel {
  /// Creates a color grading wheel adjustment.
  const ColorGradingWheel({
    required this.range,
    this.hue = 0,
    this.saturation = 0,
    this.luminance = 0,
    this.blending = 0.5,
  });

  /// Creates a color grading wheel from a serialized map.
  factory ColorGradingWheel.fromMap(Map<String, dynamic> map) {
    return ColorGradingWheel(
      range: ColorGradingRange.values.firstWhere(
        (item) => item.name == map['range'],
        orElse: () => ColorGradingRange.midtones,
      ),
      hue: safeParseDouble(map['hue']),
      saturation: safeParseDouble(map['saturation']),
      luminance: safeParseDouble(map['luminance']),
      blending: safeParseDouble(map['blending'], fallback: 0.5),
    );
  }

  /// Target tonal range.
  final ColorGradingRange range;

  /// Hue in normalized turns, where 1 equals a full color wheel.
  final double hue;

  /// Saturation strength from 0 to 1.
  final double saturation;

  /// Luminance offset from -1 to 1.
  final double luminance;

  /// Blend between neighboring tonal ranges.
  final double blending;

  /// Whether this wheel leaves pixels unchanged.
  bool get isIdentity => hue == 0 && saturation == 0 && luminance == 0;

  /// Converts this wheel to a serializable map.
  Map<String, dynamic> toMap({int maxDecimalPlaces = kMaxSafeDecimalPlaces}) {
    return {
      'range': range.name,
      'hue': hue.roundSmart(maxDecimalPlaces),
      'saturation': saturation.roundSmart(maxDecimalPlaces),
      'luminance': luminance.roundSmart(maxDecimalPlaces),
      'blending': blending.roundSmart(maxDecimalPlaces),
    };
  }

  /// Creates a copy with updated values.
  ColorGradingWheel copyWith({
    ColorGradingRange? range,
    double? hue,
    double? saturation,
    double? luminance,
    double? blending,
  }) {
    return ColorGradingWheel(
      range: range ?? this.range,
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      luminance: luminance ?? this.luminance,
      blending: blending ?? this.blending,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorGradingWheel &&
        other.range == range &&
        other.hue == hue &&
        other.saturation == saturation &&
        other.luminance == luminance &&
        other.blending == blending;
  }

  @override
  int get hashCode =>
      range.hashCode ^
      hue.hashCode ^
      saturation.hashCode ^
      luminance.hashCode ^
      blending.hashCode;
}

/// Editable color grading wheel stack.
class ColorGradingAdjustment {
  /// Creates a color grading adjustment.
  const ColorGradingAdjustment({this.wheels = const []});

  /// Creates a color grading adjustment from a serialized map.
  factory ColorGradingAdjustment.fromMap(Map<String, dynamic> map) {
    return ColorGradingAdjustment(
      wheels: (map['wheels'] as List<dynamic>? ?? [])
          .map((item) => ColorGradingWheel.fromMap(Map.from(item)))
          .toList(),
    );
  }

  /// Color grading wheels.
  final List<ColorGradingWheel> wheels;

  /// Whether every wheel is identity.
  bool get isIdentity => wheels.every((item) => item.isIdentity);

  /// Converts this adjustment to a serializable map.
  Map<String, dynamic> toMap({int maxDecimalPlaces = kMaxSafeDecimalPlaces}) {
    return {
      'wheels': wheels
          .where((item) => !item.isIdentity)
          .map((item) => item.toMap(maxDecimalPlaces: maxDecimalPlaces))
          .toList(),
    };
  }

  /// Creates a copy with updated wheels.
  ColorGradingAdjustment copyWith({List<ColorGradingWheel>? wheels}) {
    return ColorGradingAdjustment(wheels: wheels ?? this.wheels);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorGradingAdjustment && listEquals(other.wheels, wheels);
  }

  @override
  int get hashCode => Object.hashAll(wheels);
}
