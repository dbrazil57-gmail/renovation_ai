import 'support/focus_navigation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/main.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void main() {
  testWidgets(
    'startup discovers saved rooms including approved designs and retains autosave preference',
    (tester) async {
      final records = MemoryBox(), photos = MemoryBox();
      final first = RenovisionStore(records: records, photos: photos);
      final image = img.encodePng(img.Image(width: 40, height: 30));
      final project = await first.createProject('My home');
      final room = await first.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: image,
      );
      final approved = await first.createDesign(
        roomId: room.id,
        image: image,
        title: 'Chosen design',
        prompt: 'Keep windows',
      );
      await first.approveBaseline(room.id, designId: approved.id);
      await first.rateDesign(approved, keep: true);
      await first.rememberRoom(room.id);
      await first.setAutosaveEnabled(false);
      first.dispose();
      final reopened = RenovisionStore(records: records, photos: photos);
      addTearDown(reopened.dispose);
      expect(reopened.autosaveEnabled, false);
      expect(reopened.resumeRoom!.id, room.id);
      await tester.pumpWidget(RenovisionApp(store: reopened));
      await tester.pumpAndSettle();
      expect(find.text('Continue Kitchen'), findsOneWidget);
      expect(find.text('Your ideas will appear here'), findsNothing);
      await tester.tap(find.text('Continue Kitchen'));
      await tester.pumpAndSettle();
      expect(find.byType(WorkspaceScreen), findsOneWidget);
      expect(reopened.roomById(room.id)!.approvedDesignId, approved.id);
      expect(reopened.imageFor(room.originalId), orderedEquals(image));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'room pins generation; Settings holds saving, restore and AI controls without losing drafts',
    (tester) async {
      final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
      addTearDown(store.dispose);
      final project = await store.createProject('Home');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: img.encodePng(img.Image(width: 40, height: 30)),
      );
      await store.setAutosaveEnabled(false);
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Autosave off ·'), findsNothing);
      expect(find.byKey(const ValueKey('workspace-generate')), findsOneWidget);
      expect(find.text('Save now'), findsNothing);
      expect(find.text('Save as…'), findsNothing);
      final changes = find.widgetWithText(TextField, 'What should change?');
      await revealFocusControl(
        tester,
        changes,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(changes, 'Keep these edits');
      await tester.tap(find.byTooltip('Room settings'));
      await tester.pumpAndSettle();
      expect(find.text('Save now'), findsOneWidget);
      expect(find.text('AI connection and models'), findsOneWidget);
      await revealFocusControl(
        tester,
        find.text('Restore a separate copy…'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Restore a separate copy…'), findsOneWidget);
      await revealFocusControl(
        tester,
        find.text('Save now'),
        -200,
        scrollable: find.byType(Scrollable).last,
      );
      await ensureFocusVisible(tester, find.text('Save now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save now'));
      await tester.pumpAndSettle();
      expect(store.roomById(room.id)!.instructions, 'Keep these edits');
      expect(store.autosaveEnabled, false);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(WorkspaceScreen), findsOneWidget);
      expect(find.text('Save now'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test('older records with no resume setting discover a room without modifying photos', () async {
    final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    addTearDown(store.dispose);
    final project = await store.createProject('Existing');
    final image = img.encodePng(img.Image(width: 20, height: 10));
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Bedroom',
      originalImage: image,
    );
    expect(store.resumeRoom!.id, room.id);
    await store.records.put('settings:resume', {'roomId': 'missing-room'});
    expect(store.resumeRoom!.id, room.id);
    expect(store.imageFor(room.originalId), orderedEquals(image));
  });
}
