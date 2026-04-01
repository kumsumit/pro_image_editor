import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/core/models/styles/crop_rotate_editor_style.dart';
import 'package:pro_image_editor/features/crop_rotate_editor/widgets/crop_corner_painter.dart';

void main() {
  group('CropCornerPainter', () {
    test(
      'darkens the full viewport even when the image is translated down',
      () async {
        final painter = CropCornerPainter(
          drawCircle: false,
          offset: const Offset(0, 20),
          cropRect: const Rect.fromLTWH(25, 25, 50, 50),
          fadeInOpacity: 1,
          interactionOpacity: 0,
          viewRect: const Rect.fromLTWH(25, 25, 50, 50),
          screenSize: const Size(100, 100),
          scaleFactor: 1,
          rotationScaleFactor: 1,
          style: const CropRotateEditorStyle(
            background: Colors.transparent,
            cropOverlayColor: Colors.black,
            cropOverlayOpacity: 1,
            cropOverlayInteractionOpacity: 0,
            cropCornerLength: 0,
            cropCornerThickness: 0,
          ),
        );

        final image = await _paintImage(
          painter: painter,
          size: const Size(100, 100),
        );

        final Color topCenter = await _pixelAt(image, x: 50, y: 0);
        final Color cropCenter = await _pixelAt(image, x: 50, y: 50);

        expect(topCenter.alpha, 255);
        expect(cropCenter.alpha, 0);
      },
    );
  });
}

Future<ui.Image> _paintImage({
  required CustomPainter painter,
  required Size size,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, size);
  return recorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
}

Future<Color> _pixelAt(ui.Image image, {required int x, required int y}) async {
  final ByteData? byteData = await image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  );
  expect(byteData, isNotNull);

  final Uint8List bytes = byteData!.buffer.asUint8List();
  final int index = (y * image.width + x) * 4;
  return Color.fromARGB(
    bytes[index + 3],
    bytes[index],
    bytes[index + 1],
    bytes[index + 2],
  );
}
