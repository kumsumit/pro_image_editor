// Dart imports:
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

  final _backgrounds = const [
    Color(0xFF101317),
    Color(0xFFF7F3EA),
    Color(0xFFFFD166),
    Color(0xFF70C1B3),
    Color(0xFFEF476F),
    Color(0xFF5B5F97),
  ];

  late final List<CollageLayout> _layouts = _CollageTemplateCatalog.layouts;

  int _layoutIndex = 2;
  int _slotFilter = 0;
  int _backgroundIndex = 0;
  double _gap = 10;
  double _radius = 24;
  double _padding = 16;
  bool _isRendering = false;

  CollageLayout get _layout => _layouts[_layoutIndex];

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
    final to = from + delta;
    if (to < 0 || to >= widget.images.length) return;
    widget.onMoveImage?.call(from, to);
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
            child: AspectRatio(
              aspectRatio: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 680,
                  maxHeight: 680,
                  minWidth: 280,
                  minHeight: 280,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _backgrounds[_backgroundIndex],
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 30,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(_padding),
                    child: _buildLayout(_layout),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_mosaic_outlined),
            const SizedBox(width: 10),
            Text(
              '${_layouts.length} templates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 10),
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
              onPressed: widget.images.isEmpty ? null : widget.onClearImages,
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
                  onRemove: () => widget.onRemoveImage?.call(index),
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_backgrounds.length, (index) {
            final selected = index == _backgroundIndex;
            return Tooltip(
              message: 'Background',
              child: InkWell(
                onTap: () => setState(() => _backgroundIndex = index),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _backgrounds[index],
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
      ],
    );
  }

  List<int> get _filteredLayoutIndexes {
    final indexes = <int>[];
    for (var i = 0; i < _layouts.length; i++) {
      if (_slotFilter == 0 || _layouts[i].slotCount == _slotFilter) {
        indexes.add(i);
      }
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

  Widget _buildLayout(CollageLayout layout) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: List.generate(layout.slots.length, (index) {
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
        );
      },
    );
  }

  Widget _slot(int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(24),
          border: Border.all(color: Colors.white.withAlpha(28)),
        ),
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

  static List<int> get slotCounts {
    final counts = layouts.map((layout) => layout.slotCount).toSet().toList()
      ..sort();
    return counts;
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

    return layouts;
  }
}
