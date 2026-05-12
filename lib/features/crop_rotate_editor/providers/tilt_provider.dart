import 'package:flutter/widgets.dart';

import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '../enums/tilt_mode_enum.dart';

/// A provider for tilt editor state.
class TiltProvider extends InheritedWidget {
  /// Creates a new instance of [TiltProvider].
  const TiltProvider({
    required super.child,
    required this.tiltRotate,
    required this.tiltVertical,
    required this.tiltHorizontal,
    required this.cropRotateConfigs,
    required this.i18n,
    required this.isTiltEditorVisible,
    required this.tiltMode,
    required this.tiltResetCount,
    required this.onTiltChangeUpdate,
    required this.onTiltChangeEnd,
    required this.onToggleTiltBar,
    required this.onUpdateResetCount,
    super.key,
  });

  /// The current tilt rotate value.
  final double tiltRotate;

  /// The current tilt vertical value.
  final double tiltVertical;

  /// The current tilt horizontal value.
  final double tiltHorizontal;

  /// Callback for tilt value updates.
  final Function(TiltMode mode, double value) onTiltChangeUpdate;

  /// Callback for tilt value change end.
  final Function(TiltMode mode, double value) onTiltChangeEnd;

  /// Callback to toggle tilt bar visibility.
  final Function(bool isVisible) onToggleTiltBar;

  /// Callback to update reset count.
  final Function() onUpdateResetCount;

  /// The crop rotate editor configurations.
  final CropRotateEditorConfigs cropRotateConfigs;

  /// Gets the tilt configurations.
  TiltConfigs get tiltConfigs => cropRotateConfigs.tiltConfigs;

  /// The internationalization for crop rotate editor.
  final I18nCropRotateEditor i18n;

  /// Whether the tilt editor is visible.
  final bool isTiltEditorVisible;

  /// The current tilt mode.
  final TiltMode tiltMode;

  /// The number of resets performed.
  final int tiltResetCount;

  /// Gets the nearest [TiltProvider] ancestor.
  static TiltProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TiltProvider>()!;
  }

  /// Gets the nearest [TiltProvider] ancestor, or null if none exists.
  static TiltProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TiltProvider>();
  }

  /// Sets the visibility of the tilt editor.
  void setTiltEditorState(bool value) {
    onToggleTiltBar(value);
  }

  /// Sets the current tilt mode.
  void setTiltMode(TiltMode mode) {
    switch (mode) {
      case TiltMode.rotate:
        onTiltChangeUpdate(mode, tiltRotate);
        break;
      case TiltMode.horizontal:
        onTiltChangeUpdate(mode, tiltHorizontal);
        break;
      case TiltMode.vertical:
        onTiltChangeUpdate(mode, tiltVertical);
        break;
    }
  }

  /// Resets all tilt values to zero.
  void reset() {
    onTiltChangeUpdate(TiltMode.rotate, 0);
    onTiltChangeUpdate(TiltMode.horizontal, 0);
    onTiltChangeUpdate(TiltMode.vertical, 0);
    onTiltChangeEnd(tiltMode, 0);
    onUpdateResetCount();
  }

  @override
  bool updateShouldNotify(covariant TiltProvider oldWidget) {
    return tiltMode != oldWidget.tiltMode ||
        isTiltEditorVisible != oldWidget.isTiltEditorVisible ||
        tiltResetCount != oldWidget.tiltResetCount;
  }
}
