import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'editors.dart';
import 'models.dart';
import 'store.dart';
import 'ai_widgets.dart';
import 'ai_service.dart';
import 'project_transfer_widgets.dart';
import 'room_photos.dart';
import 'colour_palette_widgets.dart';
import 'room_draft.dart';
import 'design_style_widgets.dart';
import 'design_styles.dart';

Future<Uint8List?> pickRoomImage(
  BuildContext context, {
  bool camera = false,
}) async {
  try {
    final file = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
    );
    if (file == null) return null;
    final data = await file.readAsBytes();
    if (data.lengthInBytes > 18 * 1024 * 1024) {
      if (context.mounted) {
        notice(
          context,
          'Please choose an image smaller than 18 MB for this prototype.',
        );
      }
      return null;
    }
    return data;
  } catch (error) {
    if (context.mounted) notice(context, 'Image selection failed: $error');
    return null;
  }
}

void notice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<String?> askText(
  BuildContext context, {
  required String title,
  String hint = '',
  String initial = '',
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(title: title, hint: hint, initial: initial),
  );
  return result == null || result.trim().isEmpty ? null : result.trim();
}

class _NameDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String initial;
  const _NameDialog({
    required this.title,
    required this.hint,
    required this.initial,
  });

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: controller,
      autofocus: true,
      maxLength: 80,
      decoration: InputDecoration(
        labelText: widget.hint.isEmpty ? 'Name' : widget.hint,
      ),
      onSubmitted: (value) => Navigator.pop(context, value.trim()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, controller.text.trim()),
        child: const Text('Save'),
      ),
    ],
  );
}

class AppShell extends StatefulWidget {
  final RenovisionStore store;
  const AppShell({super.key, required this.store});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ExploreTab(
        store: widget.store,
        openProjects: () => setState(() => selected = 1),
      ),
      ProjectsTab(store: widget.store),
      LibraryTab(store: widget.store),
      SettingsTab(store: widget.store),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.home_work_outlined),
            SizedBox(width: 10),
            Text('Renovision AI'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                'PROTOTYPE',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ],
      ),
      body: tabs[selected],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => setState(() => selected = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Library',
          ),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  final List<Widget> children;
  const PageFrame({super.key, required this.children});
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 950),
      child: ListView(padding: const EdgeInsets.all(20), children: children),
    ),
  );
}

class EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String explanation;
  final Widget? action;
  const EmptyMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.explanation,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(explanation, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}

