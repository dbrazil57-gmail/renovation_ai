import 'app_notices.dart';
import 'wording_region.dart';
import 'ai_usage_widgets.dart';
import 'ai_usage.dart';
import 'design_reference_widgets.dart';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'editors.dart';
import 'project_management_widgets.dart';
import 'project_look_widgets.dart';
import 'models.dart';
import 'store.dart';
import 'ai_widgets.dart';
import 'ai_service.dart';
import 'project_transfer_widgets.dart';
import 'room_photos.dart';
import 'colour_palette_widgets.dart';
import 'design_palettes.dart';
import 'room_draft.dart';
import 'design_style_widgets.dart';
import 'design_styles.dart';
import 'room_analysis_widgets.dart';
import 'renovation_scope_widgets.dart';
import 'storage_status_widgets.dart';
import 'room_save_widgets.dart';
import 'exit_guard.dart';
import 'room_start_widgets.dart';
import 'room_starters.dart';
import 'room_prompt.dart';
import 'room_setup.dart';
import 'ai_activity_widget.dart';
import 'design_delete_widgets.dart';
import 'context_help.dart';
import 'image_viewer.dart';
import 'screen_toolbar.dart';
import 'focus_workspace.dart';
import 'room_features.dart';
import 'room_camera.dart';
import 'camera_room_view.dart';
import 'home_cover_widgets.dart';
import 'live_design_screen.dart';
import 'app_appearance_widgets.dart';
import 'storage_privacy_widgets.dart';
import 'design_recipe_widgets.dart';
import 'design_recipe.dart';
import 'feedback_widgets.dart';
import 'feedback_storage.dart';
import 'local_paint_screen.dart';
import 'local_paint.dart'
    show
        paintRefinementPrompt,
        isPaintRefinementPrompt,
        paintRefinementRequestPrompt,
        LocalFinish;
import 'brand_mark.dart';
import 'room_delete_widgets.dart';
import 'brief_readiness.dart';
import 'brief_readiness_widgets.dart';
import 'design_mode_widgets.dart';
import 'app_session.dart';

Widget roomEntry(
  RenovisionStore store,
  RenovationRoom room, {
  bool forceSetup = false,
  bool returnToWorkspace = false,
}) => room.setupComplete && !forceSetup
    ? WorkspaceScreen(store: store, roomId: room.id)
    : RoomSetupScreen(
        store: store,
        roomId: room.id,
        workspace: (designId) => WorkspaceScreen(
          store: store,
          roomId: room.id,
          initialDesignId: designId,
        ),
        settingsBuilder: (_) => settingsPage(store),
        projectBuilder: (_) => ProjectScreen(
          store: store,
          project: store.projectById(room.projectId)!,
        ),
        projectsBuilder: (_) => AppShell(store: store),
        returnToWorkspace: returnToWorkspace,
      );

