import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    await tester.tap(find.text('Choose photos'));
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

  testWidgets('phone camera appends a saved original without opening gallery', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    var cameraCalls = 0;
    var galleryCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) => RoomPhotosCard(
                store: store,
                room: store.roomById(room.id)!,
                selectedPhotoId: room.originalId,
                onView: (_) {},
                includeContext: true,
                onContextChanged: (_) {},
                takePhoto: (remaining) async {
                  cameraCalls++;
                  expect(remaining, 5);
                  return [image];
                },
                pickPhotos: (_) async {
                  galleryCalls++;
                  return null;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    expect(cameraCalls, 1);
    expect(galleryCalls, 0);
    final saved = store.roomById(room.id)!;
    expect(saved.photoIds, hasLength(2));
    expect(saved.originalId, room.originalId);
    expect(store.imageFor(saved.photoIds.last), orderedEquals(image));
    final reopened = RenovisionStore(records: records, photos: photos);
    expect(reopened.roomById(room.id)!.photoIds, saved.photoIds);
    reopened.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled or failed phone capture preserves existing photos', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    var shouldFail = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomPhotosCard(
            store: store,
            room: room,
            selectedPhotoId: room.originalId,
            onView: (_) {},
            includeContext: false,
            onContextChanged: null,
            takePhoto: (_) async {
              if (shouldFail) throw StateError('Camera unavailable');
              return null;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    expect(store.roomById(room.id)!.photoIds, [room.originalId]);
    shouldFail = true;
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    expect(
      find.text('Photos could not be added. Existing photos are unchanged.'),
      findsOneWidget,
    );
    expect(store.roomById(room.id)!.photoIds, [room.originalId]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'phone source chooser offers camera and gallery without a request',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      bool? source;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    source = await chooseRoomPhotoSource(context),
                child: const Text('Add photos'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Add photos'));
      await tester.pumpAndSettle();
      expect(find.text('Take photo'), findsOneWidget);
      expect(find.text('Choose photos'), findsOneWidget);
      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();
      expect(source, isTrue);
      await tester.tap(find.text('Add photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose photos'));
      await tester.pumpAndSettle();
      expect(source, isFalse);
      expect(store.roomById(room.id)!.photoIds, [room.originalId]);
    },
  );
}
