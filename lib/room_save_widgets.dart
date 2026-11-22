import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import 'file_transfer.dart';
import 'models.dart';
import 'project_backup.dart';
import 'project_transfer_widgets.dart';
import 'room_draft.dart';
import 'store.dart';
import 'context_help.dart';
import 'screen_toolbar.dart';

class AutosaveSwitch extends StatelessWidget {
  final RenovisionStore store;
  final bool enabled;
  const AutosaveSwitch({super.key, required this.store, this.enabled = true});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Autosave',
          style: TextStyle(
            fontSize: 12,
            color:
                Theme.of(context).appBarTheme.foregroundColor ??
                Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 4),
        Switch.adaptive(
          key: const ValueKey('visible-autosave-switch'),
          activeTrackColor: const Color(0xFF2E7D32),
          activeThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFF757575),
          inactiveThumbColor: Colors.white,
          value: store.autosaveEnabled,
          onChanged: !enabled
              ? null
              : (value) async {
                  try {
                    await store.setAutosaveEnabled(value);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          persist: false,
                          content: Text('Autosave setting could not be saved.'),
                          duration: Duration(seconds: 4),
                          showCloseIcon: true,
                        ),
                      );
                    }
                  }
                },
        ),
      ],
    ),
  );
}

ScreenTool autosaveMenuTool(
  BuildContext context,
  RenovisionStore store, {
  bool enabled = true,
}) => ScreenTool(
  ScreenAction.autosave,
  label: 'Autosave',
  menuOnly: true,
  checked: store.autosaveEnabled,
  onPressed: !enabled
      ? null
      : () async {
          try {
            await store.setAutosaveEnabled(!store.autosaveEnabled);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  persist: false,
                  content: Text(
                    'Could not change Autosave. Its previous setting is still active.',
                  ),
                ),
              );
            }
          }
        },
);

class RoomSaveControls extends StatefulWidget {
  final RenovisionStore store;
  final RoomDraft draft;
  final Uint8List? Function() activeImage;
  final Future<void> Function() saveAndClose;
  final Future<String?> Function(String title, String initial) askName;
  final ValueChanged<RenovationProject> onProjectCopy;
  final bool aiPending;
  final bool autosaveOnly;
  const RoomSaveControls({
    super.key,
    required this.store,
    required this.draft,
    required this.activeImage,
    required this.saveAndClose,
    required this.askName,
    required this.onProjectCopy,
    this.aiPending = false,
    this.autosaveOnly = false,
  });
  @override
  State<RoomSaveControls> createState() => _RoomSaveControlsState();
}

