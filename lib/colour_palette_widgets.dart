import 'dart:math' as math;
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import 'context_help.dart';

import 'design_palettes.dart';
import 'models.dart';
import 'store.dart';

class PaletteSwatches extends StatelessWidget {
  final DesignPalette palette;
  const PaletteSwatches({super.key, required this.palette});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final colour in palette.colours)
        Expanded(
          child: Tooltip(
            message: '${colour.surface}: ${colour.name} ${colour.hex}',
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF000000 | colour.rgb),
                border: Border.all(color: Colors.black12),
              ),
            ),
          ),
        ),
    ],
  );
}

class ColourPalettePicker extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;
  final bool horizontal;
  final ScrollController? scrollController;
  const ColourPalettePicker({
    super.key,
    required this.selectedId,
    required this.onSelected,
    this.horizontal = false,
    this.scrollController,
  });

  Widget _choice(
    BuildContext context, {
    required String id,
    required String title,
    DesignPalette? palette,
  }) {
    final selected = id == selectedId;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('${horizontal ? 'quick-' : ''}palette-$id'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelected(id),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: horizontal ? 2 : null,
                        overflow: horizontal ? TextOverflow.ellipsis : null,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (palette != null)
                  PaletteSwatches(palette: palette)
                else
                  Text(
                    'Leave colour choices open.',
                    maxLines: horizontal ? 2 : null,
                    overflow: horizontal ? TextOverflow.ellipsis : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      if (horizontal) {
        return SizedBox(
          height: 150,
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: scrollController != null,
            child: ListView.separated(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 14),
              itemCount: designPalettes.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final palette = index == 0 ? null : designPalettes[index - 1];
                return SizedBox(
                  width: 185,
                  child: _choice(
                    context,
                    id: palette?.id ?? '',
                    title: palette?.name ?? 'No palette preference',
                    palette: palette,
                  ),
                );
              },
            ),
          ),
        );
      }
      final width = bounds.maxWidth >= 520
          ? (bounds.maxWidth - 12) / 2
          : bounds.maxWidth;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: width,
            child: _choice(context, id: '', title: 'No palette preference'),
          ),
          for (final palette in designPalettes)
            SizedBox(
              width: width,
              child: _choice(
                context,
                id: palette.id,
                title: palette.name,
                palette: palette,
              ),
            ),
        ],
      );
    },
  );
}

Future<String?> chooseColourPalette(
  BuildContext context, {
  String initialId = '',
  List<Uint8List> photos = const [],
}) => showDialog<String>(
  context: context,
  builder: (_) => _PaletteDialog(initialId: initialId, photos: photos),
);

class _PaletteDialog extends StatefulWidget {
  final String initialId;
  final List<Uint8List> photos;
  const _PaletteDialog({required this.initialId, required this.photos});
  @override
  State<_PaletteDialog> createState() => _PaletteDialogState();
}

class _PaletteDialogState extends State<_PaletteDialog> {
  late String selectedId;
  @override
  void initState() {
    super.initState();
    selectedId = widget.initialId;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Choose a colour palette'),
    content: SizedBox(
      width: 640,
      height: math.min(540, MediaQuery.sizeOf(context).height * .62),
      child: ListView(
        children: [
          if (widget.photos.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final photo in widget.photos.take(3))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      photo,
                      width: 100,
                      height: 65,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'Choose a coordinated starting point. You can change it later. Surface assignments are suggestions; protected features and precise edit boundaries take priority.',
          ),
          const SizedBox(height: 14),
          ColourPalettePicker(
            selectedId: selectedId,
            onSelected: (id) => setState(() => selectedId = id),
          ),
          if (paletteById(selectedId) case final palette?) ...[
            const SizedBox(height: 14),
            Text(
              palette.colours
                  .map(
                    (colour) =>
                        '${colour.surface}: ${colour.name} ${colour.hex}',
                  )
                  .join('\n'),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Screen colours are visual guidance, not exact paint or material matches. Choosing a palette does not recolour your stored photos.',
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, selectedId),
        child: const Text('Use palette'),
      ),
    ],
  );
}

class RoomColourPaletteCard extends StatefulWidget {
  final RenovisionStore store;
  final RenovationRoom room;
  final Uint8List? preview;
  const RoomColourPaletteCard({
    super.key,
    required this.store,
    required this.room,
    this.preview,
  });
  @override
  State<RoomColourPaletteCard> createState() => _RoomColourPaletteCardState();
}

class _RoomColourPaletteCardState extends State<RoomColourPaletteCard> {
  bool busy = false;
  String? message;
  final paletteScroll = ScrollController();
  @override
  void dispose() {
    paletteScroll.dispose();
    super.dispose();
  }

  Future<void> _persist(String id) async {
    await widget.store.setRoomPalette(widget.room.id, id);
    if (mounted) {
      setState(
        () => message =
            'Palette saved for future prompts. Existing images are unchanged.',
      );
    }
  }

  Future<void> _quickChoose(String id) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await _persist(id);
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Could not save the palette. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _choose() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final id = await chooseColourPalette(
        context,
        initialId: widget.room.colourPaletteId,
        photos: [if (widget.preview != null) widget.preview!],
      );
      if (id == null) return;
      await _persist(id);
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Could not save the palette. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteById(widget.room.colourPaletteId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Colour palette',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const HelpIcon(
                  title: 'Colour palette',
                  message: 'Swipe or scroll sideways to see more palettes, or open Change palette for the full chooser. Colours guide copied and in-app AI prompts. They are visual references, not exact paint or material matches. Changing a palette affects the next design request; existing photos and approved designs stay unchanged.',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              palette?.name ??
                  (widget.room.colourPaletteId.isEmpty
                      ? 'No palette preference'
                      : 'Saved palette is unavailable'),
            ),
            const SizedBox(height: 10),
            AbsorbPointer(
              absorbing: busy,
              child: ColourPalettePicker(
                selectedId: widget.room.colourPaletteId,
                onSelected: _quickChoose,
                horizontal: true,
                scrollController: paletteScroll,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: busy ? null : _choose,
              icon: const Icon(Icons.color_lens_outlined),
              label: Text(busy ? 'Choosing palette…' : 'Change palette'),
            ),
            if (message != null) Text(message!),
          ],
        ),
      ),
    );
  }
}
