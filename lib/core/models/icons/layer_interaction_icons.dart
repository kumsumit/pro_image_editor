// Flutter imports:
import 'package:flutter/material.dart';

/// Represents the interaction icons for layers in the theme.
///
/// This class defines the icons used for various layer interactions such as
/// removing a layer and rotating/scaling a layer.
class LayerInteractionIcons {
  /// Creates a new instance of [LayerInteractionIcons].
  ///
  /// The [edit] icon defaults to [Icons.edit].
  /// The [remove] icon defaults to [Icons.clear].
  /// The [rotateScale] icon defaults to [Icons.sync].
  const LayerInteractionIcons({
    this.remove = Icons.clear,
    this.edit = Icons.edit_outlined,
    this.rotateScale = Icons.sync,
  });

  /// The icon data for removing a layer.
  final IconData remove;

  /// The icon data for editing a TextLayer.
  final IconData edit;

  /// The icon data for rotating or scaling a layer.
  final IconData rotateScale;

  /// Creates a copy of this `LayerInteractionIcons` object with the given
  /// fields replaced with new values.
  ///
  /// The [copyWith] method allows you to create a new instance of
  /// [LayerInteractionIcons] with some properties updated while keeping the
  /// others unchanged.
  LayerInteractionIcons copyWith({
    IconData? remove,
    IconData? edit,
    IconData? rotateScale,
  }) {
    return LayerInteractionIcons(
      remove: remove ?? this.remove,
      edit: edit ?? this.edit,
      rotateScale: rotateScale ?? this.rotateScale,
    );
  }
}
