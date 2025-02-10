// // Dart imports:
// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// import '/core/mixins/converted_callbacks.dart';
// import '/core/mixins/converted_configs.dart';
// import '/core/mixins/standalone_editor.dart';
// import '/core/models/transform_helper.dart';
// import '/core/platform/io/io_helper.dart';
// import '/features/tune_editor/widgets/tune_editor_bottombar.dart';
// import '/pro_image_editor.dart';
// import '/shared/services/content_recorder/widgets/content_recorder.dart';
// import '/shared/widgets/layer/layer_stack.dart';
// import '/shared/widgets/transform/transformed_content_generator.dart';
// import 'models/size_adjustment_item.dart';
// import 'widgets/size_editor_appbar.dart';
// // import 'models/tune_adjustment_matrix.dart';
// // import 'utils/tune_presets.dart';
// // import 'widgets/tune_editor_appbar.dart';

// // export 'models/tune_adjustment_item.dart';

// /// The `TuneEditor` widget allows users to edit images with various
// /// tune adjustment tools such as brightness, contrast, and saturation.
// ///
// /// You can create a `TuneEditor` using one of the factory methods provided:
// /// - `TuneEditor.file`: Loads an image from a file.
// /// - `TuneEditor.asset`: Loads an image from an asset.
// /// - `TuneEditor.network`: Loads an image from a network URL.
// /// - `TuneEditor.memory`: Loads an image from memory as a `Uint8List`.
// /// - `TuneEditor.autoSource`: Automatically selects the source based on
// /// the provided parameters.
// class SizeEditor extends StatefulWidget
//     with StandaloneEditor<TuneEditorInitConfigs> {
//   /// Constructs a `TuneEditor` widget.
//   ///
//   /// The [key] parameter is used to provide a key for the widget.
//   /// The [editorImage] parameter specifies the image to be edited.
//   /// The [initConfigs] parameter specifies the initialization configurations
//   /// for the editor.
//   const SizeEditor._({
//     super.key,
//     required this.editorImage,
//     required this.initConfigs,
//   });

//   /// Constructs a `TuneEditor` widget with image data loaded from memory.
//   factory SizeEditor.memory(
//     Uint8List byteArray, {
//     Key? key,
//     required TuneEditorInitConfigs initConfigs,
//   }) {
//     return SizeEditor._(
//       key: key,
//       editorImage: EditorImage(byteArray: byteArray),
//       initConfigs: initConfigs,
//     );
//   }

//   /// Constructs a `TuneEditor` widget with an image loaded from a file.
//   factory SizeEditor.file(
//     File file, {
//     Key? key,
//     required TuneEditorInitConfigs initConfigs,
//   }) {
//     return SizeEditor._(
//       key: key,
//       editorImage: EditorImage(file: file),
//       initConfigs: initConfigs,
//     );
//   }

//   /// Constructs a `TuneEditor` widget with an image loaded from an asset.
//   factory SizeEditor.asset(
//     String assetPath, {
//     Key? key,
//     required TuneEditorInitConfigs initConfigs,
//   }) {
//     return SizeEditor._(
//       key: key,
//       editorImage: EditorImage(assetPath: assetPath),
//       initConfigs: initConfigs,
//     );
//   }

//   /// Constructs a `TuneEditor` widget with an image loaded from a network
//   /// URL.
//   factory SizeEditor.network(
//     String networkUrl, {
//     Key? key,
//     required TuneEditorInitConfigs initConfigs,
//   }) {
//     return SizeEditor._(
//       key: key,
//       editorImage: EditorImage(networkUrl: networkUrl),
//       initConfigs: initConfigs,
//     );
//   }

