// Project imports:
import '../enums/export_import_enum.dart';
import '../types/widget_loader.dart';

/// This class represents configurations for importing editor data.
class ImportEditorConfigs {
  /// Constructs an [ImportEditorConfigs] instance.
  ///
  /// - [recalculateSizeAndPosition] is set to `true`
  /// - [mergeMode] is set to [ImportEditorMergeMode.replace]
  const ImportEditorConfigs({
    this.recalculateSizeAndPosition = true,
    this.mergeMode = ImportEditorMergeMode.replace,
    this.widgetLoader,
  });

  /// The merge mode for importing editor data.
  final ImportEditorMergeMode mergeMode;

  /// A flag indicating whether to recalculate size and position during import
  /// based on the new image size and device size.
  final bool recalculateSizeAndPosition;

  /// {@macro widgetLoader}
  final WidgetLoader? widgetLoader;
}
