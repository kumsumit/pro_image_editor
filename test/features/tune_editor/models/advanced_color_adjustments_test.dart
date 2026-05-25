import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

void main() {
  group('CurvesAdjustment', () {
    test('serializes, restores, and builds lookup tables', () {
      const adjustment = CurvesAdjustment(
        rgb: [
          CurvePoint(input: 0, output: 0),
          CurvePoint(input: 0.5, output: 0.75),
          CurvePoint(input: 1, output: 1),
        ],
        blue: [
          CurvePoint(input: 0, output: 0.1),
          CurvePoint(input: 1, output: 0.9),
        ],
      );

      final restored = CurvesAdjustment.fromMap(adjustment.toMap());
      final luts = restored.toLuts(size: 5);

      expect(restored, adjustment);
      expect(luts[ColorAdjustmentChannel.rgb], [0, 96, 191, 223, 255]);
      expect(luts[ColorAdjustmentChannel.blue], [26, 77, 128, 179, 230]);
    });
  });

  group('LevelsAdjustment', () {
    test('serializes, restores, and builds lookup tables', () {
      const adjustment = LevelsAdjustment(
        rgb: ChannelLevels(inputBlack: 0.1, inputWhite: 0.9),
        red: ChannelLevels(outputBlack: 0.2, outputWhite: 0.8),
      );

      final restored = LevelsAdjustment.fromMap(adjustment.toMap());
      final luts = restored.toLuts(size: 5);

      expect(restored, adjustment);
      expect(luts[ColorAdjustmentChannel.rgb], [0, 48, 128, 207, 255]);
      expect(luts[ColorAdjustmentChannel.red], [51, 80, 128, 175, 204]);
      expect(restored.toLinearPreviewMatrix(), hasLength(20));
    });
  });

  group('HslAdjustment', () {
    test('serializes and restores color-range adjustments', () {
      const adjustment = HslAdjustment(
        ranges: [
          HslRangeAdjustment(
            range: HslColorRange.orange,
            hue: 0.1,
            saturation: -0.2,
            luminance: 0.3,
          ),
          HslRangeAdjustment(range: HslColorRange.blue),
        ],
      );

      final restored = HslAdjustment.fromMap(adjustment.toMap());

      expect(restored.ranges, [adjustment.ranges.first]);
      expect(restored.isIdentity, isFalse);
    });
  });

  group('ColorGradingAdjustment', () {
    test('serializes and restores grading wheels', () {
      const adjustment = ColorGradingAdjustment(
        wheels: [
          ColorGradingWheel(
            range: ColorGradingRange.shadows,
            hue: 0.6,
            saturation: 0.35,
            luminance: -0.1,
            blending: 0.4,
          ),
        ],
      );

      final restored = ColorGradingAdjustment.fromMap(adjustment.toMap());

      expect(restored, adjustment);
      expect(restored.isIdentity, isFalse);
    });
  });

  group('TuneAdjustmentMatrix', () {
    test('preserves advanced color adjustments in map and copy', () {
      const matrix = TuneAdjustmentMatrix(
        id: 'pro-color',
        value: 0,
        matrix: [],
        curves: CurvesAdjustment(
          red: [
            CurvePoint(input: 0, output: 0),
            CurvePoint(input: 1, output: 0.8),
          ],
        ),
        levels: LevelsAdjustment(
          rgb: ChannelLevels(inputBlack: 0.05, inputWhite: 0.95),
        ),
        hsl: HslAdjustment(
          ranges: [
            HslRangeAdjustment(range: HslColorRange.red, saturation: 0.2),
          ],
        ),
        colorGrading: ColorGradingAdjustment(
          wheels: [
            ColorGradingWheel(
              range: ColorGradingRange.highlights,
              hue: 0.12,
              saturation: 0.4,
            ),
          ],
        ),
      );

      final restored = TuneAdjustmentMatrix.fromMap(matrix.toMap());

      expect(restored, matrix);
      expect(restored.copy(), matrix);
      expect(restored.hasAdvancedAdjustments, isTrue);
    });
  });
}
