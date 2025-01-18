import 'layer.dart';

/// A class representing a layer with emoji content.
///
/// EmojiLayer is a subclass of [Layer] that allows you to display emoji
/// on a canvas. You can specify the emoji to display, along with optional
/// properties like offset, rotation, scale, and more.
///
/// Example usage:
/// ```dart
/// EmojiLayer(
///   emoji: '😀',
///   offset: Offset(100.0, 100.0),
///   rotation: 45.0,
///   scale: 2.0,
/// );
/// ```
class EmojiLayer extends Layer {
  /// Creates an instance of EmojiLayer.
  ///
  /// The [emoji] parameter is required, and other properties are optional.
  EmojiLayer({
    required this.emoji,
    super.offset,
    super.rotation,
    super.scale,
    super.id,
    super.flipX,
    super.flipY,
    super.enableInteraction,
  });

  /// Factory constructor for creating an EmojiLayer instance from a Layer
  /// and a map.
  factory EmojiLayer.fromMap(
    Layer layer,
    Map<String, dynamic> map, {
    Function(String key)? keyConverter,
  }) {
    keyConverter ??= (String key) => key;

    /// Constructs and returns an EmojiLayer instance with properties
    /// derived from the layer and map.
    return EmojiLayer(
      id: layer.id,
      flipX: layer.flipX,
      flipY: layer.flipY,
      enableInteraction: layer.enableInteraction,
      offset: layer.offset,
      rotation: layer.rotation,
      scale: layer.scale,
      emoji: map[keyConverter('emoji')],
    );
  }

  /// The emoji to display on the layer.
  String emoji;

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'emoji': emoji,
      'type': 'emoji',
    };
  }

  @override
  Map<String, dynamic> toMapFromReference(Layer layer) {
    return {
      ...super.toMapFromReference(layer),
      if ((layer as EmojiLayer).emoji != emoji) 'emoji': emoji,
    };
  }
}

// TODO: Remove in version 8.0.0
/// **DEPRECATED:** Use [EmojiLayer] instead.
@Deprecated('Use EmojiLayer instead')
class EmojiLayerData extends EmojiLayer {
  /// Constructor for EmojiLayerData
  EmojiLayerData({
    required super.emoji,
    super.offset,
    super.rotation,
    super.scale,
    super.id,
    super.flipX,
    super.flipY,
    super.enableInteraction,
  });

  /// Factory constructor for creating an EmojiLayerData instance from a Layer
  /// and a map.
  factory EmojiLayerData.fromMap(Layer layer, Map<String, dynamic> map) {
    /// Constructs and returns an EmojiLayerData instance with properties
    /// derived from the layer and map.
    return EmojiLayerData(
      id: layer.id,
      flipX: layer.flipX,
      flipY: layer.flipY,
      enableInteraction: layer.enableInteraction,
      offset: layer.offset,
      rotation: layer.rotation,
      scale: layer.scale,
      emoji: map['emoji'],
    );
  }
}
