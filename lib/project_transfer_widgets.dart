import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';

import 'file_transfer.dart';
import 'models.dart';
import 'project_backup.dart';
import 'store.dart';
import 'context_help.dart';
import 'protected_backup.dart';
import 'backup_password_dialog.dart';

Future<void> showProjectSaveDialog(
  BuildContext context, {
  required RenovisionStore store,
  required String projectId,
  Future<bool> Function()? beforeSave,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('Save project file'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: ProjectFileControls(
          store: store,
          projectId: projectId,
          beforeSave: beforeSave,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: const Text('Close'),
      ),
    ],
  ),
);

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

Uint8List pngExportBytes(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) {
    throw const BackupFailure(
      'This image cannot be converted. Use a project backup to keep its exact bytes.',
    );
  }
  image.exif = img.ExifData();
  image.iccProfile = null;
  image.textData?.clear();
  return img.encodePng(image);
}

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
  final Future<bool> Function()? beforeSave;
  const ProjectBackupCard({
    super.key,
    required this.store,
    required this.project,
    this.beforeSave,
  });
  @override
  State<ProjectBackupCard> createState() => _ProjectBackupCardState();
}

class _ProjectBackupCardState extends State<ProjectBackupCard> {
  bool busy = false;
  String? message;
  Future<void> _backup({bool protected = false}) async {
    if (busy) return;
    final password = protected
        ? await askBackupPassword(context, creating: true)
        : null;
    if (!mounted || (protected && password == null)) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final destination = await chooseSaveDestination(
        widget.store.files,
        name:
            '${exportName(widget.project.name)}${protected ? '.renovision' : '.renovision.json'}',
        mimeType: protected ? 'application/octet-stream' : 'application/json',
      );
      if (destination == null || !mounted) return;
      if (widget.beforeSave != null && !await widget.beforeSave!()) {
        if (mounted) {
          setState(
            () => message =
                'Save pending room changes successfully before backing up.',
          );
        }
        return;
      }
      if (!mounted) return;
      setState(
        () => message = protected
            ? 'Encrypting backup…'
            : 'Preparing project copy…',
      );
      var bytes = widget.store.backupFor(widget.project.id).encode();
      if (protected) bytes = await protectBackup(bytes, password!);
      if (!mounted) return;
      final result = await destination.write(bytes);
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
              Expanded(
                child: Text(
                  'Keep a copy of this project',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const HelpIcon(
                title: 'Project backup',
                message: 'Includes original photos, every saved version, instructions, favourites and approved baselines. Keep the backup private; it contains your photos and their original metadata.',
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: busy || !widget.store.files.supported
                ? null
                : () => _backup(),
            icon: const Icon(Icons.download),
            label: Text(busy ? 'Preparing backup…' : 'Back up project'),
          ),
          OutlinedButton.icon(
            onPressed: busy || !widget.store.files.supported
                ? null
                : () => _backup(protected: true),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Password-protected backup'),
          ),
          if (busy) const LinearProgressIndicator(),
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
  final bool openDocument;
  final String? label;
  const RestoreProjectButton({
    super.key,
    required this.store,
    required this.onRestored,
    this.openDocument = false,
    this.label,
  });
  @override
  State<RestoreProjectButton> createState() => _RestoreProjectButtonState();
}

class _RestoreProjectButtonState extends State<RestoreProjectButton> {
  bool busy = false;
  Future<void> _restore() async {
    setState(() => busy = true);
    try {
      final files = widget.store.files;
      final opened = widget.openDocument && files is ProjectOpeningFiles
          ? await (files as ProjectOpeningFiles).openProjectFile()
          : null;
      final bytes = widget.openDocument && files is ProjectOpeningFiles
          ? opened?.bytes
          : await files.pickBackup();
      if (bytes == null || !mounted) return;
      final protected = isProtectedBackup(bytes);
      var plain = bytes;
      if (protected) {
        final password = await askBackupPassword(context, creating: false);
        if (password == null || !mounted) return;
        plain = await unlockBackup(bytes, password);
      }
      if (!mounted) return;
      final backup = ProjectBackup.decode(plain);
      final existing = widget.openDocument
          ? widget.store.projectById(backup.project.id)
          : null;
      final different =
          existing != null &&
          widget.store.backupFor(existing.id).contentSignature !=
              backup.contentSignature;
      var restoreCopy = !widget.openDocument;
      if (different) {
        final choice = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Local work and file differ'),
            content: Text(
              '${backup.project.name}\n\nThis project is already on this device, with different saved work. Keep the local project or open the file as a separate copy. Neither choice replaces your existing rooms or images.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'local'),
                child: const Text('Keep local project'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, 'copy'),
                child: const Text('Open file as copy'),
              ),
            ],
          ),
        );
        if (!mounted || choice == null) return;
        if (choice == 'local') {
          widget.onRestored(existing);
          return;
        }
        restoreCopy = true;
      }
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            widget.openDocument
                ? 'Open this project?'
                : 'Restore a project copy?',
          ),
          content: Text(
            '${backup.project.name}\n${backup.rooms.length} rooms · ${backup.designs.length} versions · ${backup.photos.length} images\n\n${restoreCopy
                ? 'A separate restored project will be added. Existing projects will not be replaced.'
                : existing != null
                ? 'Resume the existing project on this device. No duplicate project will be created.'
                : 'Open this project with its saved rooms, photos and versions.'}${protected ? '\n\nThe protected file stays unchanged. Make another password-protected backup to update it.' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                widget.openDocument ? 'Open project' : 'Restore copy',
              ),
            ),
          ],
        ),
      );
      if (approved != true || !mounted) return;
      final restored = restoreCopy
          ? await widget.store.restoreBackup(backup)
          : await widget.store.openBackup(backup);
      // A protected backup is never linked to plaintext project-file autosave.
      if (!protected && !restoreCopy && opened?.destination != null) {
        await widget.store.documents.link(
          restored.id,
          opened!.destination!,
          alreadySaved: true,
        );
      }
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
    label: Text(
      busy
          ? 'Opening…'
          : widget.label ??
                (widget.openDocument
                    ? 'Open project…'
                    : 'Restore project backup'),
    ),
  );
}

