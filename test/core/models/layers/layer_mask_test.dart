import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/core/models/layers/layer_mask.dart';
import 'package:pro_image_editor/core/models/selections/editor_selection.dart';

void main() {
  group('LayerMask', () {
    test('serializes and restores mask primitives', () {
      const mask = LayerMask(
        enabled: false,
        inverted: true,
        opacity: 0.75,
        primitives: [
          LayerMaskPrimitive(
            type: LayerMaskPrimitiveType.rectangle,
            bounds: Rect.fromLTWH(10, 20, 30, 40),
            feather: 2,
          ),
          LayerMaskPrimitive(
            type: LayerMaskPrimitiveType.path,
            operation: LayerMaskOperation.subtract,
            points: [Offset(1, 2), Offset(3, 4)],
            opacity: 0.5,
          ),
        ],
      );

      final restored = LayerMask.fromMap(mask.toMap());

      expect(restored, mask);
    });

    test('creates a mask from a selection', () {
      const selection = EditorSelection(
        type: EditorSelectionType.ellipse,
        bounds: Rect.fromLTWH(4, 8, 16, 32),
        feather: 3,
        inverted: true,
      );

      final mask = LayerMask.fromSelection(selection);

      expect(mask.inverted, isTrue);
      expect(mask.primitives, hasLength(1));
      expect(mask.primitives.first.type, LayerMaskPrimitiveType.oval);
      expect(mask.primitives.first.bounds, selection.bounds);
      expect(mask.primitives.first.feather, selection.feather);
    });

    test('supports color range primitives', () {
      const primitive = LayerMaskPrimitive(
        type: LayerMaskPrimitiveType.colorRange,
        color: Colors.red,
        tolerance: 24,
      );

      final restored = LayerMaskPrimitive.fromMap(primitive.toMap());

      expect(restored, primitive);
    });
  });
}
