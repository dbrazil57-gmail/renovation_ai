// Real filesystem acceptance for the project-file contract. The system chooser
// is supplied by the test; this does not claim to exercise OneDrive cloud sync.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:renovision_ai/file_transfer.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/protected_backup.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

class DiskAcceptanceDestination
    implements ReusableSaveDestination, IdentifiableDestination {
  final File file;
  bool fail = false;
  DiskAcceptanceDestination(this.file);
  @override
  Future<FileSaveResult> write(Uint8List bytes) async {
    if (fail) throw FileSystemException('Synthetic write failure');
    await file.writeAsBytes(bytes, flush: true);
    final written = await file.readAsBytes();
    if (written.length != bytes.length ||
        !List.generate(
          bytes.length,
          (i) => written[i] == bytes[i],
        ).every((v) => v)) {
      throw FileSystemException('Incomplete test project file');
    }
    return FileSaveResult.saved;
  }

  @override
  Future<bool> sameFile(SaveDestination other) async =>
      other is DiskAcceptanceDestination &&
      other.file.absolute.path == file.absolute.path;
}

Future<Directory> caseDirectory(String name) async {
  const base = String.fromEnvironment(
    'SAVE_CHECK_DIR',
    defaultValue: 'output/save-acceptance',
  );
  final directory = Directory(
    '$base/RenoVision-save-check-$name-${DateTime.now().microsecondsSinceEpoch}',
  );
  if (await directory.exists()) {
    throw StateError('Existing test folder retained');
  }
  return directory.create(recursive: true);
}

void main() {
  final photo = img.encodePng(
    img.Image(width: 24, height: 18)..clear(img.ColorRgb8(170, 180, 190)),
  );
  test('real disk: Save, autosave, Save as, failure, reopen and restore retain complete independent project work', () async {
    final directory = await caseDirectory('project');
    final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    addTearDown(store.dispose);
    final project = await store.createProject('Disk acceptance');
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      roomTypeId: 'kitchen',
      originalImage: photo,
    );
    await store.addRoomPhotos(room.id, [photo]);
    await store.updateRoom(
      store
          .roomById(room.id)!
          .copyWith(
            instructions: 'Pale benchtops',
            colourPaletteId: 'sage_oak',
            designStyleIds: ['modern'],
          ),
    );
    final design = await store.createDesign(
      roomId: room.id,
      image: photo,
      title: 'Chosen design',
      prompt: 'Saved exact instructions',
    );
    await store.approveBaseline(room.id, designId: design.id);
    final first = DiskAcceptanceDestination(
      File('${directory.path}/working.renovision.json'),
    );
    await store.documents.link(project.id, first);
    await store.documents.save(project.id);
    final initial = ProjectBackup.decode(await first.file.readAsBytes());
    expect(initial.rooms.single.photoIds, hasLength(2));
    expect(initial.designs.single.prompt, 'Saved exact instructions');
    for (final bytes in initial.photos.values) {
      expect(bytes, orderedEquals(photo));
    }
    await store.renameRoom(room.id, 'Kitchen autosaved');
    await Future<void>.delayed(const Duration(milliseconds: 2300));
    expect(
      ProjectBackup.decode(await first.file.readAsBytes()).rooms.single.name,
      'Kitchen autosaved',
    );
    final firstSnapshot = await first.file.readAsBytes();
    final second = DiskAcceptanceDestination(
      File('${directory.path}/save-as.renovision.json'),
    );
    await store.documents.link(project.id, second);
    await store.documents.save(project.id);
    await store.renameRoom(room.id, 'Kitchen in second file');
    await store.documents.save(project.id);
    expect(await first.file.readAsBytes(), orderedEquals(firstSnapshot));
    final beforeFailure = await second.file.readAsBytes();
    await store.renameRoom(room.id, 'Local edit after failure');
    second.fail = true;
    await expectLater(
      store.documents.save(project.id),
      throwsA(isA<FileSystemException>()),
    );
    expect(await second.file.readAsBytes(), orderedEquals(beforeFailure));
    expect(store.roomById(room.id)!.name, 'Local edit after failure');
    second.fail = false;
    await store.documents.save(project.id);
    final other = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    addTearDown(other.dispose);
    final loaded = await other.openBackup(
      ProjectBackup.decode(await second.file.readAsBytes()),
    );
    final reopened = other.roomsFor(loaded.id).single;
    expect(reopened.name, 'Local edit after failure');
    expect(reopened.instructions, 'Pale benchtops');
    expect(reopened.designStyleIds, ['modern']);
    expect(reopened.colourPaletteId, 'sage_oak');
    expect(other.designsFor(reopened.id).single.id, design.id);
    expect(reopened.approvedDesignId, design.id);
    expect(other.imageFor(reopened.originalId), orderedEquals(photo));
    await other.restoreBackup(
      ProjectBackup.decode(await first.file.readAsBytes()),
    );
    expect(other.projects, hasLength(2));
    expect(other.roomsFor(loaded.id).single.name, 'Local edit after failure');
    expect(
      other.projects.expand((p) => other.roomsFor(p.id)).map((r) => r.name),
      contains('Kitchen autosaved'),
    );
    expect(await first.file.length(), greaterThan(0));
    expect(await second.file.length(), greaterThan(0));
  });

  test('real disk: encrypted export protects that copy and never claims to encrypt or replace the plain source', () async {
    final directory = await caseDirectory('encrypted');
    final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    addTearDown(store.dispose);
    final project = await store.createProject('Private room fixture');
    await store.createRoom(
      projectId: project.id,
      name: 'Bedroom',
      originalImage: photo,
    );
    final bytes = store.backupFor(project.id).encode();
    final plain = DiskAcceptanceDestination(
      File('${directory.path}/plain.renovision.json'),
    );
    await plain.write(bytes);
    const password = 'temporary-save-check-passphrase';
    final encrypted = DiskAcceptanceDestination(
      File('${directory.path}/protected.renovision'),
    );
    await encrypted.write(await protectBackup(bytes, password));
    final encryptedBytes = await encrypted.file.readAsBytes();
    expect(isProtectedBackup(encryptedBytes), true);
    await expectLater(
      unlockBackup(encryptedBytes, 'incorrect-passphrase'),
      throwsA(isA<BackupFailure>()),
    );
    final decoded = ProjectBackup.decode(
      await unlockBackup(encryptedBytes, password),
    );
    expect(decoded.rooms.single.name, 'Bedroom');
    expect(decoded.photos.values.single, orderedEquals(photo));
    expect(await plain.file.readAsBytes(), orderedEquals(bytes));
    expect(store.roomById(decoded.rooms.single.id), isNotNull);
  });
}