class ProjectsTab extends StatelessWidget {
  final RenovisionStore store;
  const ProjectsTab({super.key, required this.store});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => PageFrame(
      children: [
        Text(
          'My renovation projects',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text('Your photos, designs and decisions stay on this device.'),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () async {
              final name = await askText(
                context,
                title: 'New project',
                hint: 'For example: Claylands',
              );
              if (name != null) await store.createProject(name);
            },
            icon: const Icon(Icons.add),
            label: const Text('Create project'),
          ),
        ),
        const SizedBox(height: 16),
        RestoreProjectButton(
          store: store,
          onRestored: (project) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectScreen(store: store, project: project),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Saved in this browser/device. Open a project to back it up, or a room to download an image.',
        ),
        const SizedBox(height: 16),
        if (store.projects.isEmpty)
          const EmptyMessage(
            icon: Icons.home_outlined,
            title: 'Start with your first house',
            explanation: 'Create a project, add a room and import its original photograph.',
          )
        else
          ...store.projects.map(
            (project) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.home_outlined)),
                title: Text(project.name),
                subtitle: Text('${store.roomsFor(project.id).length} rooms'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProjectScreen(store: store, project: project),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class ProjectScreen extends StatelessWidget {
  final RenovisionStore store;
  final RenovationProject project;
  const ProjectScreen({super.key, required this.store, required this.project});

  Future<void> _rename(BuildContext context) async {
    final current = store.projectById(project.id);
    if (current == null) return;
    final name = await askText(
      context,
      title: 'Rename project',
      initial: current.name,
    );
    if (name == null) return;
    try {
      await store.renameProject(project.id, name);
      if (context.mounted) notice(context, 'Project name saved.');
    } catch (_) {
      if (context.mounted) {
        notice(
          context,
          'Could not save the new project name. Please try again.',
        );
      }
    }
  }

  Future<void> _addRoom(BuildContext context, {bool camera = false}) async {
    final name = await askText(
      context,
      title: 'Add a room',
      hint: 'Kitchen, office, exterior…',
    );
    if (name == null || !context.mounted) return;
    try {
      final single = camera ? await pickRoomImage(context, camera: true) : null;
      final images = camera
          ? (single == null ? null : [single])
          : await selectRoomPhotos(remaining: 6);
      if (images == null || !context.mounted) return;
      final paletteId = await chooseColourPalette(context, photos: images);
      if (paletteId == null || !context.mounted) return;
      final room = await store.createRoom(
        projectId: project.id,
        name: name,
        originalImage: images.first,
        additionalImages: images.skip(1).toList(),
        colourPaletteId: paletteId,
      );
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkspaceScreen(store: store, roomId: room.id),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        notice(
          context,
          error is ArgumentError
              ? '${error.message}'
              : 'Room could not be saved. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: ListenableBuilder(
        listenable: store,
        builder: (context, _) =>
            Text(store.projectById(project.id)?.name ?? project.name),
      ),
      actions: [
        IconButton(
          tooltip: 'Rename project',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _rename(context),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) => PageFrame(
        children: [
          Text(
            'Rooms and spaces',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Select several photos of the same room when importing, or add more angles later. Originals are preserved; designs are stored separately.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _addRoom(context),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Import room photo'),
              ),
              if (!kIsWeb)
                OutlinedButton.icon(
                  onPressed: () => _addRoom(context, camera: true),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Take photo'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          ProjectBackupCard(
            store: store,
            project: store.projectById(project.id) ?? project,
          ),
          const SizedBox(height: 18),
          if (store.roomsFor(project.id).isEmpty)
            const EmptyMessage(
              icon: Icons.photo_library_outlined,
              title: 'No rooms added yet',
              explanation:
                  'Add one of your original Claylands before photographs.',
            )
          else
            ...store
                .roomsFor(project.id)
                .map(
                  (room) => Card(
                    child: ListTile(
                      leading: PhotoThumb(
                        bytes: store.imageFor(room.originalId),
                      ),
                      title: Text(room.name),
                      subtitle: Text(
                        '${room.photoIds.length} photos · ${store.designsFor(room.id).length} design versions',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkspaceScreen(store: store, roomId: room.id),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    ),
  );
}

class PhotoThumb extends StatelessWidget {
  final Uint8List? bytes;
  final double width;
  final double height;
  const PhotoThumb({
    super.key,
    required this.bytes,
    this.width = 72,
    this.height = 64,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: width,
      height: height,
      child: bytes == null
          ? const ColoredBox(
              color: Color(0xFFE5E9E7),
              child: Icon(Icons.broken_image_outlined),
            )
          : Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true),
    ),
  );
}

class ExploreTab extends StatelessWidget {
  final RenovisionStore store;
  final VoidCallback openProjects;
  const ExploreTab({
    super.key,
    required this.store,
    required this.openProjects,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final pending = store.allDesigns
          .where((d) => !d.favourite && !d.rejected)
          .toList();
      return PageFrame(
        children: [
          Text(
            'Explore renovation ideas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Review your generated and imported designs. Swipe right to save, or left to reject; the original photo is never affected.',
          ),
          const SizedBox(height: 16),
          if (pending.isEmpty)
            EmptyMessage(
              icon: Icons.auto_awesome,
              title: 'Your ideas will appear here',
              explanation: 'Create a room, then generate a design in its workspace or import a result made elsewhere.',
              action: FilledButton(
                onPressed: openProjects,
                child: const Text('Open projects'),
              ),
            )
          else
            ...pending.take(5).map((d) {
              final bytes = store.imageFor(d.imageId);
              return Dismissible(
                key: ValueKey(d.id),
                direction: DismissDirection.horizontal,
                background: Container(
                  alignment: Alignment.centerLeft,
                  color: Colors.green.shade100,
                  padding: const EdgeInsets.all(20),
                  child: const Icon(Icons.favorite),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.all(20),
                  child: const Icon(Icons.close),
                ),
                onDismissed: (direction) => store.rateDesign(
                  d,
                  keep: direction == DismissDirection.startToEnd,
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (bytes != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              bytes,
                              height: 230,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => store.rateDesign(d, keep: false),
                              icon: const Icon(Icons.close),
                              label: const Text('Pass'),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: () => store.rateDesign(d, keep: true),
                              icon: const Icon(Icons.favorite_border),
                              label: const Text('Save idea'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      );
    },
  );
}

class LibraryTab extends StatelessWidget {
  final RenovisionStore store;
  const LibraryTab({super.key, required this.store});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final saved = store.allDesigns.where((d) => d.favourite).toList();
      return PageFrame(
        children: [
          Text(
            'Favourite designs',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your saved ideas remain associated with their original room.',
          ),
          const SizedBox(height: 16),
          if (saved.isEmpty)
            const EmptyMessage(
              icon: Icons.favorite_outline,
              title: 'No favourites yet',
              explanation: 'Save a design in Explore or a room workspace.',
            )
          else
            ...saved.map((d) {
              final room = store.roomById(d.roomId);
              return Card(
                child: ListTile(
                  leading: PhotoThumb(bytes: store.imageFor(d.imageId)),
                  title: Text(d.title),
                  subtitle: Text(room?.name ?? 'Room'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: room == null
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkspaceScreen(
                              store: store,
                              roomId: room.id,
                              initialDesignId: d.id,
                            ),
                          ),
                        ),
                ),
              );
            }),
        ],
      );
    },
  );
}

class SettingsTab extends StatelessWidget {
  final RenovisionStore store;
  const SettingsTab({super.key, required this.store});
  @override
  Widget build(BuildContext context) => PageFrame(
    children: [
      Text(
        'Settings and privacy',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      const Card(
        child: ListTile(
          leading: Icon(Icons.phonelink_lock_outlined),
          title: Text('Local-first prototype'),
          subtitle: Text(
            'Projects and images are saved in this device/browser profile. Optional in-app AI sends your selected photo and prompt to OpenAI only after you confirm an edit.',
          ),
        ),
      ),
      const Card(
        child: ListTile(
          leading: Icon(Icons.language_outlined),
          title: Text('Browser storage warning'),
          subtitle: Text(
            'Browser storage can be cleared. Use Back up project inside each project and check the downloaded file. Restore backups from Projects. Keep original photos separately too.',
          ),
        ),
      ),
      AiConnectionCard(ai: store.ai),
      const Card(
        child: ListTile(
          leading: Icon(Icons.generating_tokens_outlined),
          title: Text('Manual AI handoff is also available'),
          subtitle: Text(
            'Copy a carefully scoped prompt, then upload the relevant photo or marked reference in your existing AI provider app. Import its output as a new design version.',
          ),
        ),
      ),
      const Card(
        child: ListTile(
          leading: Icon(Icons.shield_outlined),
          title: Text('Before public release'),
          subtitle: Text(
            'Add robust backups, encrypted local storage where appropriate, secure API integration, a privacy policy, testing and purchase verification.',
          ),
        ),
      ),
    ],
  );
}

class WorkspaceScreen extends StatefulWidget {
  final RenovisionStore store;
  final String roomId;
  final String? initialDesignId;
  const WorkspaceScreen({
    super.key,
    required this.store,
    required this.roomId,
    this.initialDesignId,
  });
  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen>
    with WidgetsBindingObserver {
  late final RoomDraft draft;
  TextEditingController get changes => draft.changes;
  TextEditingController get protected => draft.protected;
  String? selectedId;
  bool get precise => draft.preciseEdit;
  String provider = 'ChatGPT';
  late String selectedPhotoId;
  bool includeRoomContext = true;

  Future<void> _renameRoom() async {
    final current = widget.store.roomById(widget.roomId);
    if (current == null) return;
    final name = await askText(
      context,
      title: 'Rename room',
      initial: current.name,
    );
    if (name == null) return;
    try {
      await widget.store.renameRoom(widget.roomId, name);
      if (mounted) notice(context, 'Room name saved.');
    } catch (_) {
      if (mounted) {
        notice(context, 'Could not save the new room name. Please try again.');
      }
    }
  }

  Future<void> _reviewVersion(DesignVersion design, String action) async {
    try {
      if (action == 'review') {
        await widget.store.returnToReview(design.id);
      } else {
        await widget.store.rateDesign(design, keep: false);
      }
      if (mounted) {
        notice(
          context,
          action == 'review' ? 'Design returned to Explore for review.' : 'Design marked as passed. The image is kept in version history.',
        );
      }
    } catch (_) {
      if (mounted) {
        notice(context, 'Could not save the review status. Please try again.');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final room = widget.store.roomById(widget.roomId)!;
    draft = RoomDraft(widget.store, room);
    WidgetsBinding.instance.addObserver(this);
    selectedId = widget.initialDesignId ?? room.approvedDesignId;
    selectedPhotoId = room.primaryId;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    draft.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && draft.dirty) {
      draft.save();
    }
  }

  Future<bool> _save() async {
    final saved = await draft.save();
    if (mounted) {
      notice(
        context,
        saved
            ? 'Room preferences saved locally.'
            : 'Save failed. Keep this screen open and try again.',
      );
    }
    return saved;
  }

  String _prompt(RenovationRoom room) =>
      buildRenovationPrompt(
        roomName: room.name,
        instructions: changes.text,
        protectedFeatures: protected.text,
        preciseEdit: precise,
        colourPaletteId: room.colourPaletteId,
        designStyleIds: draft.styleIds.toList(),
        otherStyle: draft.otherStyle.text,
        keepLayout: draft.keepLayout,
      ) +
      (includeRoomContext && room.photoIds.length > 1
          ? '\nMULTIPLE VIEWS OF THE SAME ROOM: Image 1 is the working image and defines the output camera viewpoint and any approved design. Remaining images show other angles for spatial context. Consolidate the room details across these views; do not make a collage, duplicate furniture or invent unseen geometry. Do not use older reference furnishings to undo approved changes in image 1. If views conflict, prioritise image 1. Produce one design from its viewpoint, not a verified 3D reconstruction.'
          : '');

  Uint8List? _activeImage(RenovationRoom room) {
    if (selectedId != null) {
      for (final d in widget.store.designsFor(room.id)) {
        if (d.id == selectedId) return widget.store.imageFor(d.imageId);
      }
    }
    return widget.store.imageFor(selectedPhotoId);
  }

  AiEditRequest _aiRequest(RenovationRoom room) {
    var sourceId = selectedPhotoId;
    if (selectedId != null) {
      final selected = widget.store
          .designsFor(room.id)
          .where((d) => d.id == selectedId);
      if (selected.isEmpty) {
        throw const AiFailure(
          'The selected version is unavailable. Select another image.',
        );
      }
      sourceId = selected.first.imageId;
    }
    final image = widget.store.imageFor(sourceId);
    if (image == null) {
      throw const AiFailure('The selected image is unavailable.');
    }
    return AiEditRequest(
      roomId: room.id,
      parentId: selectedId,
      sourceImageId: sourceId,
      image: image,
      supportingImages: {
        if (includeRoomContext && room.photoIds.length > 1)
          for (final id in room.photoIds.where((id) => id != sourceId))
            id:
                widget.store.imageFor(id) ??
                (throw const AiFailure('A room context photo is unavailable.')),
      },
      prompt: _prompt(room),
      instructions: changes.text,
      precise: precise,
      title: precise ? 'AI precision edit' : 'AI renovation concept',
    );
  }

  Future<void> _copyPrompt(RenovationRoom room) async {
    if (precise && changes.text.trim().isEmpty) {
      notice(
        context,
        'Describe the specific change before copying a precision prompt.',
      );
      return;
    }
    if (!await _save()) return;
    await Clipboard.setData(ClipboardData(text: _prompt(room)));
    if (mounted) {
      notice(
        context,
        'Prompt copied. Open $provider, attach the selected image and paste the prompt.',
      );
    }
  }

  Future<void> _approveBaseline(RenovationRoom room) async {
    try {
      await widget.store.approveBaseline(room.id, designId: selectedId);
      if (mounted) {
        notice(
          context,
          'Approved baseline saved. This image will open when you return to the room.',
        );
      }
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'Could not save the baseline. Your existing images are unchanged. Please try again.',
        );
      }
    }
  }

  Future<void> _importResult(RenovationRoom room) async {
    final bytes = await pickRoomImage(context);
    if (bytes == null || !mounted) return;
    final title = await askText(
      context,
      title: 'Title this AI design',
      hint: 'e.g. Office — charcoal cabinets',
    );
    if (title == null) return;
    final d = await widget.store.createDesign(
      roomId: room.id,
      image: bytes,
      title: title,
      prompt: _prompt(room),
      parentId: selectedId,
    );
    if (mounted) setState(() => selectedId = d.id);
  }

  Future<void> _editReference(
    RenovationRoom room, {
    required bool sketch,
  }) async {
    final bytes = _activeImage(room);
    if (bytes == null) return;
    final edited = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => FocusEditScreen(bytes: bytes, sketch: sketch),
      ),
    );
    if (edited == null || !mounted) return;
    final newVersion = await widget.store.createDesign(
      roomId: room.id,
      image: edited,
      title: sketch ? 'Annotated reference' : 'Focus crop',
      prompt: _prompt(room),
      parentId: selectedId,
    );
    if (mounted) setState(() => selectedId = newVersion.id);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.store, draft]),
    builder: (context, _) {
      final room = widget.store.roomById(widget.roomId)!;
      final versions = widget.store.designsFor(room.id);
      final source = _activeImage(room);
      return PopScope(
        canPop: !draft.dirty,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final saved = await draft.save();
          if (saved && !draft.dirty && context.mounted) {
            Navigator.pop(context);
          } else if (!saved && context.mounted) {
            notice(
              context,
              'Save failed. Stay on this screen and retry saving.',
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(room.name),
            actions: [
              IconButton(
                tooltip: 'Rename room',
                icon: const Icon(Icons.edit_outlined),
                onPressed: _renameRoom,
              ),
            ],
          ),
          body: PageFrame(
            children: [
              Text(
                'Design workspace',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a working image, make a reference, then compare your saved versions. Your original stays untouched.',
              ),
              const SizedBox(height: 14),
              RoomColourPaletteCard(
                store: widget.store,
                room: room,
                preview: source,
              ),
              const SizedBox(height: 14),
              RoomPhotosCard(
                store: widget.store,
                room: room,
                selectedPhotoId: selectedId == null ? selectedPhotoId : null,
                onView: (id) => setState(() {
                  selectedId = null;
                  selectedPhotoId = id;
                }),
                includeContext: includeRoomContext,
                onContextChanged: (value) =>
                    setState(() => includeRoomContext = value),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey(selectedId ?? selectedPhotoId),
                        initialValue:
                            selectedId ??
                            (selectedPhotoId == room.originalId
                                ? null
                                : 'photo:$selectedPhotoId'),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Working from',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Original photograph — locked'),
                          ),
                          ...room.additionalPhotoIds.map(
                            (id) => DropdownMenuItem<String>(
                              value: 'photo:$id',
                              child: Text(
                                'Room photo · View ${room.photoIds.indexOf(id) + 1}',
                              ),
                            ),
                          ),
                          ...versions.map(
                            (v) => DropdownMenuItem<String>(
                              value: v.id,
                              child: Text(
                                v.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (id) => setState(() {
                          if (id == null || id.startsWith('photo:')) {
                            selectedId = null;
                            selectedPhotoId = id == null
                                ? room.originalId
                                : id.substring(6);
                          } else {
                            selectedId = id;
                          }
                        }),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.lock_outline, size: 18),
                            label: Text(
                              selectedId == null
                                  ? (selectedPhotoId == room.originalId
                                        ? 'Original photo'
                                        : 'Room photo')
                                  : 'Saved version',
                            ),
                          ),
                          if (selectedId == room.approvedDesignId &&
                              (selectedId != null ||
                                  selectedPhotoId == room.originalId))
                            const Chip(
                              avatar: Icon(Icons.verified_outlined, size: 18),
                              label: Text('Approved baseline'),
                            ),
                          Chip(label: Text('${versions.length} versions')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedId == room.approvedDesignId &&
                                (selectedId != null ||
                                    selectedPhotoId == room.originalId)
                            ? 'Working from the approved baseline.'
                            : 'Viewing another image. Your approved baseline is unchanged.',
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed:
                                selectedId == room.approvedDesignId ||
                                    (selectedId == null &&
                                        selectedPhotoId != room.originalId)
                                ? null
                                : () => _approveBaseline(room),
                            icon: const Icon(Icons.verified_outlined),
                            label: const Text('Approve as baseline'),
                          ),
                          OutlinedButton(
                            onPressed:
                                selectedId == room.approvedDesignId &&
                                    (selectedId != null ||
                                        selectedPhotoId == room.originalId)
                                ? null
                                : () => setState(() {
                                    selectedId = room.approvedDesignId;
                                    selectedPhotoId = room.originalId;
                                  }),
                            child: const Text('Return to approved baseline'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (source != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 320,
                            width: double.infinity,
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 5,
                              child: Image.memory(source, fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (source != null)
                            DownloadImageButton(
                              files: widget.store.files,
                              bytes: source,
                              name:
                                  '${room.name}-${selectedId == null ? 'view-${room.photoIds.indexOf(selectedPhotoId) + 1}' : versions.firstWhere((d) => d.id == selectedId).title}',
                            ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _editReference(room, sketch: false),
                            icon: const Icon(Icons.crop),
                            label: const Text('Crop / focus'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _editReference(room, sketch: true),
                            icon: const Icon(Icons.draw_outlined),
                            label: const Text('Sketch / markup'),
                          ),
                          OutlinedButton.icon(
                            onPressed: selectedId == null
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CompareScreen(
                                          original: widget.store.imageFor(
                                            room.originalId,
                                          )!,
                                          edited: source!,
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.compare),
                            label: const Text('Compare original'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'AI instructions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Semantics(liveRegion: true, child: Text(draft.status)),
              const SizedBox(height: 10),
              DesignStyleControls(draft: draft),
              const SizedBox(height: 8),
              const Text(
                'Precision mode currently prepares instructions and reference images. It does not enforce a mask or guarantee that an external AI preserves other areas.',
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Precision edit')),
                  ButtonSegment(value: false, label: Text('Explore ideas')),
                ],
                selected: {precise},
                onSelectionChanged: (v) => draft.setPrecise(v.first),
              ),
              if (precise && looksLikeBroadRenovation(changes.text)) ...[
                const SizedBox(height: 8),
                const Text(
                  'This request mentions several room elements. Explore ideas may fit a coordinated renovation better than Precision edit.',
                ),
                TextButton(
                  onPressed: () => draft.setPrecise(false),
                  child: const Text('Switch to Explore ideas'),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: changes,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'What should change?',
                  hintText: 'Remove only the fireplace; add dark joinery',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: protected,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Keep exactly as is',
                  hintText: 'Rear windows, ceiling, doorway, room proportions',
                ),
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('Preview prepared prompt'),
                subtitle: const Text(
                  'Prepared from your choices on this device; not AI-written yet.',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(_prompt(room)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                initiallyExpanded: widget.store.ai.connected,
                title: const Text('AI generation (optional)'),
                subtitle: const Text(
                  'You can work with photos and versions without a key.',
                ),
                children: [
                  AiEditCard(
                    store: widget.store,
                    buildRequest: () => _aiRequest(room),
                    onSaved: (design) {
                      if (mounted) setState(() => selectedId = design.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save instructions'),
                  ),
                  DropdownButton<String>(
                    value: provider,
                    items: ['ChatGPT', 'Gemini']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (s) => setState(() => provider = s!),
                  ),
                  FilledButton.icon(
                    onPressed: () => _copyPrompt(room),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy AI prompt'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Alternatively, copy the prompt and attach your selected photo in ChatGPT/Gemini yourself, then import the result below. Manual handoff does not call the API.',
              ),
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                onPressed: () => _importResult(room),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Import generated AI result'),
              ),
              const SizedBox(height: 22),
              Text(
                'Version history',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'All versions are kept, including passed ideas. Use the review menu to return a design to Explore. Favourites and baseline approval are separate choices.',
              ),
              const SizedBox(height: 10),
              if (versions.isEmpty)
                const Text(
                  'No design versions yet — the original photograph is safe.',
                )
              else
                ...versions.map(
                  (d) => Card(
                    child: ListTile(
                      selected: d.id == selectedId,
                      leading: PhotoThumb(
                        bytes: widget.store.imageFor(d.imageId),
                      ),
                      title: Text(
                        d.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${d.id == room.approvedDesignId ? 'Approved baseline • ' : ''}${d.favourite
                            ? 'Favourite'
                            : d.rejected
                            ? 'Passed'
                            : 'Awaiting review'}\n${d.parentId == null ? 'From original' : 'Branched version'} • ${d.created.toLocal().toString().substring(0, 16)}',
                      ),
                      onTap: () => setState(() => selectedId = d.id),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: d.favourite
                                ? 'Remove favourite'
                                : 'Save favourite',
                            icon: Icon(
                              d.favourite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: d.favourite ? Colors.red : null,
                            ),
                            onPressed: () => widget.store.setFavourite(
                              d,
                              favourite: !d.favourite,
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Review options for ${d.title}',
                            onSelected: (action) => _reviewVersion(d, action),
                            itemBuilder: (_) => [
                              if (!d.rejected)
                                const PopupMenuItem(
                                  value: 'pass',
                                  child: Text('Mark as passed'),
                                ),
                              if (d.rejected || d.favourite)
                                const PopupMenuItem(
                                  value: 'review',
                                  child: Text('Return to review'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      );
    },
  );
}
