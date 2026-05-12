// Dart imports:
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Callback triggered after the collage has been rendered to PNG bytes.
typedef CollageMakerExportCallback = Future<void> Function(Uint8List bytes);

/// A ready-to-use collage maker with templates, frame controls, background
/// swatches, image ordering, and PNG export.
class CollageMaker extends StatefulWidget {
  /// Creates a [CollageMaker].
  const CollageMaker({
    super.key,
    required this.images,
    this.onAddImages,
    this.onClearImages,
    this.onRemoveImage,
    this.onMoveImage,
    this.onEditCollage,
    this.title = 'Collage Maker',
    this.showAppBar = true,
  });

  /// Images shown in the collage slots.
  final List<ImageProvider> images;

  /// Called when the add-images button is pressed.
  final VoidCallback? onAddImages;

  /// Called when the clear-images button is pressed.
  final VoidCallback? onClearImages;

  /// Called when an image thumbnail is removed.
  final ValueChanged<int>? onRemoveImage;

  /// Called when an image is moved from one index to another.
  final void Function(int from, int to)? onMoveImage;

  /// Called with rendered PNG bytes when the edit button is pressed.
  final CollageMakerExportCallback? onEditCollage;

  /// The app bar title when [showAppBar] is true.
  final String title;

  /// Whether this widget should render its own scaffold app bar.
  final bool showAppBar;

  @override
  State<CollageMaker> createState() => CollageMakerState();
}

/// State for [CollageMaker].
class CollageMakerState extends State<CollageMaker> {
  final _captureKey = GlobalKey();

  final _themes = const [
    _CollageTheme(
      name: 'Classic',
      icon: Icons.auto_awesome_mosaic_outlined,
      colors: [Color(0xFF101317), Color(0xFF1E293B)],
      accents: [Color(0xFF38BDF8), Color(0xFFF97316), Color(0xFFA3E635)],
    ),
    _CollageTheme(
      name: 'Wedding',
      icon: Icons.favorite_border,
      colors: [Color(0xFFFFF7ED), Color(0xFFFFE4E6)],
      accents: [Color(0xFFBE185D), Color(0xFFD97706), Color(0xFF7C2D12)],
    ),
    _CollageTheme(
      name: 'Birthday',
      icon: Icons.celebration_outlined,
      colors: [Color(0xFFFFD166), Color(0xFFEF476F), Color(0xFF118AB2)],
      accents: [Color(0xFF073B4C), Color(0xFF06D6A0), Color(0xFFFFFFFF)],
    ),
    _CollageTheme(
      name: 'Holiday',
      icon: Icons.card_giftcard_outlined,
      colors: [Color(0xFF064E3B), Color(0xFFB91C1C)],
      accents: [Color(0xFFFFFBEB), Color(0xFFFBBF24), Color(0xFF10B981)],
    ),
    _CollageTheme(
      name: 'Valentine',
      icon: Icons.favorite_outline,
      colors: [Color(0xFF831843), Color(0xFFF472B6), Color(0xFFFFE4E6)],
      accents: [Color(0xFFFFFFFF), Color(0xFFFB7185), Color(0xFFBE123C)],
    ),
    _CollageTheme(
      name: 'Travel',
      icon: Icons.flight_takeoff_outlined,
      colors: [Color(0xFF0F766E), Color(0xFFFDE68A), Color(0xFFF97316)],
      accents: [Color(0xFF134E4A), Color(0xFFECFEFF), Color(0xFF0284C7)],
    ),
    _CollageTheme(
      name: 'Graduation',
      icon: Icons.school_outlined,
      colors: [Color(0xFF111827), Color(0xFFF59E0B)],
      accents: [Color(0xFFFFFFFF), Color(0xFFFBBF24), Color(0xFF4B5563)],
    ),
    _CollageTheme(
      name: 'Baby',
      icon: Icons.child_care_outlined,
      colors: [Color(0xFFDBEAFE), Color(0xFFFCE7F3), Color(0xFFECFCCB)],
      accents: [Color(0xFF2563EB), Color(0xFFDB2777), Color(0xFF65A30D)],
    ),
    _CollageTheme(
      name: 'Festival',
      icon: Icons.light_mode_outlined,
      colors: [Color(0xFF581C87), Color(0xFFF97316), Color(0xFFFFD166)],
      accents: [Color(0xFFFFFFFF), Color(0xFF22C55E), Color(0xFFEC4899)],
    ),
    _CollageTheme(
      name: 'New Year',
      icon: Icons.nightlight_round,
      colors: [Color(0xFF020617), Color(0xFF334155), Color(0xFFFBBF24)],
      accents: [Color(0xFFFFFFFF), Color(0xFF38BDF8), Color(0xFFF59E0B)],
    ),
    _CollageTheme(
      name: 'Anniversary',
      icon: Icons.diamond_outlined,
      colors: [Color(0xFFFDF2F8), Color(0xFF7C3AED), Color(0xFFFBBF24)],
      accents: [Color(0xFFFFFFFF), Color(0xFFC026D3), Color(0xFFA16207)],
    ),
    _CollageTheme(
      name: 'Halloween',
      icon: Icons.dark_mode_outlined,
      colors: [Color(0xFF111827), Color(0xFFF97316), Color(0xFF581C87)],
      accents: [Color(0xFFFFFFFF), Color(0xFF84CC16), Color(0xFFFACC15)],
    ),
  ];

  late final List<CollageLayout> _layouts = _CollageTemplateCatalog.layouts;
  final List<_FreestyleLayer> _freestyleLayers = [];
  final Set<int> _removedFreestyleImageIndexes = {};

  int _layoutIndex = 2;
  int _slotFilter = 0;
  int _categoryFilterIndex = 0;
  int _backgroundIndex = 0;
  int _backgroundStyleIndex = 1;
  int _canvasPresetIndex = 0;
  int _frameStyleIndex = 0;
  int _borderColorIndex = 0;
  int _shadowStyleIndex = 1;
  int? _selectedFreestyleLayerIndex;
  double _gap = 10;
  double _radius = 24;
  double _padding = 16;
  double _borderWidth = 2;
  bool _isFreestyle = false;
  bool _isRendering = false;
  _FreestyleLayer? _gestureStartLayer;

