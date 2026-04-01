import 'package:flutter/widgets.dart';

import '../../constants/editor_style_constants.dart';

/// Defines the visual style of tilt editor widgets.
class TiltStyle {
  const TiltStyle({
    this.bottomBarSelectedColor = kImageEditorPrimaryColor,
    this.activeColor = kImageEditorPrimaryColor,
    this.indicatorColor = const Color(0xFFFFFFFF),
    this.tickMarkColor = const Color(0xFFFFFFFF),
    this.tickMarkHeight = 12,
    this.tickMarkWidth = 0.8,
    this.indicatorHeight = 20,
    this.indicatorWidth = 2,
    this.barHeight = 50,
    this.cursor = SystemMouseCursors.grab,
  });

  final Color bottomBarSelectedColor;
  final Color activeColor;
  final Color indicatorColor;
  final Color tickMarkColor;
  final double tickMarkHeight;
  final double tickMarkWidth;
  final double indicatorHeight;
  final double indicatorWidth;
  final double barHeight;
  final MouseCursor cursor;
}
