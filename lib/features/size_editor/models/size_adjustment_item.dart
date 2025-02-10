/// A class representing the adjustment matrix for a tune adjustment item.
///
/// This class holds the adjustment [id], the [value] of the adjustment, and
/// the corresponding transformation [matrix] that applies the adjustment.
class SizeAdjustmentItem {
  /// Creates a [SizeAdjustmentItem] instance from a [Map] representation.
  ///
  /// This factory constructor extracts [id], [value], and [matrix] from the
  /// provided [map].
  factory SizeAdjustmentItem.fromMap(Map<String, dynamic> map) {
    return SizeAdjustmentItem(
      id: map['id']?.toString() ?? '-',
      width: double.tryParse(map['width']?.toString() ?? '0') ?? 0,
      height: double.tryParse(map['height']?.toString() ?? '0') ?? 0,
      compression: double.tryParse(map['compression']?.toString() ?? '0') ?? 0,
    );
  }

  /// Creates a [SizeAdjustmentItem] with the given [id], [value], and
  /// [matrix].
  ///
  /// - [id] is the unique identifier for the adjustment.
  /// - [width] is the new width of the image.
  /// - [height] is the new height of the image.
  /// - [compression] is the compression factor of the image.
  SizeAdjustmentItem({
    required this.id,
    required this.width,
    required this.height,
    required this.compression,
  });

  /// The unique identifier for the tune adjustment.
  final String id;

  /// The new width of the image.
  final double width;
  // The new height of the image.
  final double height;
  // The new compression factor of the image.
  final double compression;

  /// The map contains the [id], [width], and [height] as key-value pairs.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'width': width,
      'height': height,
      'compression': compression,
    };
  }

  /// Creates a copy of this [TuneAdjustmentMatrix] instance with the same
  /// values.
  ///
  /// The [copy] method allows duplicating the matrix with identical properties.
  SizeAdjustmentItem copy() {
    return SizeAdjustmentItem(
      id: id,
      width: width,
      height: height,
      compression: compression,
    );
  }
}
    
