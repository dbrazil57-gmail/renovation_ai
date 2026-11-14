import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void main() {
  late RenovisionStore store;
  late RenovationProject project;
  late RenovationRoom room;
  late Uint8List image;
  setUp(() async {
    store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    image = img.encodePng(img.Image(width: 60, height: 40));
    project = await store.createProject('Claylands');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Office',
      originalImage: image,
    );
  });
  tearDown(() => store.dispose());

  Finder dialogField() => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextField),
  );

  testWidgets(
    'rename updates project header and backup; cancelling keeps name',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectScreen(store: store, project: project),
        ),
      );
      await tester.tap(find.byTooltip('Rename project'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(dialogField()).controller!.text,
        'Claylands',
      );
      await tester.enterText(dialogField(), 'Claylands revised');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Claylands revised'), findsOneWidget);
      expect(store.backupFor(project.id).project.name, 'Claylands revised');
      await tester.tap(find.byTooltip('Rename project'));
      await tester.pumpAndSettle();
      await tester.enterText(dialogField(), 'Cancelled change');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.projectById(project.id)!.name, 'Claylands revised');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rename room preserves unsaved instruction draft and baseline', (
    tester,
  ) async {
    final design = await store.createDesign(
      roomId: room.id,
      image: image,
      title: 'Option',
      prompt: 'Keep windows',
    );
    await store.approveBaseline(room.id, designId: design.id);
    await tester.pumpWidget(
      MaterialApp(
        home: WorkspaceScreen(store: store, roomId: room.id),
      ),
    );
    await tester.pumpAndSettle();
    final instructions = find.widgetWithText(TextField, 'What should change?');
    await tester.scrollUntilVisible(
      instructions,
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(instructions);
    await tester.enterText(instructions, 'Unsaved skirting instructions');
    await tester.tap(find.byTooltip('Rename room'));
    await tester.pumpAndSettle();
    await tester.enterText(dialogField(), 'Home office');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Home office'), findsOneWidget);
    expect(
      tester.widget<TextField>(instructions).controller!.text,
      'Unsaved skirting instructions',
    );
    expect(store.roomById(room.id)!.instructions, '');
    expect(store.roomById(room.id)!.approvedDesignId, design.id);
    expect(store.imageFor(room.originalId), orderedEquals(image));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'passed design returns to review on a narrow screen without changing approval',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final design = await store.createDesign(
        roomId: room.id,
        image: image,
        title: 'Long office option keeping the wide rear windows and original camera angle',
        prompt: 'Keep windows',
      );
      await store.approveBaseline(room.id, designId: design.id);
      await store.rateDesign(design, keep: false);
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      final menu = find.byTooltip('Review options for ${design.title}');
      await tester.scrollUntilVisible(
        menu,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(menu);
      await tester.pumpAndSettle();
      expect(find.textContaining('Approved baseline • Passed'), findsOneWidget);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Return to review'));
      await tester.pumpAndSettle();
      expect(store.designsFor(room.id).single.rejected, isFalse);
      expect(store.designsFor(room.id).single.favourite, isFalse);
      expect(store.roomById(room.id)!.approvedDesignId, design.id);
      expect(
        find.textContaining('Approved baseline • Awaiting review'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
