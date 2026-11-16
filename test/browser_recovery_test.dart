import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:hive_ce/src/binary/binary_writer_impl.dart';
// ignore: implementation_imports
import 'package:hive_ce/src/registry/type_registry_impl.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/store.dart';

import '../tool/recover_browser_projects.dart';
import 'support/memory_box.dart';

Map<String, dynamic> browserValue(Object? value) {
  if (value is Uint8List &&
      !(value.length >= 2 && value[0] == 0x90 && value[1] == 0xA9)) {
    return {'kind': 'bytes', 'data': base64Encode(value)};
  }
  final writer = BinaryWriterImpl(TypeRegistryImpl.nullImpl)
    ..writeByteList([0x90, 0xA9], writeLength: false)
    ..write(value);
  return {'kind': 'bytes', 'data': base64Encode(writer.toBytes())};
}

void main() {
  test('browser recovery decodes Hive records and exports exact image bytes and relationships', () async {
    final records = MemoryBox(), photos = MemoryBox();
    final store = RenovisionStore(records: records, photos: photos);
    final original = Uint8List.fromList([1, 2, 3, 4]);
    final project = await store.createProject('Recovery example');
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: original,
    );
    final design = await store.createDesign(
      roomId: room.id,
      image: Uint8List.fromList([5, 6, 7]),
      title: 'Saved design',
      prompt: 'Keep layout',
    );
    await store.approveBaseline(room.id, designId: design.id);
    await store.checkLocalStorage(); // Diagnostic entries must not enter a project backup.
    final dump = <String, dynamic>{
      'records': records.entries.map((k, v) => MapEntry(k, browserValue(v))),
      'photos': photos.entries.map((k, v) => MapEntry(k, browserValue(v))),
    };
    final backup = backupsFromBrowserDump(dump).single;
    expect(backup.project.id, project.id);
    expect(backup.rooms.single.approvedDesignId, design.id);
    expect(backup.photos[room.originalId], orderedEquals(original));
    expect(backup.designs.single.prompt, 'Keep layout');
    expect(backup.photos, hasLength(2));
    expect(
      ProjectBackup.decode(backup.encode()).photos[design.imageId],
      orderedEquals([5, 6, 7]),
    );
    store.dispose();
  });

  test('browser recovery handles prefix-escaped photo bytes and rejects missing data', () {
    final photo = Uint8List.fromList([0x90, 0xA9, 1, 2, 3]);
    expect(decodeBrowserValue(browserValue(photo)), orderedEquals(photo));
    expect(
      () => backupsFromBrowserDump({'records': {}, 'photos': null}),
      throwsFormatException,
    );
    expect(
      () => decodeBrowserValue({'kind': 'unsupported'}),
      throwsFormatException,
    );
  });
}