  CollageLayout get _layout => _layouts[_layoutIndex];
  _CollageTheme get _theme => _themes[_backgroundIndex];
  _BackgroundStyle get _backgroundStyle =>
      _BackgroundStyle.styles[_backgroundStyleIndex];
  _CanvasPreset get _canvasPreset => _CanvasPreset.presets[_canvasPresetIndex];
  _PhotoFrameStyle get _frameStyle => _PhotoFrameStyle.styles[_frameStyleIndex];
  Color get _borderColor => _PhotoBorderPalette.colors[_borderColorIndex];
  _PhotoShadowStyle get _shadowStyle =>
      _PhotoShadowStyle.styles[_shadowStyleIndex];
  ImageProvider? get _backgroundImage {
    if (widget.images.isEmpty) return null;
    final selectedLayerIndex = _selectedFreestyleLayerIndex;
    if (_isFreestyle &&
        selectedLayerIndex != null &&
        selectedLayerIndex < _freestyleLayers.length) {
      return widget.images[_freestyleLayers[selectedLayerIndex].imageIndex];
    }
    return widget.images.first;
  }

  @override
  void initState() {
    super.initState();
    _syncFreestylePlacements();
  }

  @override
  void didUpdateWidget(covariant CollageMaker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.length != widget.images.length) {
      _syncFreestylePlacements();
    }
  }

  void _syncFreestylePlacements() {
    _removedFreestyleImageIndexes.removeWhere(
      (imageIndex) => imageIndex >= widget.images.length,
    );
    _freestyleLayers.removeWhere(
      (layer) => layer.imageIndex >= widget.images.length,
    );

    for (var imageIndex = 0; imageIndex < widget.images.length; imageIndex++) {
      final hasLayer = _freestyleLayers.any(
        (layer) => layer.imageIndex == imageIndex,
      );
      if (hasLayer || _removedFreestyleImageIndexes.contains(imageIndex)) {
        continue;
      }
      _freestyleLayers.add(
        _FreestyleLayer(
          imageIndex: imageIndex,
          placement: _defaultFreestylePlacement(
            _freestyleLayers.length,
            math.max(widget.images.length, 1),
          ),
        ),
      );
    }

    if (_selectedFreestyleLayerIndex != null &&
        _selectedFreestyleLayerIndex! >= _freestyleLayers.length) {
      _selectedFreestyleLayerIndex = _freestyleLayers.isEmpty ? null : 0;
    }
  }

  _FreestylePlacement _defaultFreestylePlacement(int index, int count) {
    final columns = count <= 4 ? 2 : 3;
    final rows = (count / columns).ceil();
    final width = count <= 2 ? 0.46 : (count <= 6 ? 0.34 : 0.29);
    final height = width * (index.isEven ? 0.82 : 1.08);
    final cellWidth = 1 / columns;
    final cellHeight = 1 / rows;
    final column = index % columns;
    final row = index ~/ columns;
    final staggerX = index.isEven ? 0.01 : -0.015;
    final staggerY = index % 3 == 0 ? -0.01 : 0.015;
    final left = (column * cellWidth + (cellWidth - width) / 2 + staggerX)
        .clamp(0.0, 1 - width)
        .toDouble();
    final top = (row * cellHeight + (cellHeight - height) / 2 + staggerY)
        .clamp(0.0, 1 - height)
        .toDouble();

    return _FreestylePlacement(
      left: left,
      top: top,
      width: width,
      height: height,
    );
  }

  void _resetFreestyle() {
    setState(() {
      _removedFreestyleImageIndexes.clear();
      _freestyleLayers
        ..clear()
        ..addAll(
          List.generate(
            widget.images.length,
            (index) => _FreestyleLayer(
              imageIndex: index,
              placement: _defaultFreestylePlacement(
                index,
                widget.images.length,
              ),
            ),
          ),
        );
      _selectedFreestyleLayerIndex = _freestyleLayers.isEmpty ? null : 0;
    });
  }

  void _moveSelectedFreestyleLayer(int delta) {
    final index = _selectedFreestyleLayerIndex;
    if (index == null) return;

    final to = index + delta;
    if (to < 0 || to >= _freestyleLayers.length) return;

    setState(() {
      final layer = _freestyleLayers.removeAt(index);
      _freestyleLayers.insert(to, layer);
      _selectedFreestyleLayerIndex = to;
    });
  }

  void _duplicateSelectedFreestyleLayer() {
    final index = _selectedFreestyleLayerIndex;
    if (index == null) return;

    final source = _freestyleLayers[index];
    final width = source.placement.width;
    final height = source.placement.height;
    final placement = source.placement.copyWith(
      left: (source.placement.left + 0.06).clamp(0.0, 1 - width).toDouble(),
      top: (source.placement.top + 0.06).clamp(0.0, 1 - height).toDouble(),
    );

    setState(() {
      _freestyleLayers.add(
        source.copyWith(placement: placement, locked: false),
      );
      _selectedFreestyleLayerIndex = _freestyleLayers.length - 1;
    });
  }

  void _removeSelectedFreestyleLayer() {
    final index = _selectedFreestyleLayerIndex;
    if (index == null) return;

    setState(() {
      final layer = _freestyleLayers.removeAt(index);
      final hasSibling = _freestyleLayers.any(
        (item) => item.imageIndex == layer.imageIndex,
      );
      if (!hasSibling) _removedFreestyleImageIndexes.add(layer.imageIndex);
      _selectedFreestyleLayerIndex = _freestyleLayers.isEmpty
          ? null
          : math.min(index, _freestyleLayers.length - 1);
    });
  }

  void _toggleSelectedFreestyleLock() {
    final index = _selectedFreestyleLayerIndex;
    if (index == null) return;

    setState(() {
      final layer = _freestyleLayers[index];
      _freestyleLayers[index] = layer.copyWith(locked: !layer.locked);
    });
  }

  void _rotateSelectedFreestyleLayer(double radians) {
    final index = _selectedFreestyleLayerIndex;
    if (index == null) return;

    setState(() {
      final layer = _freestyleLayers[index];
      _freestyleLayers[index] = layer.copyWith(
        rotation: layer.rotation + radians,
      );
    });
  }

  void _shuffleDesign() {
    final random = math.Random();
    final visibleLayouts = _filteredLayoutIndexes;
    final backgroundStyleChoices =
        List.generate(_BackgroundStyle.styles.length, (index) => index)
          ..removeWhere((index) {
            return _BackgroundStyle.styles[index].requiresImage &&
                widget.images.isEmpty;
          });

    setState(() {
      if (!_isFreestyle && visibleLayouts.isNotEmpty) {
        _layoutIndex = visibleLayouts[random.nextInt(visibleLayouts.length)];
      }

      _canvasPresetIndex = random.nextInt(_CanvasPreset.presets.length);
      _backgroundIndex = random.nextInt(_themes.length);
      _backgroundStyleIndex =
          backgroundStyleChoices[random.nextInt(backgroundStyleChoices.length)];
      _frameStyleIndex = random.nextInt(_PhotoFrameStyle.styles.length);
      _borderColorIndex = random.nextInt(_PhotoBorderPalette.colors.length);
      _shadowStyleIndex = random.nextInt(_PhotoShadowStyle.styles.length);

      _gap = 4 + random.nextDouble() * 18;
      _radius = random.nextDouble() * 36;
      _padding = 8 + random.nextDouble() * 26;
      _borderWidth = random.nextDouble() * 8;

      if (_isFreestyle && _freestyleLayers.isNotEmpty) {
        _shuffleFreestyleLayers(random);
      }
    });
  }

  void _shuffleFreestyleLayers(math.Random random) {
    for (var i = 0; i < _freestyleLayers.length; i++) {
      final layer = _freestyleLayers[i];
      final width = 0.24 + random.nextDouble() * 0.22;
      final height = width * (0.78 + random.nextDouble() * 0.5);
      final left = random.nextDouble() * (1 - width);
      final top = random.nextDouble() * (1 - height);
      final rotation = (random.nextDouble() - 0.5) * math.pi / 5;

      _freestyleLayers[i] = layer.copyWith(
        locked: false,
        rotation: rotation,
        placement: _FreestylePlacement(
          left: left,
          top: top,
          width: width,
          height: height,
        ),
      );
    }

    _freestyleLayers.shuffle(random);
    _selectedFreestyleLayerIndex = random.nextInt(_freestyleLayers.length);
  }

  /// Renders the visible collage to PNG bytes.
  Future<Uint8List?> exportPngBytes({double pixelRatio = 3}) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    final image = await boundary?.toImage(pixelRatio: pixelRatio);
    final byteData = await image?.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _editCollage() async {
    if (widget.images.isEmpty || widget.onEditCollage == null) return;

    setState(() => _isRendering = true);
    try {
      final bytes = await exportPngBytes();
      if (bytes == null) return;
      await widget.onEditCollage!(bytes);
    } finally {
      if (mounted) setState(() => _isRendering = false);
    }
  }

  void _moveImage(int from, int delta) {
    if (widget.onMoveImage == null) return;

    final to = from + delta;
    if (to < 0 || to >= widget.images.length) return;

    setState(() {
      for (var i = 0; i < _freestyleLayers.length; i++) {
        final layer = _freestyleLayers[i];
        var imageIndex = layer.imageIndex;
        if (imageIndex == from) {
          imageIndex = to;
        } else if (from < to && imageIndex > from && imageIndex <= to) {
          imageIndex--;
        } else if (from > to && imageIndex >= to && imageIndex < from) {
          imageIndex++;
        }
        _freestyleLayers[i] = layer.copyWith(imageIndex: imageIndex);
      }
      _remapRemovedFreestyleIndexes(from, to);
    });

    widget.onMoveImage?.call(from, to);
  }

  void _removeImage(int index) {
    if (widget.onRemoveImage == null) return;

    setState(() {
      _freestyleLayers.removeWhere((layer) => layer.imageIndex == index);
      for (var i = 0; i < _freestyleLayers.length; i++) {
        final layer = _freestyleLayers[i];
        if (layer.imageIndex > index) {
          _freestyleLayers[i] = layer.copyWith(
            imageIndex: layer.imageIndex - 1,
          );
        }
      }
      final removed = _removedFreestyleImageIndexes.toList();
      _removedFreestyleImageIndexes.clear();
      for (final imageIndex in removed) {
        if (imageIndex == index || imageIndex >= widget.images.length - 1) {
          continue;
        }
        _removedFreestyleImageIndexes.add(
          imageIndex > index ? imageIndex - 1 : imageIndex,
        );
      }
      if (_selectedFreestyleLayerIndex != null &&
          _selectedFreestyleLayerIndex! >= _freestyleLayers.length) {
        _selectedFreestyleLayerIndex = _freestyleLayers.isEmpty
            ? null
            : _freestyleLayers.length - 1;
      }
    });
    widget.onRemoveImage?.call(index);
  }

  void _clearImages() {
    if (widget.onClearImages == null) return;

    setState(() {
      _freestyleLayers.clear();
      _removedFreestyleImageIndexes.clear();
      _selectedFreestyleLayerIndex = null;
    });
    widget.onClearImages?.call();
  }

  void _remapRemovedFreestyleIndexes(int from, int to) {
    final indexes = _removedFreestyleImageIndexes.toList();
    _removedFreestyleImageIndexes.clear();
    for (final index in indexes) {
      if (index == from) {
        _removedFreestyleImageIndexes.add(to);
      } else if (from < to && index > from && index <= to) {
        _removedFreestyleImageIndexes.add(index - 1);
      } else if (from > to && index >= to && index < from) {
        _removedFreestyleImageIndexes.add(index + 1);
      } else {
        _removedFreestyleImageIndexes.add(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildPreview()),
                const VerticalDivider(width: 1),
                SizedBox(width: 360, child: _buildControls()),
              ],
            );
          }

          return Column(
            children: [
              Expanded(child: _buildPreview()),
              const Divider(height: 1),
              SizedBox(height: 310, child: _buildControls()),
            ],
          );
        },
      ),
    );

    if (!widget.showAppBar) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: widget.onAddImages,
            tooltip: 'Add images',
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilledButton.icon(
              onPressed: _isRendering || widget.images.isEmpty
                  ? null
                  : _editCollage,
              icon: _isRendering
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildPreview() {
    return ColoredBox(
      color: const Color(0xFF0D1117),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: RepaintBoundary(
            key: _captureKey,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _canvasPreset.maxPreviewWidth,
                maxHeight: _canvasPreset.maxPreviewHeight,
                minWidth: 280,
                minHeight: _canvasPreset.minPreviewHeight,
              ),
              child: AspectRatio(
                aspectRatio: _canvasPreset.aspectRatio,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 30,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _CanvasBackground(
                          theme: _theme,
                          style: _backgroundStyle,
                          image: _backgroundImage,
                        ),
                        Padding(
                          padding: EdgeInsets.all(_padding),
                          child: _isFreestyle
                              ? _buildFreestyleLayout()
                              : _buildLayout(_layout),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    final filteredLayoutIndexes = _filteredLayoutIndexes;
    final selectedFreestyleLayer =
        _selectedFreestyleLayerIndex == null ||
            _selectedFreestyleLayerIndex! >= _freestyleLayers.length
        ? null
        : _freestyleLayers[_selectedFreestyleLayerIndex!];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_mosaic_outlined),
            const SizedBox(width: 10),
            Text(
              _isFreestyle
                  ? 'Freestyle canvas'
                  : '${filteredLayoutIndexes.length} templates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.grid_view_outlined),
              label: Text('Templates'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.open_with_outlined),
              label: Text('Freestyle'),
            ),
          ],
          selected: {_isFreestyle},
          onSelectionChanged: (selection) {
            setState(() {
              _isFreestyle = selection.first;
              _selectedFreestyleLayerIndex =
                  _isFreestyle && _freestyleLayers.isNotEmpty
                  ? _selectedFreestyleLayerIndex ?? 0
                  : null;
              _syncFreestylePlacements();
            });
          },
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: _shuffleDesign,
            icon: const Icon(Icons.shuffle_outlined),
            label: const Text('Shuffle design'),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_CanvasPreset.presets.length, (index) {
            final preset = _CanvasPreset.presets[index];
            return ChoiceChip(
              selected: _canvasPresetIndex == index,
              avatar: Icon(preset.icon, size: 18),
              label: Text(preset.label),
              onSelected: (_) => setState(() => _canvasPresetIndex = index),
            );
          }),
        ),
        const SizedBox(height: 10),
        if (_isFreestyle) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.images.isEmpty ? null : _resetFreestyle,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Reset freestyle'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LayerActionButton(
                icon: Icons.flip_to_front_outlined,
                tooltip: 'Bring forward',
                onPressed:
                    _selectedFreestyleLayerIndex == null ||
                        _selectedFreestyleLayerIndex ==
                            _freestyleLayers.length - 1
                    ? null
                    : () => _moveSelectedFreestyleLayer(1),
              ),
              _LayerActionButton(
                icon: Icons.flip_to_back_outlined,
                tooltip: 'Send backward',
                onPressed:
                    _selectedFreestyleLayerIndex == null ||
                        _selectedFreestyleLayerIndex == 0
                    ? null
                    : () => _moveSelectedFreestyleLayer(-1),
              ),
              _LayerActionButton(
                icon: Icons.content_copy_outlined,
                tooltip: 'Duplicate',
                onPressed: selectedFreestyleLayer == null
                    ? null
                    : _duplicateSelectedFreestyleLayer,
              ),
              _LayerActionButton(
                icon: Icons.rotate_90_degrees_cw_outlined,
                tooltip: 'Rotate',
                onPressed: selectedFreestyleLayer == null
                    ? null
                    : () => _rotateSelectedFreestyleLayer(math.pi / 18),
              ),
              _LayerActionButton(
                icon: selectedFreestyleLayer?.locked == true
                    ? Icons.lock_outline
                    : Icons.lock_open_outlined,
                tooltip: selectedFreestyleLayer?.locked == true
                    ? 'Unlock'
                    : 'Lock',
                onPressed: selectedFreestyleLayer == null
                    ? null
                    : _toggleSelectedFreestyleLock,
              ),
              _LayerActionButton(
                icon: Icons.delete_outline,
                tooltip: 'Remove from canvas',
                onPressed: selectedFreestyleLayer == null
                    ? null
                    : _removeSelectedFreestyleLayer,
              ),
            ],
          ),
        ] else ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_TemplateCategory.categories.length, (
              index,
            ) {
              final category = _TemplateCategory.categories[index];
              return ChoiceChip(
                selected: _categoryFilterIndex == index,
                avatar: Icon(category.icon, size: 18),
                label: Text(category.label),
                onSelected: (_) => setState(() => _categoryFilterIndex = index),
              );
            }),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                selected: _slotFilter == 0,
                label: const Text('All'),
                onSelected: (_) => setState(() => _slotFilter = 0),
              ),
              for (final slotCount in _CollageTemplateCatalog.slotCounts)
                ChoiceChip(
                  selected: _slotFilter == slotCount,
                  label: Text('$slotCount photos'),
                  onSelected: (_) => setState(() => _slotFilter = slotCount),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 126,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filteredLayoutIndexes.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final layoutIndex = filteredLayoutIndexes[index];
                final layout = _layouts[layoutIndex];
                return _TemplateCard(
                  layout: layout,
                  selected: layoutIndex == _layoutIndex,
                  onTap: () => setState(() => _layoutIndex = layoutIndex),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onAddImages,
                icon: const Icon(Icons.collections_outlined),
                label: const Text('Images'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: widget.images.isEmpty || widget.onClearImages == null
                  ? null
                  : _clearImages,
              tooltip: 'Clear',
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ],
        ),
        if (widget.images.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                return _PhotoThumb(
                  image: widget.images[index],
                  canMoveBack: index > 0,
                  canMoveForward: index < widget.images.length - 1,
                  onBack: () => _moveImage(index, -1),
                  onForward: () => _moveImage(index, 1),
                  onRemove: () => _removeImage(index),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 18),
        _buildSlider(
          icon: Icons.space_bar_outlined,
          label: 'Gap',
          value: _gap,
          min: 0,
          max: 28,
          onChanged: (value) => setState(() => _gap = value),
        ),
        _buildSlider(
          icon: Icons.rounded_corner_outlined,
          label: 'Radius',
          value: _radius,
          min: 0,
          max: 46,
          onChanged: (value) => setState(() => _radius = value),
        ),
        _buildSlider(
          icon: Icons.padding_outlined,
          label: 'Frame',
          value: _padding,
          min: 0,
          max: 42,
          onChanged: (value) => setState(() => _padding = value),
        ),
        _buildSlider(
          icon: Icons.border_outer_outlined,
          label: 'Border',
          value: _borderWidth,
          min: 0,
          max: 16,
          onChanged: (value) => setState(() => _borderWidth = value),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_PhotoFrameStyle.styles.length, (index) {
            final style = _PhotoFrameStyle.styles[index];
            return ChoiceChip(
              selected: _frameStyleIndex == index,
              avatar: Icon(style.icon, size: 18),
              label: Text(style.label),
              onSelected: (_) => setState(() => _frameStyleIndex = index),
            );
          }),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_PhotoShadowStyle.styles.length, (index) {
            final style = _PhotoShadowStyle.styles[index];
            return ChoiceChip(
              selected: _shadowStyleIndex == index,
              avatar: Icon(style.icon, size: 18),
              label: Text(style.label),
              onSelected: (_) => setState(() => _shadowStyleIndex = index),
            );
          }),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_PhotoBorderPalette.colors.length, (index) {
            final selected = _borderColorIndex == index;
            return Tooltip(
              message: 'Photo border',
              child: InkWell(
                onTap: () => setState(() => _borderColorIndex = index),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _PhotoBorderPalette.colors[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.white : Colors.white24,
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_BackgroundStyle.styles.length, (index) {
            final style = _BackgroundStyle.styles[index];
            return ChoiceChip(
              selected: _backgroundStyleIndex == index,
              avatar: Icon(style.icon, size: 18),
              label: Text(style.label),
              onSelected: style.requiresImage && widget.images.isEmpty
                  ? null
                  : (_) => setState(() => _backgroundStyleIndex = index),
            );
          }),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_themes.length, (index) {
            final selected = index == _backgroundIndex;
            final theme = _themes[index];
            return ChoiceChip(
              selected: selected,
              avatar: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: theme.colors),
                ),
                child: Icon(
                  theme.icon,
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.white,
                  size: 16,
                ),
              ),
              label: Text(theme.name),
              onSelected: (_) => setState(() => _backgroundIndex = index),
            );
          }),
        ),
      ],
    );
  }

  List<int> get _filteredLayoutIndexes {
    final category = _TemplateCategory.categories[_categoryFilterIndex];
    final indexes = <int>[];
    for (var i = 0; i < _layouts.length; i++) {
      final layout = _layouts[i];
      final matchesCategory = category.matches(layout);
      final matchesSlot = _slotFilter == 0 || layout.slotCount == _slotFilter;
      if (matchesCategory && matchesSlot) indexes.add(i);
    }
    return indexes;
  }

  Widget _buildSlider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        SizedBox(width: 58, child: Text(label)),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildFreestyleLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            _OccasionFrame(theme: _theme),
            if (_freestyleLayers.isEmpty) const _EmptySlot(index: 1),
            ...List.generate(_freestyleLayers.length, (index) {
              final layer = _freestyleLayers[index];
              final placement = layer.placement;
              final selected = index == _selectedFreestyleLayerIndex;

              return Positioned(
                left: placement.left * width,
                top: placement.top * height,
                width: placement.width * width,
                height: placement.height * height,
                child: Transform.rotate(
                  angle: layer.rotation,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedFreestyleLayerIndex = index);
                    },
                    onScaleStart: layer.locked
                        ? null
                        : (_) {
                            _gestureStartLayer = _freestyleLayers[index];
                            setState(
                              () => _selectedFreestyleLayerIndex = index,
                            );
                          },
                    onScaleUpdate: layer.locked
                        ? null
                        : (details) {
                            final start =
                                _gestureStartLayer ?? _freestyleLayers[index];
                            final current = _freestyleLayers[index];
                            final nextWidth =
                                (start.placement.width * details.scale)
                                    .clamp(0.18, 0.92)
                                    .toDouble();
                            final nextHeight =
                                (start.placement.height * details.scale)
                                    .clamp(0.16, 0.92)
                                    .toDouble();
                            final nextLeft =
                                (current.placement.left +
                                        details.focalPointDelta.dx / width)
                                    .clamp(0.0, 1 - nextWidth)
                                    .toDouble();
                            final nextTop =
                                (current.placement.top +
                                        details.focalPointDelta.dy / height)
                                    .clamp(0.0, 1 - nextHeight)
                                    .toDouble();

                            setState(() {
                              _freestyleLayers[index] = current.copyWith(
                                placement: _FreestylePlacement(
                                  left: nextLeft,
                                  top: nextTop,
                                  width: nextWidth,
                                  height: nextHeight,
                                ),
                              );
                            });
                          },
                    onScaleEnd: layer.locked
                        ? null
                        : (_) => _gestureStartLayer = null,
                    child: _FreestylePhoto(
                      image: widget.images[layer.imageIndex],
                      selected: selected,
                      locked: layer.locked,
                      radius: _radius,
                      borderColor: _borderColor,
                      borderWidth: _borderWidth,
                      frameStyle: _frameStyle,
                      shadowStyle: _shadowStyle,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildLayout(CollageLayout layout) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            _OccasionFrame(theme: _theme),
            ...List.generate(layout.slots.length, (index) {
              final slot = layout.slots[index];
              return Positioned(
                left: slot.left * width,
                top: slot.top * height,
                width: slot.width * width,
                height: slot.height * height,
                child: Padding(
                  padding: EdgeInsets.all(_gap / 2),
                  child: _slot(index),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _slot(int index) {
    return _FramedPhoto(
      radius: _radius,
      borderColor: _borderColor,
      borderWidth: _borderWidth,
      frameStyle: _frameStyle,
      shadowStyle: _shadowStyle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_frameStyle.contentRadius(_radius)),
        child: index < widget.images.length
            ? Image(
                image: widget.images[index],
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              )
            : _EmptySlot(index: index + 1),
      ),
    );
  }
}

class _FreestylePhoto extends StatelessWidget {
  const _FreestylePhoto({
    required this.image,
    required this.selected,
    required this.locked,
    required this.radius,
    required this.borderColor,
    required this.borderWidth,
    required this.frameStyle,
    required this.shadowStyle,
  });

  final ImageProvider image;
  final bool selected;
  final bool locked;
  final double radius;
  final Color borderColor;
  final double borderWidth;
  final _PhotoFrameStyle frameStyle;
  final _PhotoShadowStyle shadowStyle;

  @override
  Widget build(BuildContext context) {
    return _FramedPhoto(
      radius: radius,
      borderColor: borderColor,
      borderWidth: borderWidth,
      frameStyle: frameStyle,
      shadowStyle: shadowStyle,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(
              frameStyle.contentRadius(radius),
            ),
            child: Image(
              image: image,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                frameStyle.contentRadius(radius),
              ),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: selected ? 3 : 0,
              ),
            ),
          ),
          if (selected)
            Positioned(
              right: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.open_with_outlined,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 18,
                ),
              ),
            ),
          if (locked)
            Positioned(
              left: 8,
              top: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(145),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FramedPhoto extends StatelessWidget {
  const _FramedPhoto({
    required this.child,
    required this.radius,
    required this.borderColor,
    required this.borderWidth,
    required this.frameStyle,
    required this.shadowStyle,
  });

  final Widget child;
  final double radius;
  final Color borderColor;
  final double borderWidth;
  final _PhotoFrameStyle frameStyle;
  final _PhotoShadowStyle shadowStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderWidth = frameStyle.borderWidth(borderWidth);
    final padding = frameStyle.padding(borderWidth);
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        padding,
        padding,
        padding,
        padding + frameStyle.bottomExtra,
      ),
      child: child,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: frameStyle.backgroundColor(borderColor),
        borderRadius: BorderRadius.circular(frameStyle.outerRadius(radius)),
        border: Border.all(color: borderColor, width: effectiveBorderWidth),
        boxShadow: shadowStyle.shadows,
      ),
      child: content,
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.image,
    required this.canMoveBack,
    required this.canMoveForward,
    required this.onBack,
    required this.onForward,
    required this.onRemove,
  });

  final ImageProvider image;
  final bool canMoveBack;
  final bool canMoveForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
              image: image,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: _TinyIconButton(
              icon: Icons.close,
              tooltip: 'Remove',
              onPressed: onRemove,
            ),
          ),
          Positioned(
            left: 4,
            bottom: 4,
            child: _TinyIconButton(
              icon: Icons.chevron_left,
              tooltip: 'Move left',
              onPressed: canMoveBack ? onBack : null,
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: _TinyIconButton(
              icon: Icons.chevron_right,
              tooltip: 'Move right',
              onPressed: canMoveForward ? onForward : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.layout,
    required this.selected,
    required this.onTap,
  });

  final CollageLayout layout;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: layout.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 96,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withAlpha(26),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(child: _TemplatePreview(layout: layout)),
              const SizedBox(height: 6),
              Text(
                layout.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplatePreview extends StatelessWidget {
  const _TemplatePreview({required this.layout});

  final CollageLayout layout;

  @override
  Widget build(BuildContext context) {
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.secondary,
      const Color(0xFFFFD166),
      const Color(0xFF70C1B3),
      const Color(0xFFEF476F),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(42),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: List.generate(layout.slots.length, (index) {
                final slot = layout.slots[index];
                return Positioned(
                  left: slot.left * constraints.maxWidth,
                  top: slot.top * constraints.maxHeight,
                  width: slot.width * constraints.maxWidth,
                  height: slot.height * constraints.maxHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _TinyIconButton extends StatelessWidget {
  const _TinyIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    );
  }
}

class _LayerActionButton extends StatelessWidget {
  const _LayerActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(onPressed: onPressed, icon: Icon(icon)),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: Colors.white.withAlpha(180),
            size: 34,
          ),
          const SizedBox(height: 6),
          Text(
            '$index',
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OccasionFrame extends StatelessWidget {
  const _OccasionFrame({required this.theme});

  final _CollageTheme theme;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(38)),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 12,
                top: 12,
                child: Icon(theme.icon, color: Colors.white.withAlpha(120)),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Icon(theme.icon, color: Colors.white.withAlpha(105)),
              ),
              Positioned(
                right: -24,
                top: -24,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.accents.first.withAlpha(44),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(dimension: 96),
                ),
              ),
              Positioned(
                left: -18,
                bottom: -18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.accents.last.withAlpha(36),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(dimension: 72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollageTheme {
  const _CollageTheme({
    required this.name,
    required this.icon,
    required this.colors,
    required this.accents,
  });

  final String name;
  final IconData icon;
  final List<Color> colors;
  final List<Color> accents;
}

class _CanvasBackground extends StatelessWidget {
  const _CanvasBackground({
    required this.theme,
    required this.style,
    required this.image,
  });

  final _CollageTheme theme;
  final _BackgroundStyle style;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    return switch (style.kind) {
      _BackgroundKind.solid => ColoredBox(color: theme.colors.first),
      _BackgroundKind.gradient => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.colors,
          ),
        ),
      ),
      _BackgroundKind.pattern => Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.colors,
              ),
            ),
          ),
          CustomPaint(
            painter: _BackgroundPatternPainter(
              primary: theme.accents.first,
              secondary: theme.accents.last,
            ),
          ),
        ],
      ),
      _BackgroundKind.blurImage =>
        image == null
            ? DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: theme.colors,
                  ),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Image(
                      image: image!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colors.first.withAlpha(112),
                          theme.colors.last.withAlpha(150),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    };
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  const _BackgroundPatternPainter({
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = primary.withAlpha(42)
      ..strokeWidth = 2;
    for (var offset = -size.height; offset < size.width; offset += 28) {
      canvas.drawLine(
        Offset(offset, size.height),
        Offset(offset + size.height, 0),
        linePaint,
      );
    }

    final dotPaint = Paint()..color = secondary.withAlpha(54);
    for (var y = 18.0; y < size.height; y += 42) {
      for (var x = 18.0; x < size.width; x += 42) {
        canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPatternPainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.secondary != secondary;
  }
}

enum _BackgroundKind { solid, gradient, pattern, blurImage }

class _BackgroundStyle {
  const _BackgroundStyle({
    required this.label,
    required this.icon,
    required this.kind,
    this.requiresImage = false,
  });

  static const styles = [
    _BackgroundStyle(
      label: 'Solid',
      icon: Icons.format_color_fill_outlined,
      kind: _BackgroundKind.solid,
    ),
    _BackgroundStyle(
      label: 'Gradient',
      icon: Icons.gradient_outlined,
      kind: _BackgroundKind.gradient,
    ),
    _BackgroundStyle(
      label: 'Pattern',
      icon: Icons.grid_4x4_outlined,
      kind: _BackgroundKind.pattern,
    ),
    _BackgroundStyle(
      label: 'Blur',
      icon: Icons.blur_on_outlined,
      kind: _BackgroundKind.blurImage,
      requiresImage: true,
    ),
  ];

  final String label;
  final IconData icon;
  final _BackgroundKind kind;
  final bool requiresImage;
}

class _CanvasPreset {
  const _CanvasPreset({
    required this.label,
    required this.icon,
    required this.width,
    required this.height,
  });

  static const presets = [
    _CanvasPreset(
      label: 'Square',
      icon: Icons.crop_square_outlined,
      width: 1,
      height: 1,
    ),
    _CanvasPreset(
      label: 'Story',
      icon: Icons.stay_current_portrait_outlined,
      width: 9,
      height: 16,
    ),
    _CanvasPreset(
      label: 'Portrait',
      icon: Icons.crop_portrait_outlined,
      width: 4,
      height: 5,
    ),
    _CanvasPreset(
      label: 'Landscape',
      icon: Icons.crop_landscape_outlined,
      width: 16,
      height: 9,
    ),
    _CanvasPreset(
      label: 'Wallpaper',
      icon: Icons.wallpaper_outlined,
      width: 9,
      height: 19.5,
    ),
  ];

  final String label;
  final IconData icon;
  final double width;
  final double height;

  double get aspectRatio => width / height;
  double get maxPreviewWidth => aspectRatio >= 1 ? 680 : 680 * aspectRatio;
  double get maxPreviewHeight => aspectRatio >= 1 ? 680 / aspectRatio : 680;
  double get minPreviewHeight => 280 / aspectRatio;
}

class _TemplateCategory {
  const _TemplateCategory({
    required this.label,
    required this.icon,
    required this.prefixes,
  });

  static const categories = [
    _TemplateCategory(label: 'All', icon: Icons.apps_outlined, prefixes: []),
    _TemplateCategory(
      label: 'Classic',
      icon: Icons.grid_view_outlined,
      prefixes: ['Duo', 'Story', 'Feature', 'Grid', 'Mosaic', 'Gallery'],
    ),
    _TemplateCategory(
      label: 'Wedding',
      icon: Icons.favorite_border,
      prefixes: ['Wedding', 'Anniversary', 'Valentine'],
    ),
    _TemplateCategory(
      label: 'Birthday',
      icon: Icons.celebration_outlined,
      prefixes: ['Birthday', 'Baby'],
    ),
    _TemplateCategory(
      label: 'Travel',
      icon: Icons.flight_takeoff_outlined,
      prefixes: ['Travel'],
    ),
    _TemplateCategory(
      label: 'Festival',
      icon: Icons.light_mode_outlined,
      prefixes: ['Festival', 'Holiday', 'New Year', 'Halloween'],
    ),
    _TemplateCategory(
      label: 'Graduation',
      icon: Icons.school_outlined,
      prefixes: ['Graduation'],
    ),
  ];

  final String label;
  final IconData icon;
  final List<String> prefixes;

  bool matches(CollageLayout layout) {
    if (prefixes.isEmpty) return true;
    return prefixes.any(layout.label.startsWith);
  }
}

class _PhotoFrameStyle {
  const _PhotoFrameStyle({
    required this.label,
    required this.icon,
    required this.extraPadding,
    required this.bottomExtra,
    required this.forceBorderWidth,
    this.forceWhiteBackground = false,
  });

  static const styles = [
    _PhotoFrameStyle(
      label: 'Clean',
      icon: Icons.crop_square_outlined,
      extraPadding: 0,
      bottomExtra: 0,
      forceBorderWidth: null,
    ),
    _PhotoFrameStyle(
      label: 'Border',
      icon: Icons.border_outer_outlined,
      extraPadding: 2,
      bottomExtra: 0,
      forceBorderWidth: null,
    ),
    _PhotoFrameStyle(
      label: 'Polaroid',
      icon: Icons.photo_size_select_actual_outlined,
      extraPadding: 8,
      bottomExtra: 16,
      forceBorderWidth: 0,
      forceWhiteBackground: true,
    ),
  ];

  final String label;
  final IconData icon;
  final double extraPadding;
  final double bottomExtra;
  final double? forceBorderWidth;
  final bool forceWhiteBackground;

  double padding(double borderWidth) => extraPadding + borderWidth / 2;
  double borderWidth(double borderWidth) => forceBorderWidth ?? borderWidth;
  double outerRadius(double radius) => radius + extraPadding;
  double contentRadius(double radius) => math.max(0, radius - extraPadding / 2);

  Color backgroundColor(Color borderColor) {
    if (forceWhiteBackground) return const Color(0xFFFFFBF5);
    if (borderColor == const Color(0x00000000)) return Colors.transparent;
    return borderColor.withAlpha(210);
  }
}

class _PhotoShadowStyle {
  const _PhotoShadowStyle({
    required this.label,
    required this.icon,
    required this.shadows,
  });

  static const styles = [
    _PhotoShadowStyle(
      label: 'Flat',
      icon: Icons.crop_din_outlined,
      shadows: [],
    ),
    _PhotoShadowStyle(
      label: 'Soft',
      icon: Icons.blur_on_outlined,
      shadows: [
        BoxShadow(
          color: Color(0x4D000000),
          blurRadius: 14,
          offset: Offset(0, 7),
        ),
      ],
    ),
    _PhotoShadowStyle(
      label: 'Deep',
      icon: Icons.layers_outlined,
      shadows: [
        BoxShadow(
          color: Color(0x73000000),
          blurRadius: 24,
          offset: Offset(0, 14),
        ),
      ],
    ),
  ];

  final String label;
  final IconData icon;
  final List<BoxShadow> shadows;
}

class _PhotoBorderPalette {
  const _PhotoBorderPalette._();

  static const colors = [
    Color(0xFFFFFFFF),
    Color(0xFF111827),
    Color(0xFFFFD166),
    Color(0xFFEF476F),
    Color(0xFF70C1B3),
    Color(0xFF7C3AED),
    Color(0xFFF97316),
    Color(0x00000000),
  ];
}

class _FreestylePlacement {
  const _FreestylePlacement({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  _FreestylePlacement copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
  }) {
    return _FreestylePlacement(
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

class _FreestyleLayer {
  const _FreestyleLayer({
    required this.imageIndex,
    required this.placement,
    this.rotation = 0,
    this.locked = false,
  });

  final int imageIndex;
  final _FreestylePlacement placement;
  final double rotation;
  final bool locked;

  _FreestyleLayer copyWith({
    int? imageIndex,
    _FreestylePlacement? placement,
    double? rotation,
    bool? locked,
  }) {
    return _FreestyleLayer(
      imageIndex: imageIndex ?? this.imageIndex,
      placement: placement ?? this.placement,
      rotation: rotation ?? this.rotation,
      locked: locked ?? this.locked,
    );
  }
}

/// Metadata for a collage template.
class CollageLayout {
  /// Creates a [CollageLayout].
  const CollageLayout({required this.label, required this.slots});

  /// Display label.
  final String label;

  /// Display icon.
  IconData get icon {
    return switch (slotCount) {
      2 => Icons.view_column_outlined,
      3 => Icons.dashboard_outlined,
      4 => Icons.grid_view_outlined,
      5 => Icons.auto_awesome_mosaic_outlined,
      _ => Icons.apps_outlined,
    };
  }

  /// Rectangles that describe where images are placed in the collage.
  final List<CollageSlot> slots;

  /// Number of photos this template is designed for.
  int get slotCount => slots.length;
}

/// A normalized collage slot rectangle.
class CollageSlot {
  /// Creates a [CollageSlot].
  const CollageSlot({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Creates a slot from a 12 by 12 design grid.
  const CollageSlot.grid({
    required int left,
    required int top,
    required int width,
    required int height,
  }) : left = left / 12,
       top = top / 12,
       width = width / 12,
       height = height / 12;

  /// Normalized left offset.
  final double left;

  /// Normalized top offset.
  final double top;

  /// Normalized width.
  final double width;

  /// Normalized height.
  final double height;

  String get _key {
    return '${(left * 1000).round()},'
        '${(top * 1000).round()},'
        '${(width * 1000).round()},'
        '${(height * 1000).round()}';
  }
}

class _CollageTemplateCatalog {
  static final List<CollageLayout> layouts = _buildLayouts();

  static const _occasionNames = [
    'Birthday',
    'Wedding',
    'Festival',
    'Holiday',
    'Travel',
    'Graduation',
    'Anniversary',
    'Valentine',
    'Baby',
    'New Year',
  ];

  static List<int> get slotCounts {
    final counts = layouts.map((layout) => layout.slotCount).toSet().toList()
      ..sort();
    return counts;
  }

  static List<CollageSlot> _gridFromCuts({
    required List<int> xCuts,
    required List<int> yCuts,
  }) {
    final xLines = [0, ...xCuts, 12];
    final yLines = [0, ...yCuts, 12];
    final slots = <CollageSlot>[];

    for (var y = 0; y < yLines.length - 1; y++) {
      for (var x = 0; x < xLines.length - 1; x++) {
        slots.add(
          CollageSlot.grid(
            left: xLines[x],
            top: yLines[y],
            width: xLines[x + 1] - xLines[x],
            height: yLines[y + 1] - yLines[y],
          ),
        );
      }
    }

    return slots;
  }

  static List<CollageLayout> _buildLayouts() {
    final layouts = <CollageLayout>[];
    final seen = <String>{};

    void add(String name, List<CollageSlot> slots) {
      final key = slots.map((slot) => slot._key).join('|');
      if (!seen.add(key)) return;

      final count = layouts.where((layout) => layout.slotCount == slots.length);
      final number = count.length + 1;
      layouts.add(
        CollageLayout(
          label: '$name ${number.toString().padLeft(2, '0')}',
          slots: slots,
        ),
      );
    }

    for (final split in [4, 5, 6, 7, 8]) {
      add('Duo', [
        CollageSlot.grid(left: 0, top: 0, width: split, height: 12),
        CollageSlot.grid(left: split, top: 0, width: 12 - split, height: 12),
      ]);
      add('Duo', [
        CollageSlot.grid(left: 0, top: 0, width: 12, height: split),
        CollageSlot.grid(left: 0, top: split, width: 12, height: 12 - split),
      ]);
    }

    for (final hero in [5, 6, 7, 8]) {
      for (final split in [4, 5, 6, 7, 8]) {
        add('Story', [
          CollageSlot.grid(left: 0, top: 0, width: hero, height: 12),
          CollageSlot.grid(left: hero, top: 0, width: 12 - hero, height: split),
          CollageSlot.grid(
            left: hero,
            top: split,
            width: 12 - hero,
            height: 12 - split,
          ),
        ]);
        add('Story', [
          CollageSlot.grid(left: 12 - hero, top: 0, width: hero, height: 12),
          CollageSlot.grid(left: 0, top: 0, width: 12 - hero, height: split),
          CollageSlot.grid(
            left: 0,
            top: split,
            width: 12 - hero,
            height: 12 - split,
          ),
        ]);
        add('Feature', [
          CollageSlot.grid(left: 0, top: 0, width: 12, height: hero),
          CollageSlot.grid(left: 0, top: hero, width: split, height: 12 - hero),
          CollageSlot.grid(
            left: split,
            top: hero,
            width: 12 - split,
            height: 12 - hero,
          ),
        ]);
        add('Feature', [
          CollageSlot.grid(left: 0, top: 12 - hero, width: 12, height: hero),
          CollageSlot.grid(left: 0, top: 0, width: split, height: 12 - hero),
          CollageSlot.grid(
            left: split,
            top: 0,
            width: 12 - split,
            height: 12 - hero,
          ),
        ]);
      }
    }

    for (final splitX in [4, 5, 6, 7, 8]) {
      for (final splitLeft in [4, 5, 6, 7, 8]) {
        for (final splitRight in [4, 5, 6, 7, 8]) {
          add('Grid', [
            CollageSlot.grid(left: 0, top: 0, width: splitX, height: splitLeft),
            CollageSlot.grid(
              left: 0,
              top: splitLeft,
              width: splitX,
              height: 12 - splitLeft,
            ),
            CollageSlot.grid(
              left: splitX,
              top: 0,
              width: 12 - splitX,
              height: splitRight,
            ),
            CollageSlot.grid(
              left: splitX,
              top: splitRight,
              width: 12 - splitX,
              height: 12 - splitRight,
            ),
          ]);
        }
      }
    }

    for (final hero in [5, 6, 7]) {
      for (final splitX in [4, 5, 6, 7, 8]) {
        if (hero + splitX >= 12) continue;
        for (final splitY in [5, 6, 7]) {
          add('Mosaic', [
            CollageSlot.grid(left: 0, top: 0, width: hero, height: 12),
            CollageSlot.grid(left: hero, top: 0, width: splitX, height: splitY),
            CollageSlot.grid(
              left: hero + splitX,
              top: 0,
              width: 12 - hero - splitX,
              height: splitY,
            ),
            CollageSlot.grid(
              left: hero,
              top: splitY,
              width: splitX,
              height: 12 - splitY,
            ),
            CollageSlot.grid(
              left: hero + splitX,
              top: splitY,
              width: 12 - hero - splitX,
              height: 12 - splitY,
            ),
          ]);
        }
      }
    }

    for (final splitY in [4, 5, 6, 7, 8]) {
      for (final splitX1 in [3, 4, 5]) {
        for (final splitX2 in [7, 8, 9]) {
          add('Gallery', [
            CollageSlot.grid(left: 0, top: 0, width: splitX1, height: splitY),
            CollageSlot.grid(
              left: splitX1,
              top: 0,
              width: splitX2 - splitX1,
              height: splitY,
            ),
            CollageSlot.grid(
              left: splitX2,
              top: 0,
              width: 12 - splitX2,
              height: splitY,
            ),
            CollageSlot.grid(
              left: 0,
              top: splitY,
              width: splitX1,
              height: 12 - splitY,
            ),
            CollageSlot.grid(
              left: splitX1,
              top: splitY,
              width: splitX2 - splitX1,
              height: 12 - splitY,
            ),
            CollageSlot.grid(
              left: splitX2,
              top: splitY,
              width: 12 - splitX2,
              height: 12 - splitY,
            ),
          ]);
        }
      }
    }

    var occasionIndex = 0;
    for (final x1 in [3, 4, 5]) {
      for (final x2 in [7, 8, 9]) {
        for (final y1 in [3, 4, 5]) {
          for (final y2 in [7, 8, 9]) {
            add(
              _occasionNames[occasionIndex % _occasionNames.length],
              _gridFromCuts(xCuts: [x1, x2], yCuts: [y1, y2]),
            );
            occasionIndex++;
          }
        }
      }
    }

    for (final xCuts in [
      [2, 5, 8],
      [2, 5, 9],
      [2, 6, 9],
      [3, 5, 8],
      [3, 5, 9],
      [3, 6, 9],
      [3, 7, 10],
      [4, 6, 9],
      [4, 7, 10],
      [5, 7, 10],
    ]) {
      for (final yCuts in [
        [3, 7],
        [4, 8],
      ]) {
        if (occasionIndex >= 100) break;
        add(
          _occasionNames[occasionIndex % _occasionNames.length],
          _gridFromCuts(xCuts: xCuts, yCuts: yCuts),
        );
        occasionIndex++;
      }
      if (occasionIndex >= 100) break;
    }

    return layouts;
  }
}
