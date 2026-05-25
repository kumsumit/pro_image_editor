import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/core/constants/int_constants.dart';
import '/core/models/layers/layer_mask.dart';
import '/shared/extensions/num_extension.dart';
import '/shared/utils/parser/double_parser.dart';

/// Image-level retouch operation types.
enum RetouchOperationType {
  /// Clone pixels from a source offset into the masked region.
  cloneStamp,

  /// Clone pixels and blend them with target luminance.
  healingBrush,

  /// Fill the masked region from nearby surrounding pixels.
  objectRemoval,
}

/// A non-destructive retouch instruction stored in editor history.
class RetouchOperation {
  /// Creates a retouch operation.
  const RetouchOperation({
    required this.id,
    required this.type,
    required this.mask,
    this.sourceOffset = Offset.zero,
    this.strength = 1,
    this.edgeAware = true,
    this.meta = const {},
  });

  /// Creates a retouch operation from serialized data.
  factory RetouchOperation.fromMap(Map<String, dynamic> map) {
    return RetouchOperation(
      id: map['id']?.toString() ?? '-',
      type: RetouchOperationType.values.firstWhere(
        (item) => item.name == map['type'],
        orElse: () => RetouchOperationType.cloneStamp,
      ),
      mask: LayerMask.fromMap(Map<String, dynamic>.from(map['mask'] ?? {})),
      sourceOffset: _offsetFromMap(map['sourceOffset']),
      strength: safeParseDouble(map['strength'], fallback: 1.0),
      edgeAware: map['edgeAware'] != false,
      meta: Map<String, dynamic>.from(map['meta'] ?? {}),
    );
  }

  /// Stable operation id.
  final String id;

  /// Retouch behavior.
  final RetouchOperationType type;

  /// Editable mask describing the affected pixels.
  final LayerMask mask;

  /// Source offset used by clone/heal operations.
  ///
  /// A value of `Offset(-20, 0)` samples pixels 20 logical pixels left of the
  /// target pixel.
  final Offset sourceOffset;

  /// Operation strength from 0 to 1.
  final double strength;

  /// Whether the renderer may use surrounding pixels to soften hard edges.
  final bool edgeAware;

  /// Custom host-app metadata for provider-specific retouch workflows.
  final Map<String, dynamic> meta;

  /// Converts this operation to a serializable map.
  Map<String, dynamic> toMap({int maxDecimalPlaces = kMaxSafeDecimalPlaces}) {
    return {
      'id': id,
      'type': type.name,
      'mask': mask.toMap(maxDecimalPlaces: maxDecimalPlaces),
      if (sourceOffset != Offset.zero)
        'sourceOffset': _offsetToMap(sourceOffset, maxDecimalPlaces),
      if (strength != 1) 'strength': strength.roundSmart(maxDecimalPlaces),
      if (!edgeAware) 'edgeAware': edgeAware,
      if (meta.isNotEmpty) 'meta': meta,
    };
  }

  /// Creates a copy with updated values.
  RetouchOperation copyWith({
    String? id,
    RetouchOperationType? type,
    LayerMask? mask,
    Offset? sourceOffset,
    double? strength,
    bool? edgeAware,
    Map<String, dynamic>? meta,
  }) {
    return RetouchOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      mask: mask ?? this.mask,
      sourceOffset: sourceOffset ?? this.sourceOffset,
      strength: strength ?? this.strength,
      edgeAware: edgeAware ?? this.edgeAware,
      meta: meta ?? this.meta,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RetouchOperation &&
        other.id == id &&
        other.type == type &&
        other.mask == mask &&
        other.sourceOffset == sourceOffset &&
        other.strength == strength &&
        other.edgeAware == edgeAware &&
        mapEquals(other.meta, meta);
  }

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      mask.hashCode ^
      sourceOffset.hashCode ^
      strength.hashCode ^
      edgeAware.hashCode ^
      Object.hashAll(meta.entries);
}

Map<String, dynamic> _offsetToMap(Offset offset, int maxDecimalPlaces) => {
  'x': offset.dx.roundSmart(maxDecimalPlaces),
  'y': offset.dy.roundSmart(maxDecimalPlaces),
};

Offset _offsetFromMap(dynamic rawOffset) {
  final map = Map<String, dynamic>.from(rawOffset ?? {});
  return Offset(safeParseDouble(map['x']), safeParseDouble(map['y']));
}
