import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/core/models/editor_configs/image_generation_configs/image_generation_configs.dart';
import 'package:pro_image_editor/plugins/image/src/image/image.dart';
import 'package:pro_image_editor/shared/services/content_recorder/utils/encoder/encode_image.dart';

void main() {
  group('encodeImage', () {
    for (final format in OutputFormat.values) {
      test('encodes a non-empty ${format.name} image', () async {
        final bytes = await _encode(format);

        expect(bytes, isNotEmpty);
        _expectFormatSignature(format, bytes);
      });
    }
  });
}

Future<Uint8List> _encode(OutputFormat outputFormat) {
  return encodeImage(
    image: _createTestImage(),
    outputFormat: outputFormat,
    singleFrame: true,
    jpegQuality: 92,
    jpegChroma: JpegChroma.yuv444,
    pngFilter: PngFilter.none,
    pngLevel: 6,
    jpegBackgroundColor: 0xFFFFFFFF,
  );
}

Image _createTestImage() {
  final image = Image(width: 2, height: 2, numChannels: 4)
    ..setPixelRgba(0, 0, 255, 0, 0, 255)
    ..setPixelRgba(1, 0, 0, 255, 0, 255)
    ..setPixelRgba(0, 1, 0, 0, 255, 255)
    ..setPixelRgba(1, 1, 255, 255, 255, 128);

  return image;
}

void _expectFormatSignature(OutputFormat format, Uint8List bytes) {
  switch (format) {
    case OutputFormat.jpg:
      expect(bytes.take(3), [0xFF, 0xD8, 0xFF]);
      expect(bytes.skip(bytes.length - 2), [0xFF, 0xD9]);
      break;
    case OutputFormat.png:
      expect(bytes.take(8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      break;
    case OutputFormat.tiff:
      expect(
        bytes.take(4),
        anyOf(
          equals([0x49, 0x49, 0x2A, 0x00]),
          equals([0x4D, 0x4D, 0x00, 0x2A]),
        ),
      );
      break;
    case OutputFormat.bmp:
      expect(bytes.take(2), [0x42, 0x4D]);
      break;
    case OutputFormat.cur:
      expect(bytes.take(4), [0x00, 0x00, 0x02, 0x00]);
      break;
    case OutputFormat.pvr:
      expect(bytes.take(4), [0x50, 0x56, 0x52, 0x03]);
      break;
    case OutputFormat.tga:
      expect(bytes.length, greaterThan(18));
      expect(bytes[12] | (bytes[13] << 8), 2);
      expect(bytes[14] | (bytes[15] << 8), 2);
      break;
    case OutputFormat.ico:
      expect(bytes.take(4), [0x00, 0x00, 0x01, 0x00]);
      break;
  }
}
