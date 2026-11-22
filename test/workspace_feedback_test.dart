import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_model_choices.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/ai_widgets.dart';
import 'package:renovision_ai/colour_palette_widgets.dart';
import 'package:renovision_ai/design_mode_widgets.dart';
import 'package:renovision_ai/focus_workspace.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/room_start_widgets.dart';
import 'package:renovision_ai/room_starters.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/secret_store.dart';
import 'package:renovision_ai/store.dart';

import 'support/focus_navigation.dart';
import 'support/memory_box.dart';

void main() {
  late RenovisionStore store;
  late RenovationRoom room;
  late int checks;
  setUp(() async {
    checks = 0;
    final ai = AiService(
      keyStore: SessionSecretStore(),
      clientFactory: () => MockClient((request) async {
        checks++;
        expect(request.url.path, '/v1/models');
        return http.Response(
          jsonEncode({
            'data': [
              {'id': preferredRoomImageModels.first},
              {'id': 'gpt-6-luna'},
            ],
          }),
          200,
        );
      }),
    );
    store = RenovisionStore(records: MemoryBox(), photos: MemoryBox(), ai: ai);
    final project = await store.createProject('Feedback fixture');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: img.encodePng(img.Image(width: 40, height: 30)),
    );
  });
  tearDown(() => store.dispose());

  testWidgets(
    'a session API key survives every workspace tab and rebuilt settings, but is not exported or restored after a page restart',
    (tester) async {
      const fixtureKey = 'synthetic-session-fixture';
      await store.ai.connectDirect(apiKey: fixtureKey);
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      for (final section in FocusSection.values) {
        await tester.tap(find.byKey(ValueKey('focus-section-${section.name}')));
        await tester.pumpAndSettle();
        expect(store.ai.connected, true);
        expect(store.ai.keyRememberedOnDevice, false);
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AiConnectionCard(ai: store.ai)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Browser connection'), findsOneWidget);
      expect(store.ai.connected, true);
      expect(checks, 1);
      final saved = store.ai.rememberedConnection!;
      expect(jsonEncode(saved), isNot(contains(fixtureKey)));
      expect(
        utf8.decode(store.backupFor(room.projectId).encode()),
        isNot(contains(fixtureKey)),
      );
      final restarted = AiService(keyStore: SessionSecretStore());
      await restarted.restoreConnection(saved);
      expect(restarted.connected, false);
      expect(restarted.connectionNotice, contains('Enter your'));
      expect(checks, 1);
      restarted.dispose();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'normal room entry starts New design and retains correction text; explicit refinement enters precision',
    (tester) async {
      await store.updateRoom(
        room.copyWith(
          preciseEdit: true,
          correctionInstructions: 'Change only the tap',
          instructions: 'A complete kitchen concept',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('focus-section-refine')));
      await tester.pumpAndSettle();
      final control = find.byType(SegmentedButton<RoomDesignMode>);
      expect(tester.widget<SegmentedButton<RoomDesignMode>>(control).selected, {
        RoomDesignMode.newDesign,
      });
      expect(find.text('Partial'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        store.roomById(room.id)!.correctionInstructions,
        'Change only the tap',
      );
      final design = await store.createDesign(
        roomId: room.id,
        image: store.imageFor(room.originalId)!,
        title: 'Fixture result',
        prompt: 'Saved design',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(
            store: store,
            roomId: room.id,
            initialDesignId: design.id,
            startInPrecision: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SegmentedButton<RoomDesignMode>>(
              find.byType(SegmentedButton<RoomDesignMode>),
            )
            .selected,
        {RoomDesignMode.precise},
      );
      expect(store.imageFor(room.originalId), isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'three modes preserve separate instructions and partial selections',
    (tester) async {
      final draft = RoomDraft(store, room);
      draft.changes.text = 'Update the floor';
      draft.correction.text = 'Brass tap only';
      draft.setScope('flooring', true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DesignModeControls(draft: draft)),
        ),
      );
      await tester.tap(find.text('Partial'));
      await tester.pumpAndSettle();
      expect(draft.preciseEdit, false);
      expect(draft.fullRenovation, false);
      await tester.tap(find.text('Precise correction'));
      await tester.pumpAndSettle();
      expect(draft.preciseEdit, true);
      await tester.tap(find.text('New design'));
      await tester.pumpAndSettle();
      expect(draft.fullRenovation, true);
      expect(draft.scopeIds, contains('flooring'));
      expect(draft.changes.text, 'Update the floor');
      expect(draft.correction.text, 'Brass tap only');
      await draft.save();
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );

  testWidgets('compact palette cards fit a phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(
            body: ColourPalettePicker(
              selectedId: '',
              horizontal: true,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final size = tester.getSize(find.byType(ColourPalettePicker));
    expect(size.height, lessThan(105));
    expect(
      tester.getSize(find.byKey(const ValueKey('quick-palette-'))).width,
      124,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'empty Ideas offers inspiration and applies only confirmed style/palette choices to the existing room',
    (tester) async {
      await store.updateRoom(
        room.copyWith(
          instructions: 'Retain the sink',
          protectedFeatures: 'Window',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('focus-section-ideas')));
      await tester.pumpAndSettle();
      final browse = find.text('Browse design inspiration');
      await ensureFocusVisible(tester, browse);
      await tester.tap(browse);
      await tester.pumpAndSettle();
      tester
          .widget<InspirationGallery>(find.byType(InspirationGallery))
          .onUse(roomStarters.first);
      await tester.pumpAndSettle();
      expect(find.text('Apply this look to the room?'), findsOneWidget);
      await tester.tap(find.text('Apply style and palette'));
      await tester.pumpAndSettle();
      final current = store.roomById(room.id)!;
      expect(current.colourPaletteId, roomStarters.first.paletteId);
      expect(current.designStyleIds, [roomStarters.first.styleId]);
      expect(current.instructions, 'Retain the sink');
      expect(current.protectedFeatures, 'Window');
      expect(current.originalId, room.originalId);
      expect(store.roomsFor(room.projectId), hasLength(1));
      expect(store.designsFor(room.id), isEmpty);
      expect(checks, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
