import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

enum FocusSection { room, style, refine, ideas }

abstract final class FocusColours {
  static const canvas = Color(0xFF26251F);
  static const paper = Color(0xFFF1ECE3);
  static const panel = Color(0xFFFCF9F3);
  static const olive = Color(0xFF706B3E);
  static const ink = Color(0xFF292A24);
}

/// Keeps all control groups mounted so switching tabs cannot discard drafts,
/// a running paid request, or a received result waiting for a local save.
class FocusWorkspace extends StatefulWidget {
  final FocusSection selected;
  final ValueChanged<FocusSection> onSelected;
  final Widget Function(double height) imageBuilder;
  final List<Widget> imageTools;
  final List<Widget> thumbnails;
  final Map<FocusSection, List<Widget>> sections;
  final Widget saveStatus;
  const FocusWorkspace({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.imageBuilder,
    required this.imageTools,
    required this.thumbnails,
    required this.sections,
    required this.saveStatus,
  });

  @override
  State<FocusWorkspace> createState() => _FocusWorkspaceState();
}

class _FocusWorkspaceState extends State<FocusWorkspace> {
  final scroll = ScrollController();
  final offsets = <FocusSection, double>{};

  @override
  void didUpdateWidget(FocusWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      if (scroll.hasClients) offsets[oldWidget.selected] = scroll.offset;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scroll.hasClients) {
          scroll.jumpTo(
            (offsets[widget.selected] ?? 0).clamp(
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
    color: FocusColours.canvas,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.imageTools,
            ),
          ),
          if (!compact && widget.thumbnails.isNotEmpty)
            SizedBox(
              height: 72,
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
    color: FocusColours.paper,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
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
                            : FocusColours.ink,
                        backgroundColor: section == widget.selected
                            ? FocusColours.olive
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 12,
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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
          child: widget.saveStatus,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final desktop = bounds.maxWidth >= 900 && bounds.maxHeight >= 420;
      final panel = controls(context);
      final canvasHeight = bounds.maxHeight < 400
          ? (bounds.maxHeight * .28).clamp(48.0, 105.0)
          : (bounds.maxHeight * .52).clamp(150.0, 440.0);
      return ColoredBox(
        color: FocusColours.canvas,
        child: Flex(
          direction: desktop ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: desktop
                  ? bounds.maxWidth - (bounds.maxWidth * .4).clamp(350.0, 510.0)
                  : bounds.maxWidth,
              height: desktop ? bounds.maxHeight : canvasHeight,
              child: canvas(compact: !desktop && bounds.maxHeight < 500),
            ),
            Expanded(child: panel),
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
            width: 100,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: selected ? FocusColours.olive : FocusColours.canvas,
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
                            width: 90,
                            cacheWidth: 240,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
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
          constraints: const BoxConstraints(minHeight: 300),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                          fontSize: 30,
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
                const SizedBox(height: 96),
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
