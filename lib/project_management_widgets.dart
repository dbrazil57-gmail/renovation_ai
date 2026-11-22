import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'store.dart';
import 'project_transfer_widgets.dart';
import 'project_backup.dart';
import 'protected_backup.dart';
import 'backup_password_dialog.dart';

class ImportProjectRoomsButton extends StatefulWidget {
  final RenovisionStore store;
  final RenovationProject target;
  const ImportProjectRoomsButton({
    super.key,
    required this.store,
    required this.target,
  });
  @override
  State<ImportProjectRoomsButton> createState() =>
      _ImportProjectRoomsButtonState();
}

class _ImportProjectRoomsButtonState extends State<ImportProjectRoomsButton> {
  bool busy = false;
  String? message;
  Future<void> importRooms() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      var bytes = await widget.store.files.pickBackup();
      if (bytes == null || !mounted) return;
      if (isProtectedBackup(bytes)) {
        final password = await askBackupPassword(context, creating: false);
        if (password == null) return;
        bytes = await unlockBackup(bytes, password);
      }
      final backup = ProjectBackup.decode(bytes);
      if (!mounted) return;
      final approved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import room copies into this project?'),
          content: Text(
            'Add ${backup.rooms.length} rooms and ${backup.designs.length} designs from ${backup.project.name} to ${widget.target.name}. Existing rooms are untouched. Every imported room gets separate photo/version identifiers. This adds room copies; it does not reconcile edits to the same room or overwrite the source file.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Import room copies'),
            ),
          ],
        ),
      );
      if (approved != true) return;
      await widget.store.restoreBackup(
        backup,
        targetProjectId: widget.target.id,
      );
      message =
          'Room copies imported. Existing rooms and source file are unchanged.';
    } catch (_) {
      message = 'Room import could not finish. Existing rooms are retained; check the file and storage before retrying.';
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      OutlinedButton.icon(
        onPressed: busy ? null : importRooms,
        icon: const Icon(Icons.merge_outlined),
        label: Text(busy ? 'Importing rooms…' : 'Import rooms from project…'),
      ),
      if (message != null) Text(message!),
    ],
  );
}

class ProjectManagementButton extends StatelessWidget {
  final RenovisionStore store;
  final RenovationProject project;
  const ProjectManagementButton({
    super.key,
    required this.store,
    required this.project,
  });
  Future<void> manage(BuildContext context) async {
    var typed = '', busy = false, error = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, change) => AlertDialog(
          title: Text('Manage ${project.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Archive hides this project and keeps all rooms, photos and designs. Delete also keeps a recoverable copy in Archived & deleted projects. Export a backup first for a separate safety copy.',
                ),
                ProjectBackupCard(store: store, project: project),
                TextField(
                  key: ValueKey('confirm-project-${project.id}'),
                  onChanged: (value) => change(() => typed = value),
                  decoration: InputDecoration(
                    labelText: 'Type ${project.name} to confirm',
                  ),
                ),
                if (error.isNotEmpty) Text(error),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            for (final deleting in [false, true])
              TextButton(
                onPressed: busy || typed.trim() != project.name
                    ? null
                    : () async {
                        change(() => busy = true);
                        try {
                          await store.archiveProject(
                            project.id,
                            delete: deleting,
                            confirmation: typed,
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } catch (_) {
                          if (dialogContext.mounted) {
                            change(() {
                              busy = false;
                              error = 'Project could not be moved. Finish AI work or retry its pending file save first.';
                            });
                          }
                        }
                      },
                child: Text(deleting ? 'Delete project' : 'Archive project'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Archive or delete project',
    onPressed: () => manage(context),
    icon: const Icon(Icons.more_horiz),
  );
}

class ArchivedProjects extends StatelessWidget {
  final RenovisionStore store;
  const ArchivedProjects({super.key, required this.store});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => store.archivedProjects.isEmpty
        ? const SizedBox.shrink()
        : ExpansionTile(
            title: const Text('Archived & deleted projects'),
            children: [
              for (final p in store.archivedProjects)
                ListTile(
                  title: Text(p.name),
                  subtitle: Text(
                    p.deleted ? 'Deleted · recoverable' : 'Archived',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      try {
                        await store.restoreProject(p.id);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              persist: false,
                              content: Text('Project could not be restored.'),
                              showCloseIcon: true,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Restore project'),
                  ),
                ),
            ],
          ),
  );
}
