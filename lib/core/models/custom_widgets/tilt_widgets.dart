import 'package:flutter/widgets.dart';

/// A set of customizable widgets used in the tilt editor.
class TiltWidgets {
  /// Creates a new instance of [TiltWidgets].
  const TiltWidgets({
    this.ruler,
    this.tickMark,
    this.indicator,
    this.bottomBar,
  });

  /// A widget builder for the ruler component.
  final Widget Function(
    double value,
    ValueChanged<double> onChangeUpdate,
    ValueChanged<double> onChangeEnd,
  )?
  ruler;
  /// The indicator widget.
  final Widget? indicator;
  /// A widget builder for tick marks.
  final Widget Function(bool isBig, bool isZero)? tickMark;
  /// The bottom bar widget.
  final Widget? bottomBar;

  /// Creates a copy of this [TiltWidgets] with optional overrides.
  TiltWidgets copyWith({
    Widget Function(
      double value,
      ValueChanged<double> onChangeUpdate,
      ValueChanged<double> onChangeEnd,
    )?
    ruler,
    Widget? indicator,
    Widget Function(bool isBig, bool isZero)? tickMark,
    Widget? bottomBar,
  }) {
    return TiltWidgets(
      ruler: ruler ?? this.ruler,
      indicator: indicator ?? this.indicator,
      tickMark: tickMark ?? this.tickMark,
      bottomBar: bottomBar ?? this.bottomBar,
    );
  }
}
