import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'store.dart';

Future<bool> confirmDeleteDesign(
  BuildContext context,
  RenovisionStore store,
  DesignVersion design,
) async {
  final approved = store.roomById(design.roomId)?.approvedDesignId == design.id;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        approved ? 'Approved baseline is protected' : 'Delete this design?',
      ),
      content: Text(
        approved
            ? 'Approve the original photo or another design as the baseline first. You can then delete this version.'
            : '“${design.title}” will be removed from your design lists and moved to Deleted designs. You can restore it later. Original photos and other versions stay unchanged.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(approved ? 'Close' : 'Cancel'),
        ),
        if (!approved)
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete design'),
          ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await store.trashDesign(design.id);
    if (context.mounted) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Design moved to Deleted designs.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                await store.restoreDesign(design.id);
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Could not restore the design. Try Restore in Deleted designs.',
                    ),
                  ),
                );
              }
            },
          ),
        ),
      );
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error is DesignChangeFailure
                ? error.message
                : 'Could not delete this design. Try again.',
          ),
        ),
      );
    }
    return false;
  }
}

class DeleteDesignButton extends StatefulWidget {
  final RenovisionStore store;
  final DesignVersion design;
  final bool enabled;
  const DeleteDesignButton({
    super.key,
    required this.store,
    required this.design,
    this.enabled = true,
  });
  @override
  State<DeleteDesignButton> createState() => _DeleteDesignButtonState();
}

class _DeleteDesignButtonState extends State<DeleteDesignButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store.ai.activity,
    builder: (context, _) => IconButton(
      tooltip: 'Delete ${widget.design.title}',
      icon: const Icon(Icons.delete_outline),
      onPressed: busy || !widget.enabled || widget.store.ai.activity.active
          ? null
          : () async {
              setState(() => busy = true);
              try {
                await confirmDeleteDesign(context, widget.store, widget.design);
              } finally {
                if (mounted) setState(() => busy = false);
              }
            },
    ),
  );
}

class DeletedDesignsCard extends StatelessWidget {
  final RenovisionStore store;
  final String roomId;
  const DeletedDesignsCard({
    super.key,
    required this.store,
    required this.roomId,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final designs = store.deletedDesignsFor(roomId);
      if (designs.isEmpty) return const SizedBox.shrink();
      return Card(
        child: ExpansionTile(
          title: Text('Deleted designs (${designs.length})'),
          subtitle: const Text(
            'Recoverable designs stay in your project, including saved project files.',
          ),
          children: [
            for (final design in designs)
              ListTile(
                title: Text(
                  design.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: 'Restore ${design.title}',
                  icon: const Icon(Icons.restore_from_trash_outlined),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await store.restoreDesign(design.id);
                    } catch (_) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not restore the design. Try again.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}
