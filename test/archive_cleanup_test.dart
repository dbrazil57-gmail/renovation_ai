import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/archive_cleanup_widgets.dart';
import 'package:renovision_ai/ai_activity.dart';
import 'package:renovision_ai/file_transfer.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';
import 'project_documents_test.dart' show DiskFile;

class CleanupBox extends MemoryBox {
  String? failDelete;
  Completer<void>? entered, gate;
  @override
  Future<void> delete(dynamic key) async {
    if (gate != null) {
      final wait = gate!;
      gate = null;
      entered?.complete();
      await wait.future;
    }
    if (key == failDelete) {
      failDelete = null;
      // Exercise failure after a write too, not just before deletion.
      await super.delete(key);
      throw StateError('Synthetic storage failure');
    }
    await super.delete(key);
  }
}

class CleanupFiles implements AppFiles {
  FileSaveResult result = FileSaveResult.saved;
  Uint8List? saved;
  bool fail = false;
  @override
  bool get supported => true;
  @override
  Future<Uint8List?> pickBackup() async => null;
  @override
  Future<FileSaveResult> save(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async {
    if (fail) throw StateError('Synthetic export failure');
    saved = Uint8List.fromList(bytes);
    return result;
  }
}

void main() {
  late CleanupBox records, photos;
  late CleanupFiles files;
  late RenovisionStore store;
  final image = img.encodePng(img.Image(width: 24, height: 18));
  setUp(() {
    records = CleanupBox();
    photos = CleanupBox();
    files = CleanupFiles();
    store = RenovisionStore(records: records, photos: photos, files: files);
  });
  tearDown(() => store.dispose());
  Future<RenovationProject> archive({String name = 'Old kitchen'}) async {
    final project = await store.createProject(name);
    await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: image,
    );
    await store.archiveProject(project.id, confirmation: project.name);
    return store.projectById(project.id)!;
  }

  test('permanent cleanup removes selected deleted rooms/history but protects shared photos, other projects, settings and files', () async {
    final active = await store.createProject('Active');
    final activeRoom = await store.createRoom(
      projectId: active.id,
      name: 'Bedroom',
      originalImage: image,
    );
    final old = await store.createProject('Old');
    final room = await store.createRoom(
      projectId: old.id,
      name: 'Kitchen',
      originalImage: image,
      additionalImages: [image],
    );
    final design = await store.createDesign(
      roomId: room.id,
      image: image,
      title: 'Old option',
      prompt: 'Fixture',
      sourceImageId: room.originalId,
    );
    await store.createDesign(
      roomId: activeRoom.id,
      image: image,
      title: 'Active option',
      prompt: 'Fixture',
      supportingImageIds: [room.originalId],
    );
    await store.setHomeCoverImage(room.id, room.originalId);
    await records.put('settings:ai_connection', {
      'url': 'synthetic-test',
      'remember': true,
    });
    await store.setImageBudget(3);
    await store.rememberBriefReview(room.id, precise: false);
    await store.trashDesign(design.id);
    await store.deleteRoom(room.id, confirmation: room.name);
    final disk = DiskFile();
    store.documents.attach(old.id, disk);
    await store.documents.save(old.id);
    await store.archiveProject(old.id, confirmation: old.name);
    final diskBefore = Uint8List.fromList(disk.bytes!);
    await photos.put('unrelated-orphan', image);
    final activeBefore = store.backupFor(active.id).contentSignature;
    final plan = store.archiveRemovalPlan(old.id);
    expect(plan.roomCount, 1);
    expect(plan.designCount, 1);
    expect(plan.images.containsKey(room.originalId), isFalse);
    await store.purgeArchivedProject(
      old.id,
      confirmation: old.name,
      revision: plan.revision,
    );
    expect(store.projectById(old.id), isNull);
    expect(records.get('room:${room.id}'), isNull);
    expect(records.get('design:${design.id}'), isNull);
    expect(store.imageFor(room.additionalPhotoIds.single), isNull);
    expect(store.imageFor(design.imageId), isNull);
    expect(store.imageFor(room.originalId), orderedEquals(image));
    expect(store.imageFor('unrelated-orphan'), orderedEquals(image));
    expect(store.backupFor(active.id).contentSignature, activeBefore);
    expect(records.get('settings:ai_connection'), {
      'url': 'synthetic-test',
      'remember': true,
    });
    expect(records.get('settings:image_budget_usd'), 3);
    expect(records.get('settings:home_cover'), isNull);
    expect(disk.bytes, orderedEquals(diskBefore));
    await expectLater(store.updateRoom(room), throwsStateError);
  });

  test('cleanup rejects active projects, wrong names, stale previews and running AI', () async {
    final active = await store.createProject('Current');
    expect(() => store.archiveRemovalPlan(active.id), throwsStateError);
    final old = await archive();
    final plan = store.archiveRemovalPlan(old.id);
    await expectLater(
      store.purgeArchivedProject(
        old.id,
        confirmation: 'wrong',
        revision: plan.revision,
      ),
      throwsArgumentError,
    );
    store.ai.activity.begin(roomId: 'fixture', operation: 'Fixture');
    await expectLater(
      store.purgeArchivedProject(
        old.id,
        confirmation: old.name,
        revision: plan.revision,
      ),
      throwsStateError,
    );
    store.ai.activity.update(AiStage.completed);
    final room = store.roomsFor(old.id).single;
    await store.updateRoom(room.copyWith(instructions: 'A newer saved change'));
    await expectLater(
      store.purgeArchivedProject(
        old.id,
        confirmation: old.name,
        revision: plan.revision,
      ),
      throwsStateError,
    );
    await store.restoreProject(old.id);
    await expectLater(
      store.purgeArchivedProject(
        old.id,
        confirmation: old.name,
        revision: plan.revision,
      ),
      throwsStateError,
    );
    expect(store.projects, hasLength(2));
  });

