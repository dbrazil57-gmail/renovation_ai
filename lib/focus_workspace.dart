import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import 'app_appearance.dart';
import 'workspace_layout.dart';

enum FocusSection { room, style, refine, ideas }

/// Keeps all control groups mounted so switching tabs cannot discard drafts,
/// a running paid request, or a received result waiting for a local save.
class FocusWorkspace extends StatefulWidget {
  final FocusSection selected;
  final ValueChanged<FocusSection> onSelected;
  final Widget Function(double height) imageBuilder;
  final List<Widget> imageTools;
  final List<Widget> thumbnails;
  final Map<FocusSection, List<Widget>> sections;
  final Widget footer;
  final int revealRevision;
  final WorkspaceLayout initialLayout;
  final ValueChanged<WorkspaceLayout>? onLayoutChanged;
  const FocusWorkspace({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.imageBuilder,
    required this.imageTools,
    required this.thumbnails,
    required this.sections,
    required this.footer,
    this.revealRevision = 0,
    this.initialLayout = const WorkspaceLayout(),
    this.onLayoutChanged,
  });

  @override
  State<FocusWorkspace> createState() => _FocusWorkspaceState();
}

class _FocusWorkspaceState extends State<FocusWorkspace> {
  final scroll = ScrollController();
  final offsets = <FocusSection, double>{};
  late WorkspaceLayout layout = widget.initialLayout;
  double? dragExtent;

  void resizeImage(
    double extent, {
    required bool wide,
    required double available,
    required double minimum,
    required double maximum,
  }) {
    if (available <= 0 || maximum <= minimum) return;
    setState(
      () => layout = layout.resize(
        extent.clamp(minimum, maximum) / available,
        wide: wide,
      ),
    );
  }

