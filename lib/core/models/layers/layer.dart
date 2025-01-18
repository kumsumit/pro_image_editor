// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/shared/services/import_export/utils/key_minifier.dart';

import '/shared/services/import_export/types/widget_loader.dart';
import '../../utils/parser/double_parser.dart';
import '../../utils/unique_id_generator.dart';
import '../editor_image.dart';
import 'emoji_layer.dart';
import 'paint_layer.dart';
import 'text_layer.dart';
import 'widget_layer.dart';

export 'emoji_layer.dart';
export 'paint_layer.dart';
export 'text_layer.dart';
export 'widget_layer.dart';

/// Represents a layer with common properties for widgets.
class Layer {
  /// Creates a new layer with optional properties.
  ///
  /// The [id] parameter can be used to provide a custom identifier for the
  /// layer.
  /// The [offset] parameter determines the position offset of the widget.
  /// The [rotation] parameter sets the rotation angle of the widget in degrees
  /// (default is 0).
  /// The [scale] parameter sets the scale factor of the widget (default is 1).
  /// The [flipX] parameter controls horizontal flipping (default is false).
  /// The [flipY] parameter controls vertical flipping (default is false).
  /// The [enableInteraction] parameter controls if a user can interact with
  /// the layer
  Layer({
    String? id,
    Offset? offset,
    double? rotation,
    double? scale,
    bool? flipX,
    bool? flipY,
    bool? enableInteraction,
    bool? isDeleted,
  }) {
    key = GlobalKey();
    // Initialize properties with provided values or defaults.
    this.id = id ?? generateUniqueId();
    this.offset = offset ?? Offset.zero;
    this.rotation = rotation ?? 0;
    this.scale = scale ?? 1;
    this.flipX = flipX ?? false;
    this.flipY = flipY ?? false;
    this.enableInteraction = enableInteraction ?? true;
    this.isDeleted = isDeleted ?? false;
  }

  /// Factory constructor for creating a Layer instance from a map and a list
  /// of stickers.
  factory Layer.fromMap(
    Map<String, dynamic> map, {
    List<Uint8List>? widgetRecords,
    WidgetLoader? widgetLoader,
    String? id,
    Function(EditorImage editorImage)? requirePrecache,
    EditorKeyMinifier? minifier,
  }) {
    var keyConverter = minifier?.convertLayerKey ?? (String key) => key;

    /// Creates a base Layer instance with default or map-provided properties.
    Layer layer = Layer(
      id: id,
      flipX: map[keyConverter('flipX')] ?? false,
      flipY: map[keyConverter('flipY')] ?? false,
      enableInteraction: map[keyConverter('enableInteraction')] ?? true,
      offset: Offset(safeParseDouble(map['x']), safeParseDouble(map['y'])),
      rotation: safeParseDouble(map[keyConverter('rotation')]),
      scale: safeParseDouble(map[keyConverter('scale')], fallback: 1),
    );

    /// Determines the layer type from the map and returns the appropriate
    /// LayerData subclass.
    switch (map[keyConverter('type')]) {
      case 'text':
        // Returns a TextLayer instance when type is 'text'.
        return TextLayer.fromMap(layer, map, keyConverter: keyConverter);
      case 'emoji':
        // Returns an EmojiLayer instance when type is 'emoji'.
        return EmojiLayer.fromMap(layer, map, keyConverter: keyConverter);
      case 'paint':
      case 'painting':
        // Returns a PaintLayer instance when type is 'paint'.
        return PaintLayer.fromMap(layer, map, minifier: minifier);
      case 'sticker':
      case 'widget':
        // Returns a WidgetLayer instance when type is 'widget' or 'sticker',
        // utilizing the widgets layer list.
        return WidgetLayer.fromMap(
          layer: layer,
          map: map,
          widgetRecords: widgetRecords ?? [],
          widgetLoader: widgetLoader,
          requirePrecache: requirePrecache,
          keyConverter: keyConverter,
        );
      default:
        // Returns the base Layer instance when type is unrecognized.
        return layer;
    }
  }

  /// Global key associated with the Layer instance, used for accessing the
  /// widget tree.
  late GlobalKey key;

  /// The position offset of the widget.
  late Offset offset;

  /// The rotation and scale values of the widget.
  late double rotation, scale;

  /// Flags to control horizontal and vertical flipping.
  late bool flipX, flipY;

  /// Flag to enable or disable the user interaction with the layer.
  late bool enableInteraction;

  /// Flag which indicates to the history that the layer is removed.
  late bool isDeleted;

  /// A unique identifier for the layer.
  late String id;

  /// Converts this transform object to a Map.
  ///
  /// Returns a Map representing the properties of this layer object,
  /// including the X and Y coordinates, rotation angle, scale factors, and
  /// flip flags.
  Map<String, dynamic> toMap() {
    return {
      'x': offset.dx,
      'y': offset.dy,
      'rotation': rotation,
      'scale': scale,
      'flipX': flipX,
      'flipY': flipY,
      if (isDeleted) 'isDeleted': isDeleted,
      'enableInteraction': enableInteraction,
      'type': 'default',
    };
  }

  /// Converts the current layer to a map representation, comparing it with a
  /// reference layer.
  ///
  /// The resulting map will contain only the properties that differ from the
  /// reference layer.
  Map<String, dynamic> toMapFromReference(Layer layer) {
    return {
      'id': layer.id,
      if (layer.offset.dx != offset.dx) 'x': offset.dx,
      if (layer.offset.dy != offset.dy) 'y': offset.dy,
      if (layer.rotation != rotation) 'rotation': rotation,
      if (layer.scale != scale) 'scale': scale,
      if (layer.flipX != flipX) 'flipX': flipX,
      if (layer.flipY != flipY) 'flipY': flipY,
      if (isDeleted) 'isDeleted': isDeleted,
      if (layer.enableInteraction != enableInteraction)
        'enableInteraction': enableInteraction,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Layer &&
        other.id == id &&
        other.offset == offset &&
        other.rotation == rotation &&
        other.scale == scale &&
        other.flipX == flipX &&
        other.flipY == flipY &&
        other.enableInteraction == enableInteraction &&
        other.isDeleted == isDeleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        offset.hashCode ^
        rotation.hashCode ^
        scale.hashCode ^
        flipX.hashCode ^
        flipY.hashCode ^
        enableInteraction.hashCode ^
        isDeleted.hashCode;
  }
}
