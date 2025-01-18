import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '/shared/services/import_export/types/widget_loader.dart';
import '../../utils/parser/int_parser.dart';
import '../editor_image.dart';
import 'layer.dart';

export '/shared/services/import_export/models/widget_layer_export_configs.dart';

/// A class representing a layer with custom widget content.
///
/// WidgetLayer is a subclass of [Layer] that allows you to display
/// custom widget content. You can specify properties like offset, rotation,
/// scale, and more.
///
/// Example usage:
/// ```dart
/// WidgetLayer(
///   offset: Offset(50.0, 50.0),
///   rotation: -30.0,
///   scale: 1.5,
/// );
/// ```
class WidgetLayer extends Layer {
  /// Creates an instance of WidgetLayer.
  ///
  /// The [widget] parameter is required, and other properties are optional.
  WidgetLayer({
    required this.widget,
    super.offset,
    super.rotation,
    super.scale,
    super.id,
    super.flipX,
    super.flipY,
    super.enableInteraction,
    this.exportConfigs = const WidgetLayerExportConfigs(),
  });

  /// Factory constructor for creating a WidgetLayer instance from a
  /// Layer, a map, and a list of widgets.
  factory WidgetLayer.fromMap({
    required Layer layer,
    required Map<String, dynamic> map,
    required List<Uint8List> widgetRecords,
    required WidgetLoader? widgetLoader,
    required Function(EditorImage editorImage)? requirePrecache,
    Function(String key)? keyConverter,
  }) {
    keyConverter ??= (String key) => key;

    /// Determines the position of the widget in the list.
    int widgetPosition = safeParseInt(
        map[keyConverter('recordPosition')] ?? map['listPosition'],
        fallback: -1);

    var exportConfigs =
        WidgetLayerExportConfigs.fromMap(map[keyConverter('exportConfigs')]);

    /// Widget to display a widget or a placeholder if not found.
    Widget widget = kDebugMode
        ? Text(
            'Widget $widgetPosition not found',
            style: const TextStyle(color: Color(0xFFF44336), fontSize: 48),
          )
        : const SizedBox.shrink();

    var defaultConstraints = const BoxConstraints(minWidth: 1, minHeight: 1);

    /// Updates the widget widget if the position is valid.
    if (exportConfigs.id != null) {
      assert(
        widgetLoader != null,
        'The `widgetLoader` must be defined when '
        'importing the widget layer by id',
      );
      widget = widgetLoader!(exportConfigs.id!, meta: exportConfigs.meta);
    } else if (exportConfigs.networkUrl != null) {
      widget = ConstrainedBox(
        constraints: defaultConstraints,
        child: Image.network(exportConfigs.networkUrl!),
      );
      requirePrecache?.call(EditorImage(networkUrl: exportConfigs.networkUrl));
    } else if (exportConfigs.assetPath != null) {
      widget = ConstrainedBox(
        constraints: defaultConstraints,
        child: Image.asset(exportConfigs.assetPath!),
      );
      requirePrecache?.call(EditorImage(assetPath: exportConfigs.assetPath));
    } else if (exportConfigs.fileUrl != null) {
      widget = ConstrainedBox(
        constraints: defaultConstraints,
        child: Image.file(File(exportConfigs.fileUrl!)),
      );
      requirePrecache?.call(EditorImage(file: File(exportConfigs.fileUrl!)));
    } else if (widgetRecords.isNotEmpty &&
        widgetRecords.length > widgetPosition) {
      var bytes = widgetRecords[widgetPosition];
      widget = ConstrainedBox(
        constraints: defaultConstraints,
        child: Image.memory(bytes),
      );
      requirePrecache?.call(EditorImage(byteArray: bytes));
    }

    /// Constructs and returns a WidgetLayer instance with properties
    /// derived from the layer and map.
    return WidgetLayer(
      id: layer.id,
      flipX: layer.flipX,
      flipY: layer.flipY,
      enableInteraction: layer.enableInteraction,
      offset: layer.offset,
      rotation: layer.rotation,
      scale: layer.scale,
      widget: widget,
      exportConfigs: exportConfigs,
    );
  }

  /// The widget to display on the layer.
  Widget widget;

  /// Configuration settings for exporting a widget layer.
  ///
  /// This class holds the necessary configurations required for a custom
  /// widget import-loader.
  WidgetLayerExportConfigs exportConfigs;

  /// Converts this transform object to a Map suitable for representing a
  /// widget.
  ///
  /// Returns a Map representing the properties of this transform object,
  /// augmented with the specified [recordPosition] indicating the position of
  /// the widget in a list.
  @override
  Map<String, dynamic> toMap([int? recordPosition]) {
    var exportConfigMap = exportConfigs.toMap();

    return {
      ...super.toMap(),
      if (recordPosition != null) 'recordPosition': recordPosition,
      if (exportConfigMap.isNotEmpty) 'exportConfigs': exportConfigMap,
      'type': 'widget',
    };
  }

  @override
  Map<String, dynamic> toMapFromReference(Layer layer) {
    return {
      ...super.toMapFromReference(layer),
    };
  }

  /// Creates a new instance of [WidgetLayer] with modified properties.
  ///
  /// Each property of the new instance can be replaced by providing a value
  /// to the corresponding parameter of this method. Unprovided parameters
  /// will default to the current instance's values.
  WidgetLayer copyWith({
    Widget? widget,
    Offset? offset,
    double? rotation,
    double? scale,
    String? id,
    bool? flipX,
    bool? flipY,
    bool? enableInteraction,
  }) {
    return WidgetLayer(
      widget: widget ?? this.widget,
      offset: offset ?? this.offset,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      id: id ?? this.id,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
      enableInteraction: enableInteraction ?? this.enableInteraction,
    );
  }
}

/// **DEPRECATED:** Use [WidgetLayer] instead.
///
/// A class representing a layer with custom sticker content.
@Deprecated('Use WidgetLayer instead')
class StickerLayerData extends WidgetLayer {
  /// Constructor for StickerLayerData
  StickerLayerData({
    required Widget sticker,
    super.offset,
    super.rotation,
    super.scale,
    super.id,
    super.flipX,
    super.flipY,
    super.enableInteraction,
  }) : super(widget: sticker);

  /// Factory constructor for creating a StickerLayerData instance from a
  /// Layer, a map, and a list of stickers.
  factory StickerLayerData.fromMap(
    Layer layer,
    Map<String, dynamic> map,
    List<Uint8List> stickers,
  ) {
    /// Determines the position of the sticker in the list.
    int stickerPosition = safeParseInt(
        map['recordPosition'] ?? map['listPosition'],
        fallback: -1);

    /// Widget to display a sticker or a placeholder if not found.
    Widget sticker = kDebugMode
        ? Text(
            'Sticker $stickerPosition not found',
            style: const TextStyle(color: Color(0xFFF44336), fontSize: 24),
          )
        : const SizedBox.shrink();

    /// Updates the sticker widget if the position is valid.
    if (stickers.isNotEmpty && stickers.length > stickerPosition) {
      sticker = ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1, minHeight: 1),
        child: Image.memory(
          stickers[stickerPosition],
        ),
      );
    }

    /// Constructs and returns a StickerLayerData instance with properties
    /// derived from the layer and map.
    return StickerLayerData(
      id: layer.id,
      flipX: layer.flipX,
      flipY: layer.flipY,
      enableInteraction: layer.enableInteraction,
      offset: layer.offset,
      rotation: layer.rotation,
      scale: layer.scale,
      sticker: sticker,
    );
  }
}
