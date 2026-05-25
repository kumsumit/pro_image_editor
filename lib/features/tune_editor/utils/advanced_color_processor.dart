import 'dart:math';

import '/features/tune_editor/models/tune_adjustment_matrix.dart';
import '/plugins/image/src/image/image.dart' as img;

/// Applies advanced tune color payloads to an image.
///
/// This renderer handles nonlinear and selective adjustments that cannot be
/// represented by Flutter's 4x5 [ColorFilter.matrix], such as curves, gamma
/// levels, selective HSL ranges, and tonal color-grading wheels.
img.Image applyAdvancedColorAdjustments(
  img.Image source,
  List<TuneAdjustmentMatrix> tuneAdjustments,
) {
  final advancedAdjustments = tuneAdjustments
      .where((item) => item.hasAdvancedAdjustments)
      .toList();
  if (advancedAdjustments.isEmpty) return source;

  final output = img.Image.from(source);

  for (final frame in output.frames) {
    for (var y = 0; y < frame.height; y++) {
      for (var x = 0; x < frame.width; x++) {
        final pixel = frame.getPixel(x, y);
        var color = _Rgb(
          pixel.r.toDouble().clamp(0, 255) / 255,
          pixel.g.toDouble().clamp(0, 255) / 255,
          pixel.b.toDouble().clamp(0, 255) / 255,
        );

        for (final adjustment in advancedAdjustments) {
          color = _applyAdjustment(color, adjustment);
        }

        frame.setPixelRgba(
          x,
          y,
          _toByte(color.r),
          _toByte(color.g),
          _toByte(color.b),
          pixel.a,
        );
      }
    }
  }

  return output;
}

_Rgb _applyAdjustment(_Rgb color, TuneAdjustmentMatrix adjustment) {
  var next = color;

  final curves = adjustment.curves;
  if (curves != null && !curves.isIdentity) {
    final luts = curves.toLuts();
    next = _Rgb(
      _lut(
        luts[ColorAdjustmentChannel.red]!,
        _lut(luts[ColorAdjustmentChannel.rgb]!, next.r),
      ),
      _lut(
        luts[ColorAdjustmentChannel.green]!,
        _lut(luts[ColorAdjustmentChannel.rgb]!, next.g),
      ),
      _lut(
        luts[ColorAdjustmentChannel.blue]!,
        _lut(luts[ColorAdjustmentChannel.rgb]!, next.b),
      ),
    );
  }

  final levels = adjustment.levels;
  if (levels != null && !levels.isIdentity) {
    final luts = levels.toLuts();
    next = _Rgb(
      _lut(luts[ColorAdjustmentChannel.red]!, next.r),
      _lut(luts[ColorAdjustmentChannel.green]!, next.g),
      _lut(luts[ColorAdjustmentChannel.blue]!, next.b),
    );
  }

  final hsl = adjustment.hsl;
  if (hsl != null && !hsl.isIdentity) {
    next = _applyHsl(next, hsl);
  }

  final colorGrading = adjustment.colorGrading;
  if (colorGrading != null && !colorGrading.isIdentity) {
    next = _applyColorGrading(next, colorGrading);
  }

  return next.clamped();
}

_Rgb _applyHsl(_Rgb color, HslAdjustment adjustment) {
  var hsl = _Hsl.fromRgb(color);

  for (final range in adjustment.ranges) {
    if (range.isIdentity) continue;
    final weight = _hslRangeWeight(hsl.h, range.range);
    if (weight == 0) continue;

    hsl = hsl.copyWith(
      h: _wrapHue(hsl.h + range.hue * weight),
      s: _shiftUnitValue(hsl.s, range.saturation * weight),
      l: _shiftUnitValue(hsl.l, range.luminance * weight),
    );
  }

  return hsl.toRgb();
}

_Rgb _applyColorGrading(_Rgb color, ColorGradingAdjustment adjustment) {
  var next = color;

  for (final wheel in adjustment.wheels) {
    if (wheel.isIdentity) continue;

    final luminance = next.luminance;
    final weight = _gradingWeight(luminance, wheel);
    if (weight == 0) continue;

    final tint = _Hsl(
      h: _wrapHue(wheel.hue),
      s: wheel.saturation.clamp(0.0, 1.0),
      l: 0.5,
    ).toRgb();
    final tintStrength = (wheel.saturation * weight).clamp(0.0, 1.0);

    next = _Rgb(
      _mix(next.r, tint.r, tintStrength),
      _mix(next.g, tint.g, tintStrength),
      _mix(next.b, tint.b, tintStrength),
    );

    if (wheel.luminance != 0) {
      next = _Rgb(
        _shiftUnitValue(next.r, wheel.luminance * weight),
        _shiftUnitValue(next.g, wheel.luminance * weight),
        _shiftUnitValue(next.b, wheel.luminance * weight),
      );
    }
  }

  return next;
}

