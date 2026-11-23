import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/file_transfer.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/project_transfer_widgets.dart';
import 'package:renovision_ai/protected_backup.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

const fixturePassword = 'only-a-synthetic-test-password';

class ProtectedTestFile implements ReusableSaveDestination {
  Uint8List? saved;
  @override
  Future<FileSaveResult> write(Uint8List bytes) async {
    saved = bytes;
    return FileSaveResult.saved;
  }
}

class ProtectedTestFiles implements AppFiles, ProjectOpeningFiles {
  final destination = ProtectedTestFile();
  Uint8List opening;
  ProtectedTestFiles(this.opening);
  @override
  bool get supported => true;
  @override
  Future<Uint8List?> pickBackup() async => opening;
  @override
  Future<OpenedProjectFile?> openProjectFile() async =>
      OpenedProjectFile(opening, destination: destination);
  @override
  Future<FileSaveResult> save(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) => destination.write(bytes);
}

void main() {
  late Uint8List plain, protected;
  setUpAll(() async {
    final source = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    final project = await source.createProject('Synthetic private home');
    await source.createRoom(
      projectId: project.id,
      name: 'Secret lounge fixture',
      roomTypeId: 'living',
      originalImage: Uint8List.fromList([1, 2, 3]),
    );
    plain = source.backupFor(project.id).encode();
    source.dispose();
    protected = await protectBackup(plain, fixturePassword);
  });

  test('protected backups round trip exact project bytes, use random salt/nonce and contain no plaintext project name', () async {
    expect(isProtectedBackup(protected), isTrue);
    expect(isProtectedBackup(plain), isFalse);
    expect(latin1.decode(protected), isNot(contains('Synthetic private home')));
    final unlocked = await unlockBackup(protected, fixturePassword);
    expect(unlocked, plain);
    expect(
      ProjectBackup.decode(unlocked).rooms.single.name,
      'Secret lounge fixture',
    );
    final another = await protectBackup(plain, fixturePassword);
    expect(another, isNot(orderedEquals(protected)));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('wrong password and modified ciphertext fail authentication; malformed headers and weak passwords fail safely', () async {
    await expectLater(
      unlockBackup(protected, 'different-synthetic-password'),
      throwsA(isA<BackupFailure>()),
    );
    final changed = Uint8List.fromList(protected)..[protected.length - 20] ^= 1;
    await expectLater(
      unlockBackup(changed, fixturePassword),
      throwsA(isA<BackupFailure>()),
    );
    final invalidLength = Uint8List.fromList(protected);
    ByteData.sublistView(invalidLength).setUint32(8, 0xffffffff);
    await expectLater(
      unlockBackup(invalidLength, fixturePassword),
      throwsA(isA<BackupFailure>()),
    );
    await expectLater(
      protectBackup(plain, 'short'),
      throwsA(isA<BackupFailure>()),
    );
    final headerLength = ByteData.sublistView(protected).getUint32(8);
    final alteredHeader = Uint8List.fromList(protected);
    final metadata = utf8
        .decode(alteredHeader.sublist(12, 12 + headerLength))
        .replaceFirst('600000', '600001');
    alteredHeader.setRange(12, 12 + headerLength, utf8.encode(metadata));
    await expectLater(
      unlockBackup(alteredHeader, fixturePassword),
      throwsA(isA<BackupFailure>()),
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  Future<void> waitForCrypto(WidgetTester tester, bool Function() done) async {
    final deadline = DateTime.now().add(const Duration(seconds: 90));
    while (!done() && DateTime.now().isBefore(deadline)) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(done(), isTrue, reason: 'Backup work did not finish');
    await tester.pumpAndSettle();
  }

  testWidgets(
    'opening a protected backup asks for its password, preserves existing work and never links plaintext autosave to the protected file',
    (tester) async {
      final files = ProtectedTestFiles(protected);
      final store = RenovisionStore(
        records: MemoryBox(),
        photos: MemoryBox(),
        files: files,
      );
      addTearDown(store.dispose);
      final existing = await store.createProject('Existing project');
      final room = await store.createRoom(
        projectId: existing.id,
        name: 'Untouched room',
        originalImage: Uint8List.fromList([4, 5, 6]),
      );
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestoreProjectButton(
              store: store,
              openDocument: true,
              onRestored: (project) => opened = project.id,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open project…'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('backup-password')),
        fixturePassword,
      );
      await tester.tap(find.text('Unlock'));
      await tester.pump(const Duration(milliseconds: 400));
      await waitForCrypto(
        tester,
        () => find.text('Open this project?').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Open project'));
      await tester.pumpAndSettle();
      expect(opened, isNotNull);
      expect(store.projects, hasLength(2));
      expect(store.documents.linked(opened!), isFalse);
      expect(files.destination.saved, isNull);
      expect(store.roomsFor(opened!).single.name, 'Secret lounge fixture');
      expect(store.imageFor(room.originalId), [4, 5, 6]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancelled or wrong backup passwords create no project or image records',
    (tester) async {
      final files = ProtectedTestFiles(protected);
      final store = RenovisionStore(
        records: MemoryBox(),
        photos: MemoryBox(),
        files: files,
      );
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestoreProjectButton(
              store: store,
              onRestored: (_) => fail('No project should open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Restore a separate copy…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.projects, isEmpty);
      await tester.tap(find.text('Restore a separate copy…'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('backup-password')),
        'wrong-synthetic-password',
      );
      await tester.tap(find.text('Unlock'));
      await tester.pump(const Duration(milliseconds: 400));
      await waitForCrypto(
        tester,
        () => find
            .textContaining('password did not unlock')
            .evaluate()
            .isNotEmpty,
      );
      expect(store.projects, isEmpty);
      expect(store.photos.keys, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'protected export validates password confirmation and saves a separately encrypted copy',
    (tester) async {
      final files = ProtectedTestFiles(protected);
      final store = RenovisionStore(
        records: MemoryBox(),
        photos: MemoryBox(),
        files: files,
      );
      addTearDown(store.dispose);
      final project = await store.createProject('Existing source');
      await store.createRoom(
        projectId: project.id,
        name: 'My kitchen',
        originalImage: Uint8List.fromList([7, 8, 9]),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectBackupCard(store: store, project: project),
          ),
        ),
      );
      await tester.tap(find.text('Advanced: encrypted export'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export password-protected copy'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('backup-password')),
        fixturePassword,
      );
      await tester.enterText(
        find.byKey(const ValueKey('backup-password-repeat')),
        'not-the-same-password',
      );
      await tester.tap(find.text('Protect and save'));
      await tester.pumpAndSettle();
      expect(find.text('The passwords do not match.'), findsOneWidget);
      expect(files.destination.saved, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('backup-password-repeat')),
        fixturePassword,
      );
      await tester.tap(find.text('Protect and save'));
      await tester.pump(const Duration(milliseconds: 400));
      await waitForCrypto(tester, () => files.destination.saved != null);
      expect(isProtectedBackup(files.destination.saved!), isTrue);
      final unlocked = await tester.runAsync(
        () => unlockBackup(files.destination.saved!, fixturePassword),
      );
      expect(ProjectBackup.decode(unlocked!).rooms.single.name, 'My kitchen');
      expect(store.projects, hasLength(1));
      expect(
        store.records.keys.map((key) => store.records.get(key)).toString(),
        isNot(contains(fixturePassword)),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
