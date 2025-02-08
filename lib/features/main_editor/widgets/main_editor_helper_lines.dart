import 'package:flutter/material.dart';

import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/shared/widgets/extended/extended_interactive_viewer.dart';
import '../controllers/main_editor_controllers.dart';
import '../services/layer_interaction_manager.dart';
import '../services/sizes_manager.dart';

/// A widget that displays helper lines in the main editor to assist with
/// alignment and positioning of elements.
class MainEditorHelperLines extends StatelessWidget {
  /// Creates a `MainEditorHelperLines` widget with the necessary managers,
  /// controllers, and configurations.
  ///
  /// - [sizesManager]: Manages size-related settings and adjustments.
  /// - [layerInteractionManager]: Handles interactions with editor layers.
  /// - [controllers]: Manages the main editor's controllers.
  /// - [interactiveViewer]: A key for managing the interactive viewer state.
  /// - [helperLines]: Configurations for displaying helper lines.
  /// - [configs]: Configuration settings for the editor.
  const MainEditorHelperLines({
    super.key,
    required this.sizesManager,
    required this.layerInteractionManager,
    required this.controllers,
    required this.interactiveViewer,
    required this.helperLines,
    required this.configs,
  });

  /// Manages size-related settings and adjustments.
  final SizesManager sizesManager;

  /// Handles interactions with editor layers.
  final LayerInteractionManager layerInteractionManager;

  /// Manages the main editor's controllers.
  final MainEditorControllers controllers;

  /// A key for managing the interactive viewer state.
  final GlobalKey<ExtendedInteractiveViewerState> interactiveViewer;

  /// Configurations for displaying helper lines.
  final HelperLineConfigs helperLines;

  /// Configuration settings for the editor.
  final ProImageEditorConfigs configs;

  final double _lineHeight = 1.25;
  final int _duration = 100;

  double get _screenHeight => sizesManager.screen.height;
  double get _screenWidth => sizesManager.screen.width;

  @override
  Widget build(BuildContext context) {
    if (!layerInteractionManager.showHelperLines) {
      return const SizedBox.shrink();
    }
    return RepaintBoundary(
      child: StreamBuilder(
          stream: controllers.helperLineCtrl.stream,
          builder: (context, snapshot) {
            if (interactiveViewer.currentState != null &&
                interactiveViewer.currentState!.scaleFactor > 1) {
              return const SizedBox.shrink();
            }
            return Stack(
              children: [
                if (helperLines.showVerticalLine) _buildVerticalLine(),
                if (helperLines.showHorizontalLine) _buildHorizontalLine(),
                if (helperLines.showRotateLine) _buildRotateLine(),
              ],
            );
          }),
    );
  }

  Widget _buildVerticalLine() {
    return Align(
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: Duration(milliseconds: _duration),
        width: layerInteractionManager.showVerticalHelperLine ? _lineHeight : 0,
        height: _screenHeight,
        color: helperLines.style.verticalColor,
      ),
    );
  }

  Widget _buildHorizontalLine() {
    return Align(
      alignment: Alignment.center,
      child: AnimatedContainer(
        margin: configs.layerInteraction.hideToolbarOnInteraction
            ? EdgeInsets.only(
                top: sizesManager.appBarHeight,
                bottom: sizesManager.bottomBarHeight,
              )
            : EdgeInsets.zero,
        duration: Duration(milliseconds: _duration),
        width: _screenWidth,
        height:
            layerInteractionManager.showHorizontalHelperLine ? _lineHeight : 0,
        color: helperLines.style.horizontalColor,
      ),
    );
  }

  Widget _buildRotateLine() {
    return Positioned(
      left: layerInteractionManager.rotationHelperLineX,
      top: layerInteractionManager.rotationHelperLineY,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.rotate(
          angle: layerInteractionManager.rotationHelperLineDeg,
          child: AnimatedContainer(
            duration: Duration(milliseconds: _duration),
            width: layerInteractionManager.showRotationHelperLine
                ? _lineHeight
                : 0,
            height: _screenHeight * 2,
            color: helperLines.style.rotateColor,
          ),
        ),
      ),
    );
  }
}
