import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/app_session.dart';
import 'package:renovision_ai/focus_workspace.dart';
import 'package:renovision_ai/editors.dart';
import 'package:renovision_ai/image_viewer.dart';
import 'package:renovision_ai/local_paint.dart';
import 'package:renovision_ai/local_paint_screen.dart';
import 'package:renovision_ai/main.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/focus_navigation.dart';
import 'support/memory_box.dart';

Future<void> waitForPage(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 100 && !ready(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(ready(), isTrue);
}

Future<void> reloadApp(WidgetTester tester, RenovisionStore store) async {
  await tester.pump(const Duration(seconds: 1));
  final session = tester
      .widget<AppPageSessionScope>(find.byType(AppPageSessionScope))
      .session;
  await session.flush();
  final pages = store.records.get(AppPageSession.recordKey) as List;
  final reopenPaint = (pages.last as Map)['page'] == 'finishes';
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(RenovisionApp(store: store));
  await tester.pump(const Duration(milliseconds: 600));
  if (reopenPaint) {
    await waitForPage(
      tester,
      () => find.byKey(const ValueKey('paint-canvas')).evaluate().isNotEmpty,
    );
    await tester.pump(const Duration(milliseconds: 600));
  }
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await waitForPage(
    tester,
    () =>
        find.byType(CircularProgressIndicator).evaluate().isEmpty &&
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is LinearProgressIndicator && widget.value == null,
            )
            .evaluate()
            .isEmpty,
  );
  await tester.pumpAndSettle();
}

