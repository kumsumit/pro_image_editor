import 'package:flutter/widgets.dart';

import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '../enums/tilt_mode_enum.dart';

class TiltProvider extends InheritedWidget {
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

  final double tiltRotate;
  final double tiltVertical;
  final double tiltHorizontal;
  final Function(TiltMode mode, double value) onTiltChangeUpdate;
  final Function(TiltMode mode, double value) onTiltChangeEnd;
  final Function(bool isVisible) onToggleTiltBar;
  final Function() onUpdateResetCount;
  final CropRotateEditorConfigs cropRotateConfigs;
  TiltConfigs get tiltConfigs => cropRotateConfigs.tiltConfigs;
  final I18nCropRotateEditor i18n;
  final bool isTiltEditorVisible;
  final TiltMode tiltMode;
  final int tiltResetCount;

  static TiltProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TiltProvider>()!;
  }

  static TiltProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TiltProvider>();
  }

  void setTiltEditorState(bool value) {
    onToggleTiltBar(value);
  }

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