//   /// Constructs a `TuneEditor` widget with an image loaded automatically
//   /// based on the provided source.
//   ///
//   /// Either [byteArray], [file], [networkUrl], or [assetPath] must be provided.
//   factory SizeEditor.autoSource({
//     Key? key,
//     Uint8List? byteArray,
//     File? file,
//     String? assetPath,
//     String? networkUrl,
//     EditorImage? editorImage,
//     required TuneEditorInitConfigs initConfigs,
//   }) {
//     if (byteArray != null || editorImage?.byteArray != null) {
//       return SizeEditor.memory(
//         byteArray ?? editorImage!.byteArray!,
//         key: key,
//         initConfigs: initConfigs,
//       );
//     } else if (file != null || editorImage?.file != null) {
//       return SizeEditor.file(
//         file ?? editorImage!.file!,
//         key: key,
//         initConfigs: initConfigs,
//       );
//     } else if (networkUrl != null || editorImage?.networkUrl != null) {
//       return SizeEditor.network(
//         networkUrl ?? editorImage!.networkUrl!,
//         key: key,
//         initConfigs: initConfigs,
//       );
//     } else if (assetPath != null || editorImage?.assetPath != null) {
//       return SizeEditor.asset(
//         assetPath ?? editorImage!.assetPath!,
//         key: key,
//         initConfigs: initConfigs,
//       );
//     } else {
//       throw ArgumentError(
//           "Either 'byteArray', 'file', 'networkUrl' or 'assetPath' must "
//           'be provided.');
//     }
//   }
//   @override
//   final TuneEditorInitConfigs initConfigs;
//   @override
//   final EditorImage editorImage;

//   @override
//   createState() => SizeEditorState();
// }

// /// The state class for the `TuneEditor` widget.
// class SizeEditorState extends State<SizeEditor>
//     with
//         ImageEditorConvertedConfigs,
//         ImageEditorConvertedCallbacks,
//         StandaloneEditorState<SizeEditor, TuneEditorInitConfigs> {
//   /// A stream controller used to manage UI updates.
//   ///
//   /// This stream is used to broadcast events when the UI needs to be rebuilt.
//   late final StreamController<void> uiStream;

//   /// A scroll controller for the bottom bar in the tune editor.
//   ///
//   /// This controller manages the scrolling behavior of the bottom bar.
//   final bottomBarScrollCtrl = ScrollController();

//   /// The index of the currently selected tune adjustment item.
//   ///
//   /// This index represents the adjustment item that is currently being modified
//   /// by the user.
//   int selectedIndex = 0;

//  /// A stack used to keep track of previous states for undo functionality.
//   ///
//   /// Each entry in the list is a snapshot of the `tuneAdjustmentMatrix` at a
//   /// certain point, allowing the user to revert to a previous state.
//   List<SizeAdjustmentItem> _undoStack = [];

//   /// A stack used to keep track of states for redo functionality.
//   ///
//   /// When the user undoes an action, the current state is moved to this stack,
//   /// allowing them to redo the action and return to that state if desired.
//   List<List<SizeAdjustmentItem>> _redoStack = [];

//   /// Determines whether undo can be performed on the current state.
//   bool get canUndo => _undoStack.isNotEmpty;

//   /// Determines whether redo can be performed on the current state.
//   bool get canRedo => _redoStack.isNotEmpty;

//   @override
//   void initState() {
//     super.initState();
//     uiStream = StreamController.broadcast();
//     uiStream.stream.listen((_) => rebuildController.add(null));

//     tuneEditorCallbacks?.onInit?.call();
//     WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
//       tuneEditorCallbacks?.onAfterViewInit?.call();
//     });
//   }

//   @override
//   void dispose() {
//     bottomBarScrollCtrl.dispose();
//     uiStream.close();
//     super.dispose();
//   }

//   @override
//   void setState(void Function() fn) {
//     rebuildController.add(null);
//     super.setState(fn);
//   }

//   /// Handles the "Done" action, either by applying changes or closing the
//   /// editor.
//   void done() async {
//     doneEditing(
//       editorImage: editorImage,
//       returnValue: tuneAdjustmentMatrix,
//     );
//     tuneEditorCallbacks?.handleDone();
//   }

