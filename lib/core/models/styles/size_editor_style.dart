// Flutter imports:
import 'package:flutter/services.dart';

import '../../constants/editor_style_constants.dart';

/// The `CropRotateEditorStyle` class defines the styles for the crop and rotate
/// editor in the image editor.
/// It includes properties such as colors for the app bar, background, crop
/// corners, and more.
///
/// Usage:
///
/// ```dart
/// CropRotateEditorStyle cropRotateEditorStyle = CropRotateEditorStyle(
///   appBarBackgroundColor: Colors.black,
///   appBarForegroundColor: Colors.white,
///   background: Colors.grey,
///   cropCornerColor: Colors.blue,
///   cropRectType: InitCropRectType.circle,
/// );
/// ```
///
/// Properties:
///
/// - `appBarBackgroundColor`: Background color of the app bar in the crop and
/// rotate editor.
///
/// - `appBarForegroundColor`: Foreground color (text and icons) of the app bar.
///
/// - `background`: Background color of the crop and rotate editor.
///
/// - `cropCornerColor`: Color of the crop corners.
///
/// - `cropRectType`: Type of the initial crop rectangle
/// (e.g., `InitCropRectType.circle`, `InitCropRectType.imageRect`).
///
/// Example Usage:
///
/// ```dart
/// CropRotateEditorStyle cropRotateEditorStyle = CropRotateEditorStyle(
///   appBarBackgroundColor: Colors.black,
///   appBarForegroundColor: Colors.white,
///   background: Colors.grey,
///   cropCornerColor: Colors.blue,
///   cropRectType: InitCropRectType.circle,
/// );
///
/// Color appBarBackgroundColor = cropRotateEditorStyle.appBarBackgroundColor;
/// Color background = cropRotateEditorStyle.background;
/// // Access other style properties...
/// ```
class SizeEditorStyle {
  /// Creates an instance of the `CropRotateEditorStyle` class with the
  /// specified style properties.
  const SizeEditorStyle({
    this.appBarBackground = kImageEditorAppBarBackground,
    this.appBarColor = kImageEditorAppBarColor,
    this.helperLineColor = const Color(0xFF000000),
    this.background = kImageEditorBackground,
    this.bottomBarBackground = kImageEditorAppBarBackground,
    this.bottomBarColor = kImageEditorAppBarColor,
    this.uiOverlayStyle = kImageEditorUiOverlayStyle,
  });

  /// Background color of the app bar in the crop and rotate editor.
  final Color appBarBackground;

  /// Foreground color (text and icons) of the app bar.
  final Color appBarColor;

  /// Background color of the bottom app bar.
  final Color bottomBarBackground;

  /// Foreground color (text and icons) of the bottom app bar.
  final Color bottomBarColor;

  /// Background color of the crop and rotate editor.
  final Color background;

  /// Color from the helper lines when moving the image.
  final Color helperLineColor;

  /// UI overlay style, defining the appearance of system status bars.
  final SystemUiOverlayStyle uiOverlayStyle;

  /// Creates a copy of this `CropRotateEditorStyle` object with the given
  /// fields replaced with new values.
  ///
  /// The [copyWith] method allows you to create a new instance of
  /// [SizeEditorStyle] with some properties updated while keeping the
  /// others unchanged.
  SizeEditorStyle copyWith({
    Color? appBarBackground,
    Color? appBarColor,
    Color? bottomBarBackground,
    Color? bottomBarColor,
    Color? aspectRatioSheetBackgroundColor,
    Color? aspectRatioSheetForegroundColor,
    Color? background,
    Color? cropCornerColor,
    Color? helperLineColor,
    Color? cropOverlayColor,
    double? cropCornerLength,
    double? cropCornerThickness,
    SystemUiOverlayStyle? uiOverlayStyle,
  }) {
    return SizeEditorStyle(
      appBarBackground: appBarBackground ?? this.appBarBackground,
      appBarColor: appBarColor ?? this.appBarColor,
      bottomBarBackground: bottomBarBackground ?? this.bottomBarBackground,
      bottomBarColor: bottomBarColor ?? this.bottomBarColor,
      background: background ?? this.background,
      helperLineColor: helperLineColor ?? this.helperLineColor,
      uiOverlayStyle: uiOverlayStyle ?? this.uiOverlayStyle,
    );
  }
}
