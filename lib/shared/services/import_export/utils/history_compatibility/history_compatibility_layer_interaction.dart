import '/core/models/layers/layer_interaction.dart';
import '/shared/services/import_export/utils/key_minifier.dart';
import '../../constants/export_import_version.dart';

/// Handles the compatibility of layer interactions based on the provided
/// version.
///
/// This function updates the `layerMap` to ensure compatibility with different
/// versions of the export/import format. It converts the interaction-related keys
/// using the provided `minifier` and updates the `layerMap` accordingly.
///
/// The function supports the following versions:
/// - `ExportImportVersion.version_1_0_0`
/// - `ExportImportVersion.version_2_0_0`
/// - `ExportImportVersion.version_3_0_0`
/// - `ExportImportVersion.version_3_0_1`
/// - `ExportImportVersion.version_4_0_0`
/// - `ExportImportVersion.version_5_0_0`
///
/// If the `enableInteraction` key is present in the `layerMap`, it converts it
/// to the `interaction` key using the `LayerInteraction` class and the provided
/// `minifier`.
///
/// Parameters:
/// - `layerMap`: A map representing the layer data.
/// - `version`: The version of the export/import format.
/// - `minifier`: An instance of `EditorKeyMinifier` used to convert keys.
historyCompatibilityLayerInteraction({
  required Map<String, dynamic> layerMap,
  required String version,
  required EditorKeyMinifier minifier,
}) {
  switch (version) {
    case ExportImportVersion.version_1_0_0:
    case ExportImportVersion.version_2_0_0:
    case ExportImportVersion.version_3_0_0:
    case ExportImportVersion.version_3_0_1:
    case ExportImportVersion.version_4_0_0:
    case ExportImportVersion.version_5_0_0:
      {
        var keyConverter = minifier.convertLayerKey;
        if (layerMap[keyConverter('enableInteraction')] != null) {
          var interactionMap = LayerInteraction.fromDefaultValue(
                  layerMap[keyConverter('enableInteraction')] == true)
              .toMap();
          layerMap[keyConverter('interaction')] = interactionMap.map(
            (itemKey, itemValue) => MapEntry(
                minifier.convertLayerInteractionKey(itemKey), itemValue),
          );
        }
      }
    default:
    // No action required
  }
}