double _hslRangeWeight(double hue, HslColorRange range) {
  if (range == HslColorRange.global) return 1;

  final center = switch (range) {
    HslColorRange.red => 0.0,
    HslColorRange.orange => 30 / 360,
    HslColorRange.yellow => 60 / 360,
    HslColorRange.green => 120 / 360,
    HslColorRange.aqua => 180 / 360,
    HslColorRange.blue => 240 / 360,
    HslColorRange.purple => 270 / 360,
    HslColorRange.magenta => 300 / 360,
    HslColorRange.global => 0.0,
  };

  final distance = _hueDistance(hue, center);
  const halfWidth = 45 / 360;
  return (1 - distance / halfWidth).clamp(0.0, 1.0);
}

double _gradingWeight(double luminance, ColorGradingWheel wheel) {
  final blend = wheel.blending.clamp(0.0, 1.0);
  final width = 0.18 + blend * 0.22;

  return switch (wheel.range) {
    ColorGradingRange.shadows => 1 - _smoothStep(0.25, 0.25 + width, luminance),
    ColorGradingRange.midtones =>
      _smoothStep(0.12, 0.12 + width, luminance) *
          (1 - _smoothStep(0.88 - width, 0.88, luminance)),
    ColorGradingRange.highlights => _smoothStep(0.75 - width, 0.75, luminance),
  };
}

double _smoothStep(double edge0, double edge1, double value) {
  if (edge0 == edge1) return value < edge0 ? 0 : 1;
  final t = ((value - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double _lut(List<int> lut, double value) {
  final index = (value.clamp(0.0, 1.0) * (lut.length - 1)).round();
  return lut[index] / 255;
}

double _shiftUnitValue(double value, double amount) {
  if (amount >= 0) {
    return value + (1 - value) * amount;
  }
  return value * (1 + amount);
}

double _mix(double a, double b, double amount) => a + (b - a) * amount;

double _hueDistance(double a, double b) {
  final distance = (a - b).abs();
  return min(distance, 1 - distance);
}

double _wrapHue(double value) {
  final wrapped = value % 1;
  return wrapped < 0 ? wrapped + 1 : wrapped;
}

int _toByte(double value) => (value.clamp(0.0, 1.0) * 255).round();

class _Rgb {
  const _Rgb(this.r, this.g, this.b);

  final double r;
  final double g;
  final double b;

  double get maxChannel => max(r, max(g, b));

  double get minChannel => min(r, min(g, b));

  double get luminance => 0.2126 * r + 0.7152 * g + 0.0722 * b;

  _Rgb clamped() =>
      _Rgb(r.clamp(0.0, 1.0), g.clamp(0.0, 1.0), b.clamp(0.0, 1.0));
}

class _Hsl {
  const _Hsl({required this.h, required this.s, required this.l});

  factory _Hsl.fromRgb(_Rgb rgb) {
    final maxChannel = rgb.maxChannel;
    final minChannel = rgb.minChannel;
    final chroma = maxChannel - minChannel;
    final luminance = (maxChannel + minChannel) / 2;

    if (chroma == 0) {
      return _Hsl(h: 0, s: 0, l: luminance);
    }

    final saturation = chroma / (1 - (2 * luminance - 1).abs());
    late final double hue;
    if (maxChannel == rgb.r) {
      hue = ((rgb.g - rgb.b) / chroma) % 6;
    } else if (maxChannel == rgb.g) {
      hue = (rgb.b - rgb.r) / chroma + 2;
    } else {
      hue = (rgb.r - rgb.g) / chroma + 4;
    }

    return _Hsl(h: _wrapHue(hue / 6), s: saturation, l: luminance);
  }

  final double h;
  final double s;
  final double l;

  _Hsl copyWith({double? h, double? s, double? l}) {
    return _Hsl(
      h: h ?? this.h,
      s: (s ?? this.s).clamp(0.0, 1.0),
      l: (l ?? this.l).clamp(0.0, 1.0),
    );
  }

  _Rgb toRgb() {
    if (s == 0) return _Rgb(l, l, l);

    final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    final p = 2 * l - q;

    return _Rgb(
      _hueToRgb(p, q, h + 1 / 3),
      _hueToRgb(p, q, h),
      _hueToRgb(p, q, h - 1 / 3),
    );
  }

  static double _hueToRgb(double p, double q, double t) {
    t = _wrapHue(t);
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  }
}
