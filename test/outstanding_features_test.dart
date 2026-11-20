import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/design_recipe.dart';
import 'package:renovision_ai/main.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/project_transfer_widgets.dart';
import 'package:renovision_ai/room_analysis.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'project_documents_test.dart' show DocumentFiles;
import 'support/memory_box.dart';
import 'support/focus_navigation.dart';

class PublishFailure extends MemoryBox {
  bool failPublishing = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (failPublishing && key.toString().startsWith('project:')) {
      throw StateError('Synthetic storage failure');
    }
    await super.put(key, value);
  }
}

class PartialDesignFailure extends MemoryBox {
  @override
  Future<void> put(dynamic key, dynamic value) async {
    await super.put(key, value);
    if (key.toString().startsWith('design:')) {
      throw StateError('Synthetic failure after publishing a design record');
    }
  }
}

void main() {
  final photo = img.encodePng(img.Image(width: 48, height: 32));
  late RenovisionStore store;
  late RenovationProject project;
  late RenovationRoom room;
  setUp(() async {
    store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    project = await store.createProject('Existing home');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: photo,
      colourPaletteId: 'charcoal_walnut',
    );
  });
  tearDown(() => store.dispose());

  test('Open twice and after restart resumes stable project, room and image identities', () async {
    final backup = ProjectBackup.decode(store.backupFor(project.id).encode());
    final records = MemoryBox(), photos = MemoryBox();
    final other = RenovisionStore(records: records, photos: photos);
    final opened = await other.openBackup(backup);
    expect(opened.id, project.id);
    expect(other.roomsFor(opened.id).single.originalId, room.originalId);
    await other.openBackup(backup);
    expect(other.projects, hasLength(1));
    other.dispose();
    final restarted = RenovisionStore(records: records, photos: photos);
    addTearDown(restarted.dispose);
    await restarted.openBackup(backup);
    expect(restarted.projects, hasLength(1));
    expect(restarted.imageFor(room.originalId), photo);
    final copy = await restarted.restoreBackup(backup);
    expect(copy.id, isNot(project.id));
    expect(
      restarted.roomsFor(copy.id).single.originalId,
      isNot(room.originalId),
    );
    expect(restarted.projects, hasLength(2));
  });

  test('opening a divergent file cannot overwrite local work', () async {
    final backup = store.backupFor(project.id);
    await store.renameRoom(room.id, 'Local kitchen changes');
    await expectLater(store.openBackup(backup), throwsA(isA<BackupFailure>()));
    expect(store.roomById(room.id)!.name, 'Local kitchen changes');
    expect(store.projects, hasLength(1));
  });

  test(
    'failed design publication leaves no dangling record or lost original',
    () async {
      final records = PartialDesignFailure(), photos = MemoryBox();
      final other = RenovisionStore(records: records, photos: photos);
      addTearDown(other.dispose);
      final home = await other.createProject('Retained home');
      final original = await other.createRoom(
        projectId: home.id,
        name: 'Kitchen',
        originalImage: photo,
      );
      final recordsBefore = jsonEncode(records.entries),
          photosBefore = jsonEncode(photos.entries);
      await expectLater(
        other.createDesign(
          roomId: original.id,
          image: photo,
          title: 'Interrupted result',
          prompt: 'Keep layout',
        ),
        throwsStateError,
      );
      expect(jsonEncode(records.entries), recordsBefore);
      expect(jsonEncode(photos.entries), photosBefore);
      expect(
        other.backupFor(home.id).rooms.single.originalId,
        original.originalId,
      );
    },
  );

  test('interrupted Open rolls back only its new records and leaves existing photos intact', () async {
    final records = PublishFailure(), photos = MemoryBox();
    final other = RenovisionStore(records: records, photos: photos);
    addTearDown(other.dispose);
    final local = await other.createProject('Unrelated local work');
    await other.createRoom(
      projectId: local.id,
      name: 'Bedroom',
      originalImage: photo,
    );
    final recordsBefore = jsonEncode(records.entries),
        photosBefore = jsonEncode(photos.entries);
    records.failPublishing = true;
    await expectLater(
      other.openBackup(store.backupFor(project.id)),
      throwsA(isA<BackupFailure>()),
    );
    expect(jsonEncode(records.entries), recordsBefore);
    expect(jsonEncode(photos.entries), photosBefore);
  });

  testWidgets(
    'Open conflict can keep local work or explicitly import a separate file copy',
    (tester) async {
      final files = DocumentFiles()
        ..opening = store.backupFor(project.id).encode();
      final local = RenovisionStore(
        records: store.records,
        photos: store.photos,
        files: files,
      );
      addTearDown(local.dispose);
      await local.renameRoom(room.id, 'Locally changed');
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RestoreProjectButton(
              store: local,
              openDocument: true,
              onRestored: (p) => opened = p.id,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open project…'));
      await tester.pumpAndSettle();
      expect(find.text('Local work and file differ'), findsOneWidget);
      await tester.tap(find.text('Keep local project'));
      await tester.pumpAndSettle();
      expect(opened, project.id);
      expect(local.projects, hasLength(1));
      expect(local.roomById(room.id)!.name, 'Locally changed');
      await tester.tap(find.text('Open project…'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open file as copy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open project'));
      await tester.pumpAndSettle();
      expect(local.projects, hasLength(2));
      expect(local.documents.linked(opened!), isFalse);
      expect(local.roomsFor(opened!).single.name, 'Kitchen');
      expect(local.roomById(room.id)!.name, 'Locally changed');
    },
  );

  test('recipe snapshots are detached, preserve analysis and exclude connection credentials', () async {
    final draft = RoomDraft(store, room);
    addTearDown(draft.dispose);
    draft.setStyle('modern', true);
    draft.setAnalysis(
      RoomAnalysis(
        result: const RoomAnalysisResult(
          observations: 'Window over sink',
          questions: [],
          prompt: 'Keep the window',
          model: 'synthetic-vision',
        ),
        sourceImageId: room.originalId,
        supportingImageIds: [],
        context: 'Original context',
        created: DateTime.utc(2026),
      ),
    );
    final recipe = draft.captureRecipe().withValues({
      'imageModel': 'synthetic-image',
      'imageQuality': 'high',
      'apiKey': 'synthetic-private-key',
    });
    draft.setStyle('classic', true);
    draft.protected.text = 'New choices';
    final exported = recipe.toMap();
    (exported['designStyleIds'] as List).clear();
    expect(recipe.toMap()['designStyleIds'], ['modern']);
    expect(recipe.toMap()['protectedFeatures'], '');
    expect(recipe.analysis!.result.observations, 'Window over sink');
    expect(
      jsonEncode(recipe.toMap()),
      isNot(contains('synthetic-private-key')),
    );
    final design = await store.createDesign(
      roomId: room.id,
      image: photo,
      title: 'Saved design',
      prompt: 'Exact sent prompt',
      sourceImageId: room.originalId,
      recipe: recipe,
    );
    final copy = await store.restoreBackup(
      ProjectBackup.decode(store.backupFor(project.id).encode()),
    );
    final copyRoom = store.roomsFor(copy.id).single;
    final copyDesign = store.designsFor(copyRoom.id).single;
    expect(copyDesign.recipe!.analysis!.sourceImageId, copyRoom.originalId);
    expect(copyDesign.recipe!.toMap()['imageQuality'], 'high');
    expect(copyDesign.prompt, design.prompt);
    expect(
      DesignVersion.fromMap({...design.toMap()}..remove('recipe')).recipe,
      isNull,
    );
  });

  testWidgets(
    'saved settings restore room choices and refine the chosen design without generation',
    (tester) async {
      final recipe = DesignRecipe({
        ...room.toMap(),
        'instructions': 'Original renovation brief',
        'designStyleIds': ['modern'],
        'roomTypeId': 'kitchen',
        'preciseEdit': false,
      });
      final design = await store.createDesign(
        roomId: room.id,
        image: photo,
        title: 'Stored option',
        prompt: 'Original prompt',
        sourceImageId: room.originalId,
        recipe: recipe,
      );
      await store.updateRoom(
        room.copyWith(
          instructions: 'Current brief',
          designStyleIds: ['classic'],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildRenovisionTheme(),
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await ensureFocusVisible(tester, find.text('Saved settings'));
      await tester.tap(find.text('Saved settings'));
      await tester.pumpAndSettle();
      expect(find.text('Palette: Charcoal & walnut'), findsOneWidget);
      await tester.tap(find.text('Use these settings'));
      await tester.pumpAndSettle();
      expect(
        store.roomById(room.id)!.instructions,
        'Original renovation brief',
      );
      expect(store.roomById(room.id)!.designStyleIds, ['modern']);
      await ensureFocusVisible(tester, find.text('Saved settings'));
      await tester.tap(find.text('Saved settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refine this design'));
      await tester.pumpAndSettle();
      expect(store.roomById(room.id)!.preciseEdit, isTrue);
      expect(store.roomById(room.id)!.correctionInstructions, '');
      expect(store.roomById(room.id)!.approvedDesignId, isNull);
      expect(store.designsFor(room.id).single.id, design.id);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'startup displays progress before storage opens and then retains existing projects',
    (tester) async {
      final pending = Completer<RenovisionStore>();
      final fixture = RenovisionStore(
        records: MemoryBox(),
        photos: MemoryBox(),
      );
      await fixture.createProject('Saved startup home');
      await tester.pumpWidget(
        RenovisionStartup(loadStore: () => pending.future),
      );
      await tester.pump();
      expect(find.text('Opening your projects…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(fixture);
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(fixture.projects.single.name, 'Saved startup home');
    },
  );

  testWidgets('startup failure offers Retry and never clears local records', (
    tester,
  ) async {
    var attempts = 0;
    final records = MemoryBox()..entries['private-marker'] = 'Keep';
    final fixture = RenovisionStore(records: records, photos: MemoryBox());
    await tester.pumpWidget(
      RenovisionStartup(
        loadStore: () async {
          if (++attempts == 1) {
            throw StateError('Synthetic unavailable storage');
          }
          return fixture;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved projects could not be opened'), findsOneWidget);
    expect(records.get('private-marker'), 'Keep');
    await tester.tap(find.text('Retry opening projects'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(AppShell), findsOneWidget);
    expect(records.get('private-marker'), 'Keep');
  });
}
