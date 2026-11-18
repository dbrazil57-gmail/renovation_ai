import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/ai_widgets.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/room_analysis.dart';
import 'package:renovision_ai/room_analysis_widgets.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

class AnalysisRecords extends MemoryBox {
  bool fail = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (fail && key.toString().startsWith('room:')) {
      throw StateError('Simulated disk failure');
    }
    await super.put(key, value);
  }
}

void main() {
  late RenovisionStore store;
  late AnalysisRecords records;
  late AiService ai;
  late RenovationRoom room;
  late Uint8List image;
  late int analyses;
  late int edits;
  late bool failSavingResult;
  late int responseStatus;
  late Completer<void>? gate;
  late Map<String, dynamic>? submitted;
  late Map<String, dynamic> responseBody;
  setUp(() async {
    analyses = edits = 0;
    failSavingResult = false;
    responseStatus = 200;
    gate = null;
    submitted = null;
    responseBody = {
      'provider': 'OpenAI',
      'model': 'test-vision',
      'requestId': 'analysis-id',
      'observations': 'A large window and peninsula are visible.',
      'questions': ['Are dining-facing storage doors required?'],
      'prompt':
          'Keep the window and layout. Use charcoal cabinetry and pale stone.',
    };
    records = AnalysisRecords();
    image = img.encodePng(img.Image(width: 40, height: 30));
    ai = AiService(
      clientFactory: () => MockClient((request) async {
        if (request.url.path == '/health') {
          return http.Response(
            jsonEncode({
              'provider': 'OpenAI',
              'model': 'test-image',
              'quality': 'low',
              'maxInputImages': 7,
              'analysisModel': 'test-vision',
            }),
            200,
          );
        }
        submitted = jsonDecode(request.body) as Map<String, dynamic>;
        if (request.url.path == '/analyse') {
          analyses++;
          if (gate != null) await gate!.future;
          if (failSavingResult) records.fail = true;
          return http.Response(jsonEncode(responseBody), responseStatus);
        }
        edits++;
        return http.Response(
          jsonEncode({
            'provider': 'OpenAI',
            'model': 'test-image',
            'image': base64Encode(image),
          }),
          200,
        );
      }),
    );
    await ai.connect(
      url: 'http://127.0.0.1:8787',
      pairingCode: 'synthetic-code',
    );
    store = RenovisionStore(records: records, photos: MemoryBox(), ai: ai);
    final project = await store.createProject('Claylands');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: image,
    );
  });
  tearDown(() => store.dispose());

  RoomDraft draftForTest() => RoomDraft(store, room);
  AiEditRequest request(RoomDraft draft) => AiEditRequest(
    roomId: room.id,
    parentId: null,
    sourceImageId: room.originalId,
    image: image,
    prompt: 'Room request: ${draft.changes.text}',
    title: 'Concept',
    instructions: draft.changes.text,
    precise: false,
  );
  Future<void> showCard(WidgetTester tester, RoomDraft draft) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RoomAnalysisCard(
              store: store,
              draft: draft,
              buildRequest: () => request(draft),
              onBusyChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> analyse(WidgetTester tester) async {
    await tester.tap(find.text('Analyse room photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send photos for analysis'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'redesign choices appear after analysis and persist without generating',
    (tester) async {
      final draft = draftForTest();
      await showCard(tester, draft);
      expect(find.text('Choose your redesign options'), findsNothing);
      await analyse(tester);
      final choices = find.text('3 ideas');
      await tester.ensureVisible(choices);
      await tester.tap(choices);
      await tester.pump(const Duration(milliseconds: 700));
      expect(draft.conceptCount, 3);
      expect(store.roomById(room.id)!.conceptCount, 3);
      expect(analyses, 1);
      expect(edits, 0);
      expect(store.designsFor(room.id), isEmpty);
      expect(find.text('Choose your redesign options'), findsOneWidget);
      draft.changes.text = 'Different brief';
      await tester.pumpAndSettle();
      expect(find.text('Choose your redesign options'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await draft.save();
      draft.dispose();
    },
  );

  testWidgets(
    'upload has explicit unanalysed state; cancelling analysis sends nothing',
    (tester) async {
      final draft = draftForTest();
      await showCard(tester, draft);
      expect(find.textContaining('not analysed yet'), findsOneWidget);
      expect(analyses, 0);
      await tester.tap(find.text('Analyse room photos'));
      await tester.pumpAndSettle();
      expect(find.textContaining('API charges apply'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(analyses, 0);
      expect(store.roomById(room.id)!.analysis, isNull);
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );

  testWidgets(
    'analysis saves real response and editable prompt without generating or approving a design',
    (tester) async {
      final draft = draftForTest();
      await showCard(tester, draft);
      await analyse(tester);
      expect(analyses, 1);
      expect(edits, 0);
      expect(submitted!['confirmed'], true);
      expect(base64Decode(submitted!['image'] as String), orderedEquals(image));
      expect(
        store.roomById(room.id)!.analysis!.result.observations,
        contains('large window'),
      );
      expect(
        store.roomById(room.id)!.analysis!.result.requestId,
        'analysis-id',
      );
      expect(store.roomById(room.id)!.useAiPrompt, false);
      expect(store.designsFor(room.id), isEmpty);
      expect(store.roomById(room.id)!.approvedDesignId, isNull);
      expect(store.imageFor(room.originalId), orderedEquals(image));
      final field = find.widgetWithText(
        TextField,
        'AI-prepared design prompt (editable)',
      );
      await tester.ensureVisible(field);
      await tester.enterText(
        field,
        'Edited AI prompt: retain the wide window.',
      );
      await tester.pump(const Duration(milliseconds: 700));
      final use = find.text('Use this AI prompt for the next design');
      await tester.ensureVisible(use);
      await tester.pumpAndSettle();
      await tester.tap(use);
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        store.roomById(room.id)!.aiPrompt,
        'Edited AI prompt: retain the wide window.',
      );
      expect(store.roomById(room.id)!.useAiPrompt, true);
      expect(
        store.roomById(room.id)!.analysis!.result.prompt,
        responseBody['prompt'],
      );
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
      final reopened = RoomDraft(store, store.roomById(room.id)!);
      expect(
        reopened.aiPrompt.text,
        'Edited AI prompt: retain the wide window.',
      );
      expect(reopened.useAiPrompt, true);
      reopened.dispose();
      final restored = await store.restoreBackup(
        ProjectBackup.decode(store.backupFor(room.projectId).encode()),
      );
      final copied = store.roomsFor(restored.id).single;
      expect(copied.aiPrompt, 'Edited AI prompt: retain the wide window.');
      expect(copied.analysis!.sourceImageId, copied.originalId);
      expect(copied.analysis!.sourceImageId, isNot(room.originalId));
      expect(copied.useAiPrompt, true);
      expect(copied.analysis!.result.requestId, 'analysis-id');
    },
  );

  testWidgets(
    'local result-save failure retries storage without another AI call',
    (tester) async {
      final draft = draftForTest();
      await showCard(tester, draft);
      failSavingResult = true;
      await analyse(tester);
      expect(draft.state, DraftSaveState.failed);
      expect(draft.analysis, isNotNull);
      expect(store.roomById(room.id)!.analysis, isNull);
      records.fail = false;
      await tester.ensureVisible(find.text('Retry saving analysis'));
      await tester.tap(find.text('Retry saving analysis'));
      await tester.pumpAndSettle();
      expect(store.roomById(room.id)!.analysis, isNotNull);
      expect(analyses, 1);
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );

  testWidgets(
    'preferences changed during request leave result marked out of date',
    (tester) async {
      final draft = draftForTest();
      await showCard(tester, draft);
      gate = Completer<void>();
      await tester.tap(find.text('Analyse room photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send photos for analysis'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      draft.changes.text = 'New floor as well';
      gate!.complete();
      await tester.pumpAndSettle();
      expect(draft.analysis!.context, 'Room request: ');
      expect(
        find.textContaining('Photos or preferences have changed'),
        findsOneWidget,
      );
      expect(draft.useAiPrompt, false);
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );

  test('analysis backup remaps design sources and supporting photos and rejects unrelated photos', () async {
    await store.addRoomPhotos(room.id, [image]);
    final withViews = store.roomById(room.id)!;
    final design = await store.createDesign(
      roomId: room.id,
      image: image,
      title: 'Selected design',
      prompt: 'Retain layout',
    );
    RoomAnalysis snapshot(String source) => RoomAnalysis(
      result: RoomAnalysisResult.fromMap(responseBody),
      sourceImageId: source,
      supportingImageIds: withViews.photoIds,
      context: 'Room preferences',
      created: DateTime.now(),
    );
    await store.updateRoom(
      withViews.copyWith(
        analysis: snapshot(design.imageId),
        aiPrompt: 'Keep the layout.',
        useAiPrompt: true,
      ),
    );
    final restored = await store.restoreBackup(
      ProjectBackup.decode(store.backupFor(room.projectId).encode()),
    );
    final copy = store.roomsFor(restored.id).single;
    expect(
      copy.analysis!.sourceImageId,
      store.designsFor(copy.id).single.imageId,
    );
    expect(copy.analysis!.sourceImageId, isNot(design.imageId));
    expect(copy.analysis!.supportingImageIds, copy.photoIds);
    final unrelatedProject = await store.createProject('Other home');
    final unrelated = await store.createRoom(
      projectId: unrelatedProject.id,
      name: 'Other kitchen',
      originalImage: image,
    );
    await store.updateRoom(
      store
          .roomById(room.id)!
          .copyWith(analysis: snapshot(unrelated.originalId)),
    );
    expect(
      () => store.backupFor(room.projectId).encode(),
      throwsA(isA<BackupFailure>()),
    );
  });

  testWidgets(
    'scrolling away during analysis keeps the result alive and saves it',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Analyse room photos'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      gate = Completer<void>();
      await tester.ensureVisible(find.text('Analyse room photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Analyse room photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send photos for analysis'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.scrollUntilVisible(
        find.text('AI instructions'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(analyses, 1);
      gate!.complete();
      await tester.pumpAndSettle();
      expect(store.roomById(room.id)!.analysis, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  test('older relay cannot masquerade as photo-analysis capable', () async {
    final older = AiService(
      clientFactory: () => MockClient((request) async {
        expect(request.url.path, '/health');
        return http.Response(
          jsonEncode({
            'provider': 'OpenAI',
            'model': 'old-image',
            'quality': 'low',
          }),
          200,
        );
      }),
    );
    await older.connect(url: 'http://127.0.0.1:8787', pairingCode: 'old-code');
    expect(older.connected, true);
    expect(older.supportsAnalysis, false);
    await expectLater(
      older.analyse(image: image, context: 'Kitchen'),
      throwsA(isA<AiFailure>()),
    );
    older.dispose();
  });

  test('provider errors and incomplete analysis do not produce a saved or fabricated result', () async {
    responseStatus = 402;
    await expectLater(
      ai.analyse(image: image, context: 'Kitchen'),
      throwsA(isA<AiFailure>()),
    );
    responseStatus = 200;
    responseBody.remove('observations');
    await expectLater(
      ai.analyse(image: image, context: 'Kitchen'),
      throwsA(isA<AiFailure>()),
    );
    expect(analyses, 2);
    expect(store.roomById(room.id)!.analysis, isNull);
  });

  test('analysis freshness checks viewpoint, supporting photos and user requirements', () {
    final analysis = RoomAnalysis(
      result: RoomAnalysisResult.fromMap(responseBody),
      sourceImageId: 'main',
      supportingImageIds: ['side'],
      context: 'Keep windows',
      created: DateTime.now(),
    );
    expect(analysis.matches('main', ['side'], 'Keep windows'), true);
    expect(analysis.matches('other', ['side'], 'Keep windows'), false);
    expect(analysis.matches('main', [], 'Keep windows'), false);
    expect(analysis.matches('main', ['side'], 'Remove windows'), false);
  });

  testWidgets(
    'reviewed AI prompt is used by generation and stale preferences block sending',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      final analyseButton = find.text('Analyse room photos');
      await tester.scrollUntilVisible(
        analyseButton,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(analyseButton);
      await tester.pumpAndSettle();
      await tester.tap(analyseButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send photos for analysis'));
      await tester.pumpAndSettle();
      final use = find.text('Use this AI prompt for the next design');
      await tester.ensureVisible(use);
      await tester.pumpAndSettle();
      await tester.tap(use);
      await tester.pump(const Duration(milliseconds: 700));
      final generation = find.text('AI generation (optional)');
      await tester.scrollUntilVisible(
        generation,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      // Connected AI controls are expanded by default.
      await tester.ensureVisible(find.text('Generate AI design'));
      await tester.tap(find.text('Generate AI design'));
      await tester.pumpAndSettle();
      expect(find.text('Send this edit to OpenAI?'), findsOneWidget);
      await tester.tap(find.text('Send to OpenAI'));
      await tester.pumpAndSettle();
      expect(edits, 1);
      expect(submitted!['prompt'], contains(responseBody['prompt']));
      expect(submitted!['prompt'], contains('CURRENT USER REQUIREMENTS'));
      expect(submitted!['prompt'], contains('PHOTO ANALYSIS'));
      expect(submitted!['prompt'], contains(responseBody['observations']));
      expect(
        submitted!['prompt'],
        contains('not automatically authorised for removal'),
      );
      expect(store.designsFor(room.id).single.prompt, submitted!['prompt']);
      // Switch back to the original viewpoint, then change the user brief.
      // Any selected new design already counts as a stale source.
      await tester.ensureVisible(find.text('Generate AI design'));
      await tester.tap(find.text('Generate AI design'));
      await tester.pumpAndSettle();
      expect(find.textContaining('no longer matches'), findsOneWidget);
      expect(edits, 1);
      expect(analyses, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
