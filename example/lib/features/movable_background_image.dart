// Dart imports:
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import '/core/mixin/example_helper.dart';
import '/shared/widgets/material_icon_button.dart';
import '/shared/widgets/pixel_transparent_painter.dart';
import 'reorder_layer_example.dart';

/// The example for movableBackground
class MovableBackgroundImageExample extends StatefulWidget {
  /// Creates a new [MovableBackgroundImageExample] widget.
  const MovableBackgroundImageExample({super.key});

  @override
  State<MovableBackgroundImageExample> createState() =>
      _MovableBackgroundImageExampleState();
}

class _MovableBackgroundImageExampleState
    extends State<MovableBackgroundImageExample>
    with ExampleHelperState<MovableBackgroundImageExample> {
  late final ScrollController _bottomBarScrollCtrl;
  Uint8List? _transparentBytes;
  double _transparentAspectRatio = -1;

  final String _imageUrl =
      'https://picsum.photos/id/${Random().nextInt(200)}/2000';

  /// Better sense of scale when we start with a large number
  final double _initScale = 20;

  /// set the aspect ratio from your image.
  final double _imgRatio = 1;

  final _bottomTextStyle = const TextStyle(fontSize: 10.0, color: Colors.white);

  @override
  void initState() {
    preCacheImage(networkUrl: _imageUrl);
    _createTransparentImage(_imgRatio);
    _bottomBarScrollCtrl = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    _bottomBarScrollCtrl.dispose();
    super.dispose();
  }

  void _openPicker(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image == null) return;

    Uint8List? bytes;

    bytes = await image.readAsBytes();

    if (!mounted) return;
    await precacheImage(MemoryImage(bytes), context);
    var decodedImage = await decodeImageFromList(bytes);

    if (!mounted) return;
    if (kIsWeb ||
        (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS)) {
      Navigator.pop(context);
    }

    editorKey.currentState!.addLayer(
      WidgetLayer(
        offset: Offset.zero,
        scale: _initScale * 0.5,
        widget: Image.memory(
          bytes,
          width: decodedImage.width.toDouble(),
          height: decodedImage.height.toDouble(),
          fit: BoxFit.cover,
        ),
      ),
    );
    setState(() {});
  }

  void _chooseCameraOrGallery() async {
    /// Open directly the gallery if the camera is not supported
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      _openPicker(ImageSource.gallery);
      return;
    }

    if (!kIsWeb && Platform.isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => CupertinoTheme(
          data: const CupertinoThemeData(),
          child: CupertinoActionSheet(
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                onPressed: () => _openPicker(ImageSource.camera),
                child: const Wrap(
                  spacing: 7,
                  runAlignment: WrapAlignment.center,
                  children: [
                    Icon(CupertinoIcons.photo_camera),
                    Text('Camera'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () => _openPicker(ImageSource.gallery),
                child: const Wrap(
                  spacing: 7,
                  runAlignment: WrapAlignment.center,
                  children: [
                    Icon(CupertinoIcons.photo),
                    Text('Gallery'),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        showDragHandle: true,
        constraints: BoxConstraints(
          minWidth: min(MediaQuery.of(context).size.width, 360),
        ),
        builder: (context) {
          return Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                child: Wrap(
                  spacing: 45,
                  runSpacing: 30,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runAlignment: WrapAlignment.center,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    MaterialIconActionButton(
                      primaryColor: const Color(0xFFEC407A),
                      secondaryColor: const Color(0xFFD3396D),
                      icon: Icons.photo_camera,
                      text: 'Camera',
                      onTap: () => _openPicker(ImageSource.camera),
                    ),
                    MaterialIconActionButton(
                      primaryColor: const Color(0xFFBF59CF),
                      secondaryColor: const Color(0xFFAC44CF),
                      icon: Icons.image,
                      text: 'Gallery',
                      onTap: () => _openPicker(ImageSource.gallery),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _createTransparentImage(double aspectRatio) async {
    if (_transparentAspectRatio == aspectRatio) return;

    double minSize = 1;

    double width = aspectRatio < 1 ? minSize : minSize * aspectRatio;
    double height = aspectRatio < 1 ? minSize / aspectRatio : minSize;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
        recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
    final paint = Paint()..color = Colors.transparent;
    canvas.drawRect(
        Rect.fromLTWH(0.0, 0.0, width.toDouble(), height.toDouble()), paint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    _transparentAspectRatio = aspectRatio;
    _transparentBytes = pngBytes!.buffer.asUint8List();
  }

  Size get _editorSize => Size(
        MediaQuery.of(context).size.width -
            MediaQuery.of(context).padding.horizontal,
        MediaQuery.of(context).size.height -
            kToolbarHeight -
            kBottomNavigationBarHeight -
            MediaQuery.of(context).padding.vertical,
      );

  void _openReorderSheet(ProImageEditorState editor) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ReorderLayerSheet(
          layers: editor.activeLayers,
          onReorder: (oldIndex, newIndex) {
            editor.moveLayerListPosition(
              oldIndex: oldIndex,
              newIndex: newIndex,
            );
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_transparentBytes == null || !isPreCached) {
      return const PrepareImageWidget();
    }

    return LayoutBuilder(builder: (context, constraints) {
      return CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: const PixelTransparentPainter(
          primary: Colors.white,
          secondary: Color(0xFFE2E2E2),
        ),
        child: ProImageEditor.memory(
          _transparentBytes!,
          key: editorKey,
          callbacks: ProImageEditorCallbacks(
            onImageEditingStarted: onImageEditingStarted,
            onImageEditingComplete: onImageEditingComplete,
            onCloseEditor: () =>
                onCloseEditor(enablePop: !isDesktopMode(context)),
            mainEditorCallbacks: MainEditorCallbacks(
              onAfterViewInit: () {
                editorKey.currentState!.addLayer(
                  WidgetLayer(
                    offset: Offset.zero,
                    scale: _initScale,
                    widget: Image.network(
                      _imageUrl,
                      width: _editorSize.width,
                      height: _editorSize.height,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        return AnimatedSwitcher(
                          layoutBuilder: (currentChild, previousChildren) {
                            return SizedBox(
                              width: 120,
                              height: 120,
                              child: Stack(
                                fit: StackFit.expand,
                                alignment: Alignment.center,
                                children: <Widget>[
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              ),
                            );
                          },
                          duration: const Duration(milliseconds: 200),
                          child: loadingProgress == null
                              ? child
                              : Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          configs: ProImageEditorConfigs(
            designMode: platformDesignMode,
            imageGeneration: ImageGenerationConfigs(
              captureOnlyDrawingBounds: true,
              captureOnlyBackgroundImageArea: false,
              outputFormat: OutputFormat.png,

              /// Set the pixel ratio manually. You can also set this
              /// value higher than the device pixel ratio for higher
              /// quality.
              customPixelRatio: max(2000 / MediaQuery.of(context).size.width,
                  MediaQuery.of(context).devicePixelRatio),
            ),
            mainEditor: MainEditorConfigs(
              enableCloseButton: !isDesktopMode(context),
              widgets: MainEditorWidgets(
                bodyItems: (editor, rebuildStream) {
                  return [
                    ReactiveWidget(
                      stream: rebuildStream,
                      builder: (_) => editor.selectedLayerIndex >= 0 ||
                              editor.isSubEditorOpen
                          ? const SizedBox.shrink()
                          : Positioned(
                              bottom: 20,
                              left: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.lightBlue.shade200,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(100),
                                    bottomRight: Radius.circular(100),
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: () => _openReorderSheet(editor),
                                  icon: const Icon(
                                    Icons.reorder,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ];
                },
                bottomBar: (editor, rebuildStream, key) => ReactiveWidget(
                  stream: rebuildStream,
                  key: key,
                  builder: (_) => _bottomNavigationBar(
                    editor,
                    constraints,
                  ),
                ),
              ),
              style: const MainEditorStyle(
                uiOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: Colors.black,
                ),
                background: Colors.transparent,
              ),
            ),
            paintEditor: const PaintEditorConfigs(
              style: PaintEditorStyle(
                uiOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: Colors.black,
                ),
                background: Colors.transparent,
              ),
            ),

            /// Crop-Rotate, Filter and Blur editors are not supported
            cropRotateEditor: const CropRotateEditorConfigs(enabled: false),
            filterEditor: const FilterEditorConfigs(enabled: false),
            blurEditor: const BlurEditorConfigs(enabled: false),

            stickerEditor: StickerEditorConfigs(
              enabled: false,
              initWidth: (_editorSize.aspectRatio > _imgRatio
                      ? _editorSize.height
                      : _editorSize.width) /
                  _initScale,
              buildStickers: (setLayer, scrollController) {
                // Optionally your code to pick layers
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _bottomNavigationBar(
    ProImageEditorState editor,
    BoxConstraints constraints,
  ) {
    return Scrollbar(
      controller: _bottomBarScrollCtrl,
      scrollbarOrientation: ScrollbarOrientation.top,
      thickness: isDesktop ? null : 0,
      child: BottomAppBar(
        /// kBottomNavigationBarHeight is important that helper-lines will work
        height: kBottomNavigationBarHeight,
        color: Colors.black,
        padding: EdgeInsets.zero,
        child: Center(
          child: SingleChildScrollView(
            controller: _bottomBarScrollCtrl,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: min(constraints.maxWidth, 500),
                maxWidth: 500,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FlatIconTextButton(
                      label: Text('Add Image', style: _bottomTextStyle),
                      icon: const Icon(
                        Icons.image_outlined,
                        size: 22.0,
                        color: Colors.white,
                      ),
                      onPressed: _chooseCameraOrGallery,
                    ),
                    FlatIconTextButton(
                      label: Text('Paint', style: _bottomTextStyle),
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 22.0,
                        color: Colors.white,
                      ),
                      onPressed: editor.openPaintEditor,
                    ),
                    FlatIconTextButton(
                      label: Text('Text', style: _bottomTextStyle),
                      icon: const Icon(
                        Icons.text_fields,
                        size: 22.0,
                        color: Colors.white,
                      ),
                      onPressed: editor.openTextEditor,
                    ),
                    FlatIconTextButton(
                      label: Text('Emoji', style: _bottomTextStyle),
                      icon: const Icon(
                        Icons.sentiment_satisfied_alt_rounded,
                        size: 22.0,
                        color: Colors.white,
                      ),
                      onPressed: editor.openEmojiEditor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
