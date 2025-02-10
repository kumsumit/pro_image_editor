import 'package:flutter/rendering.dart';

/// A custom painter that renders a gradient-filled rectangle.
/// 
/// The gradient is defined by four colors representing the corners of the
///  rectangle.
/// It blends from the top-left to the bottom-right.
///
/// Example usage:
/// ```dart
/// CustomPaint(
///   size: Size(200, 200),
///   painter: GradientPainter([Colors.red, Colors.blue, Colors.green,
///   Colors.yellow]),
/// )
/// ```
class GradientPainter extends CustomPainter {

  /// Creates a [GradientPainter] with the specified corner colors.
  ///
 
  GradientPainter(this.colors);
  /// The list of colors used to define the gradient.
  ///
  /// Expected to be a list of exactly four colors:
  /// - `colors[0]` → Top-left corner
  /// - `colors[1]` → Top-right corner
  /// - `colors[2]` → Bottom-left corner
  /// - `colors[3]` → Bottom-right corner
  /// The list must contain exactly four colors.
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    // Create a paint object with a linear gradient shader
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          colors[0], // Top-left color
          colors[1], // Top-right color
          colors[2], // Bottom-left color
          colors[3], // Bottom-right color
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw a rectangle covering the entire canvas with the gradient
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // Always repaint to reflect any color changes
    return true;
  }
}

