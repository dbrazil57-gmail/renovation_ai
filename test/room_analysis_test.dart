import 'support/focus_navigation.dart';

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
import 'package:renovision_ai/design_concepts.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/room_analysis.dart';
import 'package:renovision_ai/room_analysis_widgets.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/room_prompt.dart';
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
    await tester.tap(find.text('Analyse photos with AI'));
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
      await ensureFocusVisible(tester, choices);
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
      await tester.tap(find.text('Analyse photos with AI'));
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
      expect(store.roomById(room.id)!.useAiPrompt, true);
      expect(store.designsFor(room.id), isEmpty);
      expect(store.roomById(room.id)!.approvedDesignId, isNull);
      expect(store.imageFor(room.originalId), orderedEquals(image));
      final field = find.widgetWithText(
        TextField,
        'Suggested design plan (editable)',
      );
      await ensureFocusVisible(tester, field);
      await tester.enterText(
        field,
        'Edited AI prompt: retain the wide window.',
      );
      await tester.pump(const Duration(milliseconds: 700));
      final use = find.text('Apply this plan when generating');
      await ensureFocusVisible(tester, use);
      await tester.pumpAndSettle();
      await tester.tap(use);
      await tester.pump(const Duration(milliseconds: 700));
      expect(store.roomById(room.id)!.useAiPrompt, false);
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
      await ensureFocusVisible(tester, find.text('Retry saving analysis'));
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
      await tester.tap(find.text('Analyse photos with AI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send photos for analysis'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      draft.changes.text = 'New floor as well';
      gate!.complete();
      await tester.pumpAndSettle();
      expect(draft.analysis!.context, 'Room request: ');
      expect(
        find.textContaining('Photo observations still match'),
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
      await revealFocusControl(
        tester,
        find.text('Analyse photos with AI'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      gate = Completer<void>();
      await ensureFocusVisible(tester, find.text('Analyse photos with AI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Analyse photos with AI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send photos for analysis'));
      await tester.pump(const Duration(milliseconds: 300));
      await revealFocusControl(
        tester,
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
    expect(analysis.matchesPhotos('main', ['side']), true);
  });

  test('new designs reuse matching photo facts without adopting an unreviewed AI brief', () {
    final draft = draftForTest();
    addTearDown(draft.dispose);
    draft.setPrecise(false);
    draft.setAnalysis(
      RoomAnalysis(
        result: RoomAnalysisResult.fromMap(responseBody),
        sourceImageId: room.originalId,
        supportingImageIds: const ['side'],
        context: 'old user choices',
        created: DateTime.now(),
      ),
    );
    draft.setUseAiPrompt(false);
    String prompt({String? source, List<String> views = const ['side']}) =>
        reviewedRoomPrompt(
          'Keep the window. New palette requested.',
          draft,
          sourceImageId: source ?? room.originalId,
          supportingImageIds: views,
        );
    expect(prompt(), contains(responseBody['observations']));
    expect(prompt(), isNot(contains(responseBody['prompt'])));
    expect(prompt(), contains('CURRENT USER REQUIREMENTS'));
    draft.setStyle('japanese', true);
    expect(prompt(), contains(responseBody['observations']));
    expect(
      prompt(source: 'a generated design'),
      isNot(contains('PHOTO ANALYSIS')),
    );
    expect(prompt(views: []), isNot(contains('PHOTO ANALYSIS')));
    expect(prompt(views: ['another angle']), isNot(contains('PHOTO ANALYSIS')));
    draft.setPrecise(true);
    expect(prompt(), isNot(contains('PHOTO ANALYSIS')));
    expect(analyses, 0);
    expect(edits, 0);
  });

  test(
    'analysis asks for a visible inventory and scope-aware design initiative',
    () {
      for (final phrase in [
        'floor and wall finishes',
        'ceiling/bulkheads',
        'appliances, main and task lighting',
        'what is obscured',
        'all supplied views',
        'few or no comments',
        'rather than copying the old decor',
        'For Partial renovation',
        'For precise corrections',
        'genuine conflicts',
      ]) {
        expect(roomAnalysisInstructions, contains(phrase));
      }
    },
  );

  test('current proposal follows choices; stale or disabled proposals stay out without losing photo facts', () async {
    final draft = draftForTest();
    addTearDown(draft.dispose);
    draft.changes.text = 'Handleless cupboards. Keep the existing window.';
    final template = roomTemplatePrompt(room, draft);
    final analysis = RoomAnalysis(
      result: RoomAnalysisResult.fromMap(responseBody),
      sourceImageId: room.originalId,
      supportingImageIds: const [],
      context: template,
      created: DateTime.now(),
    );
    draft.setAnalysis(analysis, useProposal: true);
    String prepared({String? source}) => reviewedRoomPrompt(
      roomTemplatePrompt(store.roomById(room.id)!, draft),
      draft,
      sourceImageId: source ?? room.originalId,
    );
    expect(prepared(), contains(responseBody['prompt']));
    expect(prepared(), contains('Handleless cupboards'));
    expect(prepared(), contains('CURRENT USER REQUIREMENTS'));
    final captured = draft.captureRecipe();
    draft.setUseAiPrompt(false);
    expect(prepared(), isNot(contains(responseBody['prompt'])));
    expect(prepared(), contains(responseBody['observations']));
    draft.setUseAiPrompt(true);
    await store.setRoomPalette(room.id, 'charcoal_walnut');
    final changed = prepared();
    expect(changed, contains('Charcoal & walnut'));
    expect(changed, contains(responseBody['observations']));
    expect(changed, isNot(contains(responseBody['prompt'])));
    expect(
      prepared(source: 'a different image'),
      isNot(contains('PHOTO ANALYSIS')),
    );
    expect(draft.aiPrompt.text, responseBody['prompt']);
    expect(draft.analysis!.context, template);
    expect(captured.toMap()['colourPaletteId'], '');
    expect(captured.analysis!.context, template);
    expect(store.imageFor(room.originalId), orderedEquals(image));
    expect(analyses, 0);
    expect(edits, 0);
  });

  test('detailed kitchen analysis and proposal fit three concepts without shortening user requirements or the saved analysis', () {
    final draft = draftForTest();
    addTearDown(draft.dispose);
    draft.changes.text =
        'Push-open doors.\nDESIGN SYNTHESIS: Keep the existing sink.';
    draft.protected.text = 'All original openings and the oven';
    draft.setItemChoice('kitchen_oven', 'keep');
    draft.setStyle('modern', true);
    final observations = List.filled(
      50,
      'A wide timber-trimmed window sits above the sink and beside a peninsula. ',
    ).join();
    final proposal = List.filled(
      28,
      'Use matte charcoal cabinetry, pale warm stone and warm large-format floor tiles; coordinate new main and task lighting. ',
    ).join();
    final template = roomTemplatePrompt(room, draft);
    draft.setAnalysis(
      RoomAnalysis(
        result: RoomAnalysisResult(
          observations: observations,
          questions: const [],
          prompt: proposal,
          model: 'fixture',
        ),
        sourceImageId: room.originalId,
        supportingImageIds: const [],
        context: template,
        created: DateTime.now(),
      ),
      useProposal: true,
    );
    final prepared = reviewedRoomPrompt(
      template,
      draft,
      sourceImageId: room.originalId,
      proposalRequirements: roomTemplatePrompt(
        room,
        draft,
        conciseDesignDirection: true,
      ),
    );
    final concepts = planDesignConcepts(
      prompt: prepared,
      precise: false,
      count: 3,
      styleIds: ['modern'],
      compareStyles: false,
    );
    expect(concepts, hasLength(3));
    for (final concept in concepts) {
      expect(concept.prompt.length, lessThanOrEqualTo(16000));
      expect(concept.prompt, contains(draft.changes.text));
      expect(concept.prompt, contains(draft.protected.text));
      expect(concept.prompt, contains('KEEP EXISTING Oven:'));
      expect(concept.prompt, contains(proposal.trim()));
      expect(concept.prompt, contains('Photo observations excerpt'));
      expect(concept.prompt, contains('actual outside view'));
    }
    expect(draft.analysis!.result.observations, observations);
    expect(draft.analysis!.result.prompt, proposal);
    expect(draft.analysis!.context, template);
    expect(analyses, 0);
    expect(edits, 0);
  });

  test('precise correction never inherits a whole-room proposal even with an inconsistent saved flag', () {
    final draft = draftForTest();
    addTearDown(draft.dispose);
    draft.setPrecise(true);
    draft.correction.text = 'Replace only the tap with brushed brass.';
    final template = roomTemplatePrompt(room, draft);
    draft.setAnalysis(
      RoomAnalysis(
        result: RoomAnalysisResult.fromMap(responseBody),
        sourceImageId: room.originalId,
        supportingImageIds: const [],
        context: template,
        created: DateTime.now(),
      ),
      useProposal: true,
    );
    expect(draft.useAiPrompt, false);
    draft.setUseAiPrompt(true);
    final prompt = reviewedRoomPrompt(
      template,
      draft,
      sourceImageId: room.originalId,
    );
    expect(prompt, template);
    expect(prompt, contains('Replace only the tap'));
    expect(prompt, isNot(contains(responseBody['prompt'])));
    expect(prompt, isNot(contains('DESIGN SYNTHESIS')));
  });

  test('camera proposal uses its exact analysis brief and falls back to photo facts after changing choices', () {
    final draft = draftForTest();
    addTearDown(draft.dispose);
    final template = roomTemplatePrompt(room, draft, includeRoomContext: false);
    draft.setAnalysis(
      RoomAnalysis(
        result: RoomAnalysisResult.fromMap(responseBody),
        sourceImageId: room.originalId,
        supportingImageIds: const [],
        context: liveRoomAnalysisPrompt(template),
        created: DateTime.now(),
      ),
      useProposal: true,
    );
    String prepared() {
      final current = roomTemplatePrompt(
        room,
        draft,
        includeRoomContext: false,
      );
      return reviewedRoomPrompt(
        current,
        draft,
        sourceImageId: room.originalId,
        analysisContext: liveRoomAnalysisPrompt(current),
      );
    }

    expect(prepared(), contains(responseBody['prompt']));
    draft.setStyle('japanese', true);
    expect(prepared(), contains('Japanese'));
    expect(prepared(), contains(responseBody['observations']));
    expect(prepared(), isNot(contains(responseBody['prompt'])));
    expect(analyses, 0);
  });

  testWidgets(
    'changed palette uses current choices and photo facts without reanalysis or an old proposal',
    (tester) async {
      final initialDraft = draftForTest();
      final originalTemplate = roomTemplatePrompt(room, initialDraft);
      initialDraft.dispose();
      await store.updateRoom(
        room.copyWith(
          useAiPrompt: true,
          aiPrompt: responseBody['prompt'] as String,
          analysis: RoomAnalysis(
            result: RoomAnalysisResult.fromMap(responseBody),
            sourceImageId: room.originalId,
            supportingImageIds: const [],
            context: originalTemplate,
            created: DateTime.now(),
          ),
        ),
      );
      await store.setRoomPalette(room.id, 'charcoal_walnut');
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(aiGenerateAction());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send to OpenAI'));
      await tester.pumpAndSettle();
      expect(submitted!['prompt'], contains('Charcoal & walnut'));
      expect(submitted!['prompt'], contains(responseBody['observations']));
      expect(submitted!['prompt'], isNot(contains(responseBody['prompt'])));
      expect(analyses, 0);
      expect(edits, 1);
      expect(store.designsFor(room.id).single.prompt, submitted!['prompt']);
      expect(store.roomById(room.id)!.analysis!.context, originalTemplate);
    },
  );

  testWidgets(
    'generation attaches matching observations by default without sending the optional AI-written brief',
    (tester) async {
      await store.updateRoom(
        room.copyWith(
          preciseEdit: false,
          useAiPrompt: false,
          analysis: RoomAnalysis(
            result: RoomAnalysisResult.fromMap(responseBody),
            sourceImageId: room.originalId,
            supportingImageIds: const [],
            context: 'an earlier palette',
            created: DateTime.now(),
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(aiGenerateAction());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send to OpenAI'));
      await tester.pumpAndSettle();
      expect(submitted!['prompt'], contains(responseBody['observations']));
      expect(submitted!['prompt'], isNot(contains(responseBody['prompt'])));
      expect(analyses, 0);
      expect(edits, 1);
      expect(store.designsFor(room.id).single.prompt, submitted!['prompt']);
    },
  );

  testWidgets(
    'analysis proposal is automatic; changing working photo excludes it without blocking generation',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      final analyseButton = find.text('Analyse photos with AI');
      await revealFocusControl(
        tester,
        analyseButton,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await ensureFocusVisible(tester, analyseButton);
      await tester.pumpAndSettle();
      await tester.tap(analyseButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send photos for analysis'));
      await tester.pumpAndSettle();
      expect(store.roomById(room.id)!.useAiPrompt, true);
      final generation = find.text('AI generation (optional)');
      await revealFocusControl(
        tester,
        generation,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      // Connected AI controls are expanded by default.
      await ensureFocusVisible(tester, aiGenerateAction());
      await tester.tap(aiGenerateAction());
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
      // Generation selects the new image; the earlier proposal/photo facts
      // must not be applied to that different working image.
      await ensureFocusVisible(tester, find.text('New design'));
      await tester.tap(find.text('New design'));
      await tester.pumpAndSettle();
      await ensureFocusVisible(tester, aiGenerateAction());
      await tester.tap(aiGenerateAction());
      await tester.pumpAndSettle();
      expect(find.text('Send this edit to OpenAI?'), findsOneWidget);
      await tester.tap(find.text('Send to OpenAI'));
      await tester.pumpAndSettle();
      expect(submitted!['prompt'], isNot(contains(responseBody['prompt'])));
      expect(
        submitted!['prompt'],
        isNot(contains(responseBody['observations'])),
      );
      expect(edits, 2);
      expect(analyses, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