class ProjectFileControls extends StatefulWidget {
  final RenovisionStore store;
  final String projectId;
  final Future<bool> Function()? beforeSave;
  const ProjectFileControls({
    super.key,
    required this.store,
    required this.projectId,
    this.beforeSave,
  });
  @override
  State<ProjectFileControls> createState() => _ProjectFileControlsState();
}

class _ProjectFileControlsState extends State<ProjectFileControls> {
  bool busy = false;
  String? error;
  Future<void> save({bool saveAs = false}) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final docs = widget.store.documents;
      SaveDestination? destination;
      if (saveAs || !docs.linked(widget.projectId)) {
        final project = widget.store.projectById(widget.projectId)!;
        destination = await chooseSaveDestination(
          widget.store.files,
          name: '${exportName(project.name)}.renovision.json',
          mimeType: 'application/json',
        );
        if (destination == null) return;
      }
      if (widget.beforeSave != null && !await widget.beforeSave!()) {
        throw const BackupFailure(
          'Room changes could not be saved. Retry before saving the project file.',
        );
      }
      if (destination != null) {
        await docs.link(widget.projectId, destination);
      }
      await docs.save(widget.projectId);
    } catch (failure) {
      if (mounted) {
        setState(
          () => error = failure is BackupFailure ? failure.message : 'Project file could not be saved. Local work is retained; try Save project as.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store.documents,
    builder: (context, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HelpHeading(
              title: 'Project file',
              style: Theme.of(context).textTheme.titleMedium,
              message:
                  'One file contains all rooms, original photos, designs and their saved instructions and choices. Keep it private. AI connection credentials are stored separately on this device.\n\n${kIsWeb ? 'Chrome can update a file you choose while it is open here. After restarting the app, use Open project to reconnect that file. Other browsers may download a separate copy.' : 'App-local autosave keeps your work on this device. Save project writes a complete file using the system chooser; Open project loads a saved file.'}',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: busy || !widget.store.files.supported
                      ? null
                      : () => save(),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(busy ? 'Saving project…' : 'Save project'),
                ),
                OutlinedButton(
                  onPressed: busy || !widget.store.files.supported
                      ? null
                      : () => save(saveAs: true),
                  child: const Text('Save project as…'),
                ),
              ],
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                error ??
                    compactProjectFileStatus(
                      widget.store.documents.status(widget.projectId),
                    ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String compactProjectFileStatus(String status) {
  if (status ==
      'Saved on this device. Save a project file to keep a portable copy.') {
    return 'Saved on this device.';
  }
  if (status ==
      'Project file saved. App-local autosave continues; use Save project to choose a destination for the next file copy.') {
    return 'Project file saved.';
  }
  if (status ==
      'Project file opened. Save updates this file during this session.') {
    return 'Project file opened.';
  }
  return status; // Keep errors, pending changes and action-required feedback visible.
}