Future<void> startRoomWithPhotos(
  BuildContext context,
  RenovisionStore store, {
  RenovationProject? project,
  RoomStarter? starter,
  bool? camera,
  String? initialRoomTypeId,
}) async {
  try {
    String? newProjectName;
    if (project == null) {
      newProjectName = await askText(
        context,
        title: 'Name your project',
        hint: 'e.g. My renovation',
      );
      if (newProjectName == null || !context.mounted) return;
    }
    final choice = await showDialog<RoomStartChoice>(
      context: context,
      builder: (_) => RoomStartDialog(
        starter: starter,
        initialRoomTypeId: initialRoomTypeId,
        camera: camera,
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice.method == RoomStartMethod.liveDesign) {
      final destination = project ?? await store.createProject(newProjectName!);
      if (!context.mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => LiveDesignScreen(
            store: store,
            projectId: destination.id,
            initialRoomChoice: choice,
            settingsBuilder: (_) => settingsPage(store),
            workspace: (roomId, designId) => WorkspaceScreen(
              store: store,
              roomId: roomId,
              initialDesignId: designId,
              startInPrecision: true,
            ),
          ),
        ),
      );
      return;
    }
    final useCamera = choice.method == RoomStartMethod.camera;
    final images = await selectRoomPhotos(
      remaining: 6,
      camera: useCamera,
      capture: () => captureRoomPhoto(context),
    );
    if (images == null || images.isEmpty || !context.mounted) return;
    final destination = project ?? await store.createProject(newProjectName!);
    final room = await store.createRoom(
      projectId: destination.id,
      name: choice.name,
      originalImage: images.first,
      additionalImages: images.skip(1).toList(),
      colourPaletteId: choice.starter?.paletteId ?? '',
      guidedSetup: true,
      roomTypeId: choice.roomTypeId,
      designStyleIds: choice.starter == null || choice.starter!.styleId.isEmpty
          ? []
          : [choice.starter!.styleId],
    );
    if (context.mounted) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => roomEntry(store, room)),
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

Future<void> useRoomStarter(
  BuildContext context,
  RenovisionStore store,
  RoomStarter starter,
) async {
  String? projectId;
  if (store.projects.isNotEmpty) {
    projectId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choose a project'),
        children: [
          for (final project in store.projects)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, project.id),
              child: Text(project.name),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, ''),
            child: const Text('Create a new project'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (projectId == null || !context.mounted) return;
  }
  if (!context.mounted) return;
  await startRoomWithPhotos(
    context,
    store,
    project: projectId == null || projectId.isEmpty
        ? null
        : store.projectById(projectId),
    starter: starter,
  );
}

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
  showAppNotice(context, message);
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
  final int initialTab;
  const AppShell({super.key, required this.store, this.initialTab = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int selected = widget.initialTab;

  void selectTab(int next) => setState(() {
    if (next == selected) return;
    selected = next;
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ProjectsTab(store: widget.store),
      ExploreTab(store: widget.store, openProjects: () => selectTab(0)),
      LibraryTab(store: widget.store),
    ];
    return SavedAppPage(
      page: {'page': 'home', 'tab': selected},
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              ExcludeSemantics(child: RenoVisionMark()),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'RenoVision',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            if (MediaQuery.sizeOf(context).width >= 700)
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: Text(
                    'PROTOTYPE',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ),
              ),
            ScreenToolbar(
              tools: [
                ScreenTool(
                  ScreenAction.settings,
                  label: 'Settings',
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => settingsPage(widget.store),
                    ),
                  ),
                ),
                ScreenTool.help(
                  context,
                  title: ['Projects', 'Explore ideas', 'Library'][selected],
                  message: [
                    'Create or open a project, then add rooms and photos. Project files include saved designs and choices; AI credentials stay on this device.',
                    'Browse sample designs or import your own room photos to start. Saved design ideas can be reviewed and compared in their room workspace.',
                    'Favourite designs appear here. Tap a design to open its room, or its thumbnail to view full screen.',
                  ][selected],
                ),
              ],
            ),
          ],
        ),
        body: tabs[selected],
        bottomNavigationBar: NavigationBar(
          height: MediaQuery.textScalerOf(context).scale(12) > 16 ? 80 : 64,
          selectedIndex: selected,
          onDestinationSelected: selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Projects',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Library',
            ),
          ],
        ),
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
      child: ListView(padding: const EdgeInsets.all(12), children: children),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
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

  Future<void> _start(
    BuildContext context, {
    bool? camera,
    String? roomType,
  }) async {
    RenovationProject? project;
    if (store.projects.length == 1) {
      project = store.projects.single;
    } else if (store.projects.length > 1) {
      final id = await showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Choose a project'),
          children: [
            for (final item in store.projects)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, item.id),
                child: Text(item.name),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, ''),
              child: const Text('Create a new project'),
            ),
          ],
        ),
      );
      if (id == null || !context.mounted) return;
      if (id.isNotEmpty) project = store.projectById(id);
    }
    if (!context.mounted) return;
    await startRoomWithPhotos(
      context,
      store,
      project: project,
      camera: camera,
      initialRoomTypeId: roomType,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => PageFrame(
      children: [
        FocusHomeHero(
          image: store.homeCoverImageId == null
              ? null
              : store.imageFor(store.homeCoverImageId!),
          imageAsset: store.homeCoverAsset,
          changeCover: () => chooseHomeCover(context, store),
          takePhoto: supportsRoomCamera
              ? () => _start(context, camera: true)
              : null,
          choosePhotos: () => _start(context, camera: false),
        ),
        const SizedBox(height: 12),
        if (store.resumeRoom case final room?) ...[
          Card(
            child: ListTile(
              title: Text('Continue ${room.displayName}'),
              subtitle: Text(
                '${store.projectById(room.projectId)?.name ?? ''} / saved on this device',
              ),
              trailing: const Icon(Icons.play_arrow_outlined),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => roomEntry(store, room)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text('Room type', style: Theme.of(context).textTheme.titleLarge),
        const Text('Example rooms - choose a type, then add your own photos.'),
        const SizedBox(height: 8),
        SizedBox(
          height: 112,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final sample
                  in ['kitchen', 'living', 'bedroom', 'bathroom'].map(
                    (id) => roomStarters.firstWhere(
                      (sample) => sample.roomTypeId == id,
                    ),
                  ))
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 110,
                    child: InkWell(
                      onTap: () => _start(context, roomType: sample.roomTypeId),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              sample.asset,
                              height: 76,
                              cacheWidth: 260,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Text(
                            roomTypes[sample.roomTypeId] ?? sample.roomTypeId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        HelpHeading(
          title: 'Saved projects',
          message:
              'Tap a project below to open work already saved on this device. Your photos, designs and decisions stay with it.\n\nOpen project file loads a saved .renovision.json file with its rooms, photos and design choices. Restore a separate backup copy from Settings. AI credentials stay on this device.\n\n${kIsWeb ? 'Keep using the same browser address/profile (http://localhost:7357 for local testing) to see the same saved projects.' : 'Install app updates over the existing app to keep your local work.'}',
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
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
            RestoreProjectButton(
              store: store,
              openDocument: true,
              label: 'Open project file…',
              onRestored: (project) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectScreen(store: store, project: project),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...store.projects.map(
          (project) => Card(
            child: ListTile(
              dense: true,
              leading: const CircleAvatar(child: Icon(Icons.home_outlined)),
              title: Text(store.projectLabel(project)),
              subtitle: Text('${store.roomsFor(project.id).length} rooms'),
              trailing: ProjectManagementButton(store: store, project: project),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectScreen(store: store, project: project),
                ),
              ),
            ),
          ),
        ),
        ArchivedProjects(store: store),
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
    await startRoomWithPhotos(context, store, project: project, camera: camera);
  }

  @override
  Widget build(BuildContext context) => SavedAppPage(
    page: {'page': 'project', 'projectId': project.id},
    child: Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: store,
          builder: (context, _) => Text(
            store.projectLabel(store.projectById(project.id) ?? project),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: SizedBox(
            height: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [AutosaveSwitch(store: store)]),
            ),
          ),
        ),
        actions: [
          ScreenToolbar(
            tools: [
              ScreenTool(
                ScreenAction.save,
                label: 'Save project file',
                onPressed: !store.files.supported
                    ? null
                    : () => showProjectSaveDialog(
                        context,
                        store: store,
                        projectId: project.id,
                      ),
              ),
              ScreenTool(
                ScreenAction.settings,
                label: 'Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => settingsPage(store)),
                ),
              ),
              ScreenTool(
                ScreenAction.rename,
                label: 'Rename project',
                onPressed: () => _rename(context),
              ),
              ScreenTool.help(
                context,
                title: 'Project tools',
                message: 'Rooms, original photos and saved designs are kept on this device. You do not need to save again just to open a project. Use Save for a portable project file or to update a linked file. Settings contains saving and AI options. Rename changes the project name without changing rooms or images.',
              ),
            ],
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
            ListenableBuilder(
              listenable: store.documents,
              builder: (context, _) {
                final status = store.documents.status(project.id);
                if (!store.documents.hasPending(project.id) &&
                    !status.contains('failed') &&
                    !status.contains('Local work is retained')) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      status,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (supportsRoomCamera)
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveDesignScreen(
                          store: store,
                          projectId: project.id,
                          settingsBuilder: (_) => settingsPage(store),
                          workspace: (roomId, designId) => WorkspaceScreen(
                            store: store,
                            roomId: roomId,
                            initialDesignId: designId,
                            startInPrecision: true,
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Live design'),
                  ),
                if (supportsRoomCamera)
                  FilledButton.icon(
                    onPressed: () => _addRoom(context, camera: true),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Take photo'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _addRoom(context),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose photos'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Sample designs')),
                        body: PageFrame(
                          children: [
                            InspirationGallery(
                              onUse: (starter) => startRoomWithPhotos(
                                context,
                                store,
                                project: project,
                                starter: starter,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.collections_outlined),
                  label: const Text('Browse sample designs'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (store.deletedRoomsFor(project.id).isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.restore_from_trash_outlined),
                label: Text(
                  'Deleted rooms (${store.deletedRoomsFor(project.id).length})',
                ),
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DeletedRoomsScreen(store: store, projectId: project.id),
                  ),
                ),
              ),
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
                        title: Text(room.displayName),
                        subtitle: Text(
                          '${room.photoIds.length} photos · ${store.designsFor(room.id).length} design versions'
                          '${room.setupComplete ? '' : '\nContinue setup · step ${room.setupStep + 1} of 4'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DeleteRoomButton(
                              key: ValueKey('delete-room-${room.id}'),
                              store: store,
                              room: room,
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => roomEntry(store, room),
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    ),
  );
}

class PhotoThumb extends StatelessWidget {
  final Uint8List? bytes;
  final double width;
  final double height;
  final String? viewerTitle;
  const PhotoThumb({
    super.key,
    required this.bytes,
    this.width = 72,
    this.height = 64,
    this.viewerTitle,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: bytes == null
            ? const ColoredBox(
                color: Color(0xFFE5E9E7),
                child: Icon(Icons.broken_image_outlined),
              )
            : Image.memory(
                bytes!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: 600,
                frameBuilder: (context, child, frame, synchronous) =>
                    synchronous || frame != null
                    ? child
                    : const Center(child: Text('Loading…')),
              ),
      ),
    );
    if (bytes == null || viewerTitle == null) return thumbnail;
    return InkWell(
      onTap: () => openImageViewer(context, bytes!, title: viewerTitle!),
      child: Semantics(
        button: true,
        label: 'View $viewerTitle full screen',
        child: thumbnail,
      ),
    );
  }
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
                            child: ExpandableImage(
                              bytes: bytes,
                              title: d.title,
                              height: 230,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
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
                            DeleteDesignButton(store: store, design: d),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
          InspirationGallery(
            onUse: (starter) => useRoomStarter(context, store, starter),
          ),
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
      return LayoutBuilder(
        builder: (context, available) {
          final columns = available.maxWidth >= 740 ? 2 : 1;
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
                for (var row = 0; row < saved.length; row += columns)
                  LayoutBuilder(
                    builder: (context, bounds) {
                      final width =
                          (bounds.maxWidth - 12 * (columns - 1)) / columns;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (
                              var index = row;
                              index < row + columns;
                              index++
                            ) ...[
                              if (index > row) const SizedBox(width: 12),
                              Expanded(
                                child: index >= saved.length
                                    ? const SizedBox.shrink()
                                    : Builder(
                                        builder: (context) {
                                          final d = saved[index];
                                          final room = store.roomById(d.roomId);
                                          final project = room == null
                                              ? null
                                              : store.projectById(
                                                  room.projectId,
                                                );
                                          final description =
                                              '${d.title}\n${[project?.name, room?.displayName].whereType<String>().join(' / ')}';
                                          final bytes = store.imageFor(
                                            d.imageId,
                                          );
                                          void open() {
                                            if (room != null) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      WorkspaceScreen(
                                                        store: store,
                                                        roomId: room.id,
                                                        initialDesignId: d.id,
                                                      ),
                                                ),
                                              );
                                            }
                                          }

                                          return Card(
                                            key: ValueKey(
                                              'library-design-${d.id}',
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                if (bytes != null)
                                                  Tooltip(
                                                    message: description,
                                                    constraints:
                                                        const BoxConstraints(
                                                          maxWidth: 360,
                                                        ),
                                                    child: ExpandableImage(
                                                      bytes: bytes,
                                                      title: d.title,
                                                      height: (width / 1.5)
                                                          .clamp(160.0, 240.0),
                                                      showHint: false,
                                                    ),
                                                  ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      Tooltip(
                                                        message: description,
                                                        constraints:
                                                            const BoxConstraints(
                                                              maxWidth: 360,
                                                            ),
                                                        child: InkWell(
                                                          onTap: room == null
                                                              ? null
                                                              : open,
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .stretch,
                                                            children: [
                                                              Text(
                                                                d.title,
                                                                key: ValueKey(
                                                                  'library-caption-${d.id}',
                                                                ),
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: Theme.of(
                                                                  context,
                                                                ).textTheme.titleMedium,
                                                              ),
                                                              const SizedBox(
                                                                height: 4,
                                                              ),
                                                              Text(
                                                                [
                                                                      project
                                                                          ?.name,
                                                                      room?.displayName,
                                                                    ]
                                                                    .whereType<
                                                                      String
                                                                    >()
                                                                    .join(
                                                                      ' / ',
                                                                    ),
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: Theme.of(
                                                                  context,
                                                                ).textTheme.bodySmall,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 6,
                                                        children: [
                                                          OutlinedButton.icon(
                                                            onPressed:
                                                                room == null
                                                                ? null
                                                                : open,
                                                            icon: const Icon(
                                                              Icons
                                                                  .edit_outlined,
                                                            ),
                                                            label: const Text(
                                                              'Edit design',
                                                            ),
                                                          ),
                                                          DeleteDesignButton(
                                                            store: store,
                                                            design: d,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
            ],
          );
        },
      );
    },
  );
}

Widget settingsPage(
  RenovisionStore store, {
  Future<bool> Function()? beforeBackup,
  Widget? roomSaving,
}) => SavedAppPage(
  page: {'page': 'settings'},
  child: Scaffold(
    appBar: AppBar(
      title: const Text('Settings'),
      actions: [
        Builder(
          builder: (context) => ScreenToolbar(
            tools: [
              ScreenTool.help(
                context,
                title: 'Settings',
                message: 'Manage saving, project files and the AI connection. Changes save on this device. Project files keep rooms and images, but do not contain your API key.',
              ),
            ],
          ),
        ),
      ],
    ),
    body: SettingsTab(
      store: store,
      beforeBackup: beforeBackup,
      roomSaving: roomSaving,
    ),
  ),
);

class SettingsTab extends StatelessWidget {
  final RenovisionStore store;
  final Widget? roomSaving;
  final Future<bool> Function()? beforeBackup;
  const SettingsTab({
    super.key,
    required this.store,
    this.roomSaving,
    this.beforeBackup,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => PageFrame(
      children: [
        Text(
          'Settings and privacy',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        AiConnectionSettingsCard(ai: store.ai),
        ?roomSaving,
        WordingRegionSettings(store: store),
        AiUsageCard(store: store),
        HomeCoverSettingsCard(store: store),
        StoragePrivacyCard(store: store),
        FeedbackCard(drafts: LocalFeedbackDrafts(store.records)),
        AppAppearanceSettingsCard(store: store),
        Text('Save and restore', style: Theme.of(context).textTheme.titleLarge),
        const Text(
          kIsWeb
              ? 'Projects save locally in this browser/profile. Save project keeps the working file; Save project as makes another copy. Restore imports a separate project without replacing local work.'
              : 'Projects save locally in the app. Use Save project for a portable file and Open project to load one.',
        ),
        RestoreProjectButton(
          store: store,
          onRestored: (project) => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ProjectScreen(store: store, project: project),
            ),
          ),
        ),
        for (final project in store.projects) ...[
          Text(project.name, style: Theme.of(context).textTheme.titleMedium),
          ImportProjectRoomsButton(store: store, target: project),
          ProjectFileControls(
            store: store,
            projectId: project.id,
            beforeSave: beforeBackup,
          ),
          ProjectBackupCard(
            store: store,
            project: project,
            beforeSave: beforeBackup,
          ),
        ],
        StorageStatusCard(store: store),
      ],
    ),
  );
}

class WorkspaceScreen extends StatefulWidget {
  final RenovisionStore store;
  final String roomId;
  final String? initialDesignId;
  final String? initialPhotoId;
  final ValueChanged<String?>? onDesignSelected;
  final bool startInPrecision;
  final FocusSection? initialSection;
  final RoomDesignMode? initialMode;
  final int? initialFinishPanel;
  final String? initialTool;
  const WorkspaceScreen({
    super.key,
    required this.store,
    required this.roomId,
    this.initialDesignId,
    this.initialPhotoId,
    this.onDesignSelected,
    this.startInPrecision = false,
    this.initialSection,
    this.initialMode,
    this.initialFinishPanel,
    this.initialTool,
  });
  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen>
    with WidgetsBindingObserver {
  late final RoomDraft draft;
  final generation = AiEditController();
  bool analysingRoom = false;
  bool editingRoom = false;
  bool get aiPending => analysingRoom || editingRoom;
  late final PageExitGuard pageExitGuard;
  TextEditingController get changes =>
      precise ? draft.correction : draft.changes;
  bool get hasEffectiveChanges => precise
      ? draft.correction.text.trim().isNotEmpty
      : draft.hasRequestedChanges;
  TextEditingController get protected => draft.protected;
  String? selectedId;
  bool get precise => draft.preciseEdit;
  late String selectedPhotoId;
  List<String>? restoredSupportingIds;
  bool includeRoomContext = true;
  DesignVersion? get finishPreview => widget.store
      .designsFor(widget.roomId)
      .where((design) => design.id == selectedId && design.paintRecipe != null)
      .firstOrNull;
  bool get polishingFinishes =>
      precise && finishPreview != null && isPaintRefinementPrompt(changes.text);
  FocusSection focusSection = FocusSection.room;
  int focusRevealRevision = 0;
  final instructionAnchor = GlobalKey();

  void _visitSection(FocusSection next) {
    focusSection = next;
  }

  void _improveBrief(BriefTarget target) {
    setState(() {
      _visitSection(switch (target) {
        BriefTarget.room => FocusSection.room,
        BriefTarget.style || BriefTarget.palette => FocusSection.style,
        BriefTarget.refine => FocusSection.refine,
      });
      focusRevealRevision++;
    });
    if (target == BriefTarget.refine) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.microtask(() async {
          final anchor = instructionAnchor.currentContext;
          if (mounted &&
              focusSection == FocusSection.refine &&
              anchor != null &&
              anchor.mounted) {
            await Scrollable.ensureVisible(
              anchor,
              alignment: .2,
              duration: const Duration(milliseconds: 180),
            );
          }
        });
      });
    }
  }

  Future<void> _reviewBrief() async {
    final room = widget.store.roomById(widget.roomId);
    if (room == null) return;
    final readiness = draft.briefReadiness(
      imageAvailable: _activeImage(room) != null,
    );
    final action = await reviewBrief(context, readiness);
    if (!mounted) return;
    if (action == BriefReviewAction.refine) {
      _improveBrief(readiness.recommendedTarget);
    } else if (action == BriefReviewAction.proceed) {
      await _generateFromWorkspace(briefReviewed: true);
    }
  }

  Future<void> _generateFromWorkspace({bool briefReviewed = false}) async {
    if (aiPending || widget.store.ai.activity.active) return;
    if (!widget.store.ai.connected) {
      await _openSettings();
      return;
    }
    if ((precise && draft.correction.text.trim().isEmpty) ||
        (!precise && !draft.fullRenovation && !draft.hasRequestedChanges)) {
      setState(
        () => _visitSection(precise ? FocusSection.refine : FocusSection.style),
      );
      notice(
        context,
        precise
            ? 'Describe the specific correction in Refine before generating.'
            : 'Select the items to update, or describe your partial renovation in Refine.',
      );
      return;
    }
    final previousCount = widget.store.designsFor(widget.roomId).length;
    await generation.generate(briefReviewed: briefReviewed);
    if (!mounted) return;
    if (generation.needsAttention) {
      setState(() => _visitSection(FocusSection.refine));
    } else if (widget.store.designsFor(widget.roomId).length > previousCount) {
      setState(() => _visitSection(FocusSection.ideas));
    }
  }

  Widget _generationFooter() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BriefReadinessIndicator(
          readiness: draft.briefReadiness(
            imageAvailable:
                _activeImage(widget.store.roomById(widget.roomId)!) != null,
          ),
          onReview: _reviewBrief,
        ),
        if (draft.state != DraftSaveState.saved)
          Semantics(
            liveRegion: true,
            child: Text(
              draft.status,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (editingRoom && !widget.store.ai.activity.active)
          TextButton(
            onPressed: () => setState(() => _visitSection(FocusSection.refine)),
            child: const Text('Review pending result'),
          )
        else
          FilledButton.icon(
            key: const ValueKey('workspace-generate'),
            onPressed: aiPending || widget.store.ai.activity.active
                ? null
                : _generateFromWorkspace,
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              aiPending || widget.store.ai.activity.active
                  ? 'AI working…'
                  : !widget.store.ai.connected
                  ? 'Connect AI to generate'
                  : !polishingFinishes &&
                        (precise
                                ? draft.precisionConceptCount
                                : draft.conceptCount) >
                            1
                  ? 'Generate ${precise ? draft.precisionConceptCount : draft.conceptCount} ${precise ? 'variations' : 'design ideas'}'
                  : polishingFinishes && precise
                  ? 'Polish with AI'
                  : precise && selectedId != null
                  ? 'Review & generate change'
                  : 'Generate AI design',
            ),
          ),
      ],
    ),
  );

  Widget _selectedDesignLook(RenovationRoom room) {
    final saved = widget.store
        .designsFor(room.id)
        .where((design) => design.id == selectedId)
        .firstOrNull
        ?.recipe
        ?.toMap();
    final styles = saved?['designStyleIds'] is List
        ? (saved!['designStyleIds'] as List).whereType<String>().toList()
        : draft.styleIds.toList();
    final palette = paletteById(
      saved?['colourPaletteId'] as String? ?? room.colourPaletteId,
    );
    final customStyle =
        (saved?['otherStyle'] as String? ?? draft.otherStyle.text).trim();
    final styleNames = [
      for (final id in styles) designStyles[id] ?? id,
      if (customStyle.isNotEmpty) customStyle,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              saved == null
                  ? 'Current room look'
                  : 'Look saved with this design',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Style: ${styleNames.isEmpty ? 'No saved preference' : styleNames.join(', ')}',
            ),
            Text('Palette: ${palette?.name ?? 'No saved preference'}'),
            if (palette != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: 220,
                child: PaletteSwatches(palette: palette, height: 12),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton(
                  onPressed: aiPending
                      ? null
                      : () => draft.setDesignMode(RoomDesignMode.partial),
                  child: const Text('Change selected items'),
                ),
                FilledButton.tonal(
                  onPressed: aiPending
                      ? null
                      : () => draft.setDesignMode(RoomDesignMode.newDesign),
                  child: const Text('New design style'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  RoomSaveControls _savingControls({
    bool compact = false,
    BuildContext? settingsContext,
  }) => RoomSaveControls(
    store: widget.store,
    draft: draft,
    activeImage: () => _activeImage(widget.store.roomById(widget.roomId)!),
    autosaveOnly: compact,
    aiPending: aiPending,
    saveAndClose: () async {
      if (settingsContext == null) {
        await _saveAndClose();
        return;
      }
      if (await _save() && settingsContext.mounted) {
        Navigator.pop(settingsContext);
      }
    },
    askName: (title, initial) =>
        askText(settingsContext ?? context, title: title, initial: initial),
    onProjectCopy: (copy) => Navigator.pushReplacement(
      settingsContext ?? context,
      MaterialPageRoute<void>(
        builder: (_) => ProjectScreen(store: widget.store, project: copy),
      ),
    ),
  );

  Future<void> _openSettings() async {
    if (aiPending) {
      notice(
        context,
        'Finish or save the pending AI result before opening Settings.',
      );
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (settingsContext) => settingsPage(
          widget.store,
          beforeBackup: draft.save,
          roomSaving: _savingControls(settingsContext: settingsContext),
        ),
      ),
    );
  }

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

  Future<void> _openSetup() async {
    if (aiPending || !await draft.save() || !mounted) return;
    final current = widget.store.roomById(widget.roomId)!;
    try {
      await widget.store.updateRoom(current.copyWith(setupStep: 0));
      if (!mounted) return;
      final generated = await Navigator.push<String?>(
        context,
        MaterialPageRoute<String?>(
          builder: (_) => roomEntry(
            widget.store,
            widget.store.roomById(widget.roomId)!,
            forceSetup: true,
            returnToWorkspace: true,
          ),
        ),
      );
      if (!mounted) return;
      if (AppPageSessionScope.maybeOf(context) == null) {
        await _reloadSetupChoices();
      }
      if (generated != null &&
          mounted &&
          !widget.store.isDesignDeleted(generated)) {
        _selectDesign(generated, clearUpdate: true);
      }
    } catch (_) {
      if (mounted) {
        notice(context, 'Could not open guided setup. Your room is retained.');
      }
    }
  }

  Future<void> _reloadSetupChoices() async {
    if (!mounted) return;
    final saved = widget.store.roomById(widget.roomId);
    if (saved == null || saved.deleted) return;
    if (!await draft.applyRecipe(DesignRecipe(saved.toMap())) && mounted) {
      notice(
        context,
        'Setup choices are retained. Retry saving before generating.',
      );
    }
  }

  Future<void> _projectFile() async {
    if (aiPending) return;
    final current = widget.store.roomById(widget.roomId)!;
    await showProjectSaveDialog(
      context,
      store: widget.store,
      projectId: current.projectId,
      beforeSave: draft.save,
    );
  }

  Future<void> _reviewVersion(DesignVersion design, String action) async {
    if (action == 'delete') {
      if (!aiPending) await confirmDeleteDesign(context, widget.store, design);
      return;
    }
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
    pageExitGuard = createPageExitGuard(() {
      draft.save();
    });
    draft.addListener(_updateExitGuard);
    widget.store.documents.addListener(_updateExitGuard);
    WidgetsBinding.instance.addObserver(this);
    final cameraPhoto = room.photoIds.contains(widget.initialPhotoId);
    selectedId = cameraPhoto
        ? null
        : widget.initialDesignId ?? room.approvedDesignId;
    // A selected design is the new baseline: subsequent requests are updates,
    // rather than another run of its original whole-room renovation brief.
    draft.setPrecise(selectedId != null || widget.startInPrecision);
    if (widget.initialMode != null) draft.setDesignMode(widget.initialMode!);
    focusSection =
        widget.initialSection ??
        (selectedId == null ? FocusSection.room : FocusSection.refine);
    selectedPhotoId = cameraPhoto ? widget.initialPhotoId! : room.primaryId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await widget.store.rememberRoom(widget.roomId);
        if (mounted && widget.initialFinishPanel != null) {
          await _paintRoom(room, initialPanel: widget.initialFinishPanel!);
        } else if (mounted && widget.initialTool != null) {
          final tool = widget.initialTool!;
          if (tool == 'crop' || tool == 'sketch') {
            await _editReference(room, sketch: tool == 'sketch');
          } else if (tool == 'compare') {
            await _compareRoom(room);
          } else if (_activeImage(room) case final bytes?) {
            await openImageViewer(
              context,
              bytes,
              title: room.displayName,
              sessionPage: const {'page': 'tool', 'tool': 'viewer'},
            );
          }
        }
      } catch (_) {
        if (mounted) {
          notice(
            context,
            'Could not remember this room for startup. Your project is retained.',
          );
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    draft.removeListener(_updateExitGuard);
    widget.store.documents.removeListener(_updateExitGuard);
    pageExitGuard.dispose();
    draft.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        draft.dirty &&
        (draft.autosaveEnabled || state == AppLifecycleState.detached)) {
      draft.save();
    }
  }

  Future<bool> _save() async {
    final saved = await draft.save();
    final projectId = widget.store.roomById(widget.roomId)!.projectId;
    if (saved && widget.store.documents.linked(projectId)) {
      try {
        await widget.store.documents.save(projectId);
      } catch (_) {
        if (mounted) {
          notice(
            context,
            'Project file could not be saved. Local work is retained; retry Save project.',
          );
        }
        return false;
      }
    }
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

  void _updateExitGuard() => pageExitGuard.setPending(
    draft.dirty || aiPending || widget.store.documents.pending,
  );

  Future<void> _saveAndClose() async {
    if (aiPending) return;
    if (await _save() && !draft.dirty && mounted) Navigator.pop(context);
  }

  Future<void> _goToProject({bool home = false}) async {
    if (aiPending ||
        widget.store.ai.activity.active ||
        !await _save() ||
        !mounted) {
      return;
    }
    final navigator = Navigator.of(context);
    if (home) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => AppShell(store: widget.store)),
        (_) => false,
      );
    } else {
      final room = widget.store.roomById(widget.roomId);
      final project = room == null
          ? null
          : widget.store.projectById(room.projectId);
      if (project == null || project.deleted || project.archived) return;
      final previous = AppPageSessionScope.maybeOf(context)
          ?.projectRoute(project.id);
      if (previous != null) {
        navigator.popUntil((route) => route == previous);
      } else {
        navigator.pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) =>
                ProjectScreen(store: widget.store, project: project),
          ),
        );
      }
    }
  }

  void _selectDesign(String? id, {bool clearUpdate = false}) {
    final previousPolish = polishingFinishes;
    draft.setPrecise(id != null);
    if (id != null) draft.setPrecisionConceptCount(1);
    if (clearUpdate || (previousPolish && id != selectedId)) {
      draft.correction.clear();
    }
    setState(() {
      selectedId = id;
      restoredSupportingIds = null;
      if (id != null) _visitSection(FocusSection.refine);
    });
    widget.onDesignSelected?.call(id);
  }

  Future<void> _chooseRoomInspiration() async {
    if (aiPending) return;
    RoomStarter? selected;
    late final MaterialPageRoute<void> picker;
    picker = MaterialPageRoute<void>(
      builder: (pickerContext) => Scaffold(
        appBar: AppBar(title: const Text('Design inspiration')),
        body: PageFrame(
          children: [
            const Text(
              'Choose a look for this room. Examples set style and palette; your own photos remain the design source.',
            ),
            InspirationGallery(
              onUse: (starter) {
                selected = starter;
                Navigator.of(pickerContext)
                    .popUntil((route) => route == picker);
                Navigator.of(pickerContext).pop();
              },
            ),
          ],
        ),
      ),
    );
    await Navigator.push<void>(context, picker);
    if (!mounted || selected == null) return;
    final starter = selected!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apply this look to the room?'),
        content: Text(
          '${starter.title}\n\nReplaces the selected style and palette. Your photos, written instructions, scope and Keep choices stay saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Apply style and palette'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !await _save()) return;
    try {
      final current = widget.store.roomById(widget.roomId)!;
      await widget.store.updateRoom(
        current.copyWith(
          colourPaletteId: starter.paletteId,
          designStyleIds: [starter.styleId],
        ),
      );
      for (final id in draft.styleIds.toList()) {
        draft.setStyle(id, false);
      }
      if (starter.styleId.isNotEmpty) draft.setStyle(starter.styleId, true);
      await draft.save();
      if (mounted) setState(() => _visitSection(FocusSection.style));
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'This look could not be saved. Your room photos and designs are unchanged.',
        );
      }
    }
  }

  Future<void> _savedSettings(DesignVersion design) async {
    if (aiPending) return;
    final refine = await showDesignRecipe(context, design);
    if (refine == null || !mounted || design.recipe == null || !await _save()) {
      return;
    }
    final room = widget.store.roomById(widget.roomId)!;
    final source = refine
        ? design.imageId
        : design.sourceImageId ?? room.primaryId;
    if (widget.store.imageFor(source) == null) {
      if (mounted) {
        notice(
          context,
          'The saved source photo is unavailable. Current settings were kept.',
        );
      }
      return;
    }
    final parent = widget.store
        .designsFor(room.id)
        .where((d) => d.imageId == source)
        .firstOrNull;
    if (!room.photoIds.contains(source) && parent == null) {
      if (mounted) {
        notice(
          context,
          'Restore the saved source version from Deleted designs before reusing its settings.',
        );
      }
      return;
    }
    setState(() {
      selectedId = parent?.id;
      selectedPhotoId = room.photoIds.contains(source)
          ? source
          : room.primaryId;
      includeRoomContext = design.supportingImageIds.isNotEmpty;
      restoredSupportingIds = [...design.supportingImageIds];
      _visitSection(refine ? FocusSection.refine : FocusSection.style);
    });
    final saved = await draft.applyRecipe(design.recipe!, refine: refine);
    if (!mounted) return;
    final settings = design.recipe!.toMap();
    final ai = widget.store.ai;
    if (saved &&
        !ai.activity.active &&
        settings['provider'] == ai.providerLabel &&
        ai.imageModels.contains(settings['imageModel']) &&
        ai.imageQualities.contains(settings['imageQuality'])) {
      ai.selectImageSettings(
        imageModel: settings['imageModel'] as String,
        imageQuality: settings['imageQuality'] as String,
      );
    }
    widget.onDesignSelected?.call(selectedId);
    notice(
      context,
      saved
          ? (refine
                ? 'Saved choices loaded. Describe the next correction.'
                : 'Saved choices and source loaded. Review before generating.')
          : 'Choices are loaded but saving needs attention. Keep this room open and retry saving.',
    );
  }

  Widget _historyCard(RenovationRoom room, DesignVersion design) {
    final selected = design.id == selectedId;
    final status = [
      if (design.id == room.approvedDesignId) 'Approved baseline',
      design.favourite
          ? 'Favourite'
          : design.rejected
          ? 'Passed'
          : 'Awaiting review',
    ].join(' • ');
    final source = design.parentId == null
        ? 'From original'
        : 'Branched version';
    final created = design.created.toLocal().toString().substring(0, 16);
    final details = '${design.title}\n$status\n$source · $created';
    return Semantics(
      selected: selected,
      child: Card(
        key: ValueKey('history-design-${design.id}'),
        color: selected
            ? Theme.of(context).colorScheme.secondaryContainer
            : null,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _selectDesign(design.id),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Tooltip(
                  message: details,
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: PhotoThumb(
                    bytes: widget.store.imageFor(design.imageId),
                    width: double.infinity,
                    height: 128,
                    viewerTitle: design.title,
                  ),
                ),
                const SizedBox(height: 10),
                Tooltip(
                  message: details,
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Text(
                    design.title,
                    key: ValueKey('history-caption-${design.id}'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(status, style: Theme.of(context).textTheme.bodySmall),
                if (design.aiProvider != null)
                  AiUsageSummary(
                    operation: 'Design',
                    model: design.aiModel,
                    usage: design.recipe?.toMap()['usage'] is Map
                        ? AiUsage.fromMap(
                            design.recipe!.toMap()['usage'] as Map,
                          )
                        : null,
                  ),
                Text(
                  '$source · $created',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  key: ValueKey('history-actions-${design.id}'),
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: aiPending
                          ? null
                          : () => _savedSettings(design),
                      icon: const Icon(Icons.tune),
                      label: const Text('Saved settings'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _selectDesign(design.id),
                      icon: Icon(selected ? Icons.check : Icons.edit_outlined),
                      label: Text(selected ? 'Selected' : 'Use design'),
                    ),
                    IconButton(
                      tooltip: design.favourite
                          ? 'Remove favourite'
                          : 'Save favourite',
                      icon: Icon(
                        design.favourite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: design.favourite ? Colors.red : null,
                      ),
                      onPressed: () => widget.store.setFavourite(
                        design,
                        favourite: !design.favourite,
                      ),
                    ),
                    PopupMenuButton<String>(
                      enabled: !aiPending,
                      tooltip: 'Review options for ${design.title}',
                      onSelected: (action) => _reviewVersion(design, action),
                      itemBuilder: (_) => [
                        if (!design.rejected)
                          const PopupMenuItem(
                            value: 'pass',
                            child: Text('Mark as passed'),
                          ),
                        if (design.rejected || design.favourite)
                          const PopupMenuItem(
                            value: 'review',
                            child: Text('Return to review'),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete design'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCameraRoom() async {
    if (aiPending || !await _save() || !mounted) return;
    if (widget.initialPhotoId != null) {
      await Navigator.maybePop(context);
      return;
    }
    final room = widget.store.roomById(widget.roomId)!;
    final photoId =
        roomPhotoForDesign(
          room,
          widget.store.designsFor(room.id),
          selectedId,
        ) ??
        selectedPhotoId;
    // Replace this workspace so two independent room drafts cannot overwrite
    // each other when the camera opens its own design workspace.
    await Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraRoomView(
          store: widget.store,
          roomId: room.id,
          initialPhotoId: photoId,
          initialDesignId: selectedId,
          settingsBuilder: (_) => settingsPage(widget.store),
          liveDesignBuilder: (photoId) => LiveDesignScreen(
            store: widget.store,
            projectId: room.projectId,
            roomId: room.id,
            initialPhotoId: photoId,
            settingsBuilder: (_) => settingsPage(widget.store),
            workspace: (roomId, designId) => WorkspaceScreen(
              store: widget.store,
              roomId: roomId,
              initialDesignId: designId,
              startInPrecision: true,
            ),
          ),
          workspace: (photo, onSelected) => WorkspaceScreen(
            store: widget.store,
            roomId: room.id,
            initialPhotoId: photo,
            onDesignSelected: onSelected,
          ),
        ),
      ),
    );
  }

  String _templatePrompt(RenovationRoom room) =>
      roomTemplatePrompt(room, draft, includeRoomContext: includeRoomContext);

  String _prompt(RenovationRoom room) {
    if (precise && polishingFinishes) {
      return '${paintRefinementRequestPrompt(finishPreview!.paintRecipe!, changes.text)}\n'
          '${protected.text.trim().isEmpty ? '' : 'MUST RETAIN: ${protected.text.trim()}.\n'}'
          '${buildRoomItemsPrompt(draft.effectiveRoomType, Map.fromEntries(draft.roomItemChoices.entries.where((e) => e.value == 'keep')), const [])}';
    }
    final sourceId = selectedId == null
        ? selectedPhotoId
        : widget.store
              .designsFor(room.id)
              .where((d) => d.id == selectedId)
              .firstOrNull
              ?.imageId;
    return reviewedRoomPrompt(
      _templatePrompt(room),
      draft,
      sourceImageId: sourceId,
      proposalRequirements: roomTemplatePrompt(
        room,
        draft,
        includeRoomContext: includeRoomContext,
        conciseDesignDirection: true,
      ),
      supportingImageIds: [
        if (includeRoomContext && room.photoIds.length > 1)
          ...(restoredSupportingIds ?? room.photoIds).where(
            (id) => id != sourceId,
          ),
      ],
    );
  }

  Uint8List? _activeImage(RenovationRoom room) {
    if (selectedId != null) {
      for (final d in widget.store.designsFor(room.id)) {
        if (d.id == selectedId) return widget.store.imageFor(d.imageId);
      }
    }
    return widget.store.imageFor(selectedPhotoId);
  }

  AiEditRequest _aiRequest(RenovationRoom room, {bool forAnalysis = false}) {
    if (precise && isWholeRoomRequest(changes.text)) {
      throw const AiFailure(
        '“All” is a whole-room request. Choose New design, or describe a specific correction before copying or generating.',
      );
    }
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
    final guideId = sourceId;
    final finishPolish = !forAnalysis && polishingFinishes;
    if (finishPolish) {
      final cleanId = finishPreview!.sourceImageId;
      if (cleanId == null ||
          cleanId == guideId ||
          widget.store.imageFor(cleanId) == null) {
        throw const AiFailure(
          'The clean source for this finish preview is unavailable. Select the clean design and reopen Colours & tiles before polishing. No AI request was sent.',
        );
      }
      sourceId = cleanId;
    }
    final image = widget.store.imageFor(sourceId);
    if (image == null) {
      throw const AiFailure('The selected image is unavailable.');
    }
    final supporting = {
      if (finishPolish) guideId: widget.store.imageFor(guideId)!,
      if (!precise && includeRoomContext && room.photoIds.length > 1)
        for (final id in (restoredSupportingIds ?? room.photoIds).where(
          (id) => id != sourceId,
        ))
          id:
              widget.store.imageFor(id) ??
              (throw const AiFailure('A room context photo is unavailable.')),
    };
    final prompt = forAnalysis ? _templatePrompt(room) : _prompt(room);
    if (prompt.length > 16000) {
      throw const AiFailure(
        'The prepared prompt is too long. Shorten the instructions or edited AI prompt.',
      );
    }
    return AiEditRequest(
      roomId: room.id,
      parentId: selectedId,
      sourceImageId: sourceId,
      image: image,
      supportingImages: supporting,
      finishPolish: finishPolish,
      styleIds: draft.styleIds.toList(),
      otherStyle: draft.otherStyle.text,
      prompt: prompt,
      instructions: hasEffectiveChanges
          ? [
              changes.text,
              if (!precise) draft.scopePrompt,
            ].where((s) => s.trim().isNotEmpty).join('\n')
          : '',
      precise: precise,
      title: precise
          ? (polishingFinishes ? 'AI finish polish' : 'AI precision edit')
          : 'AI renovation concept',
    );
  }

  Future<void> _copyPrompt(RenovationRoom room) async {
    try {
      _aiRequest(room);
    } on AiFailure catch (error) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Check the design request'),
          content: Text(error.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (!mounted) return;
    if (precise && !hasEffectiveChanges) {
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
        polishingFinishes
            ? 'Prompt copied. Attach the clean design first and this local finish preview second in your AI app.'
            : 'Prompt copied. Paste it into your AI app and attach the working photo and any selected supporting views.',
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
      sourceImageId: selectedId == null
          ? selectedPhotoId
          : widget.store
                .designsFor(room.id)
                .firstWhere((d) => d.id == selectedId)
                .imageId,
    );
    if (mounted) _selectDesign(d.id);
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
        builder: (_) => SavedAppPage(
          page: {'page': 'tool', 'tool': sketch ? 'sketch' : 'crop'},
          child: FocusEditScreen(bytes: bytes, sketch: sketch),
        ),
      ),
    );
    if (edited == null || !mounted) return;
    final newVersion = await widget.store.createDesign(
      roomId: room.id,
      image: edited,
      title: sketch ? 'Annotated reference' : 'Focus crop',
      prompt: _prompt(room),
      parentId: selectedId,
      sourceImageId: selectedId == null
          ? selectedPhotoId
          : widget.store
                .designsFor(room.id)
                .firstWhere((d) => d.id == selectedId)
                .imageId,
    );
    if (mounted) _selectDesign(newVersion.id);
  }

  Future<void> _paintRoom(RenovationRoom room, {int initialPanel = 0}) async {
    if (aiPending || !await draft.save() || !mounted) return;
    final active = _activeImage(room);
    if (active == null) return;
    final parent = selectedId;
    final selected = parent == null
        ? null
        : widget.store
              .designsFor(room.id)
              .firstWhere((design) => design.id == parent);
    final sourceId = selected?.paintRecipe != null
        ? selected!.sourceImageId!
        : selected?.imageId ?? selectedPhotoId;
    final workingImageId = selected?.imageId ?? selectedPhotoId;
    final source = widget.store.imageFor(sourceId);
    if (source == null) {
      notice(context, 'The source for this paint version is unavailable.');
      return;
    }
    final current = widget.store.roomById(room.id)!;
    DesignVersion? created;
    var finishWithAi = false;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LocalPaintScreen(
          initialPanel: initialPanel,
          sessionPage: {
            'page': 'finishes',
            'projectId': room.projectId,
            'roomId': room.id,
          },
          source: source,
          before: active,
          roomTypeId: resolveRoomType(current.roomTypeId, current.name),
          initial: current.paintDrafts[workingImageId] ?? selected?.paintRecipe,
          savedRecipe: selected?.paintRecipe,
          requestAiFinish: () => finishWithAi = true,
          saveDraft: (recipe) =>
              widget.store.savePaintDraft(room.id, workingImageId, recipe),
          saveVersion: (result, recipe) async {
            created = await widget.store.createDesign(
              roomId: room.id,
              image: result.bytes,
              title: recipe.surfaces.isEmpty
                  ? 'Local paint removed'
                  : recipe.surfaces.any((s) => s.finish != LocalFinish.paint)
                  ? 'Local finishes · ${recipe.surfaces.length} surfaces'
                  : 'Local paint · ${recipe.surfaces.length} ${recipe.surfaces.length == 1 ? 'wall' : 'walls'}',
              prompt: 'Local finish preview. Saved surface selections, colours and tile patterns; no AI request. See saved finish layers for details.',
              parentId: parent,
              sourceImageId: sourceId,
              paintRecipe: recipe,
            );
          },
        ),
      ),
    );
    if (mounted && created != null) {
      _selectDesign(created!.id);
      if (finishWithAi) await _polishFinishes(created!);
    }
  }

  Future<void> _compareRoom(RenovationRoom room) async {
    final source = _activeImage(room);
    final original = widget.store.imageFor(room.originalId);
    if (source == null || original == null) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SavedAppPage(
          page: const {'page': 'tool', 'tool': 'compare'},
          child: CompareScreen(original: original, edited: source),
        ),
      ),
    );
  }

  Future<void> _polishFinishes(DesignVersion preview) async {
    draft.correction.text = paintRefinementPrompt(preview.paintRecipe!);
    draft.setPrecise(true);
    draft.setPrecisionConceptCount(1);
    draft.setUseAiPrompt(false);
    setState(() {
      _visitSection(FocusSection.refine);
      focusRevealRevision++;
    });
    final saved = await draft.save();
    if (!mounted) return;
    notice(
      context,
      saved
          ? 'Local preview saved. AI has not run yet. Review the clean design and finish guide, then confirm to polish.'
          : 'Local preview saved. Correction draft could not save; keep this screen open and retry Save.',
    );
    // Let the owner read/edit the prepared finish instructions first. A separate
    // Review & send action opens the paid-request confirmation.
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.store, draft, widget.store.documents]),
    builder: (context, _) {
      final room = widget.store.roomById(widget.roomId)!;
      final versions = widget.store.designsFor(room.id);
      if (selectedId != null && !versions.any((v) => v.id == selectedId)) {
        selectedId = room.approvedDesignId;
        selectedPhotoId = room.originalId;
      }
      final source = _activeImage(room);
      return SavedAppPage(
        onReturn: (page) {
          if (page['page'] == 'setup') _reloadSetupChoices();
        },
        page: {
          'page': 'workspace',
          'projectId': room.projectId,
          'roomId': room.id,
          'designId': selectedId,
          'photoId': selectedPhotoId,
          'section': focusSection.name,
          'mode': draft.designMode.name,
        },
        child: PopScope(
          canPop:
              !draft.dirty &&
              !aiPending &&
              !widget.store.documents.hasPending(room.projectId),
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (aiPending) {
              notice(
                context,
                analysingRoom
                    ? 'Photo analysis is running. Wait for it to finish so the result can be saved.'
                    : 'An AI design is running or waiting to save. Keep this room open and save the result before leaving.',
              );
              return;
            }
            final saved = await draft.save();
            if (saved && widget.store.documents.linked(room.projectId)) {
              try {
                await widget.store.documents.save(room.projectId);
              } catch (_) {
                if (context.mounted) {
                  notice(
                    context,
                    'Project file could not be saved. Local work is retained; retry Save project.',
                  );
                }
                return;
              }
            }
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
              title: Text(
                room.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(32),
                child: SizedBox(
                  height: 32,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        AutosaveSwitch(
                          store: widget.store,
                          enabled: !aiPending,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                ScreenToolbar(
                  tools: [
                    ScreenTool(
                      ScreenAction.save,
                      label: 'Save project file',
                      onPressed: aiPending ? null : _projectFile,
                    ),
                    ScreenTool(
                      ScreenAction.setup,
                      label: 'Guided room setup',
                      onPressed: aiPending ? null : _openSetup,
                    ),
                    ScreenTool(
                      ScreenAction.settings,
                      label: 'Room settings',
                      onPressed: _openSettings,
                    ),
                    ScreenTool(
                      ScreenAction.rename,
                      label: 'Rename room',
                      onPressed: _renameRoom,
                    ),
                    ScreenTool(
                      ScreenAction.projectRooms,
                      label: 'Rooms & spaces',
                      menuOnly: true,
                      onPressed: aiPending ? null : () => _goToProject(),
                    ),
                    ScreenTool(
                      ScreenAction.projectsHome,
                      label: 'Projects home',
                      menuOnly: true,
                      onPressed: aiPending
                          ? null
                          : () => _goToProject(home: true),
                    ),
                    ScreenTool.help(
                      context,
                      title: 'Room tools',
                      message: 'Save writes a project file. Guided setup walks through room choices. Room settings holds saving and AI options. Rename changes this room name. Extra tools remain in the same order under More tools on smaller screens.',
                    ),
                  ],
                ),
              ],
            ),
            bottomNavigationBar: AiActivityStrip(
              activity: widget.store.ai.activity,
              roomId: room.id,
            ),
            body: FocusWorkspace(
              selected: focusSection,
              revealRevision: focusRevealRevision,
              onSelected: (section) => setState(() => _visitSection(section)),
              imageBuilder: (height) => source == null
                  ? const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                      ),
                    )
                  : ExpandableImage(
                      bytes: source,
                      sessionPage: const {'page': 'tool', 'tool': 'viewer'},
                      title: selectedId == null
                          ? '${room.displayName} / room photo'
                          : versions
                                .firstWhere((v) => v.id == selectedId)
                                .title,
                      height: height,
                      inlineZoom: true,
                      showHint: false,
                    ),
              imageTools: [
                IconButton(
                  tooltip: 'Colours & tiles without AI',
                  onPressed: aiPending || source == null
                      ? null
                      : () => _paintRoom(room),
                  icon: const Icon(Icons.format_paint_outlined),
                ),
                if (supportsLiveRoomCamera)
                  IconButton(
                    tooltip: 'Camera renovation view',
                    onPressed: aiPending ? null : _openCameraRoom,
                    icon: const Icon(Icons.videocam_outlined),
                  ),
                IconButton(
                  tooltip: 'Crop / focus',
                  onPressed: aiPending
                      ? null
                      : () => _editReference(room, sketch: false),
                  icon: const Icon(Icons.crop),
                ),
                IconButton(
                  tooltip: 'Sketch / markup',
                  onPressed: aiPending
                      ? null
                      : () => _editReference(room, sketch: true),
                  icon: const Icon(Icons.draw_outlined),
                ),
                IconButton(
                  tooltip: 'Compare original',
                  onPressed: selectedId == null
                      ? null
                      : () => _compareRoom(room),
                  icon: const Icon(Icons.compare),
                ),
                IconButton(
                  tooltip: 'Refine selected design',
                  onPressed: selectedId == null || aiPending
                      ? null
                      : () {
                          draft.setPrecise(true);
                          setState(() => _visitSection(FocusSection.refine));
                        },
                  icon: const Icon(Icons.auto_fix_high_outlined),
                ),
                if (selectedId != null)
                  DeleteDesignButton(
                    key: const ValueKey('delete-selected-design'),
                    store: widget.store,
                    design: versions.firstWhere(
                      (design) => design.id == selectedId,
                    ),
                    enabled: !aiPending,
                  ),
              ],
              thumbnails: [
                FocusVersionThumbnail(
                  image: widget.store.imageFor(room.originalId),
                  title: 'Original',
                  selected:
                      selectedId == null && selectedPhotoId == room.originalId,
                  onTap: () => setState(() {
                    selectedId = null;
                    selectedPhotoId = room.originalId;
                  }),
                ),
                for (final design in versions)
                  FocusVersionThumbnail(
                    image: widget.store.imageFor(design.imageId),
                    title: design.title,
                    selected: selectedId == design.id,
                    onTap: () => setState(() {
                      selectedId = design.id;
                      widget.onDesignSelected?.call(design.id);
                      _visitSection(FocusSection.refine);
                    }),
                  ),
              ],
              footer: _generationFooter(),
              sections: {
                FocusSection.room: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: aiPending ? null : _openSetup,
                      icon: const Icon(Icons.format_list_numbered),
                      label: const Text('4-step room setup'),
                    ),
                  ),
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
                              widget.onDesignSelected?.call(selectedId);
                            }),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                avatar: const Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                ),
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
                                  avatar: Icon(
                                    Icons.verified_outlined,
                                    size: 18,
                                  ),
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
                                child: const Text(
                                  'Return to approved baseline',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: aiPending ? null : _openSettings,
                      icon: const Icon(Icons.settings_input_component_outlined),
                      label: const Text('AI connection settings'),
                    ),
                  ),
                  RoomAnalysisCard(
                    store: widget.store,
                    draft: draft,
                    onContinue: () =>
                        setState(() => _visitSection(FocusSection.refine)),
                    buildRequest: () => _aiRequest(
                      widget.store.roomById(widget.roomId)!,
                      forAnalysis: true,
                    ),
                    onBusyChanged: (value) {
                      setState(() => analysingRoom = value);
                      _updateExitGuard();
                    },
                  ),
                  const SizedBox(height: 14),
                  RoomPhotosCard(
                    store: widget.store,
                    room: room,
                    selectedPhotoId: selectedId == null
                        ? selectedPhotoId
                        : null,
                    onView: (id) => setState(() {
                      selectedId = null;
                      selectedPhotoId = id;
                      restoredSupportingIds = null;
                    }),
                    includeContext: includeRoomContext,
                    onContextChanged: (value) => setState(() {
                      includeRoomContext = value;
                      restoredSupportingIds = null;
                    }),
                  ),
                  const SizedBox(height: 14),
                ],
                FocusSection.style: [
                  if (precise) ...[
                    const Text(
                      'This update keeps the selected design. Describe the colour or fitting to change in Refine. Choose Partial or New design for a wider renovation.',
                    ),
                    _selectedDesignLook(room),
                    TextButton(
                      onPressed: () =>
                          setState(() => _visitSection(FocusSection.refine)),
                      child: const Text('Update selected image'),
                    ),
                  ] else ...[
                    SavedProjectLookButton(store: widget.store, draft: draft),
                    RoomColourPaletteCard(
                      store: widget.store,
                      room: room,
                      preview: source,
                    ),
                    const SizedBox(height: 12),
                    if (!precise) ...[
                      const SizedBox(height: 12),
                      DesignStyleControls(draft: draft),
                      RenovationScopeControls(draft: draft),
                    ],
                  ],
                ],
                FocusSection.refine: [
                  DesignModeControls(draft: draft, enabled: !aiPending),
                  if (selectedId != null && precise)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              polishingFinishes
                                  ? 'Polish selected finishes'
                                  : 'Update this design',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            KeyedSubtree(
                              key: instructionAnchor,
                              child: TextField(
                                key: const ValueKey('selected-design-update'),
                                controller: draft.correction,
                                onChanged: (_) {
                                  if (!precise) {
                                    draft.setPrecise(true);
                                    draft.setPrecisionConceptCount(1);
                                  }
                                },
                                minLines: 1,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'What would you like to improve?',
                                  hintText: 'For example: replace only the extractor with a slim contemporary hood.',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              polishingFinishes
                                  ? 'Review these finish instructions, then choose Polish with AI. AI starts only after the sending confirmation.'
                                  : 'Creates another AI version using this image and your requested change. Your current design stays saved.',
                            ),
                            if (finishPreview != null && !polishingFinishes)
                              OutlinedButton.icon(
                                key: const ValueKey('resume-finish-polish'),
                                onPressed: aiPending
                                    ? null
                                    : () => _polishFinishes(finishPreview!),
                                icon: const Icon(Icons.auto_awesome_outlined),
                                label: const Text('Review and send AI polish'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (precise &&
                      !polishingFinishes &&
                      looksLikeBroadRenovation(changes.text)) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'This is a broad renovation request. Choose New design to coordinate the selected changes; use Precise correction for a specific detail.',
                    ),
                    TextButton(
                      onPressed: () => draft.setPrecise(false),
                      child: const Text('Use New design'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (!precise || selectedId == null)
                    KeyedSubtree(
                      key: instructionAnchor,
                      child: TextField(
                        key: ValueKey('instructions-$precise'),
                        controller: changes,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: precise
                              ? 'Specific correction'
                              : 'What should change?',
                          hintText: precise
                              ? 'Remove only the cupboard handles; keep everything else.'
                              : 'Leave blank for a fresh concept, or add your must-haves.',
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'AI generation (optional)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  AiEditCard(
                    compact: true,
                    singleConcept: polishingFinishes,
                    store: widget.store,
                    draft: draft,
                    controller: generation,
                    onImproveBrief: _improveBrief,
                    showGenerateButton: false,
                    showSavedPreview: false,
                    beforeSend: draft.save,
                    onPendingChanged: (pending) {
                      if (mounted) setState(() => editingRoom = pending);
                      _updateExitGuard();
                    },
                    buildRequest: () => _aiRequest(room),
                    onSaved: (design) {
                      if (mounted) _selectDesign(design.id, clearUpdate: true);
                    },
                  ),
                  ExpansionTile(
                    key: const ValueKey('focus-edit-options'),
                    maintainState: true,
                    title: const Text('Protected features & help'),
                    children: [
                      const HelpHeading(
                        title: 'AI instructions',
                        message: 'Whole-room renovation coordinates your goal, style, palette and Keep / Replace choices. Describe what should change and what must stay, then review the brief before generating.\n\nPrecise correction uses one narrow instruction on the selected Working from image. Your whole-room brief and style choices stay saved separately and are not reapplied. Explicit Keep choices still apply, and you can generate without analysing again.\n\nCrop and markup are visual references, not enforced masks. Review the returned image: AI can change details outside the requested area.',
                      ),
                      const SizedBox(height: 6),

                      const SizedBox(height: 10),
                      const SizedBox(height: 8),
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
                    ],
                  ),
                  ExpansionTile(
                    key: const ValueKey('prepared-prompt-preview'),
                    title: const Text('Preview prepared prompt'),
                    subtitle: const Text(
                      'Review the exact instructions that will be sent. Precision includes only the update; full and partial designs use their current scope.',
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
                    key: const ValueKey('manual-ai-tools'),
                    title: const Text('Manual AI handoff (copy / import)'),
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _copyPrompt(room),
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy AI prompt'),
                          ),
                          const HelpIcon(
                            title: 'Manual AI handoff',
                            message: 'Copy the prepared prompt into another AI app that supports image editing. Attach the working photo and selected supporting views yourself, then import its result. Copying does not connect a provider or make an API request.',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => _importResult(room),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Import generated AI result'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                FocusSection.ideas: [
                  const Text(
                    'Review results here. Choose a design to refine, compare or save as your favourite.',
                  ),
                  const SizedBox(height: 8),
                  const HelpHeading(
                    title: 'Version history',
                    message: 'Passed ideas stay in history. Use the review menu to return them to Explore or delete an unwanted design. Deleted designs below lets you restore it. Favourites and baseline approval are separate choices. Deleting a design keeps a recoverable copy and its source history.',
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(height: 10),
                  if (versions.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Find a direction for your first design',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Browse a look, then apply its style and palette to this room.',
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: aiPending
                                      ? null
                                      : _chooseRoomInspiration,
                                  icon: const Icon(Icons.collections_outlined),
                                  label: const Text(
                                    'Browse design inspiration',
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => setState(
                                    () => _visitSection(FocusSection.refine),
                                  ),
                                  child: const Text('Review my design brief'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...versions.map((design) => _historyCard(room, design)),
                  DeletedDesignsCard(store: widget.store, roomId: room.id),
                  AiUsageCard(store: widget.store, roomId: room.id),
                  DesignReferenceCard(
                    store: widget.store,
                    roomId: room.id,
                    onPending: (pending) {
                      setState(() => analysingRoom = pending);
                      _updateExitGuard();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              },
            ),
          ),
        ),
      );
    },
  );
}