//   /// Resets the tune editor state, clearing undo and redo stacks.
//   void reset() {
//     _undoStack = [];
//     _redoStack = [];
//     _setMatrixList();
//     setState(() {});
//   }

//   /// Redoes the last undone action.
//   ///
//   /// Moves the last action from the redo stack to the undo stack and restores
//   /// the adjustment matrix.
//   void redo() {
//     if (_redoStack.isNotEmpty) {
//       /// Save current state to undo stack
//       _undoStack.add(List.from(tuneAdjustmentMatrix.map((e) => e.copy())));

//       /// Restore the last state from redo stack
//       tuneAdjustmentMatrix = _redoStack.removeLast();

//       tuneEditorCallbacks?.handleRedo();

//       setState(() {});
//     }
//   }

//   /// Undoes the last action.
//   ///
//   /// Moves the last action from the undo stack to the redo stack and restores
//   /// the previous adjustment matrix.
//   void undo() {
//     if (_undoStack.isNotEmpty) {
//       /// Save current state to redo stack
//       _redoStack.add(List.from(tuneAdjustmentMatrix.map((e) => e.copy())));

//       /// Restore the last state from undo stack
//       tuneAdjustmentMatrix = _undoStack.removeLast();

//       tuneEditorCallbacks?.handleUndo();

//       setState(() {});
//     }
//   }

//   /// Initializes the adjustment matrix with default values.
//   void _setMatrixList() {
//     tuneAdjustmentMatrix = tuneAdjustmentList
//         .map(
//           (item) => TuneAdjustmentMatrix(
//             id: item.id,
//             value: 0,
//             matrix: item.toMatrix(0),
//           ),
//         )
//         .toList();
//   }

//   /// Handles changes in the tune factor value.
//   void onChanged(double value) {
//     var selectedItem = tuneAdjustmentList[selectedIndex];

//     int index =
//         tuneAdjustmentMatrix.indexWhere((item) => item.id == selectedItem.id);

//     var item = TuneAdjustmentMatrix(
//       id: selectedItem.id,
//       value: value,
//       matrix: selectedItem.toMatrix(value),
//     );
//     if (index >= 0) {
//       tuneAdjustmentMatrix[index] = item;
//     } else {
//       tuneAdjustmentMatrix.add(item);
//     }

//     /// Important that the hash-code update
//     tuneAdjustmentMatrix = [...tuneAdjustmentMatrix];

//     uiStream.add(null);
//     tuneEditorCallbacks?.handleTuneFactorChange(tuneAdjustmentMatrix);
//   }

//   /// Saves the current state to the undo stack before making changes.
//   void onChangedStart(double value) {
//     // Save current state to undo stack before making changes
//     _undoStack.add(
//       tuneAdjustmentMatrix.map((e) => e.copy()).toList(),
//     );
//     // Clear redo stack because a new change is made
//     _redoStack.clear();
//   }

//   /// Handles the end of changes in the tune factor value.
//   void onChangedEnd(double value) {
//     setState(() {});

