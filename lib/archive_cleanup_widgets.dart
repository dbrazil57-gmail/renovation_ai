import 'package:material_ui/material_ui.dart';

import 'archive_cleanup.dart';
import 'app_notices.dart';
import 'file_transfer.dart';
import 'models.dart';
import 'project_backup.dart';
import 'project_transfer_widgets.dart';
import 'store.dart';

class ArchiveCleanupSettingsCard extends StatelessWidget {
  final RenovisionStore store;
  const ArchiveCleanupSettingsCard({super.key, required this.store});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: const ValueKey('archive-cleanup-settings'),
      leading: const Icon(Icons.cleaning_services_outlined),
      title: const Text('Storage cleanup'),
      subtitle: Text(
        '${store.archivedProjects.length} archived or deleted projects',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => ArchiveCleanupScreen(store: store)),
      ),
    ),
  );
}

class ArchiveCleanupScreen extends StatelessWidget {
  final RenovisionStore store;
  const ArchiveCleanupScreen({super.key, required this.store});
  Future<void> review(BuildContext context, String id) async {
    try {
      final plan = store.archiveRemovalPlan(id);
      final removed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _DeleteArchiveDialog(store: store, plan: plan),
      );
      if (removed == true && context.mounted) {
        showAppNotice(context, 'Archive permanently deleted from this device.');
      }
    } catch (_) {
      if (context.mounted) {
        showAppNotice(
          context,
          'This archive is unavailable. Refresh the list and try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Archive cleanup')),
    body: ListenableBuilder(
      listenable: Listenable.merge([store, store.ai.activity]),
      builder: (context, _) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Choose an archive to permanently remove from this device. You can save an offline backup first.',
              ),
              const SizedBox(height: 12),
              if (store.ai.activity.active)
                const Text(
                  'Wait for the AI request to finish before cleaning up.',
                ),
              if (store.archivedProjects.isEmpty)
                const ListTile(
                  title: Text('Nothing to clean up'),
                  subtitle: Text('Active projects are kept.'),
                ),
              for (final project in store.archivedProjects)
                Card(
                  child: ListTile(
                    title: Text(store.projectLabel(project)),
                    subtitle: Text(
                      project.deleted ? 'Deleted · recoverable' : 'Archived',
                    ),
                    trailing: IconButton(
                      key: ValueKey('purge-archive-${project.id}'),
                      tooltip: 'Permanently delete ${project.name}',
                      icon: const Icon(Icons.delete_forever_outlined),
                      onPressed: store.ai.activity.active
                          ? null
                          : () => review(context, project.id),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

enum _BackupChoice { undecided, saved, skipped }

class _DeleteArchiveDialog extends StatefulWidget {
  final RenovisionStore store;
  final ArchiveRemovalPlan plan;
  const _DeleteArchiveDialog({required this.store, required this.plan});
  @override
  State<_DeleteArchiveDialog> createState() => _DeleteArchiveDialogState();
}

class _DeleteArchiveDialogState extends State<_DeleteArchiveDialog> {
  var choice = _BackupChoice.undecided;
  var busy = false, needsDownloadCheck = false, downloadChecked = false;
  String typed = '', message = '';
  Future<void> backup() async {
    setState(() {
      busy = true;
      message = '';
    });
    try {
      final original = widget.store.backupFor(widget.plan.project.id);
      final bytes = ProjectBackup(
        project: RenovationProject.fromMap({
          ...original.project.toMap(),
          'archived': false,
          'deleted': false,
        }),
        rooms: original.rooms,
        designs: original.designs,
        photos: original.photos,
      ).encode();
      final result = await widget.store.files.save(
        bytes,
        name:
            '${exportName(widget.plan.project.name)}-archive-backup.renovision.json',
        mimeType: 'application/json',
      );
      if (!mounted) return;
      setState(() {
        message = saveMessage(result);
        if (result != FileSaveResult.cancelled) {
          choice = _BackupChoice.saved;
          needsDownloadCheck = result == FileSaveResult.requested;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Backup could not be saved. The archive is kept. Retry or explicitly continue without a backup.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove() async {
    setState(() {
      busy = true;
      message = '';
    });
    try {
      await widget.store.purgeArchivedProject(
        widget.plan.project.id,
        confirmation: typed,
        revision: widget.plan.revision,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => message = error is StateError ? error.message.toString() : 'Cleanup could not finish. Check storage and your backup before retrying.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text('Delete ${widget.plan.project.name} permanently?'),
      content: SizedBox(
        width: 490,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.plan.roomCount} rooms · ${widget.plan.designCount} designs · ${widget.plan.images.length} stored images to remove (${(widget.plan.imageBytes / 1048576).toStringAsFixed(1)} MB).',
              ),
              const SizedBox(height: 8),
              const Text(
                'This removes the local archive and its own photos and designs. It cannot be undone here. Active projects, images used elsewhere, AI keys and settings are kept. Exported files and cloud copies are outside this cleanup.',
              ),
              const SizedBox(height: 14),
              if (choice == _BackupChoice.undecided) ...[
                const Text('Would you like an offline project backup first?'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy || !widget.store.files.supported
                      ? null
                      : backup,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save offline backup first'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() => choice = _BackupChoice.skipped),
                  child: const Text('Continue without a backup'),
                ),
              ] else ...[
                Text(
                  choice == _BackupChoice.saved
                      ? (needsDownloadCheck
                            ? 'Check your downloaded backup before deleting.'
                            : 'Offline backup saved. Confirm deletion below.')
                      : 'You chose to continue without a backup.',
                ),
                if (needsDownloadCheck)
                  CheckboxListTile(
                    key: const ValueKey('archive-backup-download-checked'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I checked that the backup file is saved.',
                    ),
                    value: downloadChecked,
                    onChanged: busy
                        ? null
                        : (value) =>
                              setState(() => downloadChecked = value == true),
                  ),
                TextField(
                  key: const ValueKey('archive-delete-name'),
                  enabled: !busy,
                  onChanged: (value) => setState(() => typed = value),
                  decoration: InputDecoration(
                    labelText: 'Type ${widget.plan.project.name} to confirm',
                  ),
                ),
              ],
              if (message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(message),
              ],
              if (busy) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-permanent-archive-delete'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed:
              busy ||
                  choice == _BackupChoice.undecided ||
                  typed.trim() != widget.plan.project.name ||
                  (needsDownloadCheck && !downloadChecked)
              ? null
              : remove,
          child: const Text('Delete permanently'),
        ),
      ],
    ),
  );
}
