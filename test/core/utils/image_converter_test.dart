import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

Future<ui.Image> createTestUiImage() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 1, 1),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  return recorder.endRecording().toImage(1, 1);
}

void main() {
  group('ImageConverter', () {
    testWidgets(
      'uiImageToImageBytes returns bytes and precaches if context is provided',
      (tester) async {
        late BuildContext context;
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (builderContext) {
                context = builderContext;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final testImage = await createTestUiImage();

        final result = await tester.runAsync(
          () => ImageConverter.instance.uiImageToImageBytes(
            testImage,
            context: context,
          ),
        );
        expect(result, isA<Uint8List?>());
      },
    );

    test('uiImageToImageBytes returns bytes without context', () async {
      final testImage = await createTestUiImage();

      final result = await ImageConverter.instance.uiImageToImageBytes(
        testImage,
      );
      expect(result, isA<Uint8List?>());
    });
  });
}
