import 'package:flutter/widgets.dart';

/// A set of customizable widgets used in the tilt editor.
class TiltWidgets {
  const TiltWidgets({
    this.ruler,
    this.tickMark,
    this.indicator,
    this.bottomBar,
  });

  final Widget Function(
    double value,
    ValueChanged<double> onChangeUpdate,
    ValueChanged<double> onChangeEnd,
  )?
  ruler;
  final Widget? indicator;
  final Widget Function(bool isBig, bool isZero)? tickMark;
  final Widget? bottomBar;

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
