import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/room_photos.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

class FailPhotoUpdate extends MemoryBox {
  bool fail = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (fail && key.toString().startsWith('room:')) {
      fail = false;
      throw StateError('Simulated disk failure');
    }
    return super.put(key, value);
  }
}

void main() {
  late RenovisionStore store;
  late FailPhotoUpdate records;
  late MemoryBox photos;
  late RenovationRoom room;
  late Uint8List image;
  setUp(() async {
    records = FailPhotoUpdate();
    photos = MemoryBox();
    store = RenovisionStore(records: records, photos: photos);
    image = img.encodePng(img.Image(width: 40, height: 30));
    final project = await store.createProject('Claylands');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Office',
      originalImage: image,
    );
  });
  tearDown(() => store.dispose());

  test(
    'multiple views, primary and AI supporting IDs survive backup restore',
    () async {
      await store.addRoomPhotos(room.id, [image, image]);
      final views = store.roomById(room.id)!.photoIds;
      await store.setPrimaryPhoto(room.id, views.last);
      final design = await store.createDesign(
        roomId: room.id,
        image: image,
        title: 'Combined design',
        prompt: 'Use all room views',
        sourceImageId: views.last,
        supportingImageIds: views.take(2).toList(),
      );
      await store.approveBaseline(room.id, designId: design.id);
      final restored = await store.restoreBackup(
        ProjectBackup.decode(store.backupFor(room.projectId).encode()),
      );
      final copy = store.roomsFor(restored.id).single;
      expect(copy.photoIds, hasLength(3));
      expect(copy.primaryId, copy.photoIds.last);
      final generated = store.designsFor(copy.id).single;
      expect(generated.sourceImageId, copy.primaryId);
      expect(generated.supportingImageIds, copy.photoIds.take(2).toList());
      expect(copy.approvedDesignId, generated.id);
      for (final id in copy.photoIds) {
        expect(store.imageFor(id), orderedEquals(image));
      }
      expect(store.roomById(room.id)!.originalId, room.originalId);
    },
  );

  test('failed photo append rolls back only newly written photos', () async {
    final before = jsonEncode(photos.entries);
    records.fail = true;
    await expectLater(
      store.addRoomPhotos(room.id, [image, image]),
      throwsStateError,
    );
    expect(jsonEncode(photos.entries), before);
    expect(store.roomById(room.id)!.photoIds, [room.originalId]);
    await expectLater(
      store.addRoomPhotos(room.id, List.filled(6, image)),
      throwsArgumentError,
    );
    expect(jsonEncode(photos.entries), before);
  });

  test('old one-photo records and version-1 backups still load', () {
    final data = jsonDecode(
      utf8.decode(store.backupFor(room.projectId).encode()),
    ) as Map<String, dynamic>;
    data['version'] = 1;
    (data['rooms'] as List).first.remove('additionalPhotoIds');
    (data['rooms'] as List).first.remove('primaryPhotoId');
    final backup = ProjectBackup.decode(
      Uint8List.fromList(utf8.encode(jsonEncode(data))),
    );
    expect(backup.rooms.single.photoIds, [room.originalId]);
    expect(backup.rooms.single.primaryId, room.originalId);
  });

  test('unrelated primary view is rejected before restore', () async {
    await store.addRoomPhotos(room.id, [image]);
    final data = jsonDecode(
      utf8.decode(store.backupFor(room.projectId).encode()),
    ) as Map<String, dynamic>;
    data['rooms'][0]['primaryPhotoId'] = 'missing';
    expect(
      () => ProjectBackup.decode(
        Uint8List.fromList(utf8.encode(jsonEncode(data))),
      ),
      throwsA(isA<BackupFailure>()),
    );
    await expectLater(
      store.setPrimaryPhoto(room.id, 'missing'),
      throwsArgumentError,
    );
    expect(store.roomById(room.id)!.primaryId, room.originalId);
  });

  testWidgets('gallery adds a batch and lets user choose a primary view', (
    tester,
  ) async {
    String? viewed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) => RoomPhotosCard(
                store: store,
                room: store.roomById(room.id)!,
                selectedPhotoId: viewed,
                onView: (id) => viewed = id,
                includeContext: true,
                onContextChanged: (_) {},
                pickPhotos: (_) async => [image, image],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Add room photos'));
    await tester.pumpAndSettle();
    expect(store.roomById(room.id)!.photoIds, hasLength(3));
    expect(find.text('Room photos (3/6)'), findsOneWidget);
    await tester.tap(find.text('Use as primary').last);
    await tester.pumpAndSettle();
    expect(
      store.roomById(room.id)!.primaryId,
      store.roomById(room.id)!.photoIds.last,
    );
    expect(viewed, store.roomById(room.id)!.primaryId);
    expect(store.roomById(room.id)!.originalId, room.originalId);
    expect(tester.takeException(), isNull);
  });
}
