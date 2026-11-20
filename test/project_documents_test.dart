import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/file_transfer.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/project_transfer_widgets.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

class DiskFile implements ReusableSaveDestination {
  Uint8List? bytes;
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<FileSaveResult> write(Uint8List value) async {
    if (gate != null) await gate!.future;
    if (fail) throw StateError('Synthetic disk failure');
    bytes = Uint8List.fromList(value);
    return FileSaveResult.saved;
  }
}

class ChooserOnlyFiles implements AppFiles {
  int saves = 0;
  FileSaveResult result = FileSaveResult.saved;
  @override
  bool get supported => true;
  @override
  Future<FileSaveResult> save(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async {
    saves++;
    return result;
  }

  @override
  Future<Uint8List?> pickBackup() async => null;
}

class DocumentFiles
    implements AppFiles, LocationChoosingFiles, ProjectOpeningFiles {
  final disk = DiskFile();
  Uint8List? opening;
  bool cancel = false;
  @override
  bool get supported => true;
  @override
  Future<SaveDestination?> chooseSaveLocation({
    required String name,
    required String mimeType,
  }) async => cancel ? null : disk;
  @override
  Future<OpenedProjectFile?> openProjectFile() async =>
      opening == null ? null : OpenedProjectFile(opening!, destination: disk);
  @override
  Future<Uint8List?> pickBackup() async => opening;
  @override
  Future<FileSaveResult> save(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) => disk.write(bytes);
}

void main() {
  late RenovisionStore store;
  late DocumentFiles files;
  late String projectId, roomId;
  setUp(() async {
    files = DocumentFiles();
    store = RenovisionStore(
      records: MemoryBox(),
      photos: MemoryBox(),
      files: files,
    );
    final project = await store.createProject('House');
    projectId = project.id;
    final room = await store.createRoom(
      projectId: projectId,
      name: 'Kitchen',
      guidedSetup: true,
      originalImage: img.encodePng(img.Image(width: 20, height: 15)),
    );
    roomId = room.id;
  });
  tearDown(() => store.dispose());

  test('project file contains every room and exact photo bytes and reopens in a fresh store', () async {
    final room = store.roomById(roomId)!;
    await store.updateRoom(
      room.copyWith(
        instructions: 'Modernise',
        correctionInstructions: 'Remove handles',
        setupStep: 2,
        renovationScopeIds: ['flooring'],
        roomItemChoices: {'kitchen_oven': 'keep'},
      ),
    );
    await store.createDesign(
      roomId: roomId,
      image: store.imageFor(room.originalId)!,
      title: 'Concept',
      prompt: 'Recorded generation prompt',
      aiModel: 'synthetic-model',
    );
    store.documents.attach(projectId, files.disk);
    await store.documents.save(projectId);
    final other = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    final reopened = await other.restoreBackup(
      ProjectBackup.decode(files.disk.bytes!),
    );
    final savedRoom = other.roomsFor(reopened.id).single;
    expect(savedRoom.instructions, 'Modernise');
    expect(savedRoom.correctionInstructions, 'Remove handles');
    expect(savedRoom.setupStep, 2);
    expect(savedRoom.setupComplete, isFalse);
    expect(savedRoom.roomItemChoices, {'kitchen_oven': 'keep'});
    expect(
      other.imageFor(savedRoom.originalId),
      orderedEquals(store.imageFor(room.originalId)!),
    );
    expect(
      other.designsFor(savedRoom.id).single.prompt,
      'Recorded generation prompt',
    );
    other.dispose();
  });

  test('a failed save retains the previous file and local updates', () async {
    store.documents.attach(projectId, files.disk);
    await store.documents.save(projectId);
    final previous = files.disk.bytes!;
    await store.renameRoom(roomId, 'New room name');
    files.disk.fail = true;
    await expectLater(store.documents.save(projectId), throwsStateError);
    expect(files.disk.bytes, orderedEquals(previous));
    expect(store.roomById(roomId)!.name, 'New room name');
    expect(store.documents.hasPending(projectId), isTrue);
    files.disk.fail = false;
    await store.documents.save(projectId);
    expect(
      ProjectBackup.decode(files.disk.bytes!).rooms.single.name,
      'New room name',
    );
    expect(store.documents.hasPending(projectId), isFalse);
  });

  test(
    'queued saves cannot overwrite a newer edit with older file bytes',
    () async {
      store.documents.attach(projectId, files.disk);
      files.disk.gate = Completer<void>();
      final first = store.documents.save(projectId);
      await Future<void>.delayed(const Duration(milliseconds: 25));
      await store.renameRoom(roomId, 'Newest room name');
      final second = store.documents.save(projectId);
      files.disk.gate!.complete();
      await Future.wait([first, second]);
      expect(
        ProjectBackup.decode(files.disk.bytes!).rooms.single.name,
        'Newest room name',
      );
      expect(store.documents.hasPending(projectId), isFalse);
    },
  );

  test('opening the same destination for another copy stops the old copy autosaving over it', () async {
    final another = await store.createProject('Another project');
    await store.documents.link(projectId, files.disk);
    await store.documents.save(projectId);
    await store.documents.link(another.id, files.disk);
    expect(store.documents.linked(projectId), isFalse);
    expect(store.documents.linked(another.id), isTrue);
    expect(store.roomsFor(projectId).single.id, roomId);
    expect(
      store.documents.status(projectId),
      contains('Local work is retained'),
    );
  });

  testWidgets(
    'choosing Save project as cancellation never changes a file or local work',
    (tester) async {
      files.cancel = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectFileControls(store: store, projectId: projectId),
          ),
        ),
      );
      await tester.tap(find.text('Save project as…'));
      await tester.pumpAndSettle();
      expect(files.disk.bytes, isNull);
      expect(store.documents.linked(projectId), isFalse);
      expect(store.roomsFor(projectId), hasLength(1));
    },
  );

  testWidgets(
    'Open project resumes the matching project and links Save without duplicating it',
    (tester) async {
      files.opening = store.backupFor(projectId).encode();
      String? openedId;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestoreProjectButton(
              store: store,
              openDocument: true,
              onRestored: (p) => openedId = p.id,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open project…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open project'));
      await tester.pumpAndSettle();
      expect(openedId, projectId);
      expect(store.projects, hasLength(1));
      expect(store.documents.linked(openedId!), isTrue);
      expect(store.roomsFor(projectId).single.id, roomId);
      await tester.runAsync(() => store.documents.save(openedId!));
      expect(ProjectBackup.decode(files.disk.bytes!).rooms, hasLength(1));
    },
  );

  test('linked project autosaves later edits to its chosen file', () async {
    store.documents.attach(projectId, files.disk);
    await store.documents.save(projectId);
    await store.renameRoom(roomId, 'Updated kitchen');
    await Future<void>.delayed(const Duration(milliseconds: 2300));
    expect(
      ProjectBackup.decode(files.disk.bytes!).rooms.single.name,
      'Updated kitchen',
    );
    expect(store.documents.hasPending(projectId), isFalse);
  });

  test('chooser-only platform saves once and never opens a chooser from background autosave', () async {
    final chooser = ChooserOnlyFiles();
    final destination = await chooseSaveDestination(
      chooser,
      name: 'test.renovision.json',
      mimeType: 'application/json',
    );
    store.documents.attach(projectId, destination!);
    await store.documents.save(projectId);
    expect(chooser.saves, 1);
    expect(store.documents.linked(projectId), isFalse);
    await store.renameRoom(roomId, 'Phone edit');
    await Future<void>.delayed(const Duration(milliseconds: 2300));
    expect(chooser.saves, 1);
    expect(store.roomById(roomId)!.name, 'Phone edit');
    chooser.result = FileSaveResult.cancelled;
    store.documents.attach(projectId, destination);
    await expectLater(store.documents.save(projectId), throwsStateError);
    expect(store.documents.linked(projectId), isFalse);
    await store.renameRoom(roomId, 'After cancelled phone save');
    await Future<void>.delayed(const Duration(milliseconds: 2300));
    expect(chooser.saves, 2);
    expect(store.roomById(roomId)!.name, 'After cancelled phone save');
  });
}
