import 'package:pro_image_editor/core/models/icons/size_editor_icons.dart';
import 'package:pro_image_editor/core/models/styles/size_editor_style.dart';

class SizeEditorConfigs {
  /// Icons used in the paint editor.
  final SizeEditorIcons icons;
  
  /// Style configuration for the size editor.
  final SizeEditorStyle style;

  const SizeEditorConfigs({
    this.icons = const SizeEditorIcons(),
    this.style = const SizeEditorStyle(),
  });


}
