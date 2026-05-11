// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

// Project imports:
import '/core/mixin/example_helper.dart';

/// Demonstrates the package collage maker with gallery-picked images.
class CollageMakerExample extends StatefulWidget {
  /// Creates a new [CollageMakerExample].
  const CollageMakerExample({super.key});

  @override
  State<CollageMakerExample> createState() => _CollageMakerExampleState();
}

class _CollageMakerExampleState extends State<CollageMakerExample>
    with ExampleHelperState<CollageMakerExample> {
  final _picker = ImagePicker();
  final List<ImageProvider> _images = [];

  final _configs = ProImageEditorConfigs(designMode: platformDesignMode);

  late final _callbacks = ProImageEditorCallbacks(
    onImageEditingStarted: onImageEditingStarted,
    onImageEditingComplete: onImageEditingComplete,
    onCloseEditor: (editorMode) => onCloseEditor(editorMode: editorMode),
    mainEditorCallbacks: MainEditorCallbacks(
      helperLines: HelperLinesCallbacks(onLineHit: vibrateLineHit),
    ),
  );

  Future<void> _addImages() async {
    final pickedImages = await _picker.pickMultiImage(imageQuality: 95);
    if (pickedImages.isEmpty) return;

    final images = <ImageProvider>[];
    for (final image in pickedImages) {
      if (kIsWeb) {
        images.add(MemoryImage(await image.readAsBytes()));
      } else {
        images.add(FileImage(File(image.path)));
      }
    }

    if (!mounted) return;
    setState(() {
      _images.addAll(images);
      if (_images.length > 12) {
        _images.removeRange(12, _images.length);
      }
    });
  }

  Future<void> _openEditor(Uint8List bytes) async {
    await precacheImage(MemoryImage(bytes), context);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProImageEditor.memory(
          bytes,
          callbacks: _callbacks,
          configs: _configs,
        ),
      ),
    );
  }

  void _moveImage(int from, int to) {
    setState(() {
      final image = _images.removeAt(from);
      _images.insert(to, image);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CollageMaker(
      images: _images,
      onAddImages: _addImages,
      onClearImages: () => setState(_images.clear),
      onRemoveImage: (index) => setState(() => _images.removeAt(index)),
      onMoveImage: _moveImage,
      onEditCollage: _openEditor,
    );
  }
}
