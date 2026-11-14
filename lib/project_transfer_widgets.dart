import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';

import 'file_transfer.dart';
import 'models.dart';
import 'project_backup.dart';
import 'store.dart';

String exportName(String title) {
  final cleaned = title
      .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final name = cleaned.isEmpty ? 'renovision' : cleaned;
  return name.length > 60 ? name.substring(0, 60) : name;
}

String saveMessage(FileSaveResult result) => switch (result) {
  FileSaveResult.requested => 'Download requested. Check your browser downloads and keep the file somewhere safe.',
  FileSaveResult.saved => 'File saved to your chosen location.',
  FileSaveResult.cancelled => 'Save cancelled.',
};

class DownloadImageButton extends StatefulWidget {
  final AppFiles files;
  final Uint8List bytes;
  final String name;
  const DownloadImageButton({
    super.key,
    required this.files,
    required this.bytes,
    required this.name,
  });
  @override
  State<DownloadImageButton> createState() => _DownloadImageButtonState();
}

class _DownloadImageButtonState extends State<DownloadImageButton> {
  bool busy = false;
  Future<void> _download() async {
    final bytes = widget.bytes;
    final name = widget.name;
    setState(() => busy = true);
    try {
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw const BackupFailure(
          'This image cannot be converted for download. Use a project backup to keep the exact original.',
        );
      }
      image.exif = img.ExifData();
      image.iccProfile = null;
      image.textData?.clear();
      final result = await widget.files.save(
        img.encodePng(image),
        name: '${exportName(name)}.png',
        mimeType: 'image/png',
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(saveMessage(result))));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is BackupFailure
                  ? error.message
                  : 'Image could not be saved. Your stored photo is unchanged.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: busy || !widget.files.supported ? null : _download,
    icon: const Icon(Icons.download_outlined),
    label: Text(busy ? 'Preparing image…' : 'Download image'),
  );
}

class ProjectBackupCard extends StatefulWidget {
  final RenovisionStore store;
  final RenovationProject project;
  const ProjectBackupCard({
    super.key,
    required this.store,
    required this.project,
  });
  @override
  State<ProjectBackupCard> createState() => _ProjectBackupCardState();
}

class _ProjectBackupCardState extends State<ProjectBackupCard> {
  bool busy = false;
  String? message;
  Future<void> _backup() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final bytes = widget.store.backupFor(widget.project.id).encode();
      final result = await widget.store.files.save(
        bytes,
        name: '${exportName(widget.project.name)}.renovision.json',
        mimeType: 'application/json',
      );
      if (mounted) setState(() => message = saveMessage(result));
    } catch (error) {
      if (mounted) {
        setState(
          () => message = error is BackupFailure
              ? error.message
              : 'Backup could not be saved. Your project is unchanged.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.save_alt,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Keep a copy of this project',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Includes original photos, every saved version, instructions, favourites and approved baselines. Keep the backup private; it contains your photos and their original metadata.',
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: busy || !widget.store.files.supported ? null : _backup,
            icon: const Icon(Icons.download),
            label: Text(busy ? 'Preparing backup…' : 'Back up project'),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(message!),
            ),
        ],
      ),
    ),
  );
}

class RestoreProjectButton extends StatefulWidget {
  final RenovisionStore store;
  final ValueChanged<RenovationProject> onRestored;
  const RestoreProjectButton({
    super.key,
    required this.store,
    required this.onRestored,
  });
  @override
  State<RestoreProjectButton> createState() => _RestoreProjectButtonState();
}

class _RestoreProjectButtonState extends State<RestoreProjectButton> {
  bool busy = false;
  Future<void> _restore() async {
    setState(() => busy = true);
    try {
      final bytes = await widget.store.files.pickBackup();
      if (bytes == null || !mounted) return;
      final backup = ProjectBackup.decode(bytes);
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Restore a project copy?'),
          content: Text(
            '${backup.project.name}\n${backup.rooms.length} rooms · ${backup.designs.length} versions · ${backup.photos.length} images\n\nA separate restored project will be added. Existing projects will not be replaced.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restore copy'),
            ),
          ],
        ),
      );
      if (approved != true || !mounted) return;
      final restored = await widget.store.restoreBackup(backup);
      if (mounted) widget.onRestored(restored);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is BackupFailure ? error.message : 'The backup could not be opened. Existing projects were not replaced.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: busy || !widget.store.files.supported ? null : _restore,
    icon: const Icon(Icons.restore),
    label: Text(busy ? 'Restoring…' : 'Restore project backup'),
  );
}
