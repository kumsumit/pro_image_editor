// Flutter imports:
import 'package:flutter/widgets.dart';

// Project imports:
import 'package:pro_image_editor/widgets/custom_widgets/reactive_custom_widget.dart';

/// A typedef for creating a remove-area
///
/// - [key] - A [GlobalKey] to uniquely identify the button.
/// - [rebuildStream] - A [Stream] that triggers the widget to rebuild.
///
/// Returns a [ReactiveCustomWidget] that handles the removal of a button.
typedef RemoveButton = ReactiveCustomWidget Function(
  GlobalKey key,
  Stream<void> rebuildStream,
);

/// A typedef for creating a [ReactiveCustomWidget] that manages crop editor
/// aspect ratio options.
///
/// - [T] - The type representing the editor state.
/// - [editorState] - The current state of the editor.
/// - [rebuildStream] - A [Stream] that triggers the widget to rebuild.
/// - [aspectRatio] - The aspect ratio to be set.
/// - [originalAspectRatio] - The original aspect ratio.
///
/// Returns a [ReactiveCustomWidget] that provides options for crop editor
/// aspect ratios.
typedef CropEditorAspectRatioOptions<T> = ReactiveCustomWidget Function(
  T editorState,
  Stream<void> rebuildStream,
  double aspectRatio,
  double originalAspectRatio,
);

/// A typedef for creating a [ReactiveCustomWidget] that includes a custom
/// color picker.
///
/// - [T] - The type representing the editor state.
///
/// {@template colorPickerWidget}
/// - [editorState] - The current state of the editor.
/// - [rebuildStream] - A [Stream] that triggers the widget to rebuild.
/// - [currentColor] - The currently selected color.
/// - [setColor] - A function to update the selected color.
///
/// Returns an optional [ReactiveCustomWidget] that provides a custom color
/// picker.
///
/// **Example:**
/// ```dart
/// colorPicker: (editor, rebuildStream, currentColor, setColor) =>
///    ReactiveCustomWidget(
///      stream: rebuildStream,
///      builder: (_) => BarColorPicker(
///        configs: editor.configs,
///        length: 200,
///        horizontal: false,
///        initialColor: currentColor,
///        colorListener: (int value) {
///          setColor(Color(value));
///        },
///      ),
/// ),
/// ```
/// {@endtemplate}
typedef CustomColorPicker<T> = ReactiveCustomWidget? Function(
  T editorState,
  Stream<void> rebuildStream,
  Color currentColor,
  void Function(Color color) setColor,
);

/// A typedef for creating a [ReactiveCustomWidget] that includes a custom
/// slider.
///
/// - [T] - The type representing the editor state.
///
/// {@template customSliderWidget}
/// - [editorState] - The current state of the editor.
/// - [rebuildStream] - A [Stream] that triggers the widget to rebuild.
/// - [value] - The current value of the slider.
/// - [onChanged] - A function to handle changes to the slider's value.
/// - [onChangeEnd] - A function to handle the end of slider value changes.
///
/// Returns a [ReactiveCustomWidget] that provides a custom slider.
///
/// **Example:**
/// ```dart
/// slider: (editorState, rebuildStream, value, onChanged, onChangeEnd) {
///   return ReactiveCustomWidget(
///     stream: rebuildStream,
///     builder: (_) => Slider(
///       onChanged: onChanged,
///       onChangeEnd: onChangeEnd,
///       value: value,
///       activeColor: Colors.blue.shade200,
///     ),
///   );
/// },
/// ```
/// {@endtemplate}
typedef CustomSlider<T> = ReactiveCustomWidget Function(
  T editorState,
  Stream<void> rebuildStream,
  double value,
  Function(double value) onChanged,
  Function(double value) onChangeEnd,
);

/// A typedef for a function that creates a [ReactiveCustomWidget] for a tap
/// interaction.
///
/// The function takes the following parameters:
///
/// * [rebuildStream]: A stream that triggers the widget to rebuild.
/// * [onTap]: A callback function that is invoked when the widget is tapped.
/// * [toggleTooltipVisibility]: A function that toggles the visibility of a
/// tooltip based on the boolean value passed.
/// * [rotation]: A double value representing the current rotation of the
/// widget.
///
/// Returns a nullable [ReactiveCustomWidget].
typedef LayerInteractionTapButton = ReactiveCustomWidget? Function(
  Stream<void> rebuildStream,
  Function() onTap,
  Function(bool) toggleTooltipVisibility,
  double rotation,
);

/// A typedef for a function that creates a [ReactiveCustomWidget] for scale
/// and rotate interactions.
///
/// The function takes the following parameters:
///
/// * [rebuildStream]: A stream that triggers the widget to rebuild.
/// * [onScaleRotateDown]: A callback function that is invoked when the
/// scale/rotate action starts (on pointer down event).
/// * [onScaleRotateUp]: A callback function that is invoked when the
/// scale/rotate action ends (on pointer up event).
/// * [toggleTooltipVisibility]: A function that toggles the visibility of a
/// tooltip based on the boolean value passed.
/// * [rotation]: A double value representing the current rotation of the
/// widget.
///
/// Returns a nullable [ReactiveCustomWidget].
typedef LayerInteractionScaleRotateButton = ReactiveCustomWidget? Function(
  Stream<void> rebuildStream,
  Function(PointerDownEvent) onScaleRotateDown,
  Function(PointerUpEvent) onScaleRotateUp,
  Function(bool) toggleTooltipVisibility,
  double rotation,
);
