import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/store.dart';
import 'package:renovision_ai/project_management_widgets.dart';
import 'package:renovision_ai/project_backup.dart';

import 'support/memory_box.dart';
import 'project_documents_test.dart' show DiskFile;

class ArchiveFailingBox extends MemoryBox {
  bool fail = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (fail && key.toString().startsWith('project:')) {
      throw StateError('Synthetic archive failure');
    }
    await super.put(key, value);
  }
}

void main() {
  late RenovisionStore store;
  setUp(() {
    store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
  });
  tearDown(() => store.dispose());
  final image = img.encodePng(img.Image(width: 20, height: 20));

  test('archive failure preserves both the active project and working file connection', () async {
    final records = ArchiveFailingBox();
    final local = RenovisionStore(records: records, photos: MemoryBox());
    addTearDown(local.dispose);
    final project = await local.createProject('Home');
    final file = DiskFile();
    local.documents.attach(project.id, file);
    await local.documents.save(project.id);
    records.fail = true;
    await expectLater(
      local.archiveProject(project.id, confirmation: project.name),
      throwsStateError,
    );
    expect(local.projects.single.id, project.id);
    expect(local.documents.linked(project.id), true);
    expect(ProjectBackup.decode(file.bytes!).project.name, 'Home');
  });

  test(
    'project names are distinct and rename cannot hide another project',
    () async {
      final a = await store.createProject('Home'),
          b = await store.createProject(' home ');
      expect(a.name, 'Home');
      expect(b.name, 'home (2)');
      await expectLater(store.renameProject(b.id, 'HOME'), throwsArgumentError);
      expect(store.projectById(a.id)!.name, 'Home');
      expect(store.projectById(b.id)!.name, 'home (2)');
    },
  );

  test('archive/delete are confirmed, recoverable and preserve complete portable work', () async {
    final p = await store.createProject('Home');
    final r = await store.createRoom(
      projectId: p.id,
      name: 'Kitchen',
      originalImage: image,
    );
    final d = await store.createDesign(
      roomId: r.id,
      image: image,
      title: 'Option',
      prompt: 'Saved',
    );
    await store.approveBaseline(r.id, designId: d.id);
    await store.rememberRoom(r.id);
    final before = store.backupFor(p.id);
    await expectLater(
      store.archiveProject(p.id, confirmation: 'wrong'),
      throwsArgumentError,
    );
    expect(store.projects, hasLength(1));
    await store.archiveProject(p.id, confirmation: p.name);
    expect(store.projects, isEmpty);
    expect(store.resumeRoom, isNull);
    expect(store.archivedProjects.single.id, p.id);
    expect(store.allDesigns, isEmpty);
    final backup = ProjectBackup.decode(store.backupFor(p.id).encode());
    expect(backup.designs.single.id, d.id);
    expect(backup.rooms.single.approvedDesignId, d.id);
    expect(backup.photos.keys.toSet(), before.photos.keys.toSet());
    expect(store.imageFor(r.originalId), orderedEquals(image));
    await store.restoreProject(p.id);
    expect(store.resumeRoom!.id, r.id);
    expect(store.designsFor(r.id).single.id, d.id);
    await store.archiveProject(p.id, delete: true, confirmation: p.name);
    expect(store.archivedProjects.single.deleted, true);
    expect(store.resumeRoom, isNull);
    await store.restoreProject(p.id);
    expect(store.projects.single.id, p.id);
  });

  test('importing room copies appends remapped history and never overwrites target or source', () async {
    final source = await store.createProject('Source'),
        target = await store.createProject('Target');
    final original = await store.createRoom(
      projectId: source.id,
      name: 'Kitchen',
      originalImage: image,
    );
    final old = await store.createRoom(
      projectId: target.id,
      name: 'Living',
      originalImage: image,
    );
    final design = await store.createDesign(
      roomId: original.id,
      image: image,
      title: 'Kitchen option',
      prompt: 'Keep windows',
    );
    await store.approveBaseline(original.id, designId: design.id);
    final sourceSignature = store.backupFor(source.id).contentSignature;
    final result = await store.restoreBackup(
      store.backupFor(source.id),
      targetProjectId: target.id,
    );
    expect(result.id, target.id);
    expect(store.projects, hasLength(2));
    final rooms = store.roomsFor(target.id);
    expect(rooms, hasLength(2));
    expect(rooms.any((r) => r.id == old.id), true);
    final copy = rooms.firstWhere((r) => r.id != old.id);
    expect(copy.id, isNot(original.id));
    expect(copy.originalId, isNot(original.originalId));
    final copiedDesign = store.designsFor(copy.id).single;
    expect(copy.approvedDesignId, copiedDesign.id);
    expect(copiedDesign.id, isNot(design.id));
    expect(store.backupFor(source.id).contentSignature, sourceSignature);
    expect(
      ProjectBackup.decode(store.backupFor(target.id).encode()).rooms,
      hasLength(2),
    );
  });

  testWidgets(
    'project deletion requires typed confirmation and offers backup first',
    (tester) async {
      final project = await store.createProject('Home');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectManagementButton(store: store, project: project),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Archive or delete project'));
      await tester.pumpAndSettle();
      expect(find.text('Export backup snapshot'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Delete project'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), 'Home');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete project'));
      await tester.pumpAndSettle();
      expect(store.projects, isEmpty);
      expect(store.archivedProjects.single.deleted, true);
      expect(tester.takeException(), isNull);
    },
  );
}
