import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/core/models/selections/editor_selection.dart';

void main() {
  group('EditorSelection', () {
    test('serializes and restores polygon selections', () {
      const selection = EditorSelection(
        type: EditorSelectionType.polygon,
        points: [Offset(0, 0), Offset(10, 0), Offset(10, 12)],
        feather: 1.5,
        inverted: true,
      );

      final restored = EditorSelection.fromMap(selection.toMap());

      expect(restored, selection);
    });

    test('serializes and restores color-range selections', () {
      const selection = EditorSelection(
        type: EditorSelectionType.colorRange,
        bounds: Rect.fromLTWH(1, 2, 3, 4),
        color: Colors.blue,
        tolerance: 18,
      );

      final restored = EditorSelection.fromMap(selection.toMap());

      expect(restored, selection);
    });
  });
}
