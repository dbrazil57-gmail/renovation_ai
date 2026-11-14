import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/design_styles.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

class DraftRecords extends MemoryBox {
  bool fail = false;
  Completer<void>? gate;
  Completer<void>? entered;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (key.toString().startsWith('room:')) {
      if (fail) throw StateError('Simulated storage failure');
      final wait = gate;
      if (wait != null) {
        gate = null;
        entered?.complete();
        await wait.future;
      }
    }
    return super.put(key, value);
  }
}

void main() {
  late RenovisionStore store;
  late DraftRecords records;
  late RenovationRoom room;
  late Uint8List image;
  setUp(() async {
    records = DraftRecords();
    store = RenovisionStore(records: records, photos: MemoryBox());
    image = img.encodePng(img.Image(width: 40, height: 30));
    final project = await store.createProject('Claylands');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: image,
    );
  });
  tearDown(() => store.dispose());

  test('broad kitchen prompt has coherent scope, styles and no contradictory retain clause', () {
    final prompt = buildRenovationPrompt(
      roomName: 'Kitchen',
      instructions: 'New appliances, cupboards, benchtops and large tiles',
      protectedFeatures: 'Nothing. all to change.',
      preciseEdit: false,
      designStyleIds: ['modern', 'contemporary'],
      otherStyle: 'Warm, handleless cupboards',
    );
    expect(prompt, contains('coordinated renovation'));
    expect(
      prompt,
      contains('Modern + Contemporary + Warm, handleless cupboards'),
    );
    expect(prompt, contains('Keep the existing walls'));
    expect(prompt, isNot(contains('MUST RETAIN: Nothing')));
    expect(
      prompt,
      isNot(contains('Change only the explicitly requested area')),
    );
    expect(prompt, contains('usable doors, panels and shelving'));
    expect(prompt, contains('If no room image is attached'));
  });

  test(
    'nothing except windows remains a protection; precision stays narrow',
    () {
      final prompt = buildRenovationPrompt(
        roomName: 'Kitchen',
        instructions: 'Change only the oven',
        protectedFeatures: 'Nothing except the windows',
        preciseEdit: true,
        designStyleIds: ['modern'],
      );
      expect(prompt, contains('MUST RETAIN: Nothing except the windows'));
      expect(prompt, contains('PRECISION EDIT'));
      expect(prompt, contains('Do not silently remove items outside'));
      expect(
        looksLikeBroadRenovation('New cupboards, benchtops and flooring'),
        isTrue,
      );
      expect(looksLikeBroadRenovation('Change only the oven'), isFalse);
    },
  );

  testWidgets(
    'draft autosaves text, checkboxes, mode and free style direction',
    (tester) async {
      final draft = RoomDraft(store, room);
      addTearDown(draft.dispose);
      draft.changes.text = 'New cabinets and floor';
      draft.protected.text = 'Keep the windows';
      draft.otherStyle.text = 'Warm and practical';
      draft.setStyle('modern', true);
      draft.setStyle('contemporary', true);
      draft.setPrecise(false);
      expect(draft.state, DraftSaveState.pending);
      await tester.pump(const Duration(milliseconds: 700));
      expect(draft.state, DraftSaveState.saved);
      expect(draft.dirty, isFalse);
      final saved = store.roomById(room.id)!;
      expect(saved.instructions, 'New cabinets and floor');
      expect(saved.otherStyle, 'Warm and practical');
      expect(saved.designStyleIds, ['modern', 'contemporary']);
      final restored = await store.restoreBackup(
        ProjectBackup.decode(store.backupFor(room.projectId).encode()),
      );
      expect(
        store.roomsFor(restored.id).single.otherStyle,
        'Warm and practical',
      );
      expect(store.roomsFor(restored.id).single.designStyleIds, [
        'modern',
        'contemporary',
      ]);
      expect(store.imageFor(room.originalId), orderedEquals(image));
    },
  );

  testWidgets('save failure keeps draft available for an explicit retry', (
    tester,
  ) async {
    final draft = RoomDraft(store, room);
    addTearDown(draft.dispose);
    records.fail = true;
    draft.changes.text = 'Keep this draft';
    await tester.pump(const Duration(milliseconds: 700));
    expect(draft.state, DraftSaveState.failed);
    expect(draft.dirty, isTrue);
    expect(draft.changes.text, 'Keep this draft');
    expect(store.roomById(room.id)!.instructions, '');
    records.fail = false;
    expect(await draft.save(), isTrue);
    expect(draft.state, DraftSaveState.saved);
    expect(store.roomById(room.id)!.instructions, 'Keep this draft');
  });

  testWidgets(
    'queued saves keep the newer text when an earlier write is slow',
    (tester) async {
      final draft = RoomDraft(store, room);
      addTearDown(draft.dispose);
      final gate = Completer<void>();
      records.gate = gate;
      records.entered = Completer<void>();
      draft.changes.text = 'Older draft';
      final first = draft.save();
      await records.entered!.future;
      draft.changes.text = 'Newer draft';
      final second = draft.save();
      gate.complete();
      await Future.wait([first, second]);
      expect(store.roomById(room.id)!.instructions, 'Newer draft');
      expect(draft.dirty, isFalse);
    },
  );

  testWidgets('style chips and Other field autosave in the workspace', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WorkspaceScreen(store: store, roomId: room.id),
      ),
    );
    await tester.pumpAndSettle();
    final modern = find.widgetWithText(FilterChip, 'Modern');
    await tester.scrollUntilVisible(
      modern,
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(modern);
    await tester.tap(modern);
    final other = find.widgetWithText(
      TextField,
      'Other style / extra direction',
    );
    await tester.ensureVisible(other);
    await tester.enterText(
      other,
      'Warm charcoal and walnut, practical storage',
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(store.roomById(room.id)!.designStyleIds, ['modern']);
    expect(
      store.roomById(room.id)!.otherStyle,
      'Warm charcoal and walnut, practical storage',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('back navigation saves a pending draft before leaving the room', (
    tester,
  ) async {
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
    await tester.scrollUntilVisible(
      changes,
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(changes, 'Save before leaving');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open room'), findsOneWidget);
    expect(store.roomById(room.id)!.instructions, 'Save before leaving');
    expect(tester.takeException(), isNull);
  });
}
