import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/context_help.dart';
import 'package:renovision_ai/file_transfer.dart';
import 'package:renovision_ai/focus_workspace.dart';
import 'package:renovision_ai/image_viewer.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/room_camera.dart';
import 'package:renovision_ai/room_start_widgets.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';
import 'support/focus_navigation.dart';

class ProjectTestFiles implements AppFiles {
  Uint8List? opening;
  int picks = 0;
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
  }) async => FileSaveResult.saved;
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
      expect(store.projects, hasLength(2));
      expect(store.roomsFor(project.id).single.id, room.id);
      expect(store.imageFor(room.originalId), image);
      expect(find.byType(ProjectScreen), findsOneWidget);
    },
  );

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