  @override
  void didUpdateWidget(FocusWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reveal = oldWidget.revealRevision != widget.revealRevision;
    if (oldWidget.selected != widget.selected || reveal) {
      if (scroll.hasClients) offsets[oldWidget.selected] = scroll.offset;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scroll.hasClients) {
          scroll.jumpTo(
            (reveal ? 0.0 : offsets[widget.selected] ?? 0).clamp(
              0.0,
              scroll.position.maxScrollExtent,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Widget canvas({required bool compact}) => ColoredBox(
    color: AppAppearance.of(context).canvas,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, bounds) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.imageBuilder(bounds.maxHeight),
              ),
            ),
          ),
          const SizedBox(height: 4),
          IconTheme(
            data: const IconThemeData(color: Colors.white),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.imageTools,
              ),
            ),
          ),
          if (!compact && widget.thumbnails.isNotEmpty)
            SizedBox(
              height: 60 + MediaQuery.textScalerOf(context).scale(12) * 2.6,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: widget.thumbnails),
              ),
            ),
        ],
      ),
    ),
  );

  Widget controls(BuildContext context) => Material(
    color: AppAppearance.of(context).paper,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            children: [
              for (final section in FocusSection.values)
                Expanded(
                  child: Semantics(
                    selected: section == widget.selected,
                    child: TextButton(
                      key: ValueKey('focus-section-${section.name}'),
                      style: TextButton.styleFrom(
                        foregroundColor: section == widget.selected
                            ? Colors.white
                            : AppAppearance.of(context).ink,
                        backgroundColor: section == widget.selected
                            ? AppAppearance.of(context).accent
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 8,
                        ),
                        minimumSize: const Size(44, 44),
                      ),
                      onPressed: () => widget.onSelected(section),
                      child: Text(switch (section) {
                        FocusSection.room => 'Room',
                        FocusSection.style => 'Style',
                        FocusSection.refine => 'Refine',
                        FocusSection.ideas => 'Ideas',
                      }),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('focus-controls-scroll'),
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final section in FocusSection.values)
                  Offstage(
                    offstage: widget.selected != section,
                    child: TickerMode(
                      enabled: widget.selected == section,
                      child: Column(
                        key: ValueKey('focus-content-${section.name}'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: widget.sections[section] ?? [],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: widget.footer,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final desktop = bounds.maxWidth >= 900 && bounds.maxHeight >= 420;
      final panel = controls(context);
      final handleSize = desktop ? 24.0 : 28.0;
      final available =
          ((desktop ? bounds.maxWidth : bounds.maxHeight) - handleSize).clamp(
            0.0,
            double.infinity,
          );
      final minimumControls = desktop
          ? 320 + MediaQuery.textScalerOf(context).scale(14) * 2
          : 100 + MediaQuery.textScalerOf(context).scale(14) * 3;
      // With the keyboard open, give the controls priority. Do not overwrite
      // the saved split when the viewport temporarily becomes smaller.
      final minimumImage = desktop
          ? 240.0
          : available < minimumControls + 112
          ? 0.0
          : 112.0;
      final maximumImage = !desktop && minimumImage == 0
          ? 0.0
          : (available - minimumControls).clamp(minimumImage, available);
      final preferredCanvasHeight = bounds.maxHeight < 520
          ? (bounds.maxHeight * .28).clamp(48.0, 105.0)
          : (bounds.maxHeight * .52).clamp(150.0, 440.0);
      final defaultExtent = desktop
          ? available - (bounds.maxWidth * .4).clamp(350.0, 510.0)
          : preferredCanvasHeight.clamp(
              minimumImage,
              (available - 200 - MediaQuery.textScalerOf(context).scale(14) * 6)
                  .clamp(minimumImage, available),
            );
      final savedFraction = desktop
          ? layout.wideImageFraction
          : layout.portraitImageFraction;
      final imageExtent =
          (savedFraction == null ? defaultExtent : savedFraction * available)
              .clamp(minimumImage, maximumImage);
      final canResize = maximumImage > minimumImage;
      void adjust(double delta) {
        resizeImage(
          imageExtent + delta,
          wide: desktop,
          available: available,
          minimum: minimumImage,
          maximum: maximumImage,
        );
        widget.onLayoutChanged?.call(layout);
      }

      void reset() {
        setState(() => layout = const WorkspaceLayout());
        widget.onLayoutChanged?.call(layout);
      }

      return ColoredBox(
        color: AppAppearance.of(context).canvas,
        child: Flex(
          direction: desktop ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: const ValueKey('workspace-image-pane'),
              width: desktop ? imageExtent : bounds.maxWidth,
              height: desktop ? bounds.maxHeight : imageExtent,
              child: imageExtent < 112
                  ? const SizedBox.shrink()
                  : canvas(
                      compact:
                          !desktop &&
                          imageExtent <
                              172 +
                                  MediaQuery.textScalerOf(context).scale(12) *
                                      2.6,
                    ),
            ),
            Semantics(
              label: 'Image and options divider',
              hint: desktop
                  ? 'Drag left or right to resize. Double-tap to reset.'
                  : 'Drag up for more options, down for a larger image. Double-tap to reset.',
              value:
                  '${available == 0 ? 0 : (imageExtent / available * 100).round()}% image area',
              increasedValue: canResize
                  ? '${((imageExtent + 40).clamp(minimumImage, maximumImage) / available * 100).round()}% image area'
                  : null,
              decreasedValue: canResize
                  ? '${((imageExtent - 40).clamp(minimumImage, maximumImage) / available * 100).round()}% image area'
                  : null,
              onIncrease: canResize ? () => adjust(40) : null,
              onDecrease: canResize ? () => adjust(-40) : null,
              onTap: reset,
              child: MouseRegion(
                cursor: canResize
                    ? (desktop
                          ? SystemMouseCursors.resizeLeftRight
                          : SystemMouseCursors.resizeUpDown)
                    : SystemMouseCursors.basic,
                child: Tooltip(
                  message:
                      'Drag to resize image and options. Double-tap to reset.',
                  child: GestureDetector(
                    key: const ValueKey('workspace-resize-handle'),
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: reset,
                    onVerticalDragStart: desktop || !canResize
                        ? null
                        : (_) => dragExtent = imageExtent,
                    onVerticalDragUpdate: desktop || !canResize
                        ? null
                        : (details) {
                            dragExtent =
                                (dragExtent ?? imageExtent) + details.delta.dy;
                            resizeImage(
                              dragExtent!,
                              wide: false,
                              available: available,
                              minimum: minimumImage,
                              maximum: maximumImage,
                            );
                          },
                    onVerticalDragEnd: desktop || !canResize
                        ? null
                        : (_) {
                            dragExtent = null;
                            widget.onLayoutChanged?.call(layout);
                          },
                    onHorizontalDragStart: !desktop || !canResize
                        ? null
                        : (_) => dragExtent = imageExtent,
                    onHorizontalDragUpdate: !desktop || !canResize
                        ? null
                        : (details) {
                            dragExtent =
                                (dragExtent ?? imageExtent) + details.delta.dx;
                            resizeImage(
                              dragExtent!,
                              wide: true,
                              available: available,
                              minimum: minimumImage,
                              maximum: maximumImage,
                            );
                          },
                    onHorizontalDragEnd: !desktop || !canResize
                        ? null
                        : (_) {
                            dragExtent = null;
                            widget.onLayoutChanged?.call(layout);
                          },
                    child: SizedBox(
                      width: desktop ? handleSize : double.infinity,
                      height: desktop ? double.infinity : handleSize,
                      child: Center(
                        child: Container(
                          width: desktop ? 4 : 44,
                          height: desktop ? 44 : 4,
                          decoration: BoxDecoration(
                            color:
                                ThemeData.estimateBrightnessForColor(
                                      AppAppearance.of(context).canvas,
                                    ) ==
                                    Brightness.dark
                                ? Colors.white70
                                : AppAppearance.of(context).ink
                                      .withValues(alpha: .6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              key: const ValueKey('workspace-options-pane'),
              child: panel,
            ),
          ],
        ),
      );
    },
  );
}

class FocusVersionThumbnail extends StatelessWidget {
  final Uint8List? image;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  const FocusVersionThumbnail({
    super.key,
    required this.image,
    required this.title,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Semantics(
      selected: selected,
      child: Tooltip(
        message: title,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 128,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: selected
                  ? AppAppearance.of(context).accent
                  : AppAppearance.of(context).canvas,
              border: Border.all(
                color: selected ? Colors.white : Colors.white38,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Expanded(
                  child: image == null
                      ? const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.memory(
                            image!,
                            width: 118,
                            cacheWidth: 240,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                SizedBox(
                  height: MediaQuery.textScalerOf(context).scale(12) * 2.6,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class FocusHomeHero extends StatelessWidget {
  final Uint8List? image;
  final String imageAsset;
  final VoidCallback? takePhoto;
  final VoidCallback? changeCover;
  final VoidCallback choosePhotos;
  const FocusHomeHero({
    super.key,
    this.image,
    this.imageAsset = 'assets/inspiration/coastal-living.png',
    this.takePhoto,
    this.changeCover,
    required this.choosePhotos,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Stack(
      children: [
        Positioned.fill(
          child: image == null
              ? Image.asset(imageAsset, cacheWidth: 1000, fit: BoxFit.cover)
              : Image.memory(
                  image!,
                  cacheWidth: 1000,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset(
                    imageAsset,
                    cacheWidth: 1000,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x33000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 260),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: const Text(
                        'Capture your room',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (changeCover != null)
                      IconButton(
                        tooltip: 'Change home cover',
                        onPressed: changeCover,
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black45,
                        ),
                        icon: const Icon(Icons.wallpaper_outlined),
                      ),
                  ],
                ),
                Text(
                  image == null
                      ? 'Sample room · start with your own photo'
                      : 'Your chosen cover',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 56),
                if (takePhoto != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: takePhoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take photo'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: choosePhotos,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose photos'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
