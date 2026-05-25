import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/plugins/image/src/image/image.dart' as img;
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/shared/services/content_recorder/controllers/content_recorder_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('applyRetouchOperations', () {
    test('applies clone-stamp pixels from a source offset', () {
      final image = img.Image(width: 4, height: 1)
        ..setPixelRgba(0, 0, 255, 0, 0, 255)
        ..setPixelRgba(1, 0, 0, 255, 0, 255)
        ..setPixelRgba(2, 0, 0, 0, 255, 255)
        ..setPixelRgba(3, 0, 255, 255, 255, 255);

      final result = applyRetouchOperations(image, [
        const RetouchOperation(
          id: 'clone',
          type: RetouchOperationType.cloneStamp,
          sourceOffset: Offset(-2, 0),
          mask: LayerMask(
            primitives: [
              LayerMaskPrimitive(
                type: LayerMaskPrimitiveType.rectangle,
                bounds: Rect.fromLTWH(2, 0, 1, 1),
              ),
            ],
          ),
        ),
      ]);

      final pixel = result.getPixel(2, 0);

      expect(pixel.r, 255);
      expect(pixel.g, 0);
      expect(pixel.b, 0);
    });

    test(
      'healing brush preserves target luminance while sampling source hue',
      () {
        final image = img.Image(width: 2, height: 1)
          ..setPixelRgba(0, 0, 255, 0, 0, 255)
          ..setPixelRgba(1, 0, 80, 80, 80, 255);

        final result = applyRetouchOperations(image, [
          const RetouchOperation(
            id: 'heal',
            type: RetouchOperationType.healingBrush,
            sourceOffset: Offset(-1, 0),
            mask: LayerMask(
              primitives: [
                LayerMaskPrimitive(
                  type: LayerMaskPrimitiveType.rectangle,
                  bounds: Rect.fromLTWH(1, 0, 1, 1),
                ),
              ],
            ),
          ),
        ]);

        final pixel = result.getPixel(1, 0);

        expect(pixel.r, greaterThan(pixel.g));
        expect(pixel.g, greaterThan(0));
        expect(pixel.b, greaterThan(0));
      },
    );

    test('object removal fills masked pixels from surrounding colors', () {
      final image = img.Image(width: 3, height: 1)
        ..setPixelRgba(0, 0, 20, 20, 20, 255)
        ..setPixelRgba(1, 0, 255, 0, 0, 255)
        ..setPixelRgba(2, 0, 20, 20, 20, 255);

      final result = applyRetouchOperations(image, [
        const RetouchOperation(
          id: 'remove',
          type: RetouchOperationType.objectRemoval,
          mask: LayerMask(
            primitives: [
              LayerMaskPrimitive(
                type: LayerMaskPrimitiveType.rectangle,
                bounds: Rect.fromLTWH(1, 0, 1, 1),
              ),
            ],
          ),
        ),
      ]);

      final pixel = result.getPixel(1, 0);

      expect(pixel.r, 20);
      expect(pixel.g, 20);
      expect(pixel.b, 20);
    });
  });

  group('ContentRecorderController', () {
    test('applies retouch operations during raw image conversion', () async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder)
        ..drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = Colors.red)
        ..drawRect(
          const Rect.fromLTWH(1, 0, 1, 1),
          Paint()..color = Colors.blue,
        );
      final rawImage = await recorder.endRecording().toImage(2, 1);

      final controller = ContentRecorderController(
        isVideoEditor: false,
        configs: const ImageGenerationConfigs(
          outputFormat: OutputFormat.png,
          enableIsolateGeneration: false,
        ),
      );

      final bytes = await controller.convertRawImageData(
        image: rawImage,
        retouchOperations: const [
          RetouchOperation(
            id: 'clone',
            type: RetouchOperationType.cloneStamp,
            sourceOffset: Offset(-1, 0),
            mask: LayerMask(
              primitives: [
                LayerMaskPrimitive(
                  type: LayerMaskPrimitiveType.rectangle,
                  bounds: Rect.fromLTWH(1, 0, 1, 1),
                ),
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

      expect(data[4], greaterThan(200));
      expect(data[4], greaterThan(data[5]));
      expect(data[4], greaterThan(data[6]));
    });
  });
}
