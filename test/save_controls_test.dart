import 'support/focus_navigation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/room_save_widgets.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void main() {
  late RenovisionStore store;
  late RenovationRoom room;
  setUp(() async {
    store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    final project = await store.createProject('Claylands');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: img.encodePng(img.Image(width: 40, height: 30)),
    );
  });
  tearDown(() => store.dispose());

  testWidgets(
    'autosave off holds edits until Save now and enabling it resumes saving',
    (tester) async {
      final draft = RoomDraft(store, room);
      await store.setAutosaveEnabled(false);
      draft.changes.text = 'Keep this manual draft';
      await tester.pump(const Duration(milliseconds: 900));
      expect(store.roomById(room.id)!.instructions, '');
      expect(draft.status, contains('autosave off'));
      expect(await draft.save(), true);
      expect(store.roomById(room.id)!.instructions, 'Keep this manual draft');
      draft.changes.text = 'Resume autosaving';
      await store.setAutosaveEnabled(true);
      await tester.pump(const Duration(milliseconds: 900));
      expect(store.roomById(room.id)!.instructions, 'Resume autosaving');
      draft.dispose();
    },
  );

  testWidgets(
    'visible Save now and Save as copy include the pending draft without replacing original images',
    (tester) async {
      await store.setAutosaveEnabled(false);
      final draft = RoomDraft(store, room);
      RenovationProject? copy;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomSaveControls(
              store: store,
              draft: draft,
              activeImage: () => store.imageFor(room.originalId),
              saveAndClose: () async {},
              askName: (_, _) async => 'Kitchen alternative',
              onProjectCopy: (value) => copy = value,
            ),
          ),
        ),
      );
      draft.changes.text = 'Replace appliances and floor';
      await tester.tap(find.text('Save now'));
      await tester.pumpAndSettle();
      expect(
        store.roomById(room.id)!.instructions,
        'Replace appliances and floor',
      );
      draft.changes.text = 'Include latest unsaved update';
      await tester.tap(find.byTooltip('Copy and export options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate project…'));
      await tester.pumpAndSettle();
      expect(copy!.name, 'Kitchen alternative');
      expect(copy!.id, isNot(room.projectId));
      expect(
        store.roomsFor(copy!.id).single.instructions,
        'Include latest unsaved update',
      );
      expect(
        store.imageFor(store.roomsFor(copy!.id).single.originalId),
        orderedEquals(store.imageFor(room.originalId)!),
      );
      expect(store.projectById(room.projectId)!.name, 'Claylands');
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );

  testWidgets('Back saves on exit even when autosave is off', (tester) async {
    await store.setAutosaveEnabled(false);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      WorkspaceScreen(store: store, roomId: room.id),
                ),
              ),
              child: const Text('Open room'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open room'));
    await tester.pumpAndSettle();
    final changes = find.widgetWithText(TextField, 'What should change?');
    await revealFocusControl(
      tester,
      changes,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(changes, 'Saved while leaving');
    await tester.pump(const Duration(milliseconds: 800));
    expect(store.roomById(room.id)!.instructions, '');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open room'), findsOneWidget);
    expect(store.roomById(room.id)!.instructions, 'Saved while leaving');
    expect(store.autosaveEnabled, false);
  });
}
