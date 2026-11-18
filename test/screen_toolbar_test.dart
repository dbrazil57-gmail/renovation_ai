import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/screen_toolbar.dart';

import 'dart:typed_data';

import 'package:renovision_ai/file_transfer.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/main.dart';
import 'package:renovision_ai/store.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/editors.dart';
import 'package:renovision_ai/room_setup.dart';
import 'package:renovision_ai/image_viewer.dart';

import 'support/memory_box.dart';

class ToolbarFiles implements AppFiles {
  Uint8List? bytes;
  @override
  bool get supported => true;
  @override
  Future<Uint8List?> pickBackup() async => null;
  @override
  Future<FileSaveResult> save(
    Uint8List value, {
    required String name,
    required String mimeType,
  }) async {
    bytes = Uint8List.fromList(value);
    return FileSaveResult.saved;
  }
}

class FailAutosaveRecords extends MemoryBox {
  bool failAutosave = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (failAutosave && key == 'settings:saving') {
      throw StateError('Saving preference failed');
    }
    await super.put(key, value);
  }
}

void main() {
  for (final width in [390.0, 1000.0]) {
    testWidgets('Autosave stays in the menu and persists at width $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final records = MemoryBox();
      final photos = MemoryBox();
      final store = RenovisionStore(records: records, photos: photos);
      addTearDown(store.dispose);
      final project = await store.createProject('Home');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: img.encodePng(img.Image(width: 40, height: 30)),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Autosave'), findsNothing);
      expect(find.textContaining('Autosave on ·'), findsOneWidget);
      await tester.tap(find.byTooltip('More tools'));
      await tester.pumpAndSettle();
      final autosave = find.byWidgetPredicate(
        (widget) =>
            widget is CheckedPopupMenuItem<ScreenAction> &&
            widget.value == ScreenAction.autosave,
      );
      expect(
        tester.widget<CheckedPopupMenuItem<ScreenAction>>(autosave).checked,
        isTrue,
      );
      await tester.tap(find.text('Autosave'));
      await tester.pumpAndSettle();
      expect(store.autosaveEnabled, isFalse);
      expect(find.textContaining('Autosave off ·'), findsOneWidget);
      final reopened = RenovisionStore(records: records, photos: photos);
      expect(reopened.autosaveEnabled, isFalse);
      reopened.dispose();
      await tester.tap(find.byTooltip('More tools'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<CheckedPopupMenuItem<ScreenAction>>(autosave).checked,
        isFalse,
      );
      await tester.tap(find.text('Autosave'));
      await tester.pumpAndSettle();
      expect(store.autosaveEnabled, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('failed Autosave menu change retains the old preference', (
    tester,
  ) async {
    final records = FailAutosaveRecords();
    final store = RenovisionStore(records: records, photos: MemoryBox());
    addTearDown(store.dispose);
    final project = await store.createProject('Home');
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: img.encodePng(img.Image(width: 40, height: 30)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: WorkspaceScreen(store: store, roomId: room.id),
      ),
    );
    await tester.pumpAndSettle();
    records.failAutosave = true;
    await tester.tap(find.byTooltip('More tools'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autosave'));
    await tester.pumpAndSettle();
    expect(store.autosaveEnabled, isTrue);
    expect(
      find.text(
        'Could not change Autosave. Its previous setting is still active.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shared order stays consistent when irrelevant tools are omitted',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                ScreenToolbar(
                  tools: [
                    ScreenTool(
                      ScreenAction.rename,
                      label: 'Rename',
                      onPressed: () {},
                    ),
                    ScreenTool(
                      ScreenAction.save,
                      label: 'Save',
                      onPressed: () {},
                    ),
                    ScreenTool(
                      ScreenAction.settings,
                      label: 'Settings',
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      final labels = tester
          .widgetList<IconButton>(
            find.descendant(
              of: find.byType(ScreenToolbar),
              matching: find.byType(IconButton),
            ),
          )
          .map((w) => w.tooltip);
      expect(labels, ['Save', 'Settings', 'Rename']);
      expect(find.byTooltip('Undo'), findsNothing);
    },
  );
  testWidgets(
    'phone overflow keeps order, invokes the right action, and respects disabled tools',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      var renamed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text(
                'A long room name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                ScreenToolbar(
                  tools: [
                    ScreenTool(
                      ScreenAction.rename,
                      label: 'Rename room',
                      onPressed: () => renamed++,
                    ),
                    ScreenTool(
                      ScreenAction.settings,
                      label: 'Room settings',
                      onPressed: () {},
                    ),
                    const ScreenTool(
                      ScreenAction.setup,
                      label: 'Guided room setup',
                      onPressed: null,
                    ),
                    ScreenTool(
                      ScreenAction.save,
                      label: 'Save project file',
                      onPressed: () {},
                    ),
                    ScreenTool(
                      ScreenAction.help,
                      label: 'Help',
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('More tools'));
      await tester.pumpAndSettle();
      final menu = tester.widgetList<PopupMenuItem<ScreenAction>>(
        find.byType(PopupMenuItem<ScreenAction>),
      );
      expect(menu.map((w) => w.value), [
        ScreenAction.rename,
        ScreenAction.help,
      ]);
      await tester.tap(find.text('Rename room'));
      await tester.pumpAndSettle();
      expect(renamed, 1);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Guided room setup',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'phone app home shows contextual Settings and hides redundant Settings on its page',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
      addTearDown(store.dispose);
      await tester.pumpWidget(RenovisionApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings and privacy'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'project toolbar opens existing Save controls without changing images',
    (tester) async {
      final files = ToolbarFiles();
      final store = RenovisionStore(
        records: MemoryBox(),
        photos: MemoryBox(),
        files: files,
      );
      addTearDown(store.dispose);
      final project = await store.createProject('Toolbar project');
      final bytes = img.encodePng(img.Image(width: 30, height: 20));
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: bytes,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectScreen(store: store, project: project),
        ),
      );
      await tester.pumpAndSettle();
      final toolbar = tester.widget<ScreenToolbar>(find.byType(ScreenToolbar));
      expect(
        toolbar.tools.map((t) => t.action),
        containsAll([
          ScreenAction.save,
          ScreenAction.settings,
          ScreenAction.rename,
        ]),
      );
      await tester.tap(find.byTooltip('Save project file'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Save project'),
        ),
      );
      await tester.pumpAndSettle();
      expect(ProjectBackup.decode(files.bytes!).rooms.single.id, room.id);
      expect(store.imageFor(room.originalId), bytes);
      expect(store.designsFor(room.id), isEmpty);
    },
  );
  testWidgets(
    'comparison reset and image viewer have only their relevant tools',
    (tester) async {
      final bytes = img.encodePng(img.Image(width: 40, height: 30));
      await tester.pumpWidget(
        MaterialApp(
          home: CompareScreen(original: bytes, edited: bytes),
        ),
      );
      await tester.pumpAndSettle();
      tester.widget<Slider>(find.byType(Slider)).onChanged!(.8);
      await tester.pump();
      await tester.tap(find.byTooltip('Reset comparison'));
      await tester.pump();
      expect(tester.widget<Slider>(find.byType(Slider)).value, .5);
      expect(find.byTooltip('Save project file'), findsNothing);
      await tester.pumpWidget(
        MaterialApp(
          home: ImageViewerScreen(bytes: bytes, title: 'Kitchen'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ScreenToolbar>(find.byType(ScreenToolbar))
            .tools
            .map((t) => t.action),
        [
          ScreenAction.zoomOut,
          ScreenAction.zoomIn,
          ScreenAction.fit,
          ScreenAction.help,
        ],
      );
      expect(find.byTooltip('Room settings'), findsNothing);
    },
  );
  testWidgets(
    'wizard Settings saves edits and returns to the same setup step',
    (tester) async {
      final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
      addTearDown(store.dispose);
      final project = await store.createProject('Setup toolbar');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        guidedSetup: true,
        originalImage: img.encodePng(img.Image(width: 40, height: 30)),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RoomSetupScreen(
            store: store,
            roomId: room.id,
            workspace: (_) => const Scaffold(),
            settingsBuilder: (_) => const Scaffold(body: Text('Test settings')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Your renovation goal (optional)'),
        'Keep the window and change the floor',
      );
      await tester.tap(find.byTooltip('Room settings'));
      await tester.pumpAndSettle();
      expect(find.text('Test settings'), findsOneWidget);
      expect(
        store.roomById(room.id)!.instructions,
        'Keep the window and change the floor',
      );
      Navigator.of(tester.element(find.text('Test settings'))).pop();
      await tester.pumpAndSettle();
      expect(find.textContaining('Step 2 of 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
