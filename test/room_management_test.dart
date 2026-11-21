import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/protected_backup.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';
import 'package:renovision_ai/ai_activity.dart';

import 'support/memory_box.dart';

void main() {
  final bytes = img.encodePng(img.Image(width: 40, height: 30));
  test('live and legacy unspecified names follow selected types without changing custom names', () {
    for (final name in ['Live room', 'Live view', 'Unspecified (Live)']) {
      final room = RenovationRoom(
        id: 'r',
        projectId: 'p',
        originalId: 'i',
        name: name,
        roomTypeId: 'kitchen',
        instructions: '',
        protectedFeatures: '',
        created: DateTime(2026),
      );
      expect(room.displayName, 'Kitchen (Live)');
      expect(
        room.copyWith(roomTypeId: 'bedroom').displayName,
        'Bedroom (Live)',
      );
    }
    final custom = RenovationRoom(
      id: 'r',
      projectId: 'p',
      originalId: 'i',
      name: 'Guest retreat',
      roomTypeId: 'bedroom',
      instructions: '',
      protectedFeatures: '',
      created: DateTime(2026),
    );
    expect(custom.displayName, 'Guest retreat');
    expect(
      RenovationRoom.fromMap(
        custom.toMap()
          ..['name'] = 'Unspecified (Live)'
          ..['roomTypeId'] = 'Kitchen',
      ).displayName,
      'Kitchen (Live)',
    );
    expect(
      RenovationRoom.fromMap(custom.toMap()..remove('deleted')).deleted,
      isFalse,
    );
  });

  test('typed deletion retains photos, designs, approval and portable recovery; stale edits cannot resurrect it', () async {
    final records = MemoryBox(), photos = MemoryBox();
    final store = RenovisionStore(records: records, photos: photos);
    addTearDown(store.dispose);
    final p = await store.createProject('Fixture home');
    final room = await store.createRoom(
      projectId: p.id,
      name: 'Kitchen',
      originalImage: bytes,
    );
    final design = await store.createDesign(
      roomId: room.id,
      image: bytes,
      title: 'Saved concept',
      prompt: 'Fixture',
    );
    final before = jsonEncode(photos.entries);
    await store.rememberRoom(room.id);
    await expectLater(
      store.deleteRoom(room.id, confirmation: 'wrong'),
      throwsArgumentError,
    );
    store.ai.activity.begin(roomId: room.id, operation: 'Fixture operation');
    await expectLater(
      store.deleteRoom(room.id, confirmation: 'Kitchen'),
      throwsStateError,
    );
    store.ai.activity.update(AiStage.completed);
    await store.deleteRoom(room.id, confirmation: 'Kitchen');
    expect(store.roomsFor(p.id), isEmpty);
    expect(store.allDesigns, isEmpty);
    expect(store.resumeRoom, isNull);
    expect(store.deletedRoomsFor(p.id).single.id, room.id);
    expect(jsonEncode(photos.entries), before);
    expect(records.get('design:${design.id}'), isNotNull);
    await expectLater(store.updateRoom(room), throwsStateError);
    final encoded = store.backupFor(p.id).encode();
    final checked = ProjectBackup.decode(
      await unlockBackup(
        await protectBackup(encoded, 'fixture-password'),
        'fixture-password',
      ),
    );
    final copy = await store.restoreBackup(checked);
    expect(store.roomsFor(copy.id), isEmpty);
    final restored = store.deletedRoomsFor(copy.id).single;
    await store.restoreRoom(restored.id);
    expect(store.roomsFor(copy.id).single.name, 'Kitchen');
    expect(store.designsFor(restored.id), hasLength(1));
    expect(store.imageFor(restored.originalId), orderedEquals(bytes));
    await store.restoreRoom(room.id);
    expect(store.designsFor(room.id).single.id, design.id);
    expect(jsonEncode(photos.entries), contains('photo_'));
  });

  testWidgets(
    'room list requires the exact name, then offers persistent restoration',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
      addTearDown(store.dispose);
      final project = await store.createProject('Fixture home');
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
      await tester.tap(find.byTooltip('Delete room'));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('confirm-delete-room'));
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('delete-room-name')),
        'Wrong name',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('delete-room-name')),
        'Kitchen',
      );
      await tester.pump();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(store.roomById(room.id), isNull);
      await tester.tap(find.text('Deleted rooms (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Restore Kitchen'));
      await tester.pumpAndSettle();
      expect(store.roomById(room.id), isNotNull);
      expect(find.text('No deleted rooms.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
