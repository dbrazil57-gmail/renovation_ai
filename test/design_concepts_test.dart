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
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/store.dart';
import 'package:renovision_ai/project_backup.dart';

import 'support/memory_box.dart';

class ConceptRecords extends MemoryBox {
  int writes = 0;
  int? failAt;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (key.toString().startsWith('design:') && ++writes == failAt) {
      throw StateError('Test disk failure');
    }
    await super.put(key, value);
  }
}

void main() {
  const base =
      'Keep the window and layout.\nDESIGN STYLE: Modern + Classic.\nSTYLE DETAILS: old blended suggestions.\nProduce one concept.';
  test('separate style concepts replace blended style lines and retain protections', () {
    final plans = planDesignConcepts(
      prompt: base,
      precise: false,
      count: 3,
      styleIds: ['modern', 'classic'],
      compareStyles: true,
    );
    expect(plans.map((p) => p.label), [
      'Modern / Contemporary',
      'Classic',
      'Blended styles',
    ]);
    expect(plans.first.prompt, contains('streamlined'));
    expect(plans.first.prompt, isNot(contains('Classic')));
    expect(plans[1].prompt, contains('panelled'));
    expect(plans[1].prompt, isNot(contains('Modern')));
    expect(plans[2].prompt, contains('Modern / Contemporary + Classic'));
    for (final plan in plans) {
      expect(plan.prompt, contains('Keep the window and layout'));
    }
    expect(plans.map((p) => p.prompt).toSet(), hasLength(3));
  });
  test('fresh whole-room directions vary on later attempts; precision stays narrow', () {
    final first = planDesignConcepts(
      prompt: base,
      precise: false,
      count: 1,
      styleIds: ['modern'],
      compareStyles: false,
    );
    final later = planDesignConcepts(
      prompt: base,
      precise: false,
      count: 1,
      styleIds: ['modern'],
      compareStyles: false,
      previousConcepts: 1,
    );
    expect(first.single.prompt, isNot(later.single.prompt));
    expect(first.single.prompt, contains('visibly fresh'));
    expect(
      planDesignConcepts(
        prompt: 'Change only handle',
        precise: true,
        count: 1,
        styleIds: [],
        compareStyles: false,
      ).single.prompt,
      'Change only handle',
    );
    expect(
      () => planDesignConcepts(
        prompt: base,
        precise: true,
        count: 3,
        styleIds: [],
        compareStyles: true,
      ),
      throwsA(isA<AiFailure>()),
    );
    expect(
      () => planDesignConcepts(
        prompt: base,
        precise: false,
        count: 2,
        styleIds: ['modern', 'classic', 'coastal'],
        compareStyles: true,
      ),
      throwsA(isA<AiFailure>()),
    );
  });

  test(
    'multiple options specify distinct major schemes within protections',
    () {
      final plans = planDesignConcepts(
        prompt:
            'Keep layout and windows. Replace cabinetry, floors and lights.',
        precise: false,
        count: 3,
        styleIds: ['modern'],
        compareStyles: false,
      );
      expect(plans.map((plan) => plan.label), [
        'Clean & architectural',
        'Warm & tactile',
        'Bold & sculptural',
      ]);
      for (final (index, plan) in plans.indexed) {
        expect(plan.prompt, contains('Render ONLY option ${index + 1}'));
        expect(plan.prompt, contains('at least three'));
        expect(plan.prompt, contains('Adding plants, ornaments, cushions'));
        expect(plan.prompt, contains('not images you have already seen'));
        expect(plan.prompt, contains('Only change elements authorised'));
        expect(plan.prompt, contains('Keep layout and windows'));
        for (final other in plans) {
          expect(plan.prompt, contains(other.label));
        }
      }
      final single = planDesignConcepts(
        prompt: 'Keep the approved design; refresh lighting.',
        precise: false,
        count: 1,
        styleIds: ['modern'],
        compareStyles: false,
      ).single;
      expect(single.prompt, isNot(contains('DISTINCT REDESIGN OPTIONS')));
    },
  );

  late RenovisionStore store;
  late ConceptRecords records;
  late RenovationRoom room;
  late RoomDraft draft;
  late Uint8List source;
  late List<Map> submitted;
  late int builderCalls;
  int? failRequest;
  bool identicalOutput = false;
  Completer<void>? gate;
  DesignVersion? chosen;
  setUp(() async {
    submitted = [];
    builderCalls = 0;
    failRequest = null;
    identicalOutput = false;
    gate = null;
    chosen = null;
    source = img.encodePng(img.Image(width: 40, height: 30));
    records = ConceptRecords();
    final ai = AiService(
      clientFactory: () => MockClient((request) async {
        if (request.url.path == '/health') {
          return http.Response(
            jsonEncode({
              'provider': 'OpenAI',
              'model': 'test-image',
              'quality': 'low',
              'maxInputImages': 7,
            }),
            200,
          );
        }
        submitted.add(jsonDecode(request.body) as Map);
        if (gate != null) await gate!.future;
        if (submitted.length == failRequest) return http.Response('{}', 503);
        final image = img.Image(width: 40, height: 30);
        img.fill(image, color: img.ColorRgb8(submitted.length * 50, 20, 100));
        return http.Response(
          jsonEncode({
            'image': base64Encode(
              identicalOutput ? source : img.encodePng(image),
            ),
            'provider': 'OpenAI',
            'model': 'test-image',
            'quality': 'low',
            'requestId': 'test-${submitted.length}',
          }),
          200,
        );
      }),
    );
    await ai.connect(
      url: 'http://localhost:8787',
      pairingCode: 'synthetic-code',
    );
    store = RenovisionStore(records: records, photos: MemoryBox(), ai: ai);
    final project = await store.createProject('Concept test');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: source,
    );
    draft = RoomDraft(store, room);
    draft.setStyle('modern', true);
    draft.setStyle('classic', true);
    draft.setConceptCount(3);
  });
  tearDown(() {
    draft.dispose();
    store.dispose();
  });

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AiEditCard(
              store: store,
              draft: draft,
              buildRequest: () {
                builderCalls++;
                return AiEditRequest(
                  roomId: room.id,
                  parentId: chosen?.id,
                  sourceImageId: chosen?.imageId ?? room.originalId,
                  image: chosen == null
                      ? source
                      : store.imageFor(chosen!.imageId)!,
                  prompt: base,
                  title: 'Kitchen concept',
                  instructions: 'Modernise',
                  precise: false,
                  styleIds: draft.styleIds.toList(),
                );
              },
              onSaved: (value) => chosen = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openConfirmation(WidgetTester tester) async {
    final generate = find.text(
      draft.preciseEdit || draft.conceptCount == 1
          ? 'Generate AI design'
          : 'Generate ${draft.conceptCount} redesign options',
    );
    await tester.ensureVisible(generate);
    await tester.pumpAndSettle();
    await tester.tap(generate);
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester) async {
    await openConfirmation(tester);
    await tester.tap(find.text('Send to OpenAI'));
    await tester.pumpAndSettle();
  }

  test(
    'batch preferences autosave and survive portable project round trip',
    () async {
      draft.setConceptCount(2);
      draft.setCompareStyles(false);
      await draft.save();
      final current = store.roomById(room.id)!;
      expect(current.conceptCount, 2);
      expect(current.compareStyles, isFalse);
      final restored = ProjectBackup.decode(
        store.backupFor(room.projectId).encode(),
      ).rooms.single;
      expect(restored.conceptCount, 2);
      expect(restored.compareStyles, isFalse);
      final legacy = Map.of(current.toMap())
        ..remove('conceptCount')
        ..remove('compareStyles');
      expect(RenovationRoom.fromMap(legacy).conceptCount, 1);
    },
  );
  testWidgets(
    'confirmation discloses three paid requests; cancel generates nothing',
    (tester) async {
      await show(tester);
      await openConfirmation(tester);
      expect(
        find.textContaining('3 separate paid image requests'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(submitted, isEmpty);
      expect(store.designsFor(room.id), isEmpty);
    },
  );
  testWidgets(
    'three distinct briefs use one frozen source and save individually; choose earlier result',
    (tester) async {
      await show(tester);
      await send(tester);
      expect(submitted, hasLength(3));
      expect(builderCalls, 1);
      expect(submitted.map((p) => p['prompt']).toSet(), hasLength(3));
      expect(
        submitted.every((p) => p['image'] == base64Encode(source)),
        isTrue,
      );
      final versions = store.designsFor(room.id);
      expect(versions, hasLength(3));
      expect(
        versions.every(
          (d) => d.sourceImageId == room.originalId && d.parentId == null,
        ),
        isTrue,
      );
      expect(store.roomById(room.id)!.approvedDesignId, isNull);
      final use = find.text('Use this design').first;
      await tester.ensureVisible(use);
      await tester.pumpAndSettle();
      await tester.tap(use);
      await tester.pump();
      expect(chosen!.title, contains('1/3'));
      expect(store.imageFor(room.originalId), source);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'stop waits for current result, saves it, and sends no remaining requests',
    (tester) async {
      gate = Completer<void>();
      await show(tester);
      await openConfirmation(tester);
      await tester.tap(find.text('Send to OpenAI'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final stop = find.text('Stop after this image');
      await tester.ensureVisible(stop);
      await tester.pump();
      await tester.tap(stop);
      await tester.pump();
      gate!.complete();
      await tester.pumpAndSettle();
      expect(submitted, hasLength(1));
      expect(store.designsFor(room.id), hasLength(1));
      expect(
        find.textContaining('Remaining concepts were not requested'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'provider failure retains earlier result and does not retry or request the third',
    (tester) async {
      failRequest = 2;
      await show(tester);
      await send(tester);
      expect(submitted, hasLength(2));
      expect(store.designsFor(room.id), hasLength(1));
      expect(find.textContaining('1 concepts saved'), findsOneWidget);
    },
  );
  testWidgets(
    'failed local save stops batch; retry only saves received bytes',
    (tester) async {
      records.failAt = 2;
      await show(tester);
      await send(tester);
      expect(submitted, hasLength(2));
      expect(store.designsFor(room.id), hasLength(1));
      final retry = find.text('Retry saving result');
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(submitted, hasLength(2));
      expect(store.designsFor(room.id), hasLength(2));
      expect(find.text('Retry saving result'), findsNothing);
    },
  );
  testWidgets(
    'identical returned file is flagged without paid replacement attempts',
    (tester) async {
      identicalOutput = true;
      await show(tester);
      await send(tester);
      expect(submitted, hasLength(3));
      expect(store.designsFor(room.id), hasLength(3));
      expect(find.textContaining('byte-for-byte identical'), findsOneWidget);
    },
  );

  testWidgets(
    'generated gallery delete removes the image and Undo restores it without AI calls',
    (tester) async {
      await show(tester);
      await send(tester);
      final first = store.designsFor(room.id).last;
      final delete = find.byTooltip('Delete ${first.title}');
      await tester.ensureVisible(delete);
      await tester.pumpAndSettle();
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete design'));
      await tester.pumpAndSettle();
      expect(store.designsFor(room.id), hasLength(2));
      expect(find.byTooltip('Delete ${first.title}'), findsNothing);
      expect(submitted, hasLength(3));
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(store.designsFor(room.id), hasLength(3));
      expect(find.byTooltip('Delete ${first.title}'), findsOneWidget);
      expect(submitted, hasLength(3));
    },
  );
}
