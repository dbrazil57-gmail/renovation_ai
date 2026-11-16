import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/renovation_scope_widgets.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/room_features.dart';
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

  test(
    'room type is inferred from name but explicit selection takes precedence',
    () {
      expect(resolveRoomType('', 'Kitchen / dining'), 'kitchen');
      expect(resolveRoomType('', 'Main ensuite'), 'bathroom');
      expect(resolveRoomType('', 'Guest bedroom'), 'bedroom');
      expect(resolveRoomType('', 'Study'), 'office');
      expect(resolveRoomType('', 'Laundry'), 'laundry');
      expect(resolveRoomType('', 'Front exterior'), 'exterior');
      expect(resolveRoomType('', 'Room 1'), 'other');
      expect(resolveRoomType('bathroom', 'Old kitchen'), 'bathroom');
    },
  );

  test('replace all appliances with individual oven keep produces no conflicting oven replacement', () {
    final prompt = buildRenovationPrompt(
      roomName: 'Kitchen',
      instructions: '',
      protectedFeatures: 'Keep windows',
      preciseEdit: false,
      roomItemChoices: {
        'kitchen_appliances': 'replace',
        'kitchen_oven': 'keep',
      },
    );
    expect(prompt, contains('KEEP EXISTING Oven:'));
    expect(prompt, isNot(contains('REPLACE Oven:')));
    expect(prompt, contains('REPLACE Microwave:'));
    expect(prompt, contains('REPLACE Cooktop:'));
    expect(prompt, contains('REPLACE Extractor / rangehood:'));
    expect(prompt, contains('visibly new models'));
    expect(prompt, contains('Protected features take priority'));
    expect(prompt, contains('Do not relocate the peninsula'));
    expect(prompt, contains('do not invent unseen items'));
  });

  test('individual replacement overrides keep-all and legacy checkbox remains supported', () {
    final keepMost = buildRoomItemsPrompt('kitchen', {
      'kitchen_appliances': 'keep',
      'kitchen_oven': 'replace',
    }, []);
    expect(keepMost, contains('REPLACE Oven:'));
    expect(keepMost, isNot(contains('KEEP EXISTING Oven:')));
    expect(keepMost, contains('KEEP EXISTING Microwave:'));
    final legacy = buildRoomItemsPrompt('kitchen', {}, ['appliances']);
    expect(legacy, contains('REPLACE Oven:'));
    expect(legacy, contains('REPLACE Dishwasher:'));
    final explicitKeep = buildRoomItemsPrompt(
      'kitchen',
      {'kitchen_appliances': 'keep'},
      ['appliances'],
    );
    expect(explicitKeep, contains('KEEP EXISTING Oven:'));
    expect(explicitKeep, isNot(contains('REPLACE Oven:')));
  });

  test('other room profiles omit irrelevant choices while retaining their saved values', () {
    final prompt = buildRenovationPrompt(
      roomName: 'Kitchen name kept',
      instructions: '',
      protectedFeatures: '',
      preciseEdit: false,
      roomTypeId: 'bathroom',
      renovationScopeIds: ['appliances', 'benchtops'],
      roomItemChoices: {
        'kitchen_oven': 'replace',
        'bathroom_vanity': 'replace',
        'bathroom_bath': 'keep',
      },
    );
    expect(prompt, contains('ROOM TYPE: Bathroom'));
    expect(prompt, contains('REPLACE Vanity / basin:'));
    expect(prompt, contains('KEEP EXISTING Bath:'));
    expect(prompt, isNot(contains('REPLACE Oven:')));
    expect(prompt, isNot(contains('Replace benchtop surfaces')));
    expect(prompt, isNot(contains('Do not relocate the peninsula')));
    expect(
      buildRoomItemsPrompt('laundry', {'kitchen_appliances': 'replace'}, []),
      isEmpty,
    );
  });

  testWidgets(
    'keep-only choices do not count as a precision change and type switching preserves inactive choices',
    (tester) async {
      final draft = RoomDraft(store, room);
      draft.setItemChoice('kitchen_appliances', 'keep');
      expect(draft.hasRequestedChanges, false);
      draft.setItemChoice('kitchen_oven', 'replace');
      expect(draft.hasRequestedChanges, true);
      draft.setRoomType('bathroom');
      expect(draft.hasRequestedChanges, false);
      draft.setItemChoice('bathroom_shower', 'replace');
      expect(draft.hasRequestedChanges, true);
      expect(draft.scopePrompt, isNot(contains('Oven')));
      await tester.pump(const Duration(milliseconds: 700));
      final restoredProject = await store.restoreBackup(
        ProjectBackup.decode(store.backupFor(room.projectId).encode()),
      );
      final restored = store.roomsFor(restoredProject.id).single;
      expect(restored.roomTypeId, 'bathroom');
      expect(restored.roomItemChoices, {
        'kitchen_appliances': 'keep',
        'kitchen_oven': 'replace',
        'bathroom_shower': 'replace',
      });
      final reopen = RoomDraft(store, store.roomById(room.id)!);
      reopen.setRoomType('kitchen');
      expect(reopen.scopePrompt, contains('REPLACE Oven:'));
      expect(reopen.scopePrompt, isNot(contains('Shower')));
      await reopen.save();
      reopen.dispose();
      draft.dispose();
    },
  );

  testWidgets(
    'phone-width room selector changes controls and item choices autosave',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final draft = RoomDraft(store, room);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListenableBuilder(
                listenable: draft,
                builder: (context, _) => RenovationScopeControls(draft: draft),
              ),
            ),
          ),
        ),
      );
      Finder field(String label) => find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String> &&
            widget.decoration.labelText == label,
      );
      Future<void> choose(String label, String option) async {
        await tester.ensureVisible(field(label));
        await tester.pumpAndSettle();
        await tester.tap(field(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(option).last);
        await tester.pumpAndSettle();
      }

      await choose('All kitchen appliances', 'Replace / update');
      await tester.ensureVisible(find.text('Individual appliances (optional)'));
      await tester.tap(find.text('Individual appliances (optional)'));
      await tester.pumpAndSettle();
      await choose('Oven', 'Keep existing');
      await tester.pump(const Duration(milliseconds: 700));
      expect(store.roomById(room.id)!.roomItemChoices, {
        'kitchen_appliances': 'replace',
        'kitchen_oven': 'keep',
      });
      await choose('Room type', 'Bathroom');
      expect(field('All kitchen appliances'), findsNothing);
      expect(field('Vanity / basin'), findsOneWidget);
      await choose('Vanity / basin', 'Replace / update');
      await tester.pump(const Duration(milliseconds: 700));
      expect(store.roomById(room.id)!.roomTypeId, 'bathroom');
      expect(store.roomById(room.id)!.roomItemChoices['kitchen_oven'], 'keep');
      expect(
        store.roomById(room.id)!.roomItemChoices['bathroom_vanity'],
        'replace',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );

  test('backup rejects malformed item-choice values before restoration', () {
    final data = jsonDecode(
      utf8.decode(store.backupFor(room.projectId).encode()),
    );
    data['rooms'][0]['roomItemChoices'] = {'kitchen_oven': 'maybe'};
    expect(
      () => ProjectBackup.decode(utf8.encode(jsonEncode(data))),
      throwsA(isA<BackupFailure>()),
    );
  });
}
