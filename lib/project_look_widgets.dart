import 'package:material_ui/material_ui.dart';

import 'app_notices.dart';
import 'design_palettes.dart';
import 'design_styles.dart';
import 'room_draft.dart';
import 'store.dart';

class SavedProjectLook {
  final String roomId, projectId, roomName, paletteId, otherStyle;
  final List<String> styles;
  final bool approved;
  SavedProjectLook({
    required this.roomId,
    required this.projectId,
    required this.roomName,
    required this.paletteId,
    required this.otherStyle,
    required Iterable<String> styles,
    required this.approved,
  }) : styles = List.unmodifiable(styles);
}

List<SavedProjectLook> savedProjectLooks(RenovisionStore store, String roomId) {
  final target = store.roomById(roomId);
  if (target == null) return [];
  return [
        for (final source in store.roomsFor(target.projectId))
          if (source.id != roomId)
            (() {
              final approved = store
                  .designsFor(source.id)
                  .where((d) => d.id == source.approvedDesignId)
                  .firstOrNull;
              final recipe = approved?.recipe?.toMap();
              final palette =
                  (recipe?['colourPaletteId'] ?? source.colourPaletteId)
                      as String;
              return SavedProjectLook(
                roomId: source.id,
                projectId: source.projectId,
                roomName: source.displayName,
                paletteId: paletteById(palette) == null ? '' : palette,
                otherStyle:
                    (recipe?['otherStyle'] ?? source.otherStyle) as String,
                styles: canonicalStyleIds(
                  (recipe?['designStyleIds'] as List?)?.cast<String>() ??
                      source.designStyleIds,
                ),
                approved: recipe != null,
              );
            })(),
      ]
      .where(
        (look) =>
            look.styles.isNotEmpty ||
            look.paletteId.isNotEmpty ||
            look.otherStyle.isNotEmpty,
      )
      .toList();
}

Future<bool> applyProjectLook(
  RenovisionStore store,
  RoomDraft draft,
  SavedProjectLook look,
) async {
  final target = store.roomById(draft.roomId),
      source = store.roomById(look.roomId);
  if (target == null ||
      source == null ||
      target.projectId != look.projectId ||
      source.projectId != target.projectId) {
    throw StateError('Choose a saved look from this project.');
  }
  await store.updateRoom(target.copyWith(colourPaletteId: look.paletteId));
  draft.applySavedLook(styles: look.styles, other: look.otherStyle);
  return draft.save();
}

class SavedProjectLookButton extends StatefulWidget {
  final RenovisionStore store;
  final RoomDraft draft;
  const SavedProjectLookButton({
    super.key,
    required this.store,
    required this.draft,
  });
  @override
  State<SavedProjectLookButton> createState() => _SavedProjectLookButtonState();
}

class _SavedProjectLookButtonState extends State<SavedProjectLookButton> {
  bool busy = false;
  Future<void> choose(List<SavedProjectLook> looks) async {
    final look = await showDialog<SavedProjectLook>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Use a saved project look'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose a room to copy its saved style and palette. Approved design choices take priority. Photos, room facts, layout, instructions and Keep choices stay separate. No AI request or model training is needed.',
                ),
                for (final item in looks)
                  ListTile(
                    title: Text(item.roomName),
                    subtitle: Text(
                      '${item.approved ? 'Approved design' : 'Saved room choices'} · ${paletteById(item.paletteId)?.name ?? 'No palette'}',
                    ),
                    onTap: () => Navigator.pop(ctx, item),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (look == null || !mounted) return;
    setState(() => busy = true);
    try {
      final saved = await applyProjectLook(widget.store, widget.draft, look);
      if (mounted) {
        showAppNotice(
          context,
          saved
              ? 'Style and palette reused. This room’s photos and instructions stay unchanged.'
              : 'Choices loaded; local saving needs attention. Retry Save.',
        );
      }
    } catch (_) {
      if (mounted) {
        showAppNotice(
          context,
          'The saved look could not be applied. Check this project and local saving.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final looks = savedProjectLooks(widget.store, widget.draft.roomId);
    return looks.isEmpty
        ? const SizedBox.shrink()
        : TextButton.icon(
            onPressed: busy ? null : () => choose(looks),
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Use another room’s look…'),
          );
  }
}
