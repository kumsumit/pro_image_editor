import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../mock/layers/emoji_layer_mock.dart';
import '../../../mock/layers/paint_layer_mock.dart';
import '../../../mock/layers/text_layer_mock.dart';
import '../../../mock/layers/widget_layer_mock.dart';
import '../../../mock/mock_image.dart';

void main() {
  const exportConfigs = ExportEditorConfigs(
    enableMinify: true,
    historySpan: ExportHistorySpan.current,
    maxDecimalPlaces: 16,
  );
  final importConfigs = ImportEditorConfigs(
    mergeMode: ImportEditorMergeMode.replace,
    widgetLoader: (id, {meta}) {
      if (id == 'widget-mock-container') {
        return widgetLayerMock.widget;
      }
      return Container();
    },
  );

  Future<ProImageEditorState> pumpTestEditor(
    WidgetTester tester, {
    ProImageEditorConfigs configs = const ProImageEditorConfigs(
      progressIndicatorConfigs: ProgressIndicatorConfigs(
        widgets: ProgressIndicatorWidgets(
          circularProgressIndicator: SizedBox.shrink(),
        ),
      ),
      imageGeneration: ImageGenerationConfigs(
        enableBackgroundGeneration: false,
        enableIsolateGeneration: false,
      ),
    ),
    ProImageEditorCallbacks callbacks = const ProImageEditorCallbacks(),
  }) async {
    final key = GlobalKey<ProImageEditorState>();

    await tester.pumpWidget(
      MaterialApp(
        home: ProImageEditor.memory(
          mockMemoryImage,
          key: key,
          configs: configs,
          callbacks: callbacks,
        ),
      ),
    );

    expect(find.byType(ProImageEditor), findsOneWidget);
    return key.currentState!;
  }

  Future<void> runExportImport(
    ProImageEditorState editor, {
    Function()? onAfterImport,
  }) async {
    // Export current state
    final history = await editor.exportStateHistory(configs: exportConfigs);
    final historyJson = await history.toJson();

    // Import the exported state
    final importHistory = ImportStateHistory.fromJson(
      historyJson,
      configs: importConfigs,
    );

    onAfterImport?.call();

    await editor.importStateHistory(importHistory);
  }

  group('ProImageEditor import/export', () {
    testWidgets('restores full non-destructive history after export/import', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final editor = await pumpTestEditor(tester);
        final testFilters = PresetFilters.addictiveRed.filters;
        final tuneMatrix = TuneAdjustmentMatrix(
          id: 'brightness',
          value: 0.2,
          matrix: ColorFilterAddons.brightness(0.2),
        );

        editor
          ..addHistory(blur: 3)
          ..addHistory(filters: testFilters)
          ..addHistory(tuneAdjustments: [tuneMatrix.copy()])
          ..undoAction();
        expect(editor.stateManager.historyPointer, 2);
        expect(editor.stateManager.canRedo, isTrue);
        expect(editor.stateManager.activeFilters, testFilters);
        expect(editor.stateManager.activeTuneAdjustments, isEmpty);

        final history = await editor.exportStateHistory(
          configs: const ExportEditorConfigs(
            enableMinify: true,
            historySpan: ExportHistorySpan.all,
            maxDecimalPlaces: 16,
          ),
        );
        final historyJson = await history.toJson();
        final importHistory = ImportStateHistory.fromJson(
          historyJson,
          configs: importConfigs,
        );

        editor.addHistory(blur: 0);
        expect(editor.stateManager.historyPointer, 3);
        expect(editor.stateManager.activeBlur, 0);

        await editor.importStateHistory(importHistory);

        expect(editor.stateManager.stateHistory.length, 4);
        expect(editor.stateManager.historyPointer, 2);
        expect(editor.stateManager.canUndo, isTrue);
        expect(editor.stateManager.canRedo, isTrue);
        expect(editor.stateManager.activeBlur, 3);
        expect(editor.stateManager.activeFilters, testFilters);
        expect(editor.stateManager.activeTuneAdjustments, isEmpty);

        editor.redoAction();

        expect(editor.stateManager.historyPointer, 3);
        expect(editor.stateManager.activeTuneAdjustments, [tuneMatrix.copy()]);
      });
    });

    testWidgets('restores all layers correctly after export/import', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final editor = await pumpTestEditor(tester);
        final maskedTextLayer = textLayerMock.copyWith(
          mask: const LayerMask(
            inverted: true,
            primitives: [
              LayerMaskPrimitive(
                type: LayerMaskPrimitiveType.rectangle,
                bounds: Rect.fromLTWH(4, 8, 16, 32),
                feather: 2,
              ),
            ],
          ),
        );

        // Add one of each layer type
        editor
          ..addLayer(emojiLayerMock)
          ..addLayer(maskedTextLayer)
          ..addLayer(paintLayerMock)
          ..addLayer(widgetLayerMock);

        expect(editor.activeLayers.length, 4);
        expect(editor.stateManager.historyPointer, 4);

        await runExportImport(
          editor,
          onAfterImport: () {
            editor.removeAllLayers();
            expect(editor.activeLayers.length, 0);
          },
        );

        expect(editor.activeLayers.length, 4);
        expect(editor.activeLayers[1].mask, maskedTextLayer.mask);
        expect(editor.stateManager.historyPointer, 1);
      });
    });

    testWidgets('restores blur correctly after export/import', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final editor = await pumpTestEditor(tester);

        const blurFactor = 7.0;
        editor.addHistory(blur: blurFactor);

        expect(editor.stateManager.activeBlur, blurFactor);
        expect(editor.stateManager.historyPointer, 1);

        await runExportImport(
          editor,
          onAfterImport: () {
            editor.addHistory(blur: 1);
            expect(editor.stateManager.activeBlur, 1);
          },
        );

        expect(editor.stateManager.activeBlur, blurFactor);
        expect(editor.stateManager.historyPointer, 1);
      });
    });

    testWidgets('restores filters correctly after export/import', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final editor = await pumpTestEditor(tester);

        final testFilters = PresetFilters.addictiveRed.filters;
        editor.addHistory(filters: testFilters);

        expect(editor.stateManager.activeFilters, testFilters);
        expect(editor.stateManager.historyPointer, 1);

        await runExportImport(
          editor,
          onAfterImport: () {
            editor.addHistory(filters: []);
            expect(editor.stateManager.activeFilters.length, 1);
          },
        );

        expect(editor.stateManager.activeFilters, testFilters);
        expect(editor.stateManager.historyPointer, 1);
      });
    });

    testWidgets('restores tune-adjustments correctly after export/import', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final editor = await pumpTestEditor(tester);

        final tuneMatrix = TuneAdjustmentMatrix(
          id: 'brightness',
          value: 10,
          matrix: ColorFilterAddons.brightness(10),
        );

        editor.addHistory(tuneAdjustments: [tuneMatrix.copy()]);

        expect(editor.stateManager.activeTuneAdjustments, [tuneMatrix.copy()]);
        expect(editor.stateManager.historyPointer, 1);

        await runExportImport(
          editor,
          onAfterImport: () {
            editor.addHistory(tuneAdjustments: []);
            expect(editor.stateManager.activeTuneAdjustments.length, 1);
          },
        );

        expect(editor.stateManager.activeTuneAdjustments, [tuneMatrix.copy()]);
        expect(editor.stateManager.historyPointer, 1);
      });
    });

    testWidgets(
      'restores zero-value advanced color adjustments after export/import',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          final editor = await pumpTestEditor(tester);

          const tuneMatrix = TuneAdjustmentMatrix(
            id: 'pro-color',
            value: 0,
            matrix: [],
            curves: CurvesAdjustment(
              rgb: [
                CurvePoint(input: 0, output: 0),
                CurvePoint(input: 0.5, output: 0.65),
                CurvePoint(input: 1, output: 1),
              ],
            ),
            levels: LevelsAdjustment(
              rgb: ChannelLevels(inputBlack: 0.05, inputWhite: 0.95),
            ),
            hsl: HslAdjustment(
              ranges: [
                HslRangeAdjustment(
                  range: HslColorRange.green,
                  hue: -0.04,
                  saturation: 0.2,
                  luminance: -0.1,
                ),
              ],
            ),
            colorGrading: ColorGradingAdjustment(
              wheels: [
                ColorGradingWheel(
                  range: ColorGradingRange.shadows,
                  hue: 0.58,
                  saturation: 0.25,
                  luminance: -0.08,
                ),
              ],
            ),
          );

          editor.addHistory(tuneAdjustments: [tuneMatrix.copy()]);

          expect(editor.stateManager.activeTuneAdjustments, [tuneMatrix]);
          expect(editor.stateManager.historyPointer, 1);

          await runExportImport(
            editor,
            onAfterImport: () {
              editor.addHistory(tuneAdjustments: []);
              expect(editor.stateManager.activeTuneAdjustments.length, 1);
            },
          );

          expect(editor.stateManager.activeTuneAdjustments, [tuneMatrix]);
          expect(editor.stateManager.historyPointer, 1);
        });
      },
    );

    testWidgets('restores transformations correctly after export/import', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final editor = await pumpTestEditor(tester);

        final transformConfigs = TransformConfigs(
          angle: pi / 2,
          cropRect: Rect.zero,
          originalSize: Size.zero,
          cropEditorScreenRatio: 0,
          scaleUser: 1,
          scaleRotation: 1,
          aspectRatio: 1,
          flipX: false,
          flipY: false,
          offset: Offset.zero,
          tiltRotate: 0,
          tiltHorizontal: 0,
          tiltVertical: 0,
        );

        editor.addHistory(transformConfigs: transformConfigs);

        expect(editor.stateManager.transformConfigs, transformConfigs);
        expect(editor.stateManager.historyPointer, 1);

        await runExportImport(
          editor,
          onAfterImport: () {
            editor.addHistory(transformConfigs: TransformConfigs.empty());
            expect(editor.stateManager.transformConfigs.isEmpty, isTrue);
          },
        );

        expect(editor.stateManager.transformConfigs, transformConfigs);
        expect(editor.stateManager.historyPointer, 1);
      });
    });
  });
}
