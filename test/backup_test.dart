import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/file_transfer.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/project_transfer_widgets.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

class TestFiles implements AppFiles {
  Uint8List? picked;
  Uint8List? saved;
  String? name;
  @override
  bool get supported => true;
  @override
  Future<Uint8List?> pickBackup() async => picked;
  @override
  Future<FileSaveResult> save(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async {
    saved = bytes;
    this.name = name;
    return FileSaveResult.saved;
  }
}

class FailOnceRecords extends MemoryBox {
  bool fail = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (fail && key.toString().startsWith('design:')) {
      fail = false;
      throw StateError('Simulated full storage');
    }
    return super.put(key, value);
  }
}

void main() {
  late RenovisionStore store;
  late FailOnceRecords records;
  late MemoryBox photos;
  late TestFiles files;
  late RenovationProject project;
  late RenovationRoom room;
  late DesignVersion first;
  late Uint8List original;

  setUp(() async {
    records = FailOnceRecords();
    photos = MemoryBox();
    files = TestFiles();
    store = RenovisionStore(records: records, photos: photos, files: files);
    final source = img.Image(width: 40, height: 30);
    source.exif.imageIfd.imageDescription = 'Private original';
    original = img.encodeJpg(source);
    project = await store.createProject('Claylands');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Office',
      originalImage: original,
    );
    await store.updateRoom(
      room.copyWith(
        instructions: 'Change skirting',
        protectedFeatures: 'Keep windows',
      ),
    );
    first = await store.createDesign(
      roomId: room.id,
      image: original,
      title: 'Approved',
      prompt: 'Keep windows',
    );
    await store.approveBaseline(room.id, designId: first.id);
    final branch = await store.createDesign(
      roomId: room.id,
      image: original,
      title: 'Branch',
      prompt: 'Change skirting',
      parentId: first.id,
      sourceImageId: first.imageId,
      aiProvider: 'OpenAI',
      aiModel: 'test-model',
      providerRequestId: 'test-request',
    );
    await store.setFavourite(branch, favourite: true);
  });
  tearDown(() => store.dispose());

  test('repeated restores add only one restored label and keep existing copies intact', () async {
    final restored = await store.restoreBackup(store.backupFor(project.id));
    final again = await store.restoreBackup(store.backupFor(restored.id));
    expect(again.name, 'Claylands (restored)');
    expect(again.id, isNot(restored.id));
    expect(store.projectById(project.id)!.name, 'Claylands');
    expect(store.roomsFor(again.id).single.photoIds, hasLength(1));
    await store.renameProject(again.id, 'Claylands (restored) (restored)');
    final fromOlderName = await store.restoreBackup(store.backupFor(again.id));
    expect(fromOlderName.name, 'Claylands (restored)');
    expect(store.projects, hasLength(4));
    expect(
      store.imageFor(store.roomsFor(fromOlderName.id).single.originalId),
      orderedEquals(original),
    );
  });

  test('backup round trip preserves exact originals, approvals and branch metadata', () async {
    final before = jsonEncode(records.entries);
    final backup = ProjectBackup.decode(store.backupFor(project.id).encode());
    final restored = await store.restoreBackup(backup);
    expect(restored.id, isNot(project.id));
    expect(restored.name, 'Claylands (restored)');
    final restoredRoom = store.roomsFor(restored.id).single;
    expect(restoredRoom.id, isNot(room.id));
    expect(restoredRoom.instructions, 'Change skirting');
    expect(restoredRoom.protectedFeatures, 'Keep windows');
    expect(store.imageFor(restoredRoom.originalId), orderedEquals(original));
    final designs = store.designsFor(restoredRoom.id);
    final approved = designs.firstWhere((d) => d.title == 'Approved');
    final branch = designs.firstWhere((d) => d.title == 'Branch');
    expect(restoredRoom.approvedDesignId, approved.id);
    expect(branch.parentId, approved.id);
    expect(branch.sourceImageId, approved.imageId);
    expect(branch.favourite, isTrue);
    expect(branch.aiModel, 'test-model');
    expect(branch.providerRequestId, 'test-request');
    final originalRecords = {
      for (final key in (jsonDecode(before) as Map).keys) key: records.get(key),
    };
    expect(jsonEncode(originalRecords), before);
    final secondCopy = await store.restoreBackup(backup);
    expect(secondCopy.id, isNot(restored.id));
    expect(store.projects, hasLength(3));
  });

  test(
    'failed restore rolls back only its own new photos and records',
    () async {
      final recordSnapshot = jsonEncode(records.entries);
      final photoSnapshot = jsonEncode(photos.entries);
      final backup = store.backupFor(project.id);
      records.fail = true;
      await expectLater(
        store.restoreBackup(backup),
        throwsA(isA<BackupFailure>()),
      );
      expect(jsonEncode(records.entries), recordSnapshot);
      expect(jsonEncode(photos.entries), photoSnapshot);
      expect(store.projects.single.id, project.id);
    },
  );

  test(
    'backup excludes unrelated projects and connection credentials',
    () async {
      final other = await store.createProject('Unrelated');
      await store.createRoom(
        projectId: other.id,
        name: 'Other room',
        originalImage: Uint8List.fromList([9]),
      );
      final text = utf8.decode(store.backupFor(project.id).encode());
      expect(text, isNot(contains('Unrelated')));
      expect(text, isNot(contains('Other room')));
      expect(text, isNot(contains('pairingCode')));
      expect(text, isNot(contains('apiKey')));
    },
  );

  test('bad format, photo integrity, references and ancestry are rejected before writes', () {
    final source = store.backupFor(project.id).encode();
    final snapshot = jsonEncode(records.entries);
    void invalid(void Function(Map<String, dynamic>) change) {
      final data = jsonDecode(utf8.decode(source)) as Map<String, dynamic>;
      change(data);
      expect(
        () => ProjectBackup.decode(
          Uint8List.fromList(utf8.encode(jsonEncode(data))),
        ),
        throwsA(isA<BackupFailure>()),
      );
      expect(jsonEncode(records.entries), snapshot);
    }

    invalid((data) => data['version'] = 99);
    invalid((data) => (data['photos'] as Map).values.first['data'] = 'AAAA');
    invalid(
      (data) => (data['rooms'] as List).first['approvedDesignId'] = 'missing',
    );
    invalid(
      (data) => (data['designs'] as List).first['parentId'] =
          (data['designs'] as List).first['id'],
    );
    invalid((data) => (data['photos'] as Map).clear());
    invalid(
      (data) => (data['rooms'] as List).add((data['rooms'] as List).first),
    );
    expect(
      () => ProjectBackup.decode(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<BackupFailure>()),
    );
  });

  testWidgets(
    'download exports a metadata-free image and preserves stored bytes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadImageButton(
              files: files,
              bytes: original,
              name: 'Office original',
            ),
          ),
        ),
      );
      await tester.tap(find.text('Download image'));
      await tester.pumpAndSettle();
      expect(files.name, 'Office-original.png');
      final downloaded = img.decodeImage(files.saved!)!;
      expect(downloaded.width, 40);
      expect(downloaded.exif.imageIfd.imageDescription, isNull);
      expect(store.imageFor(room.originalId), orderedEquals(original));
      expect(
        img.decodeImage(original)!.exif.imageIfd.imageDescription,
        'Private original',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('backup button saves a restorable project file', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectBackupCard(store: store, project: project),
        ),
      ),
    );
    await tester.tap(find.text('Export backup snapshot'));
    await tester.pumpAndSettle();
    expect(files.name, 'Claylands.renovision.json');
    expect(ProjectBackup.decode(files.saved!).designs, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('restore asks for confirmation and creates a separate project', (
    tester,
  ) async {
    files.picked = store.backupFor(project.id).encode();
    RenovationProject? restored;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RestoreProjectButton(
            store: store,
            onRestored: (project) => restored = project,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Restore project backup'));
    await tester.pumpAndSettle();
    expect(store.projects, hasLength(1));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.projects, hasLength(1));
    await tester.tap(find.text('Restore project backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore copy'));
    await tester.pumpAndSettle();
    expect(store.projects, hasLength(2));
    expect(restored!.id, isNot(project.id));
    expect(tester.takeException(), isNull);
  });
}
