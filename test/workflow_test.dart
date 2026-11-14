import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/main.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void main() {
  late RenovisionStore store;
  late Uint8List image;
  setUp(() {
    store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    image = img.encodePng(img.Image(width: 80, height: 60));
  });
  tearDown(() => store.dispose());

  Future<RenovationRoom> createRoom() async {
    final project = await store.createProject('Claylands');
    return store.createRoom(
      projectId: project.id,
      name: 'Office',
      originalImage: image,
    );
  }

  testWidgets('workspace fits a phone-width viewport with long version names', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final room = await createRoom();
    final design = await store.createDesign(
      roomId: room.id,
      image: image,
      title: 'A very long office design option with wide windows and charcoal walnut cupboards',
      prompt: 'Keep the windows',
    );
    await store.approveBaseline(room.id, designId: design.id);
    await tester.pumpWidget(
      MaterialApp(
        home: WorkspaceScreen(store: store, roomId: room.id),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Working from the approved baseline.'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Working from the approved baseline.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('project creation and navigation work through the app UI', (
    tester,
  ) async {
    await tester.pumpWidget(RenovisionApp(store: store));
    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create project'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Claylands');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Claylands'), findsOneWidget);
    expect(store.projects.single.name, 'Claylands');
    await tester.tap(find.text('Claylands'));
    await tester.pumpAndSettle();
    expect(find.text('Import room photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving an idea puts it in the Library', (tester) async {
    final room = await createRoom();
    await store.createDesign(
      roomId: room.id,
      image: image,
      title: 'Charcoal office',
      prompt: 'Keep the wide windows',
    );
    await tester.pumpWidget(RenovisionApp(store: store));
    await tester.tap(find.text('Save idea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Charcoal office'), findsOneWidget);
    expect(find.text('Office'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'room opens approved baseline and viewing does not approve another',
    (tester) async {
      final room = await createRoom();
      final approved = await store.createDesign(
        roomId: room.id,
        image: image,
        title: 'Approved office',
        prompt: 'Keep windows',
      );
      await store.approveBaseline(room.id, designId: approved.id);
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(DropdownButtonFormField<String>),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final selector = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(selector.initialValue, approved.id);
      expect(find.text('Working from the approved baseline.'), findsOneWidget);
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Original photograph').last);
      await tester.pumpAndSettle();
      expect(store.roomById(room.id)!.approvedDesignId, approved.id);
      await tester.tap(find.text('Approve as baseline'));
      await tester.pumpAndSettle();
      expect(store.roomById(room.id)!.approvedDesignId, isNull);
      expect(store.imageFor(room.originalId), orderedEquals(image));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'workspace unfavourite leaves design pending rather than rejected',
    (tester) async {
      final room = await createRoom();
      final design = await store.createDesign(
        roomId: room.id,
        image: image,
        title: 'Option A',
        prompt: 'Prompt',
      );
      await store.setFavourite(design, favourite: true);
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Remove favourite'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Remove favourite'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove favourite'));
      await tester.pumpAndSettle();
      expect(store.designsFor(room.id).single.favourite, isFalse);
      expect(store.designsFor(room.id).single.rejected, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
