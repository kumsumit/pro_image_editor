import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/plugins/image/src/image/image.dart' as img;
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/shared/services/content_recorder/controllers/content_recorder_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('applyAdvancedColorAdjustments', () {
    test('applies curves and levels to pixels', () {
      final image = img.Image(width: 1, height: 1)
        ..setPixelRgba(0, 0, 255, 128, 64, 255);

      final result = applyAdvancedColorAdjustments(image, [
        const TuneAdjustmentMatrix(
          id: 'advanced',
          value: 0,
          matrix: [],
          curves: CurvesAdjustment(
            red: [
              CurvePoint(input: 0, output: 0),
              CurvePoint(input: 1, output: 0.5),
            ],
          ),
          levels: LevelsAdjustment(
            green: ChannelLevels(outputBlack: 0.2, outputWhite: 0.8),
          ),
        ),
      ]);

      final pixel = result.getPixel(0, 0);

      expect(pixel.r, 128);
      expect(pixel.g, 128);
      expect(pixel.b, 64);
      expect(pixel.a, 255);
    });

    test('applies selective HSL adjustments', () {
      final image = img.Image(width: 2, height: 1)
        ..setPixelRgba(0, 0, 255, 0, 0, 255)
        ..setPixelRgba(1, 0, 0, 0, 255, 255);

      final result = applyAdvancedColorAdjustments(image, [
        const TuneAdjustmentMatrix(
          id: 'hsl',
          value: 0,
          matrix: [],
          hsl: HslAdjustment(
            ranges: [HslRangeAdjustment(range: HslColorRange.red, hue: 1 / 3)],
          ),
        ),
      ]);

      final redPixel = result.getPixel(0, 0);
      final bluePixel = result.getPixel(1, 0);

      expect(redPixel.g, greaterThan(redPixel.r));
      expect(redPixel.g, greaterThan(redPixel.b));
      expect(bluePixel.b, 255);
    });
  });

  group('ContentRecorderController', () {
    test(
      'applies advanced color adjustments during raw image conversion',
      () async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 1, 1),
          Paint()..color = Colors.red,
        );
        final rawImage = await recorder.endRecording().toImage(1, 1);

        final controller = ContentRecorderController(
          isVideoEditor: false,
          configs: const ImageGenerationConfigs(
            outputFormat: OutputFormat.png,
            enableIsolateGeneration: false,
          ),
        );

        final bytes = await controller.convertRawImageData(
          image: rawImage,
          advancedTuneAdjustments: const [
            TuneAdjustmentMatrix(
              id: 'hsl',
              value: 0,
              matrix: [],
              hsl: HslAdjustment(
                ranges: [
                  HslRangeAdjustment(range: HslColorRange.red, hue: 1 / 3),
                ],
              ),
            ),
          ],
        );
        await controller.destroy();

        final decoded = await decodeImageFromList(bytes!);
        final byteData = await decoded.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        final data = byteData!.buffer.asUint8List();

        expect(data[1], greaterThan(data[0]));
        expect(data[1], greaterThan(data[2]));
      },
    );
  });
}
