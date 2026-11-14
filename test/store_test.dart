import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/store.dart';

void main() {
  late Directory directory;
  late Box<dynamic> records;
  late Box<dynamic> photos;
  late RenovisionStore store;

  setUp(() async {
    // Isolated temporary boxes; never use the app's data path.
    directory = await Directory.systemTemp.createTemp('renovision_store_test_');
    records = await Hive.openBox<dynamic>('test_records', path: directory.path);
    photos = await Hive.openBox<dynamic>('test_photos', path: directory.path);
    store = RenovisionStore(records: records, photos: photos);
  });

  tearDown(() async {
    store.dispose();
    await records.close();
    await photos.close();
    if (directory.absolute.parent.path == Directory.systemTemp.absolute.path &&
        directory.uri.pathSegments
            .where((s) => s.isNotEmpty)
            .last
            .startsWith('renovision_store_test_')) {
      await directory.delete(recursive: true);
    }
  });

  Future<RenovationRoom> createRoom() async {
    final project = await store.createProject(' Claylands ');
    return store.createRoom(
      projectId: project.id,
      name: ' Office ',
      originalImage: Uint8List.fromList([1, 2, 3, 4]),
    );
  }

  test(
    'multiple original room views and primary choice survive reopening',
    () async {
      final project = await store.createProject('Multi-view project');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Office',
        originalImage: Uint8List.fromList([1, 2]),
        additionalImages: [
          Uint8List.fromList([3, 4]),
        ],
      );
      await store.addRoomPhotos(room.id, [
        Uint8List.fromList([5, 6]),
      ]);
      final ids = store.roomById(room.id)!.photoIds;
      await store.setPrimaryPhoto(room.id, ids.last);
      await store.setRoomPalette(room.id, 'charcoal_walnut');
      store.dispose();
      await records.close();
      await photos.close();
      records = await Hive.openBox<dynamic>(
        'test_records',
        path: directory.path,
      );
      photos = await Hive.openBox<dynamic>('test_photos', path: directory.path);
      store = RenovisionStore(records: records, photos: photos);
      expect(store.roomById(room.id)!.photoIds, ids);
      expect(store.roomById(room.id)!.colourPaletteId, 'charcoal_walnut');
      expect(store.roomById(room.id)!.primaryId, ids.last);
      expect(store.imageFor(ids[0]), orderedEquals([1, 2]));
      expect(store.imageFor(ids[1]), orderedEquals([3, 4]));
      expect(store.imageFor(ids[2]), orderedEquals([5, 6]));
    },
  );

  test(
    'renaming survives reopening without changing room data or images',
    () async {
      final room = await createRoom();
      final design = await store.createDesign(
        roomId: room.id,
        image: Uint8List.fromList([5, 6]),
        title: 'Approved design',
        prompt: 'Keep the windows',
        sourceImageId: room.originalId,
        aiProvider: 'OpenAI',
        aiModel: 'test-model',
      );
      await store.approveBaseline(room.id, designId: design.id);
      await store.updateRoom(
        store
            .roomById(room.id)!
            .copyWith(
              instructions: 'Change skirting',
              protectedFeatures: 'Wide windows',
            ),
      );
      final before = Map<dynamic, dynamic>.from(
        records.get('room:${room.id}') as Map,
      )..remove('name');
      await store.renameProject(room.projectId, ' Claylands renovation ');
      await store.renameRoom(room.id, ' Home office ');
      final after = Map<dynamic, dynamic>.from(
        records.get('room:${room.id}') as Map,
      )..remove('name');
      expect(after, before);
      store.dispose();
      await records.close();
      await photos.close();
      records = await Hive.openBox<dynamic>(
        'test_records',
        path: directory.path,
      );
      photos = await Hive.openBox<dynamic>('test_photos', path: directory.path);
      store = RenovisionStore(records: records, photos: photos);
      expect(store.projectById(room.projectId)!.name, 'Claylands renovation');
      expect(store.roomById(room.id)!.name, 'Home office');
      expect(store.roomById(room.id)!.approvedDesignId, design.id);
      expect(store.roomById(room.id)!.protectedFeatures, 'Wide windows');
      expect(store.imageFor(room.originalId), orderedEquals([1, 2, 3, 4]));
      expect(store.imageFor(design.imageId), orderedEquals([5, 6]));
      expect(
        store.backupFor(room.projectId).project.name,
        'Claylands renovation',
      );
    },
  );

  test('invalid rename cannot create or change records', () async {
    final room = await createRoom();
    await expectLater(
      store.renameProject(room.projectId, '   '),
      throwsArgumentError,
    );
    await expectLater(
      store.renameRoom(room.id, List.filled(81, 'x').join()),
      throwsArgumentError,
    );
    await expectLater(
      store.renameProject('missing', 'Valid name'),
      throwsStateError,
    );
    await expectLater(
      store.renameRoom('missing', 'Valid name'),
      throwsStateError,
    );
    expect(store.projects.single.name, 'Claylands');
    expect(store.roomById(room.id)!.name, 'Office');
    expect(store.projects, hasLength(1));
  });

  test('legacy rooms remain readable and default to the original baseline', () {
    final room = RenovationRoom.fromMap({
      'id': 'old-room',
      'projectId': 'old-project',
      'name': 'Office',
      'originalId': 'old-photo',
      'created': '2026-11-12T12:00:00.000',
    });
    expect(room.approvedDesignId, isNull);
    expect(room.originalId, 'old-photo');
  });

  test(
    'approved baseline, branches, memory and original survive reopen',
    () async {
      final room = await createRoom();
      final design = await store.createDesign(
        roomId: room.id,
        image: Uint8List.fromList([5, 6]),
        title: 'Charcoal cabinets',
        prompt: 'Keep windows',
      );
      await store.approveBaseline(room.id, designId: design.id);
      await store.updateRoom(
        store
            .roomById(room.id)!
            .copyWith(
              instructions: 'Change only the skirting',
              protectedFeatures: 'Wide windows',
            ),
      );
      final branch = await store.createDesign(
        roomId: room.id,
        image: Uint8List.fromList([7, 8]),
        title: 'Skirting correction',
        prompt: 'Change only the skirting',
        parentId: design.id,
        sourceImageId: design.imageId,
        aiProvider: 'OpenAI',
        aiModel: 'test-model',
        providerRequestId: 'test-request',
      );
      store.dispose();
      await records.close();
      await photos.close();
      records = await Hive.openBox<dynamic>(
        'test_records',
        path: directory.path,
      );
      photos = await Hive.openBox<dynamic>('test_photos', path: directory.path);
      store = RenovisionStore(records: records, photos: photos);
      expect(store.projects.single.name, 'Claylands');
      final restored = store.roomById(room.id)!;
      expect(restored.name, 'Office');
      expect(restored.approvedDesignId, design.id);
      expect(restored.instructions, 'Change only the skirting');
      expect(restored.protectedFeatures, 'Wide windows');
      expect(store.imageFor(restored.originalId), orderedEquals([1, 2, 3, 4]));
      expect(
        store.designsFor(room.id).firstWhere((d) => d.id == branch.id).parentId,
        design.id,
      );
      expect(store.imageFor(design.imageId), orderedEquals([5, 6]));
      final restoredBranch = store
          .designsFor(room.id)
          .firstWhere((d) => d.id == branch.id);
      expect(restoredBranch.sourceImageId, design.imageId);
      expect(restoredBranch.aiProvider, 'OpenAI');
      expect(restoredBranch.aiModel, 'test-model');
      expect(restoredBranch.providerRequestId, 'test-request');
      await store.setFavourite(restoredBranch, favourite: true);
      expect(
        store.designsFor(room.id).firstWhere((d) => d.id == branch.id).aiModel,
        'test-model',
      );
      await store.approveBaseline(room.id);
      expect(store.roomById(room.id)!.approvedDesignId, isNull);
      expect(store.designsFor(room.id), hasLength(2));
    },
  );

  test('unfavourite returns to pending; rejecting remains explicit', () async {
    final room = await createRoom();
    final design = await store.createDesign(
      roomId: room.id,
      image: Uint8List.fromList([5]),
      title: 'Option',
      prompt: 'Prompt',
    );
    await store.setFavourite(design, favourite: true);
    await store.setFavourite(design, favourite: false);
    expect(store.designsFor(room.id).single.favourite, isFalse);
    expect(store.designsFor(room.id).single.rejected, isFalse);
    await store.rateDesign(design, keep: false);
    expect(store.designsFor(room.id).single.rejected, isTrue);
    await store.setFavourite(design, favourite: true);
    expect(store.designsFor(room.id).single.favourite, isTrue);
    expect(store.designsFor(room.id).single.rejected, isFalse);
  });

  test('baseline cannot reference another room or a missing image', () async {
    final room = await createRoom();
    final other = await createRoom();
    final design = await store.createDesign(
      roomId: other.id,
      image: Uint8List.fromList([5]),
      title: 'Other room',
      prompt: 'Prompt',
    );
    await expectLater(
      store.approveBaseline(room.id, designId: design.id),
      throwsStateError,
    );
    await expectLater(
      store.approveBaseline(room.id, designId: 'missing'),
      throwsStateError,
    );
    expect(store.roomById(room.id)!.approvedDesignId, isNull);
    await photos.delete(design.imageId);
    await expectLater(
      store.approveBaseline(other.id, designId: design.id),
      throwsStateError,
    );
  });
}
