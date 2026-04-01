import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/core/models/editor_configs/image_generation_configs/image_generation_configs.dart';
import 'package:pro_image_editor/shared/services/content_recorder/services/image_render_service.dart';
import 'package:pro_image_editor/shared/utils/decode_image.dart';

void main() {
  group('ImageRenderService', () {
    final service = ImageRenderService(const ImageGenerationConfigs());

    test('calculateCropRect centers the crop for landscape images', () {
      const imageInfos = ImageInfos(
        rawSize: Size(400, 200),
        renderedSize: Size(400, 200),
        originalRenderedSize: Size(400, 200),
        cropRectSize: Size.square(200),
        pixelRatio: 1,
        isRotated: false,
      );

      final rect = service.calculateCropRect(
        imageSize: const Size(400, 200),
        imageInfos: imageInfos,
      );

      expect(rect, const Rect.fromLTWH(100, 0, 200, 200));
    });

    test('calculateCropRect uses the rotated crop ratio', () {
      const imageInfos = ImageInfos(
        rawSize: Size(600, 300),
        renderedSize: Size(600, 300),
        originalRenderedSize: Size(600, 300),
        cropRectSize: Size(300, 100),
        pixelRatio: 1,
        isRotated: true,
      );

      final rect = service.calculateCropRect(
        imageSize: const Size(600, 300),
        imageInfos: imageInfos,
      );

      expect(rect, const Rect.fromLTWH(250, 0, 100, 300));
    });

    test(
      'cropToImageBounds returns the expected cropped output size',
      () async {
        const imageInfos = ImageInfos(
          rawSize: Size(4, 2),
          renderedSize: Size(4, 2),
          originalRenderedSize: Size(4, 2),
          cropRectSize: Size.square(2),
          pixelRatio: 1,
          isRotated: false,
        );

        final ui.Image image = await _createSolidImage(
          width: 4,
          height: 2,
          color: const Color(0xFFFF0000),
        );

        final ui.Image cropped = await service.cropToImageBounds(
          image,
          imageInfos,
        );

        expect(cropped.width, 2);
        expect(cropped.height, 2);
      },
    );
  });
}

Future<ui.Image> _createSolidImage({
  required int width,
  required int height,
  required Color color,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
  ..drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  return recorder.endRecording().toImage(width, height);
}
