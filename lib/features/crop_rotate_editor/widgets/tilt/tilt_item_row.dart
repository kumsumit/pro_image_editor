import 'package:flutter/material.dart';

import '/shared/widgets/flat_icon_text_button.dart';
import '../../enums/tilt_mode_enum.dart';
import '../../providers/tilt_provider.dart';

/// A widget that displays a row of tilt control buttons.
class TiltItemRow extends StatelessWidget {
  /// Creates a [TiltItemRow].
  const TiltItemRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = TiltProvider.of(context);
    final tiltMode = provider.tiltMode;
    final cropRotateConfigs = provider.cropRotateConfigs;
    final i18n = provider.i18n;
    final icons = cropRotateConfigs.icons;
    final foregroundColor = cropRotateConfigs.style.bottomBarColor;
    final defaultTextStyle = TextStyle(fontSize: 10.0, color: foregroundColor);

    Color buttonColor(TiltMode mode) {
      return mode == tiltMode
          ? cropRotateConfigs.style.tiltStyle.bottomBarSelectedColor
          : foregroundColor;
    }

    return cropRotateConfigs.widgets.tiltWidgets.bottomBar ??
        Row(
          children: <Widget>[
            FlatIconTextButton(
              label: Text(i18n.back, style: defaultTextStyle),
              icon: Icon(icons.backButton, color: foregroundColor),
              onPressed: () => provider.setTiltEditorState(false),
            ),
            _buildDivider(),
            if (cropRotateConfigs.tiltConfigs.showTiltRotate)
              FlatIconTextButton(
                label: Text(
                  i18n.tiltRotate,
                  style: defaultTextStyle.copyWith(
                    color: buttonColor(TiltMode.rotate),
                  ),
                ),
                icon: Icon(
                  icons.tiltRotate,
                  color: buttonColor(TiltMode.rotate),
                ),
                onPressed: () => provider.setTiltMode(TiltMode.rotate),
              ),
            if (cropRotateConfigs.tiltConfigs.showTiltHorizontal)
              FlatIconTextButton(
                label: Text(
                  i18n.tiltHorizontal,
                  style: defaultTextStyle.copyWith(
                    color: buttonColor(TiltMode.horizontal),
                  ),
                ),
                icon: Icon(
                  icons.tiltHorizontal,
                  color: buttonColor(TiltMode.horizontal),
                ),
                onPressed: () => provider.setTiltMode(TiltMode.horizontal),
              ),
            if (cropRotateConfigs.tiltConfigs.showTiltVertical)
              FlatIconTextButton(
                label: Text(
                  i18n.tiltVertical,
                  style: defaultTextStyle.copyWith(
                    color: buttonColor(TiltMode.vertical),
                  ),
                ),
                icon: Icon(
                  icons.tiltVertical,
                  color: buttonColor(TiltMode.vertical),
                ),
                onPressed: () => provider.setTiltMode(TiltMode.vertical),
              ),
            _buildDivider(),
            FlatIconTextButton(
              label: Text(i18n.reset, style: defaultTextStyle),
              icon: Icon(icons.reset, color: foregroundColor),
              onPressed: provider.reset,
            ),
          ],
        );
  }

  Widget _buildDivider() {
    return const VerticalDivider(indent: 10, endIndent: 10, width: 10);
  }
}
