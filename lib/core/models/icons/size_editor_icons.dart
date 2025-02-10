// Flutter imports:
import 'package:flutter/material.dart';

/// Customizable icons for the Size Editor component.
class SizeEditorIcons {
  /// Creates an instance of [SizeEditorIcons] with customizable icon
  /// settings.
  ///
  /// You can provide custom icons for various actions in the Size Editor
  /// component.
  ///
  /// - [bottomNavBar]: The icon for the bottom navigation bar.
 
  ///
  /// If no custom icons are provided, default icons are used for each action.
  ///
  /// Example:
  ///
  /// ```dart
  /// SizeEditorIcons(
  ///   bottomNavBar: Icons.edit_rounded,
  /// )
  /// ```
  const SizeEditorIcons( {
    this.bottomNavBar = Icons.photo_size_select_large_outlined,
    this.moveAndZoom = Icons.pinch_outlined,
    this.applyChanges = Icons.done,
    this.compress = Icons.compress_outlined,
    this.backButton = Icons.arrow_back,
    this.undoAction = Icons.undo,
    this.redoAction = Icons.redo,
  });

  /// The icon to be displayed in the bottom navigation bar.
  final IconData bottomNavBar;

  /// The icon used for moving and zooming within the editor.
  ///
  /// This icon appears in the editor bottombar.
  ///
  /// When in the [SizeEditorConfigs] the config [enableZoom] is set to
  /// `true`, this icon will be displayed, allowing users to interact with the
  /// editor's zoom and move features. If [enableZoom] is set to `false`,
  /// the icon will be hidden.
  final IconData moveAndZoom;

  // The icon for compressing the image.
  final IconData compress;

  /// The icon for the back button.
  final IconData backButton;

  /// The icon for applying changes in the editor.
  final IconData applyChanges;

  /// The icon for undoing the last action.
  final IconData undoAction;

  /// The icon for redoing the last undone action.
  final IconData redoAction;

  /// Creates a copy of this `SizeEditorIcons` object with the given fields
  /// replaced with new values.
  ///
  /// The [copyWith] method allows you to create a new instance of
  /// [SizeEditorIcons] with some properties updated while keeping the
  /// others unchanged.
  SizeEditorIcons copyWith({
    IconData? moveAndZoom,
    IconData? bottomNavBar,
    IconData? backButton,
    IconData? compress,
    IconData? undoAction,
    IconData? redoAction,
    IconData? applyChanges,
  }) {
    return SizeEditorIcons(
      moveAndZoom: moveAndZoom ?? this.moveAndZoom,
      bottomNavBar: bottomNavBar ?? this.bottomNavBar,
      compress: compress ?? this.compress,
      backButton: backButton ?? this.backButton,
      applyChanges: applyChanges ?? this.applyChanges,
      undoAction: undoAction ?? this.undoAction,
      redoAction: redoAction ?? this.redoAction,
    );
  }
}
