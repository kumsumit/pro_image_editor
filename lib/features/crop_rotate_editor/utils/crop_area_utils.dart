import 'dart:ui';

import '../enums/crop_area_part.dart';
import '../enums/crop_mode.enum.dart';

/// Determines which part of the crop area is being interacted with based 
/// on the local position.
CropAreaPart determineCropAreaPart({
  required Offset localPosition,
  required Offset translate,
  required double interactiveCornerArea,
  required double userScaleFactor,
  required Rect cropRect,
  required CropMode cropMode,
  required Size renderedImageSize,
}) {
  final Offset offset =
      convertCropHitPoint(
        zoom: userScaleFactor,
        position: localPosition,
        renderedImageSize: renderedImageSize,
      ) +
      translate * userScaleFactor;
  final double dx = offset.dx;
  final double dy = offset.dy;

  if (cropMode == CropMode.oval) {
    final double halfWidth = cropRect.width / 2;
    final double halfHeight = cropRect.height / 2;
    final double halfInteractiveCornerArea = interactiveCornerArea / 2;

    final double ellipseHitX = dx / (halfWidth + halfInteractiveCornerArea);
    final double ellipseHitY = dy / (halfHeight + halfInteractiveCornerArea);
    final bool isWithinHitArea =
        (ellipseHitX * ellipseHitX + ellipseHitY * ellipseHitY) <= 1;

    final double normalizedX = dx / (halfWidth - halfInteractiveCornerArea);
    final double normalizedY = dy / (halfHeight - halfInteractiveCornerArea);
    final bool isInsideEllipse =
        (normalizedX * normalizedX + normalizedY * normalizedY) <= 1;

    if (!isWithinHitArea) return CropAreaPart.none;

    final double cursorAreaHitWidth = halfWidth * 0.5;
    final double cursorAreaHitHeight = halfHeight * 0.5;

    final bool nearTopEdge = dy < -cursorAreaHitHeight;
    final bool nearBottomEdge = dy > cursorAreaHitHeight;
    final bool nearLeftEdge = dx < -cursorAreaHitWidth;
    final bool nearRightEdge = dx > cursorAreaHitWidth;

    if (isInsideEllipse) return CropAreaPart.inside;
    if (nearBottomEdge && nearLeftEdge) return CropAreaPart.bottomLeft;
    if (nearBottomEdge && nearRightEdge) return CropAreaPart.bottomRight;
    if (nearTopEdge && nearLeftEdge) return CropAreaPart.topLeft;
    if (nearTopEdge && nearRightEdge) return CropAreaPart.topRight;
    if (nearBottomEdge) return CropAreaPart.bottom;
    if (nearTopEdge) return CropAreaPart.top;
    if (nearLeftEdge) return CropAreaPart.left;
    if (nearRightEdge) return CropAreaPart.right;
    return CropAreaPart.inside;
  }

  final Rect rect = Rect.fromCenter(
    center: cropRect.center - translate,
    width: cropRect.width + interactiveCornerArea,
    height: cropRect.height + interactiveCornerArea,
  );

  final double halfCropWidth = rect.width / 2;
  final double halfCropHeight = rect.height / 2;

  final double left = dx + halfCropWidth;
  final double right = dx - halfCropWidth;
  final double top = dy + halfCropHeight;
  final double bottom = dy - halfCropHeight;

  final bool nearLeftEdge = left.abs() <= interactiveCornerArea;
  final bool nearRightEdge = right.abs() <= interactiveCornerArea;
  final bool nearTopEdge = top.abs() <= interactiveCornerArea;
  final bool nearBottomEdge = bottom.abs() <= interactiveCornerArea;

  if (!rect.contains(localPosition)) return CropAreaPart.none;
  if (nearLeftEdge && nearTopEdge) return CropAreaPart.topLeft;
  if (nearRightEdge && nearTopEdge) return CropAreaPart.topRight;
  if (nearLeftEdge && nearBottomEdge) return CropAreaPart.bottomLeft;
  if (nearRightEdge && nearBottomEdge) return CropAreaPart.bottomRight;
  if (nearLeftEdge) return CropAreaPart.left;
  if (nearRightEdge) return CropAreaPart.right;
  if (nearTopEdge) return CropAreaPart.top;
  if (nearBottomEdge) return CropAreaPart.bottom;
  return CropAreaPart.inside;
}

/// Converts the crop hit point based on zoom and position.
Offset convertCropHitPoint({
  required double zoom,
  required Offset position,
  required Size renderedImageSize,
}) {
  final double imgW = renderedImageSize.width;
  final double imgH = renderedImageSize.height;
  final Offset transformedLocalPosition = position * zoom;
  final Size transformedImgSize = Size(imgW, imgH) * zoom;

  return Offset(
    transformedLocalPosition.dx - transformedImgSize.width / 2,
    transformedLocalPosition.dy - transformedImgSize.height / 2,
  );
}
