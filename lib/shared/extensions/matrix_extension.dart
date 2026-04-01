import 'package:flutter/widgets.dart';

extension MatrixExtension on Matrix4 {
  Matrix4 perspective() {
    return this..setEntry(3, 2, 0.001);
  }

  Matrix4 tilt({
    required double rotate,
    required double vertical,
    required double horizontal,
  }) {
    return perspective()
      ..rotateZ(rotate)
      ..rotateX(vertical)
      ..rotateY(horizontal);
  }
}
