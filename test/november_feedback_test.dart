import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_activity.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/ai_widgets.dart';
import 'package:renovision_ai/design_concepts.dart';
import 'package:renovision_ai/main.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/openai_internet.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  test('account model availability survives restart; legacy settings stay restricted until an explicit refresh', () async {
    var calls = 0;
    var available = ['gpt-image-2.5-flare'];
    http.Client client() => MockClient((request) async {
      calls++;
      expect(request.url.path, '/v1/models');
      return http.Response(
        jsonEncode({
          'data': [
            for (final id in available) {'id': id},
          ],
        }),
        200,
      );
    });
    final first = AiService(clientFactory: client);
    addTearDown(first.dispose);
    await first.connectDirect(apiKey: 'synthetic-restart-key');
    final saved = first.rememberedConnection!;
    final next = AiService(clientFactory: client, keyStore: first.keyStore);
    addTearDown(next.dispose);
    await next.restoreConnection(saved);
    expect(next.imageModels, ['gpt-image-2.5-flare']);
    expect(calls, 1);
    final legacy = Map.of(saved)..remove('imageModels');
    await next.restoreConnection(legacy);
    expect(next.imageModels, ['gpt-image-2.5-flare']);
    expect(calls, 1);
    available = ['gpt-image-2.6-sunburst', 'gpt-image-2.5-flare'];
    await next.refreshModels();
    expect(calls, 2);
    expect(next.imageModels, available);
    expect(next.model, 'gpt-image-2.5-flare');
  });
  testWidgets(
    'AI settings is the first collapsed card; appearance also opens on demand',
    (tester) async {
      phone(tester);
      final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildRenovisionTheme(),
          home: Scaffold(body: SettingsTab(store: store)),
        ),
      );
      final ai = find.byKey(const ValueKey('ai-connection-settings'));
      final appearance = find.byKey(const ValueKey('app-appearance-settings'));
      expect(
        tester.getTopLeft(ai).dy,
        lessThan(tester.getTopLeft(appearance).dy),
      );
      expect(find.byType(AiConnectionCard), findsNothing);
      expect(find.byKey(const ValueKey('app-theme-oceanBlue')), findsNothing);
      await tester.tap(ai);
      await tester.pumpAndSettle();
      expect(find.byType(AiConnectionCard), findsOneWidget);
      await tester.tap(find.text('AI connection and models'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(appearance);
      await tester.tap(appearance);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('app-theme-oceanBlue')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'model presets use account access, generate nothing and preserve existing settings on reconnect',
    (tester) async {
      phone(tester);
      var calls = 0;
      final ai = AiService(
        clientFactory: () => MockClient((request) async {
          calls++;
          expect(request.url.path, '/v1/models');
          return http.Response(
            jsonEncode({
              'data': [
                for (final id in [...directImageModels, 'gpt-6-luna'])
                  {'id': id},
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(ai.dispose);
      await ai.connectDirect(apiKey: 'synthetic-model-choice-key');
      expect(ai.model, 'gpt-image-2.6-sunburst');
      expect(ai.quality, 'medium');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AiConnectionCard(ai: ai)),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Quick ideas'));
      await tester.tap(find.text('Quick ideas'));
      await tester.pumpAndSettle();
      expect(ai.model, 'gpt-image-2.6-flare');
      expect(ai.quality, 'low');
      await tester.tap(find.text('Final detail'));
      await tester.pumpAndSettle();
      expect(ai.model, 'gpt-image-2.6-sunburst');
      expect(ai.quality, 'high');
      expect(calls, 1);
      ai.selectImageSettings(
        imageModel: 'gpt-image-2.5-flare',
        imageQuality: 'low',
      );
      await ai.connectDirect(apiKey: 'synthetic-model-choice-key');
      expect(ai.model, 'gpt-image-2.5-flare');
      expect(ai.quality, 'low');
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'image toolbar deletes a selected version recoverably and protects original/baseline/pending AI',
    (tester) async {
      phone(tester);
      final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
      addTearDown(store.dispose);
      final image = img.encodePng(img.Image(width: 50, height: 30));
      final project = await store.createProject('Home');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: image,
      );
      final baseline = await store.createDesign(
        roomId: room.id,
        image: image,
        title: 'Approved design',
        prompt: 'Keep window',
      );
      final option = await store.createDesign(
        roomId: room.id,
        image: image,
        title: 'Other design',
        prompt: 'Keep window',
      );
      await store.approveBaseline(room.id, designId: baseline.id);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildRenovisionTheme(),
          home: WorkspaceScreen(
            store: store,
            roomId: room.id,
            initialDesignId: option.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final delete = find.byKey(const ValueKey('delete-selected-design'));
      expect(delete, findsOneWidget);
      store.ai.activity.begin(
        roomId: room.id,
        operation: 'Synthetic pending design',
      );
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(
              find.descendant(of: delete, matching: find.byType(IconButton)),
            )
            .onPressed,
        isNull,
      );
      store.ai.activity.update(AiStage.completed);
      await tester.pumpAndSettle();
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete design'));
      await tester.pumpAndSettle();
      expect(store.deletedDesignsFor(room.id).single.id, option.id);
      expect(store.roomById(room.id)!.approvedDesignId, baseline.id);
      expect(store.imageFor(room.originalId), image);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(find.text('Approved baseline is protected'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();
      expect(delete, findsNothing);
      expect(store.designsFor(room.id).single.id, baseline.id);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'precision offers 2 or 3 scoped variations without reusing the whole-room count or widening the edit',
    (tester) async {
      phone(tester);
      final image = img.encodePng(img.Image(width: 40, height: 30));
      final submitted = <Map>[];
      final ai = AiService(
        clientFactory: () => MockClient((request) async {
          if (request.url.path == '/health') {
            return http.Response(
              jsonEncode({
                'provider': 'OpenAI',
                'model': 'test-image',
                'quality': 'low',
              }),
              200,
            );
          }
          submitted.add(jsonDecode(request.body) as Map);
          return http.Response(
            jsonEncode({
              'image': base64Encode(image),
              'provider': 'OpenAI',
              'model': 'test-image',
            }),
            200,
          );
        }),
      );
      await ai.connect(
        url: 'http://localhost:8787',
        pairingCode: 'synthetic-code',
      );
      final store = RenovisionStore(
        records: MemoryBox(),
        photos: MemoryBox(),
        ai: ai,
      );
      addTearDown(store.dispose);
      final project = await store.createProject('Home');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: image,
      );
      final draft = RoomDraft(store, room);
      addTearDown(draft.dispose);
      draft.setConceptCount(3);
      draft.setPrecise(true);
      draft.correction.text = 'Change only the handles';
      expect(draft.precisionConceptCount, 1);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiEditCard(
                compact: true,
                store: store,
                draft: draft,
                buildRequest: () => AiEditRequest(
                  roomId: room.id,
                  parentId: null,
                  sourceImageId: room.originalId,
                  image: image,
                  prompt: 'Change only the cupboard handles; keep windows and all other surfaces.',
                  title: 'Correction',
                  instructions: 'Change only the handles',
                  precise: true,
                ),
                onSaved: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('2 variations'));
      await tester.pumpAndSettle();
      expect(draft.precisionConceptCount, 2);
      await tester.tap(find.text('3 variations'));
      await tester.pumpAndSettle();
      expect(draft.precisionConceptCount, 3);
      expect(draft.conceptCount, 3);
      expect(submitted, isEmpty);
      await tester.tap(find.text('Generate 3 correction variations'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('3 separate paid image requests'),
        findsOneWidget,
      );
      await tester.tap(find.text('Send to OpenAI'));
      await tester.pumpAndSettle();
      expect(submitted, hasLength(3));
      for (final request in submitted) {
        expect(request['prompt'], contains('Change only the cupboard handles'));
        expect(request['prompt'], contains('PRECISE CORRECTION VARIATION'));
        expect(request['prompt'], isNot(contains('NEW DESIGN CONCEPT')));
        expect(request['image'], base64Encode(image));
      }
      expect(store.designsFor(room.id), hasLength(3));
      await draft.save();
      final restored = ProjectBackup.decode(
        store.backupFor(project.id).encode(),
      ).rooms.single;
      expect(restored.precisionConceptCount, 3);
      final legacy = Map.of(restored.toMap())..remove('precisionConceptCount');
      expect(RenovationRoom.fromMap(legacy).precisionConceptCount, 1);
      expect(tester.takeException(), isNull);
    },
  );

  test('precise alternatives never inherit broad styling directions', () {
    final plans = planDesignConcepts(
      prompt: 'Remove only the old phone',
      precise: true,
      count: 3,
      styleIds: ['modern', 'classic'],
      compareStyles: true,
    );
    expect(plans.map((plan) => plan.prompt).toSet(), hasLength(3));
    for (final plan in plans) {
      expect(plan.prompt, contains('Remove only the old phone'));
      expect(
        plan.prompt,
        contains('only within details the user has left open'),
      );
      expect(plan.prompt, isNot(contains('Warm & tactile')));
    }
  });
}
