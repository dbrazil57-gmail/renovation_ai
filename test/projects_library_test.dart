import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/context_help.dart';
import 'package:renovision_ai/file_transfer.dart';
import 'package:renovision_ai/focus_workspace.dart';
import 'package:renovision_ai/image_viewer.dart';
import 'package:renovision_ai/live_design_screen.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/project_transfer_widgets.dart';
import 'package:renovision_ai/room_camera.dart';
import 'package:renovision_ai/room_start_widgets.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';
import 'support/focus_navigation.dart';

class ProjectTestFiles implements AppFiles {
  Uint8List? opening;
  int picks = 0, saves = 0;
  bool failSave = false;
  Uint8List? saved;
  @override
  bool get supported => true;
  @override
  Future<Uint8List?> pickBackup() async {
    picks++;
    return opening;
  }

  @override
  Future<FileSaveResult> save(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async {
    saves++;
    if (failSave) throw StateError('Synthetic file save failure');
    saved = bytes;
    return FileSaveResult.saved;
  }
}

void main() {
  late RenovisionStore store;
  late RenovationProject project;
  late ProjectTestFiles files;
  final image = Uint8List.fromList(
    img.encodePng(img.Image(width: 40, height: 30)),
  );
  setUp(() async {
    files = ProjectTestFiles();
    store = RenovisionStore(
      records: MemoryBox(),
      photos: MemoryBox(),
      files: files,
    );
    project = await store.createProject('Claylands');
  });
  tearDown(() => store.dispose());
  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'compact Projects keeps file opening separate from saved-project navigation and help',
    (tester) async {
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: image,
      );
      files.opening = store.backupFor(project.id).encode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectsTab(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      final info = find.byWidgetPredicate(
        (widget) => widget is HelpIcon && widget.title == 'Saved projects',
      );
      await tester.scrollUntilVisible(
        info,
        240,
        scrollable: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      await tap(tester, info);
      expect(find.textContaining('Open project file loads'), findsOneWidget);
      await tap(tester, find.text('Close'));
      await tap(tester, find.text('Open project file…'));
      expect(files.picks, 1);
      await tap(tester, find.text('Open project'));
      expect(store.projects, hasLength(1));
      expect(store.projects.single.id, project.id);
      expect(store.roomsFor(project.id).single.id, room.id);
      expect(store.imageFor(room.originalId), image);
      expect(find.byType(ProjectScreen), findsOneWidget);
    },
  );

  testWidgets(
    'opening a saved project shows rooms without a save panel; the toolbar still exports the complete project',
    (tester) async {
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Live room',
        roomTypeId: 'living',
        originalImage: image,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectsTab(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Claylands'),
        280,
        scrollable: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      await tap(tester, find.text('Claylands'));
      expect(find.byType(ProjectScreen), findsOneWidget);
      expect(find.text('Rooms and spaces'), findsOneWidget);
      expect(find.text('Living room (Live)'), findsOneWidget);
      expect(find.byType(ProjectFileControls), findsNothing);
      expect(find.text('Save, restore and AI settings'), findsNothing);
      expect(files.saves, 0);
      await tap(tester, find.byTooltip('Save project file'));
      expect(find.byType(ProjectFileControls), findsOneWidget);
      await tap(tester, find.text('Save project'));
      expect(files.saves, 1);
      final backup = ProjectBackup.decode(files.saved!);
      expect(backup.rooms.single.name, 'Live room');
      expect(backup.rooms.single.roomTypeId, 'living');
      expect(backup.photos[room.originalId], image);
      await tap(tester, find.text('Close'));
      expect(store.roomById(room.id)!.name, 'Live room');
      expect(store.imageFor(room.originalId), image);
      files.failSave = true;
      await tap(tester, find.byTooltip('Save project file'));
      await tap(tester, find.text('Save project'));
      await tap(tester, find.text('Close'));
      expect(find.textContaining('Project file save failed.'), findsOneWidget);
      expect(store.imageFor(room.originalId), image);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'generic live labels follow the confirmed room type while custom names, saved records and originals stay intact',
    (tester) async {
      final living = await store.createRoom(
        projectId: project.id,
        name: 'Live view',
        roomTypeId: 'living',
        originalImage: image,
      );
      await store.createRoom(
        projectId: project.id,
        name: 'Live room',
        roomTypeId: 'kitchen',
        originalImage: image,
      );
      final unknown = await store.createRoom(
        projectId: project.id,
        name: 'Live room',
        roomTypeId: 'other',
        originalImage: image,
      );
      final custom = await store.createRoom(
        projectId: project.id,
        name: 'Guest retreat',
        roomTypeId: 'bedroom',
        originalImage: image,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectScreen(store: store, project: project),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Living room (Live)'), findsOneWidget);
      expect(find.text('Kitchen (Live)'), findsOneWidget);
      expect(find.text('Unspecified (Live)'), findsOneWidget);
      expect(find.text('Guest retreat'), findsOneWidget);
      await store.updateRoom(unknown.copyWith(roomTypeId: 'office'));
      await tester.pumpAndSettle();
      expect(find.text('Office (Live)'), findsOneWidget);
      expect(find.text('Unspecified (Live)'), findsNothing);
      await tap(tester, find.text('Living room (Live)'));
      expect(find.byType(WorkspaceScreen), findsOneWidget);
      expect(find.text('Living room (Live)'), findsOneWidget);
      await store.renameRoom(living.id, 'Front lounge');
      await store.updateRoom(
        store.roomById(living.id)!.copyWith(roomTypeId: 'kitchen'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Front lounge'), findsOneWidget);
      expect(store.roomById(custom.id)!.name, 'Guest retreat');
      expect(store.roomById(unknown.id)!.name, 'Live room');
      expect(store.roomById(living.id)!.photoIds, [living.originalId]);
      expect(store.imageFor(living.originalId), image);
      expect(files.saves, 0);
      expect(tester.takeException(), isNull);
    },
  );

  test('automatic Live names track type, survive backup/restore and yield to an explicit rename', () async {
    final live = await store.createRoom(
      projectId: project.id,
      name: 'Bedroom',
      roomTypeId: 'bedroom',
      automaticLiveName: true,
      originalImage: image,
    );
    final ordinary = await store.createRoom(
      projectId: project.id,
      name: 'Bedroom',
      roomTypeId: 'bedroom',
      originalImage: image,
    );
    expect(live.displayName, 'Bedroom (Live)');
    expect(ordinary.displayName, 'Bedroom');
    final changed = live.copyWith(roomTypeId: 'kitchen');
    await store.updateRoom(changed);
    expect(store.roomById(live.id)!.displayName, 'Kitchen (Live)');
    expect(store.roomById(live.id)!.name, 'Bedroom');
    final restoredProject = await store.restoreBackup(
      ProjectBackup.decode(store.backupFor(project.id).encode()),
    );
    final restoredLive = store
        .roomsFor(restoredProject.id)
        .singleWhere((room) => room.automaticLiveName);
    expect(restoredLive.displayName, 'Kitchen (Live)');
    expect(store.imageFor(restoredLive.originalId), image);
    final legacy = Map.of(changed.toMap())
      ..remove('automaticLiveName')
      ..['name'] = 'Room (Live view)';
    expect(RenovationRoom.fromMap(legacy).displayName, 'Kitchen (Live)');
    await store.renameRoom(live.id, 'Guest retreat');
    final renamed = store.roomById(live.id)!;
    expect(renamed.automaticLiveName, isFalse);
    await store.updateRoom(renamed.copyWith(roomTypeId: 'office'));
    expect(store.roomById(live.id)!.displayName, 'Guest retreat');
    expect(store.imageFor(live.originalId), image);
  });

  for (final camera in [true, false]) {
    testWidgets(
      '${camera ? 'camera' : 'gallery'} start describes the actual next action without creating a room on cancel',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        await tester.pumpWidget(
          MaterialApp(
            home: ProjectScreen(store: store, project: project),
          ),
        );
        await tester.pumpAndSettle();
        await tap(tester, find.text(camera ? 'Take photo' : 'Choose photos'));
        expect(
          tester.widget<RoomStartDialog>(find.byType(RoomStartDialog)).camera,
          camera,
        );
        expect(
          find.text(camera ? 'Continue to camera' : 'Continue to photos'),
          findsOneWidget,
        );
        if (camera) {
          await tap(tester, find.text('Continue to camera'));
          expect(find.byType(RoomCaptureScreen), findsOneWidget);
          await tester.pageBack();
          await tester.pumpAndSettle();
        } else {
          await tap(tester, find.text('Cancel'));
        }
        expect(store.roomsFor(project.id), isEmpty);
      },
    );
  }

  for (final camera in <bool?>[true, false, null]) {
    testWidgets(
      'room chooser can switch from ${camera == null
          ? 'room shortcut'
          : camera
          ? 'camera'
          : 'gallery'} into live design without losing room choices',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: camera == null
                ? Scaffold(body: ProjectsTab(store: store))
                : ProjectScreen(store: store, project: project),
          ),
        );
        await tester.pumpAndSettle();
        await tap(
          tester,
          find.text(
            camera == null
                ? 'Kitchen'
                : camera
                ? 'Take photo'
                : 'Choose photos',
          ),
        );
        await tester.enterText(
          find.byKey(const ValueKey('room-name')),
          'My sunny retreat',
        );
        await tester.enterText(
          find.byKey(const ValueKey('room-search')),
          'sunroom',
        );
        await tester.pumpAndSettle();
        await tap(tester, find.byKey(const ValueKey('room-type-sunroom')));
        await tap(
          tester,
          find.byKey(const ValueKey('room-start-method-liveDesign')),
        );
        await tap(tester, find.text('Continue to live design'));
        final viewer = tester.widget<LiveDesignScreen>(
          find.byType(LiveDesignScreen),
        );
        expect(viewer.initialRoomChoice!.name, 'My sunny retreat');
        expect(viewer.initialRoomChoice!.roomTypeId, 'sunroom');
        expect(viewer.initialRoomChoice!.method, RoomStartMethod.liveDesign);
        expect(store.roomsFor(project.id), isEmpty);
        expect(store.photos.keys, isEmpty);
        expect(store.ai.activity.active, isFalse);
        expect(find.byType(RoomCaptureScreen), findsNothing);
        expect(find.byType(WorkspaceScreen), findsNothing);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(LiveDesignScreen), findsNothing);
        expect(store.projects, hasLength(1));
        expect(store.roomsFor(project.id), isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'library caption uses the image width below it; image zoom and editing keep the selected version',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen with dining area',
        originalImage: image,
      );
      final design = await store.createDesign(
        roomId: room.id,
        image: image,
        title: 'Warm charcoal kitchen with walnut storage and a pale stone benchtop',
        prompt: 'Retain windows and layout.',
      );
      await store.setFavourite(design, favourite: true);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(body: LibraryTab(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      final preview = find.byType(ExpandableImage);
      final caption = find.byKey(ValueKey('library-caption-${design.id}'));
      final imageBounds = tester.getRect(preview),
          captionBounds = tester.getRect(caption);
      expect(captionBounds.top, greaterThanOrEqualTo(imageBounds.bottom));
      expect(captionBounds.width, greaterThan(220));
      expect(tester.takeException(), isNull);
      await tap(tester, preview);
      expect(find.byType(ImageViewerScreen), findsOneWidget);
      await tap(tester, find.byTooltip('Close image viewer'));
      await tap(tester, find.text('Edit design'));
      expect(
        tester
            .widget<WorkspaceScreen>(find.byType(WorkspaceScreen))
            .initialDesignId,
        design.id,
      );
      expect(store.imageFor(room.originalId), image);
      expect(store.designsFor(room.id).single.favourite, isTrue);
    },
  );

  for (final size in [const Size(320, 700), const Size(1100, 800)]) {
    testWidgets(
      'version history captions stay beneath previews at $size with large text, zoom and selection preserve baseline',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final room = await store.createRoom(
          projectId: project.id,
          name: 'Kitchen',
          originalImage: image,
        );
        final baseline = await store.createDesign(
          roomId: room.id,
          image: image,
          title: 'Approved kitchen',
          prompt: 'Keep window and layout.',
        );
        await store.approveBaseline(room.id, designId: baseline.id);
        const title =
            'Warm charcoal kitchen with walnut storage, pale stone benchtops and dining-facing cupboards';
        final option = await store.createDesign(
          roomId: room.id,
          image: image,
          title: title,
          prompt: 'Explore another finish.',
        );
        await store.setFavourite(option, favourite: true);
        String? selected;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: WorkspaceScreen(
              store: store,
              roomId: room.id,
              onDesignSelected: (id) => selected = id,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tap(tester, find.byKey(const ValueKey('focus-section-ideas')));
        final card = find.byKey(ValueKey('history-design-${option.id}'));
        final caption = find.byKey(ValueKey('history-caption-${option.id}'));
        final preview = find.descendant(
          of: card,
          matching: find.byType(PhotoThumb),
        );
        final actions = find.byKey(ValueKey('history-actions-${option.id}'));
        await ensureFocusVisible(tester, caption);
        await tester.pumpAndSettle();
        final captionBounds = tester.getRect(caption);
        expect(
          captionBounds.top,
          greaterThanOrEqualTo(tester.getRect(preview).bottom),
        );
        expect(captionBounds.width, greaterThan(220));
        expect(tester.getRect(actions).top, greaterThan(captionBounds.bottom));
        expect(tester.takeException(), isNull);
        await tester.longPress(caption);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('$title\nFavourite\nFrom original'),
          findsOneWidget,
        );
        await tap(tester, preview);
        expect(find.byType(ImageViewerScreen), findsOneWidget);
        await tap(tester, find.byTooltip('Close image viewer'));
        await tap(
          tester,
          find.descendant(of: card, matching: find.text('Use design')),
        );
        expect(selected, option.id);
        expect(
          find.descendant(of: card, matching: find.text('Selected')),
          findsOneWidget,
        );
        expect(store.roomById(room.id)!.approvedDesignId, baseline.id);
        expect(store.roomById(room.id)!.photoIds, [room.originalId]);
        expect(store.imageFor(room.originalId), image);
        expect(store.designsFor(room.id), hasLength(2));
        expect(
          store
              .designsFor(room.id)
              .firstWhere((d) => d.id == option.id)
              .favourite,
          isTrue,
        );
        final strip = find.byWidgetPredicate(
          (widget) => widget is FocusVersionThumbnail && widget.title == title,
        );
        expect(strip, findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'long favourite libraries build nearby previews instead of every image at once',
    (tester) async {
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Office',
        originalImage: image,
      );
      for (var i = 0; i < 30; i++) {
        final design = await store.createDesign(
          roomId: room.id,
          image: image,
          title: 'Design $i',
          prompt: 'Test',
        );
        await store.setFavourite(design, favourite: true);
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LibraryTab(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ExpandableImage).evaluate().length, lessThan(12));
      expect(store.allDesigns, hasLength(30));
      expect(tester.takeException(), isNull);
    },
  );
}
