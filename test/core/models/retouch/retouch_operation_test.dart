import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

void main() {
  group('RetouchOperation', () {
    test('serializes and restores clone operation', () {
      const operation = RetouchOperation(
        id: 'clone-1',
        type: RetouchOperationType.cloneStamp,
        sourceOffset: Offset(-2, 0),
        strength: 0.75,
        mask: LayerMask(
          primitives: [
            LayerMaskPrimitive(
              type: LayerMaskPrimitiveType.rectangle,
              bounds: Rect.fromLTWH(2, 0, 2, 2),
              feather: 1,
            ),
          ],
        ),
        meta: {'provider': 'manual'},
      );

      final restored = RetouchOperation.fromMap(operation.toMap());

      expect(restored, operation);
    });

    test('supports object-removal operation without a source offset', () {
      const operation = RetouchOperation(
        id: 'remove-1',
        type: RetouchOperationType.objectRemoval,
        mask: LayerMask(
          primitives: [
            LayerMaskPrimitive(
              type: LayerMaskPrimitiveType.oval,
              bounds: Rect.fromLTWH(4, 4, 8, 8),
            ),
          ],
        ),
      );

      final map = operation.toMap();

      expect(map['sourceOffset'], isNull);
      expect(RetouchOperation.fromMap(map), operation);
    });
  });
}
