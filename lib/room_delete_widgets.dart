import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'store.dart';

class DeleteRoomButton extends StatelessWidget {
  final RenovisionStore store;
  final RenovationRoom room;
  const DeleteRoomButton({super.key, required this.store, required this.room});

  Future<void> remove(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var typed = '', error = '';
    var busy = false;
    final deleted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, change) => AlertDialog(
          title: Text('Delete ${room.displayName}?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The room, photos and designs move to Deleted rooms. You can restore them later.',
                ),
                const SizedBox(height: 12),
                Text('Type ${room.displayName} to confirm.'),
                TextField(
                  key: const ValueKey('delete-room-name'),
                  enabled: !busy,
                  autofocus: true,
                  onChanged: (value) => change(() => typed = value),
                  decoration: const InputDecoration(labelText: 'Room name'),
                ),
                if (error.isNotEmpty) Text(error),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('confirm-delete-room'),
              onPressed: busy || typed.trim() != room.displayName
                  ? null
                  : () async {
                      change(() {
                        busy = true;
                        error = '';
                      });
                      try {
                        await store.deleteRoom(room.id, confirmation: typed);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (_) {
                        if (dialogContext.mounted) {
                          change(() {
                            busy = false;
                            error = 'Room could not be deleted. Wait for any AI request to finish, then retry.';
                          });
                        }
                      }
                    },
              child: Text(busy ? 'Deleting…' : 'Delete room'),
            ),
          ],
        ),
      ),
    );
    if (deleted != true || !messenger.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        persist: false,
        content: Text('${room.displayName} moved to Deleted rooms.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            try {
              await store.restoreRoom(room.id);
            } catch (_) {
              if (messenger.mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    persist: false,
                    content: Text(
                      'Room could not be restored. Retry in Deleted rooms.',
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store.ai.activity,
    builder: (context, _) => IconButton(
      tooltip: 'Delete room',
      onPressed: store.ai.activity.active ? null : () => remove(context),
      icon: const Icon(Icons.delete_outline),
    ),
  );
}

class DeletedRoomsScreen extends StatefulWidget {
  final RenovisionStore store;
  final String projectId;
  const DeletedRoomsScreen({
    super.key,
    required this.store,
    required this.projectId,
  });
  @override
  State<DeletedRoomsScreen> createState() => _DeletedRoomsScreenState();
}

class _DeletedRoomsScreenState extends State<DeletedRoomsScreen> {
  final restoring = <String>{};
  Future<void> restore(String id) async {
    if (restoring.contains(id)) return;
    setState(() => restoring.add(id));
    try {
      await widget.store.restoreRoom(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            persist: false,
            content: Text('Room could not be restored. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => restoring.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Deleted rooms')),
    body: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final rooms = widget.store.deletedRoomsFor(widget.projectId);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Photos, designs and saved choices are kept until restored. Deleted rooms are included in project backups.',
            ),
            if (rooms.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No deleted rooms.'),
              ),
            for (final room in rooms)
              Card(
                child: ListTile(
                  title: Text(room.displayName),
                  trailing: IconButton(
                    tooltip: 'Restore ${room.displayName}',
                    onPressed: restoring.contains(room.id)
                        ? null
                        : () => restore(room.id),
                    icon: const Icon(Icons.restore),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