//     tuneEditorCallbacks?.handleTuneFactorChangeEnd(tuneAdjustmentMatrix);
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       takeScreenshot();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Theme(
//       data: theme.copyWith(
//           tooltipTheme: theme.tooltipTheme.copyWith(preferBelow: true)),
//       child: ExtendedPopScope(
//         child: AnnotatedRegion<SystemUiOverlayStyle>(
//           value: tuneEditorConfigs.style.uiOverlayStyle,
//           child: SafeArea(
//             top: tuneEditorConfigs.safeArea.top,
//             bottom: tuneEditorConfigs.safeArea.bottom,
//             left: tuneEditorConfigs.safeArea.left,
//             right: tuneEditorConfigs.safeArea.right,
//             child: RecordInvisibleWidget(
//               controller: screenshotCtrl,
//               child: Scaffold(
//                 backgroundColor: tuneEditorConfigs.style.background,
//                 appBar: _buildAppBar(),
//                 body: _buildBody(),
//                 bottomNavigationBar: _buildBottomNavBar(),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   /// Builds the app bar for the tune editor.
//   PreferredSizeWidget? _buildAppBar() {
//     if (tuneEditorConfigs.widgets.appBar != null) {
//       return tuneEditorConfigs.widgets.appBar!
//           .call(this, rebuildController.stream);
//     }
//     return SizeEditorAppbar(
//      configs: sizeEditorConfigs,
//       i18n: i18n.tuneEditor,
//       canRedo: canRedo,
//       canUndo: canUndo,
//       onClose: close,
//       onDone: done,
//       onRedo: redo,
//       onUndo: undo,
//     );
//   }

//   /// Builds the main content area of the editor.
//   Widget _buildBody() {
//     return LayoutBuilder(builder: (context, constraints) {
//       editorBodySize = constraints.biggest;
//       return Stack(
//         alignment: Alignment.center,
//         fit: StackFit.expand,
//         children: [
//           ContentRecorder(
//             controller: screenshotCtrl,
//             child: Stack(
//               alignment: Alignment.center,
//               fit: StackFit.expand,
//               children: [
//                 _buildBackgroundImage(),
//                 if (tuneEditorConfigs.showLayers && layers != null)
//                   _buildLayers(),
//                 if (tuneEditorConfigs.widgets.bodyItemsRecorded != null)
//                   ...tuneEditorConfigs.widgets.bodyItemsRecorded!(
//                       this, rebuildController.stream),
//               ],
//             ),
//           ),
//           if (tuneEditorConfigs.widgets.bodyItems != null)
//             ...tuneEditorConfigs.widgets.bodyItems!(
//                 this, rebuildController.stream),
//         ],
//       );
//     });
//   }

//   Widget _buildBackgroundImage() {
//     return Hero(
//       tag: heroTag,
//       createRectTween: (begin, end) => RectTween(begin: begin, end: end),
//       child: TransformedContentGenerator(
//         configs: configs,
//         transformConfigs: initialTransformConfigs ?? TransformConfigs.empty(),
//         child: StreamBuilder(
//             stream: uiStream.stream,
//             builder: (context, snapshot) {
//               return FilteredImage(
//                 width: getMinimumSize(mainImageSize, editorBodySize).width,
//                 height: getMinimumSize(mainImageSize, editorBodySize).height,
//                 configs: configs,
//                 image: editorImage,
//                 filters: appliedFilters,
//                 tuneAdjustments: tuneAdjustmentMatrix,
//                 blurFactor: appliedBlurFactor,
//               );
//             }),
//       ),
//     );
//   }

//   Widget _buildLayers() {
//     return LayerStack(
//       transformHelper: TransformHelper(
//         mainBodySize: getMinimumSize(mainBodySize, editorBodySize),
//         mainImageSize: getMinimumSize(mainImageSize, editorBodySize),
//         editorBodySize: editorBodySize,
//         transformConfigs: initialTransformConfigs,
//       ),
//       configs: configs,
//       layers: layers!,
//       clipBehavior: Clip.none,
//     );
//   }

//   /// Builds the bottom navigation bar with tune options.
//   Widget? _buildBottomNavBar() {
//     if (tuneEditorConfigs.widgets.bottomBar != null) {
//       return tuneEditorConfigs.widgets.bottomBar!
//           .call(this, rebuildController.stream);
//     }

//     return TuneEditorBottombar(
//       state: this,
//       tuneEditorConfigs: tuneEditorConfigs,
//       tuneAdjustmentList: tuneAdjustmentList,
//       tuneAdjustmentMatrix: tuneAdjustmentMatrix,
//       rebuildController: rebuildController,
//       onChangedStart: onChangedStart,
//       onChanged: onChanged,
//       onChangedEnd: onChangedEnd,
//       bottomBarScrollCtrl: bottomBarScrollCtrl,
//       onSelect: (index) {
//         setState(() {
//           selectedIndex = index;
//         });
//       },
//       selectedIndex: selectedIndex,
//     );
//   }
// }
