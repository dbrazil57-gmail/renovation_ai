import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/focus_workspace.dart';
import 'package:renovision_ai/main.dart' show buildRenovisionTheme;
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/focus_navigation.dart';
import 'support/memory_box.dart';

const partialWarning =
    'Select the items to update, or describe your partial renovation in Refine.';

void main() {
  late RenovisionStore store;
  late RenovationRoom room;
  late DesignVersion design;
  late Uint8List original, otherPhoto;
  late int paidRequests;

  setUp(() async {
    paidRequests = 0;
    final ai = AiService(
      clientFactory: () => MockClient((request) async {
        if (request.url.path == '/health') {
          return http.Response(
            jsonEncode({
              'provider': 'OpenAI',
              'model': 'fixture',
              'quality': 'low',
              'maxInputImages': 7,
            }),
            200,
          );
        }
        paidRequests++;
        throw StateError('This test must cancel before sending.');
      }),
    );
    await ai.connect(url: 'http://127.0.0.1:8787', pairingCode: 'fixture');
    store = RenovisionStore(records: MemoryBox(), photos: MemoryBox(), ai: ai);
    final project = await store.createProject('Source selection fixture');
    original = img.encodePng(img.Image(width: 60, height: 40));
    otherPhoto = img.encodePng(img.Image(width: 70, height: 50));
    room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: original,
    );
    await store.addRoomPhotos(room.id, [otherPhoto]);
    await store.updateRoom(
      store
          .roomById(room.id)!
          .copyWith(
            fullRenovation: false,
            designStyleIds: ['modern'],
            colourPaletteId: 'sage_oak',
          ),
    );
    design = await store.createDesign(
      roomId: room.id,
      image: img.encodePng(img.Image(width: 80, height: 60)),
      title: 'Generated fixture',
      prompt: 'Historical brief',
      aiProvider: 'OpenAI',
      aiModel: 'fixture',
    );
  });
  tearDown(() => store.dispose());

  Future<void> open(
    WidgetTester tester, {
    String? designId,
    String? photoId,
    RoomDesignMode? mode,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRenovisionTheme(),
        home: WorkspaceScreen(
          store: store,
          roomId: room.id,
          initialDesignId: designId,
          initialPhotoId: photoId,
          initialMode: mode,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  RoomDesignMode currentMode(WidgetTester tester) => tester
      .widget<SegmentedButton<RoomDesignMode>>(
        find.byKey(const ValueKey('design-edit-mode'), skipOffstage: false),
      )
      .selected
      .single;

  Future<void> cancelConfirmation(
    WidgetTester tester,
    Uint8List expectedPhoto, {
    bool viaBrief = false,
  }) async {
    await tester.tap(
      find.byKey(
        ValueKey(viaBrief ? 'brief-readiness-indicator' : 'workspace-generate'),
      ),
    );
    await tester.pumpAndSettle();
    if (viaBrief) {
      final proceed = find.byKey(const ValueKey('brief-proceed-checkbox'));
      if (proceed.evaluate().isNotEmpty) {
        await tester.tap(proceed);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('brief-review-primary')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Send to OpenAI'), findsOneWidget);
    final images = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(Image),
    );
    expect(
      (tester.widget<Image>(images.first).image as MemoryImage).bytes,
      orderedEquals(expectedPhoto),
    );
    expect(find.text(partialWarning), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(paidRequests, 0);
  }

  for (final restoredMode in [null, RoomDesignMode.partial]) {
    testWidgets(
      'empty generated-edit mode cannot block an original on entry or legacy refresh ($restoredMode)',
      (tester) async {
        await open(tester, photoId: room.originalId, mode: restoredMode);
        expect(currentMode(tester), RoomDesignMode.newDesign);
        await cancelConfirmation(tester, original);
        await cancelConfirmation(tester, original, viaBrief: true);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'original and another angle share the same dropdown path; clear stale partial warning on switching',
    (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('focus-section-refine')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Partial'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-generate')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('workspace-generate')),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('Add changes to continue'), findsOneWidget);
      expect(find.text('Send to OpenAI'), findsNothing);
      Future<void> choosePhoto(String title) async {
        await tester.tap(find.byKey(const ValueKey('focus-section-room')));
        await tester.pumpAndSettle();
        final source = find.byWidgetPredicate(
          (w) =>
              w is DropdownButtonFormField<String> &&
              w.decoration.labelText == 'Working from',
        );
        await ensureFocusVisible(tester, source);
        await tester.tap(source);
        await tester.pumpAndSettle();
        await tester.tap(find.text(title).last);
        await tester.pumpAndSettle();
        expect(currentMode(tester), RoomDesignMode.newDesign);
        expect(find.text(partialWarning), findsNothing);
      }

      await choosePhoto('Room photo · View 2');
      await cancelConfirmation(tester, otherPhoto);
      await choosePhoto('Original photograph — locked');
      await cancelConfirmation(tester, original, viaBrief: true);
      expect(store.imageFor(room.originalId), orderedEquals(original));
      expect(store.designsFor(room.id), hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'switching New design clears its obsolete validation immediately; generated images still default Partial',
    (tester) async {
      await open(tester, designId: design.id);
      expect(currentMode(tester), RoomDesignMode.partial);
      await tester.tap(find.byKey(const ValueKey('workspace-generate')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('workspace-generate')),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('Add changes to continue'), findsOneWidget);
      final originalThumbnail = find.byWidgetPredicate(
        (w) => w is FocusVersionThumbnail && w.title == 'Original',
      );
      await tester.ensureVisible(originalThumbnail);
      await tester.tap(originalThumbnail);
      await tester.pumpAndSettle();
      expect(currentMode(tester), RoomDesignMode.newDesign);
      expect(
        find.text(
          'Describe the specific correction in Refine before generating.',
        ),
        findsNothing,
      );
      await cancelConfirmation(tester, original);
      await tester.tap(find.byKey(const ValueKey('focus-section-refine')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Partial'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-generate')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('workspace-generate')),
            )
            .onPressed,
        isNull,
      );
      await ensureFocusVisible(tester, find.text('New design'));
      await tester.tap(find.text('New design'));
      await tester.pumpAndSettle();
      expect(find.text(partialWarning), findsNothing);
      await cancelConfirmation(tester, original);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'an explicitly scoped partial renovation on the original remains available after refresh',
    (tester) async {
      await store.updateRoom(
        store.roomById(room.id)!.copyWith(renovationScopeIds: ['flooring']),
      );
      await open(
        tester,
        photoId: room.originalId,
        mode: RoomDesignMode.partial,
      );
      expect(currentMode(tester), RoomDesignMode.partial);
      await cancelConfirmation(tester, original);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'clearing an obsolete request warning does not dismiss an unrelated save warning',
    (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('focus-section-refine')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Partial'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-generate')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('workspace-generate')),
            )
            .onPressed,
        isNull,
      );
      notice(
        tester.element(find.byType(WorkspaceScreen)),
        'Fixture project save warning',
      );
      await tester.pumpAndSettle();
      final originalThumbnail = find.byWidgetPredicate(
        (w) => w is FocusVersionThumbnail && w.title == 'Original',
      );
      await tester.ensureVisible(originalThumbnail);
      await tester.tap(originalThumbnail);
      await tester.pumpAndSettle();
      expect(currentMode(tester), RoomDesignMode.newDesign);
      expect(find.text('Fixture project save warning'), findsOneWidget);
      expect(paidRequests, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