  for (final failImage in [false, true]) {
    test(
      'cleanup rolls back a ${failImage ? 'photo' : 'record'} deletion failure',
      () async {
        final old = await archive();
        final room = store.roomsFor(old.id).single;
        final before = store.backupFor(old.id).contentSignature;
        final plan = store.archiveRemovalPlan(old.id);
        (failImage ? photos : records).failDelete = failImage
            ? room.originalId
            : 'room:${room.id}';
        await expectLater(
          store.purgeArchivedProject(
            old.id,
            confirmation: old.name,
            revision: plan.revision,
          ),
          throwsStateError,
        );
        expect(store.backupFor(old.id).contentSignature, before);
        await store.purgeArchivedProject(
          old.id,
          confirmation: old.name,
          revision: store.archiveRemovalPlan(old.id).revision,
        );
        expect(store.projectById(old.id), isNull);
      },
    );
  }

  test('a stale editor and restore cannot write into a project while cleanup is running', () async {
    final old = await archive();
    final room = store.roomsFor(old.id).single;
    final plan = store.archiveRemovalPlan(old.id);
    final gate = Completer<void>();
    records.gate = gate;
    records.entered = Completer<void>();
    final deleting = store.purgeArchivedProject(
      old.id,
      confirmation: old.name,
      revision: plan.revision,
    );
    await records.entered!.future;
    await expectLater(
      store.updateRoom(room.copyWith(instructions: 'Stale')),
      throwsStateError,
    );
    await expectLater(store.restoreProject(old.id), throwsStateError);
    await expectLater(
      store.createRoom(projectId: old.id, name: 'Stale', originalImage: image),
      throwsStateError,
    );
    gate.complete();
    await deleting;
    expect(store.projectById(old.id), isNull);
  });

  Future<void> openDialog(WidgetTester tester, RenovationProject old) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: ArchiveCleanupScreen(store: store)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('purge-archive-${old.id}')));
    await tester.pumpAndSettle();
  }

  Finder getDelete() =>
      find.byKey(const ValueKey('confirm-permanent-archive-delete'));

  testWidgets(
    'cleanup asks about backup, supports explicit skip and requires the exact name',
    (tester) async {
      final old = await archive();
      await openDialog(tester, old);
      expect(find.text('Save offline backup first'), findsOneWidget);
      expect(tester.widget<FilledButton>(getDelete()).onPressed, isNull);
      await tester.tap(find.text('Continue without a backup'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('archive-delete-name')),
        'Wrong',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(getDelete()).onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('archive-delete-name')),
        old.name,
      );
      await tester.pump();
      await tester.tap(getDelete());
      await tester.pumpAndSettle();
      expect(store.projectById(old.id), isNull);
      expect(find.text('Nothing to clean up'), findsOneWidget);
      expect(files.saved, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final result in FileSaveResult.values) {
    testWidgets(
      'backup result $result is handled without silently deleting the archive',
      (tester) async {
        files.result = result;
        final old = await archive();
        final before = store.backupFor(old.id);
        await openDialog(tester, old);
        await tester.tap(find.text('Save offline backup first'));
        await tester.pumpAndSettle();
        expect(store.projectById(old.id), isNotNull);
        if (result == FileSaveResult.cancelled) {
          expect(
            find.byKey(const ValueKey('archive-delete-name')),
            findsNothing,
          );
          expect(tester.widget<FilledButton>(getDelete()).onPressed, isNull);
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(store.projectById(old.id), isNotNull);
        } else {
          final copy = ProjectBackup.decode(files.saved!);
          expect(copy.project.archived, isFalse);
          expect(copy.project.deleted, isFalse);
          expect(copy.photos.keys.toSet(), before.photos.keys.toSet());
          await tester.enterText(
            find.byKey(const ValueKey('archive-delete-name')),
            old.name,
          );
          await tester.pump();
          if (result == FileSaveResult.requested) {
            expect(tester.widget<FilledButton>(getDelete()).onPressed, isNull);
            final checked = find.byKey(
              const ValueKey('archive-backup-download-checked'),
            );
            await tester.ensureVisible(checked);
            await tester.pumpAndSettle();
            await tester.tap(
              find.descendant(of: checked, matching: find.byType(Checkbox)),
            );
            await tester.pumpAndSettle();
            expect(
              tester.widget<FilledButton>(getDelete()).onPressed,
              isNotNull,
            );
          }
          await tester.tap(getDelete());
          await tester.pumpAndSettle();
          expect(store.projectById(old.id), isNull);
          final reopened = await store.openBackup(copy);
          expect(store.projects.single.id, reopened.id);
          expect(
            store.imageFor(store.roomsFor(reopened.id).single.originalId),
            orderedEquals(image),
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'a failed backup leaves deletion disabled and Cancel keeps everything',
    (tester) async {
      files.fail = true;
      final old = await archive();
      final before = store.backupFor(old.id).contentSignature;
      await openDialog(tester, old);
      await tester.tap(find.text('Save offline backup first'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Backup could not be saved.'), findsOneWidget);
      expect(tester.widget<FilledButton>(getDelete()).onPressed, isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.backupFor(old.id).contentSignature, before);
    },
  );

  testWidgets(
    'Settings exposes Storage cleanup independently of appearance and retains empty state',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SettingsTab(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      final entry = find.byKey(const ValueKey('archive-cleanup-settings'));
      await tester.scrollUntilVisible(
        entry,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.text('Archive cleanup'), findsOneWidget);
      expect(find.text('Nothing to clean up'), findsOneWidget);
    },
  );
}