void main() {
  late RenovisionStore store;
  final photo = img.encodePng(img.Image(width: 80, height: 60));
  setUp(
    () => store = RenovisionStore(records: MemoryBox(), photos: MemoryBox()),
  );
  tearDown(() => store.dispose());

  testWidgets(
    'Home in Rooms and spaces returns to Projects and retains all images and designs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final project = await store.createProject('Home navigation');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: photo,
        additionalImages: [photo],
      );
      final design = await store.createDesign(
        roomId: room.id,
        image: photo,
        title: 'Saved option',
        prompt: 'Fixture',
      );
      await tester.pumpWidget(RenovisionApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home navigation'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Projects home'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectsTab), findsOneWidget);
      expect(find.byType(ProjectScreen), findsNothing);
      expect(store.roomById(room.id)!.photoIds, hasLength(2));
      expect(store.designsFor(room.id).single.id, design.id);
      expect(store.imageFor(room.originalId), orderedEquals(photo));
      expect(store.imageFor(design.imageId), orderedEquals(photo));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'setup shortcuts retain progress and workspace choice across reload and new photos',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await store.setAutosaveEnabled(false);
      final project = await store.createProject('Navigation test');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Balcony',
        originalImage: photo,
        guidedSetup: true,
      );
      await tester.pumpWidget(RenovisionApp(store: store));
      await tester.pumpAndSettle();
      await revealFocusControl(tester, find.text('Navigation test'), 300);
      await tester.tap(find.text('Navigation test'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Continue setup · step 1 of 4'),
        findsOneWidget,
      );
      await tester.tap(find.text('Balcony'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Your renovation goal (optional)'),
        'Keep the view, change the finishes',
      );
      await tester.tap(find.byTooltip('More tools'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rooms & spaces'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectScreen), findsOneWidget);
      expect(find.byType(WorkspaceScreen), findsNothing);
      expect(
        find.textContaining('Continue setup · step 2 of 4'),
        findsOneWidget,
      );
      expect(
        store.roomById(room.id)!.instructions,
        'Keep the view, change the finishes',
      );
      await tester.tap(find.text('Balcony'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 4 · Design direction'), findsOneWidget);
      await reloadApp(tester, store);
      expect(find.text('Step 2 of 4 · Design direction'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('setup-open-workspace')));
      await tester.pumpAndSettle();
      expect(find.byType(WorkspaceScreen), findsOneWidget);
      expect(store.roomById(room.id)!.setupComplete, isTrue);
      await tester.tap(find.byTooltip('Guided room setup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Your renovation goal (optional)'),
        'Keep these newer choices too',
      );
      await tester.tap(find.byTooltip('Projects home'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectsTab), findsOneWidget);
      expect(find.byType(WorkspaceScreen), findsNothing);
      expect(
        store.roomById(room.id)!.instructions,
        'Keep these newer choices too',
      );
      await store.addRoomPhotos(room.id, [photo]);
      await revealFocusControl(tester, find.text('Navigation test'), 300);
      await tester.tap(find.text('Navigation test'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Continue setup · step'), findsNothing);
      await tester.tap(find.text('Balcony'));
      await tester.pumpAndSettle();
      expect(find.byType(WorkspaceScreen), findsOneWidget);
      expect(store.roomById(room.id)!.photoIds, hasLength(2));
      expect(store.designsFor(room.id), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('project shortcuts save edits and leave the workspace directly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await store.setAutosaveEnabled(false);
    final project = await store.createProject('Shortcut test');
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: photo,
    );
    await tester.pumpWidget(RenovisionApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shortcut test'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kitchen'));
    await tester.pumpAndSettle();
    for (final destination in ['Rooms & spaces', 'Projects home']) {
      await tester.tap(find.byKey(const ValueKey('focus-section-refine')));
      await tester.pumpAndSettle();
      final goal = find.widgetWithText(TextField, 'What should change?');
      await ensureFocusVisible(tester, goal);
      await tester.enterText(goal, 'Save before $destination');
      if (destination == 'Projects home') {
        await tester.tap(find.byTooltip('Projects home'));
      } else {
        await tester.tap(find.byTooltip('More tools'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(destination));
      }
      await tester.pumpAndSettle();
      expect(store.roomById(room.id)!.instructions, 'Save before $destination');
      if (destination == 'Rooms & spaces') {
        expect(find.byType(ProjectScreen), findsOneWidget);
        await tester.tap(find.text('Kitchen'));
        await tester.pumpAndSettle();
      } else {
        expect(find.byType(ProjectsTab), findsOneWidget);
        expect(find.byType(WorkspaceScreen), findsNothing);
      }
    }
    expect(store.imageFor(room.originalId), isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Back leaves the workspace screen after Settings and refresh instead of cycling tabs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final project = await store.createProject('Back test');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Exterior',
        originalImage: photo,
        roomTypeId: 'exterior',
      );
      await tester.pumpWidget(RenovisionApp(store: store));
      await tester.pumpAndSettle();
      await ensureFocusVisible(tester, find.text('Back test'));
      await tester.tap(find.text('Back test'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exterior'));
      await tester.pumpAndSettle();
      for (final section in [
        FocusSection.style,
        FocusSection.refine,
        FocusSection.ideas,
      ]) {
        await tester.tap(find.byKey(ValueKey('focus-section-${section.name}')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Room settings'));
      await tester.pumpAndSettle();
      await reloadApp(tester, store);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester.widget<FocusWorkspace>(find.byType(FocusWorkspace)).selected,
        FocusSection.ideas,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ProjectScreen), findsOneWidget);
      expect(store.imageFor(room.originalId), isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'setup opened from a workspace returns there with new choices even after refresh',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final project = await store.createProject('Setup return');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Patio',
        originalImage: photo,
        roomTypeId: 'patio',
      );
      await tester.pumpWidget(RenovisionApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setup return'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Patio'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Guided room setup'));
      await tester.pumpAndSettle();
      await reloadApp(tester, store);
      expect(find.text('Step 1 of 4 · Room photos'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Your renovation goal (optional)'),
        'Retain brick, update the patio roof',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(WorkspaceScreen), findsOneWidget);
      expect(store.roomById(room.id)!.setupComplete, isTrue);
      await tester.tap(find.byKey(const ValueKey('focus-section-refine')));
      await tester.pumpAndSettle();
      final goal = find.widgetWithText(TextField, 'What should change?');
      await ensureFocusVisible(tester, goal);
      expect(
        tester.widget<TextField>(goal).controller!.text,
        'Retain brick, update the patio roof',
      );
      expect(
        store.roomById(room.id)!.instructions,
        'Retain brick, update the patio roof',
      );
      expect(store.imageFor(room.originalId), isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'refresh retains main tab, project, selected version, workspace tab/mode and Settings back stack',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final project = await store.createProject('Claylands');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: photo,
      );
      final approved = await store.createDesign(
        roomId: room.id,
        image: photo,
        title: 'Approved option',
        prompt: '',
      );
      final other = await store.createDesign(
        roomId: room.id,
        image: photo,
        title: 'Other option',
        prompt: '',
      );
      await store.approveBaseline(room.id, designId: approved.id);
      await tester.pumpWidget(RenovisionApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      await reloadApp(tester, store);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      await ensureFocusVisible(tester, find.text('Claylands'));
      await tester.tap(find.text('Claylands'));
      await tester.pumpAndSettle();
      await reloadApp(tester, store);
      expect(find.byType(ProjectScreen), findsOneWidget);
      await tester.tap(find.text('Kitchen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Room').last);
      await tester.pumpAndSettle();
      final working = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<String> &&
            w.decoration.labelText == 'Working from',
      );
      await ensureFocusVisible(tester, working);
      await tester.tap(working);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Other option').last);
      await tester.pumpAndSettle();
      await ensureFocusVisible(tester, find.text('Partial'));
      await tester.tap(find.text('Partial'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Style'));
      await tester.pumpAndSettle();
      await reloadApp(tester, store);
      expect(
        tester.widget<FocusWorkspace>(find.byType(FocusWorkspace)).selected,
        FocusSection.style,
      );
      final selectedPage = tester
          .widgetList<SavedAppPage>(find.byType(SavedAppPage))
          .singleWhere((w) => w.page['page'] == 'workspace')
          .page;
      expect(selectedPage['designId'], other.id);
      expect(selectedPage['mode'], 'partial');
      expect(store.roomById(room.id)!.approvedDesignId, approved.id);
      await tester.tap(find.byTooltip('Room settings'));
      await tester.pumpAndSettle();
      await reloadApp(tester, store);
      expect(find.text('Settings and privacy'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester.widget<FocusWorkspace>(find.byType(FocusWorkspace)).selected,
        FocusSection.style,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ProjectScreen), findsOneWidget);
      expect(store.designsFor(room.id), hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'refresh in finishes restores the editor phase and saved selection without creating a design or AI call',
    (tester) async {
      final project = await store.createProject('Paint project');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: photo,
      );
      final recipe = LocalPaintRecipe(
        width: 80,
        height: 60,
        surfaces: [
          PaintSurface(
            name: 'Splashback 1',
            kind: LocalSurfaceKind.splashback,
            finish: LocalFinish.rectangleTiles,
            marks: [
              PaintMark(PaintMarkKind.polygon, const [
                PaintPoint(.1, .1),
                PaintPoint(.8, .1),
                PaintPoint(.8, .8),
              ]),
            ],
          ),
        ],
      );
      await store.savePaintDraft(room.id, room.originalId, recipe);
      await store.records.put(AppPageSession.recordKey, [
        {'page': 'home', 'tab': 0},
        {'page': 'project', 'projectId': project.id},
        {
          'page': 'workspace',
          'projectId': project.id,
          'roomId': room.id,
          'photoId': room.originalId,
          'section': 'style',
          'mode': 'newDesign',
        },
      ]);
      await tester.pumpWidget(RenovisionApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Colours & tiles without AI'));
      await tester.pump();
      await waitForPage(
        tester,
        () => find.text('2 Finish').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('2 Finish'));
      await tester.pump(const Duration(milliseconds: 600));
      await waitForPage(
        tester,
        () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
      );
      await tester.pumpAndSettle();
      await reloadApp(tester, store);
      await waitForPage(
        tester,
        () =>
            find.byType(LocalPaintScreen).evaluate().isNotEmpty &&
            find.text('Custom colour').evaluate().isNotEmpty,
      );
      final page = tester
          .widgetList<SavedAppPage>(find.byType(SavedAppPage))
          .singleWhere((w) => w.page['page'] == 'finishes')
          .page;
      expect(page['panel'], 1);
      expect(
        store.roomById(room.id)!.paintDrafts[room.originalId]!.toMap(),
        recipe.toMap(),
      );
      expect(store.designsFor(room.id), isEmpty);
      expect(store.imageFor(room.originalId), orderedEquals(photo));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'refresh retains workspace image viewer, comparison, crop and markup pages without creating versions',
    (tester) async {
      final project = await store.createProject('Tool project');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: photo,
      );
      final design = await store.createDesign(
        roomId: room.id,
        image: photo,
        title: 'Chosen image',
        prompt: '',
      );
      await store.records.put(AppPageSession.recordKey, [
        {'page': 'home', 'tab': 0},
        {
          'page': 'workspace',
          'projectId': project.id,
          'roomId': room.id,
          'designId': design.id,
          'section': 'refine',
          'mode': 'precise',
        },
      ]);
      await tester.pumpWidget(RenovisionApp(store: store));
      await tester.pumpAndSettle();
      for (final (tooltip, type) in [
        ('Open image full screen', ImageViewerScreen),
        ('Compare original', CompareScreen),
        ('Crop / focus', FocusEditScreen),
        ('Sketch / markup', FocusEditScreen),
      ]) {
        await tester.tap(find.byTooltip(tooltip));
        await tester.pumpAndSettle();
        await reloadApp(tester, store);
        expect(find.byType(type), findsOneWidget, reason: tooltip);
        if (tooltip == 'Sketch / markup') {
          expect(
            tester.widget<FocusEditScreen>(find.byType(FocusEditScreen)).sketch,
            isTrue,
          );
        }
        Navigator.of(tester.element(find.byType(type))).pop();
        await tester.pumpAndSettle();
      }
      expect(store.designsFor(room.id), hasLength(1));
      expect(store.imageFor(design.imageId), orderedEquals(photo));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invalid or archived session target returns safely to Projects and session stays out of project exports',
    (tester) async {
      final project = await store.createProject('Preserved project');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: photo,
      );
      await store.archiveProject(project.id, confirmation: project.name);
      await store.records.put(AppPageSession.recordKey, [
        {'page': 'home', 'tab': 0},
        {
          'page': 'workspace',
          'projectId': project.id,
          'roomId': room.id,
          'section': 'refine',
        },
      ]);
      await tester.pumpWidget(RenovisionApp(store: store));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(WorkspaceScreen), findsNothing);
      expect(store.imageFor(room.originalId), orderedEquals(photo));
      expect(
        String.fromCharCodes(store.backupFor(project.id).encode()),
        isNot(contains(AppPageSession.recordKey)),
      );
      await tester.pumpWidget(const SizedBox());
      await store.records.put(AppPageSession.recordKey, {'broken': 'record'});
      await tester.pumpWidget(RenovisionApp(store: store));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
