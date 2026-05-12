import 'package:flutter/widgets.dart';

/// Extension methods for Matrix4 to support perspective
///  and tilt transformations.
extension MatrixExtension on Matrix4 {
  /// Applies a perspective transformation to the matrix.
  Matrix4 perspective() {
    return this..setEntry(3, 2, 0.001);
  }

  /// Applies tilt transformations (rotate, vertical, horizontal) to the matrix.
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
