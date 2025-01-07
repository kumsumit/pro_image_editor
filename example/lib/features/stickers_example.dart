// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:pro_image_editor/pro_image_editor.dart';

// Project imports:
import '/core/mixin/example_helper.dart';

/// A widget that provides an example of managing and displaying stickers.
///
/// The [StickersExample] widget is a stateful widget that demonstrates how to
/// work with stickers, possibly within an image editor or a related feature.
///
/// The state for this widget is managed by the [_StickersExampleState] class.
///
/// Example usage:
/// ```dart
/// StickersExample();
/// ```
class StickersExample extends StatefulWidget {
  /// Creates a new [StickersExample] widget.
  const StickersExample({super.key});

  @override
  State<StickersExample> createState() => _StickersExampleState();
}

/// The state for the [StickersExample] widget.
///
/// This class manages the behavior and state related to the stickers within
/// the [StickersExample] widget.
class _StickersExampleState extends State<StickersExample>
    with ExampleHelperState<StickersExample> {
  final String _url = 'https://picsum.photos/id/176/2000';

  @override
  void initState() {
    preCacheImage(networkUrl: _url);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!isPreCached) return const PrepareImageWidget();

    return ProImageEditor.network(
      _url,
      callbacks: ProImageEditorCallbacks(
        onImageEditingStarted: onImageEditingStarted,
        onImageEditingComplete: onImageEditingComplete,
        onCloseEditor: () => onCloseEditor(enablePop: !isDesktopMode(context)),
      ),
      configs: ProImageEditorConfigs(
        designMode: platformDesignMode,
        blurEditor: const BlurEditorConfigs(enabled: false),
        mainEditor: MainEditorConfigs(
          enableCloseButton: !isDesktopMode(context),
        ),
        stickerEditor: StickerEditorConfigs(
          enabled: true,
          buildStickers: (setLayer, scrollController) {
            return ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 80,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                controller: scrollController,
                itemCount: 21,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      // Important make sure the image is completely loaded
                      // cuz the editor will directly take a screenshot
                      // inside of a background isolated thread.
                      LoadingDialog.instance.show(
                        context,
                        configs: const ProImageEditorConfigs(),
                        theme: Theme.of(context),
                      );
                      await precacheImage(
                          NetworkImage(
                              'https://picsum.photos/id/${(index + 3) * 3}/2000'),
                          context);
                      LoadingDialog.instance.hide();
                      setLayer(Sticker(index: index));
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Sticker(index: index),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A widget that represents a sticker in the UI.
///
/// The [Sticker] widget is a stateful widget that takes an `index` parameter
/// to
/// identify the specific sticker. The state for this widget is managed by the
/// [StickerState] class.
///
/// Example usage:
/// ```dart
/// Sticker(index: 1);
/// ```
class Sticker extends StatefulWidget {
  /// Creates a new [Sticker] widget.
  ///
  /// The [index] parameter is required and represents the position or
  /// identifier
  /// of the sticker in a collection.
  const Sticker({
    super.key,
    required this.index,
  });

  /// The index representing the position of the sticker.
  final int index;

  @override
  State<Sticker> createState() => StickerState();
}

/// The state for the [Sticker] widget.
///
/// This class manages the state and behavior of the [Sticker] widget.
class StickerState extends State<Sticker> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Image.network(
        'https://picsum.photos/id/${(widget.index + 3) * 3}/2000',
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          return AnimatedSwitcher(
            layoutBuilder: (currentChild, previousChildren) {
              return SizedBox(
                width: 80,
                height: 80,
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
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
          );
        },
      ),
    );
  }
}
