import 'support/focus_navigation.dart';

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/store.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/room_analysis.dart';
import 'package:renovision_ai/ai_activity.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/design_delete_widgets.dart';

import 'support/memory_box.dart';

class TrashRecords extends MemoryBox {
  bool fail = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (fail && key.toString().startsWith('design:')) {
      throw StateError('Test storage failure');
    }
    await super.put(key, value);
  }
}

void main() {
  late RenovisionStore store;
  late TrashRecords records;
  late MemoryBox photos;
  late Uint8List bytes;
  late RenovationRoom room;
  late DesignVersion design;
  setUp(() async {
    records = TrashRecords();
    photos = MemoryBox();
    store = RenovisionStore(records: records, photos: photos);
    bytes = img.encodePng(img.Image(width: 40, height: 30));
    final project = await store.createProject('Deletion test');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: bytes,
    );
    design = await store.createDesign(
      roomId: room.id,
      image: bytes,
      title: 'Option A',
      prompt: 'Keep window',
    );
  });
  tearDown(() => store.dispose());

  test('deletion hides a design, retains bytes/metadata, survives restart and restores favourite', () async {
    await store.setFavourite(design, favourite: true);
    final before = Map.from(records.get('design:${design.id}') as Map);
    await store.trashDesign(design.id);
    expect(store.allDesigns, isEmpty);
    expect(store.deletedDesignsFor(room.id).single.id, design.id);
    expect(store.imageFor(room.originalId), bytes);
    expect(store.imageFor(design.imageId), bytes);
    expect(
      (records.get('design:${design.id}') as Map)['prompt'],
      before['prompt'],
    );
    final reopened = RenovisionStore(records: records, photos: photos);
    expect(reopened.designsFor(room.id), isEmpty);
    await reopened.restoreDesign(design.id);
    expect(reopened.designsFor(room.id).single.favourite, isTrue);
    expect(reopened.designsFor(room.id).single.id, design.id);
    reopened.dispose();
  });
  test('deleted parent and analysis source remain valid through project export/import', () async {
    final child = await store.createDesign(
      roomId: room.id,
      image: bytes,
      title: 'Refinement',
      prompt: 'Keep layout',
      parentId: design.id,
      sourceImageId: design.imageId,
    );
    await store.updateRoom(
      room.copyWith(
        analysis: RoomAnalysis(
          result: const RoomAnalysisResult(
            observations: 'A window.',
            questions: [],
            prompt: 'Keep window',
            model: 'synthetic',
          ),
          sourceImageId: design.imageId,
          supportingImageIds: [],
          context: 'Kitchen',
          created: DateTime.now(),
        ),
        useAiPrompt: true,
        aiPrompt: 'Keep window',
      ),
    );
    await store.trashDesign(design.id);
    expect(store.designsFor(room.id).single.id, child.id);
    final backup = ProjectBackup.decode(
      store.backupFor(room.projectId).encode(),
    );
    expect(backup.designs, hasLength(2));
    expect(
      backup.designs.singleWhere((v) => v.id == design.id).deleted,
      isTrue,
    );
    final restored = await store.restoreBackup(backup);
    final restoredRoom = store.roomsFor(restored.id).single;
    final parent = store.deletedDesignsFor(restoredRoom.id).single;
    final restoredChild = store.designsFor(restoredRoom.id).single;
    expect(restoredChild.parentId, parent.id);
    expect(restoredChild.sourceImageId, parent.imageId);
    expect(restoredRoom.analysis!.sourceImageId, parent.imageId);
    await store.restoreDesign(parent.id);
    expect(store.designsFor(restoredRoom.id), hasLength(2));
  });
  test('baseline and room photos are protected; deleted designs cannot become baseline', () async {
    await store.approveBaseline(room.id, designId: design.id);
    await expectLater(
      store.trashDesign(design.id),
      throwsA(isA<DesignChangeFailure>()),
    );
    expect(store.isDesignDeleted(design.id), isFalse);
    await store.approveBaseline(room.id);
    await store.trashDesign(design.id);
    await expectLater(
      store.approveBaseline(room.id, designId: design.id),
      throwsStateError,
    );
    expect(store.imageFor(room.originalId), bytes);
    await store.restoreDesign(design.id);
    await records.put('design:${design.id}', {
      ...design.toMap(),
      'imageId': room.originalId,
    });
    await expectLater(
      store.trashDesign(design.id),
      throwsA(isA<DesignChangeFailure>()),
    );
    expect(store.imageFor(room.originalId), bytes);
  });
  test('failed delete/restore writes leave state intact; in-flight generation blocks deletion', () async {
    records.fail = true;
    await expectLater(store.trashDesign(design.id), throwsStateError);
    expect(store.designsFor(room.id), hasLength(1));
    records.fail = false;
    store.ai.activity.begin(roomId: room.id, operation: 'Design');
    await expectLater(
      store.trashDesign(design.id),
      throwsA(isA<DesignChangeFailure>()),
    );
    store.ai.activity.update(AiStage.completed);
    await store.trashDesign(design.id);
    records.fail = true;
    await expectLater(store.restoreDesign(design.id), throwsStateError);
    expect(store.isDesignDeleted(design.id), isTrue);
    expect(store.imageFor(design.imageId), bytes);
  });
  test('legacy versions default active; stale review cannot resurrect deleted version', () async {
    final legacy = Map.of(design.toMap())..remove('deleted');
    expect(DesignVersion.fromMap(legacy).deleted, isFalse);
    await store.trashDesign(design.id);
    await expectLater(
      store.rateDesign(design, keep: true),
      throwsA(isA<DesignChangeFailure>()),
    );
    await store.returnToReview(design.id);
    expect(store.allDesigns, isEmpty);
  });

  Future<void> showControls(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: store,
            builder: (_, _) => Column(
              children: [
                Text('${store.designsFor(room.id).length} active'),
                if (!store.isDesignDeleted(design.id))
                  DeleteDesignButton(store: store, design: design),
                DeletedDesignsCard(store: store, roomId: room.id),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'delete confirmation can cancel, Undo restores and Deleted designs can restore later',
    (tester) async {
      await showControls(tester);
      await tester.tap(find.byTooltip('Delete Option A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.designsFor(room.id), hasLength(1));
      await tester.tap(find.byTooltip('Delete Option A'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete design'));
      await tester.pumpAndSettle();
      expect(find.text('0 active'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('1 active'), findsOneWidget);
      await store.trashDesign(design.id);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deleted designs (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Restore Option A'));
      await tester.pumpAndSettle();
      expect(find.text('1 active'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'deleting the selected version from history safely switches Working from',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(
            store: store,
            roomId: room.id,
            initialDesignId: design.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final menu = find.byTooltip('Review options for Option A');
      await revealFocusControl(
        tester,
        menu,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await ensureFocusVisible(tester, menu);
      await tester.pumpAndSettle();
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete design'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete design'));
      await tester.pumpAndSettle();
      expect(store.designsFor(room.id), isEmpty);
      final selector = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<String> &&
            w.decoration.labelText == 'Working from',
      );
      await revealFocusControl(
        tester,
        selector,
        -400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      expect(store.imageFor(room.originalId), bytes);
    },
  );
}
