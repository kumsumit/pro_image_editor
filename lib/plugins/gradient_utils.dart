import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:palette_generator/palette_generator.dart';

/// Crops an image from the given byte list based on the specified region.
///
/// The function decodes the image, extracts the given region, and returns
/// the cropped image as a PNG-encoded byte list.
///
/// - [byteList]: The input image in `Uint8List` format.
/// - [region]: The rectangular area to crop, specified using a [Rect].
///
/// Returns a `Uint8List` containing the cropped image in PNG format.
Uint8List cropImage(Uint8List byteList, Rect region) {
  final originalImage = img.decodeImage(byteList);
  final croppedImage = img.copyCrop(
    originalImage!,
    x: region.left.toInt(),
    y: region.top.toInt(),
    width: region.width.toInt(),
    height: region.height.toInt(),
  );
  return Uint8List.fromList(img.encodePng(croppedImage));
}

/// Extracts the dominant colors from four key regions of an image.
///
/// The function divides the image into four quadrants (top-left, top-right,
/// bottom-left, bottom-right) and extracts a dominant color from each.
/// If the image is larger than 100x100 pixels, a fixed 50x50 region is used.
/// Otherwise, the image is split proportionally.
///
/// - [byteList]: The input image in `Uint8List` format.
///
/// Returns a list of four `Color` values, one from each region.
Future<List<Color>> extractColors(Uint8List byteList) async {
  img.Image? image = img.decodeImage(byteList);
  if (image != null) {
    if (image.width > 100 || image.height > 100) {
      // Define fixed regions for larger images
      const topLeft = Rect.fromLTWH(0, 0, 50, 50);
      final topRight = Rect.fromLTWH(image.width - 50, 0, 50, 50);
      final bottomLeft = Rect.fromLTWH(0, image.height - 50, 50, 50);
      final bottomRight =
          Rect.fromLTWH(image.width - 50, image.height - 50, 50, 50);

      // Extract dominant colors from cropped regions
      final topLeftColor = (await PaletteGenerator.fromImageProvider(
        MemoryImage(cropImage(byteList, topLeft)),
        maximumColorCount: 1,
      ))
          .colors;

      final topRightColor = (await PaletteGenerator.fromImageProvider(
        MemoryImage(cropImage(byteList, topRight)),
        maximumColorCount: 1,
      ))
          .colors;

      final bottomLeftColor = (await PaletteGenerator.fromImageProvider(
        MemoryImage(cropImage(byteList, bottomLeft)),
        maximumColorCount: 1,
      ))
          .colors;

      final bottomRightColor = (await PaletteGenerator.fromImageProvider(
        MemoryImage(cropImage(byteList, bottomRight)),
        maximumColorCount: 1,
      ))
          .colors;

      return [
        topLeftColor.isNotEmpty ? topLeftColor.first : getRandomColor(),
        topRightColor.isNotEmpty ? topRightColor.first : getRandomColor(),
        bottomLeftColor.isNotEmpty ? bottomLeftColor.first : getRandomColor(),
        bottomRightColor.isNotEmpty ? bottomRightColor.first : getRandomColor(),
      ];
    } else {
      // Dynamically split regions for smaller images
      final topLeft = Rect.fromLTWH(0, 0, image.width / 2, image.height / 2);
      final topRight =
          Rect.fromLTWH(image.width / 2, 0, image.width / 2, image.height / 2);
      final bottomLeft =
          Rect.fromLTWH(0, image.height / 2, image.width / 2, image.height / 2);
      final bottomRight = Rect.fromLTWH(
          image.width / 2, image.height / 2, image.width / 2, image.height / 2);

      // Extract dominant colors using the PaletteGenerator
      final topLeftColor = (await PaletteGenerator.fromImageProvider(
        MemoryImage(byteList),
        region: topLeft,
        maximumColorCount: 1,
      ))
          .colors;

      final topRightColor = (await PaletteGenerator.fromImageProvider(
        MemoryImage(byteList),
        region: topRight,
        maximumColorCount: 1,
      ))
          .colors;

      final bottomLeftColor = (await PaletteGenerator.fromImageProvider(
        MemoryImage(byteList),
        region: bottomLeft,
        maximumColorCount: 1,
      ))
          .colors;

      final bottomRightColor = (await PaletteGenerator.fromImageProvider(
        MemoryImage(byteList),
        region: bottomRight,
        maximumColorCount: 1,
      ))
          .colors;

      return [
        topLeftColor.isNotEmpty ? topLeftColor.first : getRandomColor(),
        topRightColor.isNotEmpty ? topRightColor.first : getRandomColor(),
        bottomLeftColor.isNotEmpty ? bottomLeftColor.first : getRandomColor(),
        bottomRightColor.isNotEmpty ? bottomRightColor.first : getRandomColor(),
      ];
    }
  }
  return [];
}

/// Generates a random color.
///
/// The function creates an RGB color with random values between 0 and 255.
/// The alpha channel is always set to 255 (fully opaque).
///
/// Returns a randomly generated `Color`.
Color getRandomColor() {
  final Random random = Random();
  return Color.fromARGB(
    255,
    random.nextInt(256),
    random.nextInt(256),
    random.nextInt(256),
  );
}
