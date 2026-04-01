import 'dart:math';

import 'package:flutter/material.dart';

import '/core/models/styles/crop_rotate_editor_style.dart';

class CropCornerPainter extends CustomPainter {
  CropCornerPainter({
    required this.drawCircle,
    required this.offset,
    required this.cropRect,
    required this.fadeInOpacity,
    required this.interactionOpacity,
    required this.viewRect,
    required this.screenSize,
    required this.scaleFactor,
    required this.style,
    required this.rotationScaleFactor,
    this.tiltRotate = 0,
    this.tiltHorizontal = 0,
    this.tiltVertical = 0,
  });

  final Rect cropRect;
  final Rect viewRect;
  final Size screenSize;
  final CropRotateEditorStyle style;
  final bool drawCircle;
  final Offset offset;
  final double fadeInOpacity;
  final double interactionOpacity;
  final double scaleFactor;
  final double tiltRotate;
  final double tiltHorizontal;
  final double tiltVertical;
  final double rotationScaleFactor;

  double get _cropOffsetLeft => cropRect.left;
  double get _cropOffsetRight => cropRect.right;
  double get _cropOffsetTop => cropRect.top;
  double get _cropOffsetBottom => cropRect.bottom;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isInfinite || fadeInOpacity == -1) return;
    _drawDarkenOutside(canvas: canvas, size: size);
    if (fadeInOpacity != 0) _drawHelperAreas(canvas: canvas, size: size);
    _drawCorners(canvas: canvas);
  }

  void _drawDarkenOutside({required Canvas canvas, required Size size}) {
    final double cropWidth = _cropOffsetRight - _cropOffsetLeft;
    final double cropHeight = _cropOffsetBottom - _cropOffsetTop;

    Path path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);

    final cropRectCenter = Offset(
      cropWidth / 2 + _cropOffsetLeft,
      cropHeight / 2 + _cropOffsetTop,
    );
    final effectiveCropRect = Rect.fromCenter(
      center: cropRectCenter + const Offset(0.01, 0.01),
      width: cropWidth,
      height: cropHeight,
    );

    final Path cropPath = Path()
      ..addPath(
        drawCircle
            ? (Path()..addOval(effectiveCropRect))
            : (Path()..addRect(effectiveCropRect)),
        Offset.zero,
      );

    path = Path.combine(PathOperation.difference, path, cropPath);

    final Color interpolatedColor = Color.lerp(
      style.background,
      style.cropOverlayColor,
      fadeInOpacity,
    )!;

    final double opacity =
        style.cropOverlayOpacity -
        style.cropOverlayInteractionOpacity * interactionOpacity;
    final double fadeInFactor = (1 - opacity) * (1 - fadeInOpacity);

    canvas.drawPath(
      path,
      Paint()
        ..color = interpolatedColor.withValues(
          alpha: (opacity + fadeInFactor).clamp(0, 1),
        )
        ..style = PaintingStyle.fill,
    );
  }

  void _drawCorners({required Canvas canvas}) {
    final Path path = Path();
    final double width = style.cropCornerThickness / rotationScaleFactor;

    if (!drawCircle) {
      final double length = style.cropCornerLength / rotationScaleFactor;
      path
        ..addRect(Rect.fromLTWH(_cropOffsetLeft, _cropOffsetTop, length, width))
        ..addRect(Rect.fromLTWH(_cropOffsetLeft, _cropOffsetTop, width, length))
        ..addRect(
          Rect.fromLTWH(
            _cropOffsetRight - length,
            _cropOffsetTop,
            length,
            width,
          ),
        )
        ..addRect(
          Rect.fromLTWH(
            _cropOffsetRight - width,
            _cropOffsetTop,
            width,
            length,
          ),
        )
        ..addRect(
          Rect.fromLTWH(
            _cropOffsetLeft,
            _cropOffsetBottom - width,
            length,
            width,
          ),
        )
        ..addRect(
          Rect.fromLTWH(
            _cropOffsetLeft,
            _cropOffsetBottom - length,
            width,
            length,
          ),
        )
        ..addRect(
          Rect.fromLTWH(
            _cropOffsetRight - length,
            _cropOffsetBottom - width,
            length,
            width,
          ),
        )
        ..addRect(
          Rect.fromLTWH(
            _cropOffsetRight - width,
            _cropOffsetBottom - length,
            width,
            length,
          ),
        );

      canvas.drawPath(
        path,
        Paint()
          ..color = style.cropCornerColor.withValues(alpha: fadeInOpacity)
          ..style = PaintingStyle.fill,
      );
      return;
    }

    double calculateAngleFromArcLength(double circumference, double arcLength) {
      if (circumference <= 0 || arcLength <= 0) {
        throw ArgumentError(
          'Circumference and arc length must be positive values.',
        );
      }
      return circumference / 360 * arcLength * pi / 180;
    }

    final double angleRadians = calculateAngleFromArcLength(
      cropRect.width,
      width * 2,
    );

    path
      ..addArc(
        Rect.fromCenter(
          center: cropRect.center,
          width: cropRect.width,
          height: cropRect.height,
        ),
        3 * pi / 2 - angleRadians / 2,
        angleRadians,
      )
      ..addArc(
        Rect.fromCenter(
          center: cropRect.center,
          width: cropRect.width,
          height: cropRect.height,
        ),
        pi - angleRadians / 2,
        angleRadians,
      )
      ..addArc(
        Rect.fromCenter(
          center: cropRect.center,
          width: cropRect.width,
          height: cropRect.height,
        ),
        pi / 2 - angleRadians / 2,
        angleRadians,
      )
      ..addArc(
        Rect.fromCenter(
          center: cropRect.center,
          width: cropRect.width,
          height: cropRect.height,
        ),
        -angleRadians / 2,
        angleRadians,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = style.cropCornerColor.withValues(alpha: fadeInOpacity)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawHelperAreas({required Canvas canvas, required Size size}) {
    final lineWidth = style.helperLineWidth;
    if (lineWidth <= 0) return;

    final Path path = Path();

    final double cropWidth = _cropOffsetRight - _cropOffsetLeft;
    final double cropHeight = _cropOffsetBottom - _cropOffsetTop;

    final double cropAreaSpaceW = cropWidth / 3;
    final double cropAreaSpaceH = cropHeight / 3;

    final double drawWidth = !drawCircle
        ? cropWidth
        : sqrt(pow(cropWidth, 2) - pow(cropAreaSpaceW, 2));
    final double drawHeight = !drawCircle
        ? cropHeight
        : sqrt(pow(cropHeight, 2) - pow(cropAreaSpaceH, 2));

    final double gapW = (cropWidth - drawWidth) / 2;
    final double gapH = (cropHeight - drawHeight) / 2;

    for (var i = 1; i < 3; i++) {
      path
        ..addRect(
          Rect.fromLTWH(
            cropAreaSpaceW * i + _cropOffsetLeft,
            gapH + _cropOffsetTop,
            lineWidth,
            drawHeight,
          ),
        )
        ..addRect(
          Rect.fromLTWH(
            gapW + _cropOffsetLeft,
            cropAreaSpaceH * i + _cropOffsetTop,
            drawWidth,
            lineWidth,
          ),
        );
    }

    final cornerPaint = Paint()
      ..color = style.helperLineColor.withValues(
        alpha: style.helperLineColor.a * fadeInOpacity * interactionOpacity,
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! CropCornerPainter ||
        oldDelegate.drawCircle != drawCircle ||
        oldDelegate.offset != offset ||
        oldDelegate.cropRect != cropRect ||
        oldDelegate.fadeInOpacity != fadeInOpacity ||
        oldDelegate.interactionOpacity != interactionOpacity ||
        oldDelegate.viewRect != viewRect ||
        oldDelegate.screenSize != screenSize ||
        oldDelegate.scaleFactor != scaleFactor ||
        oldDelegate.style != style ||
        oldDelegate.rotationScaleFactor != rotationScaleFactor ||
        oldDelegate.tiltRotate != tiltRotate ||
        oldDelegate.tiltHorizontal != tiltHorizontal ||
        oldDelegate.tiltVertical != tiltVertical;
  }

  CropCornerPainter copyWith({double? fadeInOpacity}) {
    return CropCornerPainter(
      drawCircle: drawCircle,
      offset: offset,
      cropRect: cropRect,
      fadeInOpacity: fadeInOpacity ?? this.fadeInOpacity,
      interactionOpacity: interactionOpacity,
      viewRect: viewRect,
      screenSize: screenSize,
      scaleFactor: scaleFactor,
      style: style,
      rotationScaleFactor: rotationScaleFactor,
      tiltRotate: tiltRotate,
      tiltHorizontal: tiltHorizontal,
      tiltVertical: tiltVertical,
    );
  }
}
