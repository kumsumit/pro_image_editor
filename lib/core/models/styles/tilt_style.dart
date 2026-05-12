import 'package:flutter/widgets.dart';

import '../../constants/editor_style_constants.dart';

/// Defines the visual style of tilt editor widgets.
class TiltStyle {
  /// Creates a new instance of [TiltStyle].
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

  /// The color for the selected item in the bottom bar.
  final Color bottomBarSelectedColor;

  /// The color for active elements.
  final Color activeColor;

  /// The color of the indicator.
  final Color indicatorColor;

  /// The color of the tick marks.
  final Color tickMarkColor;

  /// The height of the tick marks.
  final double tickMarkHeight;

  /// The width of the tick marks.
  final double tickMarkWidth;

  /// The height of the indicator.
  final double indicatorHeight;

  /// The width of the indicator.
  final double indicatorWidth;

  /// The height of the bar.
  final double barHeight;

  /// The mouse cursor for interactive elements.
  final MouseCursor cursor;
}