class _RoomSaveControlsState extends State<RoomSaveControls> {
  bool busy = false;
  String? message;
  Future<void> _toggle(bool value) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await widget.store.setAutosaveEnabled(value);
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Could not save the Autosave setting. Its previous setting is still active.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> _saveDraft() async {
    final saved = await widget.draft.save();
    if (!saved || widget.draft.dirty) {
      if (mounted) {
        setState(
          () => message = saved
              ? 'More edits arrived while saving. Use Save now again before making a copy.'
              : 'Saving failed. Keep this room open and use Save now to retry.',
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _saveNow() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (await _saveDraft() && mounted) {
        final room = widget.store.roomById(widget.draft.roomId)!;
        if (widget.store.documents.linked(room.projectId)) {
          await widget.store.documents.save(room.projectId);
        }
        if (mounted) {
          setState(
            () => message = widget.store.documents.linked(room.projectId)
                ? 'Saved locally and to the project file.'
                : 'Saved locally. Use Save project to keep a portable file.',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Project file could not be saved. Local work is retained; retry Save project.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _saveAs(String action) async {
    if (busy || widget.aiPending) return;
    final room = widget.store.roomById(widget.draft.roomId)!;
    final project = widget.store.projectById(room.projectId)!;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final name = await widget.askName(
        action == 'copy'
            ? 'Name duplicate project'
            : action == 'image'
            ? 'Save image as'
            : 'Save project backup as',
        action == 'image' ? room.name : '${project.name} copy',
      );
      if (name == null || !mounted) return;
      if (action == 'copy') {
        if (!await _saveDraft()) return;
        final copy = await widget.store.restoreBackup(
          widget.store.backupFor(project.id),
          projectName: name,
        );
        if (mounted) widget.onProjectCopy(copy);
        return;
      }
      // Ask for the destination directly after the user's dialog action, before
      // async storage/encoding can consume browser transient activation.
      final destination = await chooseSaveDestination(
        widget.store.files,
        name: action == 'image'
            ? '${exportName(name)}.png'
            : '${exportName(name)}.renovision.json',
        mimeType: action == 'image' ? 'image/png' : 'application/json',
      );
      if (destination == null) {
        if (mounted) setState(() => message = 'Save cancelled.');
        return;
      }
      if (!await _saveDraft()) return;
      final image = action == 'image' ? widget.activeImage() : null;
      if (action == 'image' && image == null) {
        throw const BackupFailure('Select an image to save.');
      }
      final bytes = action == 'image'
          ? pngExportBytes(image!)
          : widget.store.backupFor(project.id).encode();
      final result = await destination.write(bytes);
      if (mounted) setState(() => message = saveMessage(result));
    } catch (error) {
      if (mounted) {
        setState(
          () => message = error is BackupFailure ? error.message : 'Save as could not finish. Your existing project and images are retained.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.draft,
    builder: (context, _) {
      if (widget.autosaveOnly) {
        return Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.save_outlined, size: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                'Autosave ${widget.draft.autosaveEnabled ? 'on' : 'off'} · ${widget.draft.status}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const HelpIcon(
              title: 'Autosave',
              message: 'Autosave keeps room choices and instructions on this device, and updates a connected project file. Added photos and completed designs save separately. Leaving a room also saves pending edits. Use the visible Autosave switch above the workspace; Room settings contains Save now and file options. AI keys are separate.',
            ),
            if (widget.aiPending)
              const Text(
                'AI work is pending. Keep this room open until its result is saved.',
              ),
          ],
        );
      }
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Row(
                  children: [
                    Expanded(child: Text('Autosave')),
                    HelpIcon(
                      title: 'Autosave',
                      message: 'Autosave writes room choices and instructions to this device after a short pause, and updates a connected project file. Added photos and completed designs save separately, even with Autosave off. Leaving a room saves pending edits too. Save project creates your portable working file; Open project reconnects it after a browser restart. AI keys are stored separately and excluded from project files.',
                    ),
                  ],
                ),
                subtitle: Text(
                  widget.draft.autosaveEnabled
                      ? 'On · saves edits after a short pause'
                      : widget.autosaveOnly
                      ? 'Off · use Save now in room Settings'
                      : 'Off · use Save now while editing',
                ),
                value: widget.draft.autosaveEnabled,
                onChanged: busy ? null : _toggle,
              ),
              const SizedBox(height: 8),
              Semantics(liveRegion: true, child: Text(widget.draft.status)),
              if (widget.aiPending)
                const Text(
                  'AI work or a received result is pending. Finish it or retry saving its result before leaving or making a copy.',
                ),
              const SizedBox(height: 8),
              if (!widget.autosaveOnly)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: busy || widget.aiPending ? null : _saveNow,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(busy ? 'Saving…' : 'Save now'),
                    ),
                    OutlinedButton(
                      onPressed: busy || widget.aiPending
                          ? null
                          : widget.saveAndClose,
                      child: const Text('Save and close'),
                    ),
                    PopupMenuButton<String>(
                      enabled: !busy && !widget.aiPending,
                      onSelected: _saveAs,
                      tooltip: 'Copy and export options',
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'copy',
                          child: Text('Duplicate project…'),
                        ),
                        PopupMenuItem(
                          value: 'image',
                          enabled: widget.store.files.supported,
                          child: const Text('Image file…'),
                        ),
                        PopupMenuItem(
                          value: 'backup',
                          enabled: widget.store.files.supported,
                          child: const Text('Project backup file…'),
                        ),
                      ],
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Copy & export…'),
                      ),
                    ),
                  ],
                ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(message!),
                ),
            ],
          ),
        ),
      );
    },
  );
}
