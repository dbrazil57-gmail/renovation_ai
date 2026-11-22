import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_usage.dart';
import 'package:renovision_ai/app_notices.dart';
import 'package:renovision_ai/design_references.dart';
import 'package:renovision_ai/design_concepts.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/room_prompt.dart';
import 'package:renovision_ai/store.dart';
import 'package:renovision_ai/wording_region.dart';
import 'package:renovision_ai/project_backup.dart';

import 'support/memory_box.dart';

void main() {
  test('image cost uses returned modality tokens and unknown pricing remains unknown', () {
    final usage = AiUsage.openAi({
      'input_tokens': 300,
      'input_tokens_details': {'text_tokens': 100, 'image_tokens': 200},
      'output_tokens': 300,
    }, 'gpt-image-2.6-sunburst');
    expect(usage.estimatedUsd, closeTo(.0111, .0000001));
    expect(AiUsage.fromMap(usage.toMap()).estimatedUsd, usage.estimatedUsd);
    expect(
      AiUsage.openAi({
        'input_tokens_details': {},
        'output_tokens': 10,
      }, 'gpt-image-2.6-sunburst').estimatedUsd,
      isNull,
    );
    expect(
      AiUsage.openAi({
        'input_tokens': 10,
        'input_tokens_details': {
          'text_tokens': 5,
          'image_tokens': 5,
          'cached_tokens': 5,
        },
        'output_tokens': 10,
      }, 'gpt-image-2.6-sunburst').estimatedUsd,
      isNull,
    );
    expect(
      AiUsage.openAi({
        'input_tokens': 100,
        'output_tokens': 100,
      }, 'unknown-model').estimatedUsd,
      isNull,
    );
    expect(
      () => AiUsage.fromMap({...usage.toMap(), 'outputTokens': -1}),
      throwsFormatException,
    );
  });
  test('three kitchen choices have distinct cabinetry/hood recipes inside the same palette and layout', () {
    final plans = planDesignConcepts(
      prompt: 'ROOM TYPE: Kitchen. COLOUR PALETTE: Charcoal & walnut. MUST RETAIN: window.',
      precise: false,
      count: 3,
      styleIds: ['modern'],
      compareStyles: true,
    );
    for (var i = 0; i < 3; i++) {
      expect(plans[i].prompt, contains('SCHEME ${['A', 'B', 'C'][i]}:'));
      expect(plans[i].prompt, contains('COLOUR PALETTE: Charcoal & walnut'));
      expect(plans[i].prompt, contains('MUST RETAIN: window'));
    }
  });
  test('reviewed dated research survives export and is excluded from focused edits', () async {
    final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    addTearDown(store.dispose);
    final project = await store.createProject('Home');
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: img.encodePng(img.Image(width: 20, height: 20)),
    );
    final refs = DesignReferences(
      summary: 'Use a slim modern feature hood.',
      created: DateTime.utc(2026, 11, 23),
      sources: {'https://example.com/design': 'Design source'},
    );
    await store.updateRoom(
      room.copyWith(designReferences: refs, useDesignReferences: true),
    );
    final current = store.roomById(room.id)!;
    final draft = RoomDraft(store, current);
    addTearDown(draft.dispose);
    expect(
      roomTemplatePrompt(current, draft),
      contains('REVIEWED DESIGN REFERENCES'),
    );
    draft.correction.text = 'Tap only';
    draft.setPrecise(true);
    expect(
      roomTemplatePrompt(current, draft),
      isNot(contains('REVIEWED DESIGN REFERENCES')),
    );
    expect(
      roomTemplatePrompt(current, draft),
      isNot(contains('slim modern feature hood')),
    );
    expect(
      ProjectBackup.decode(store.backupFor(project.id).encode())
          .rooms
          .single
          .designReferences!
          .sources,
      refs.sources,
    );
    expect(
      () => DesignReferences.fromMap({
        ...refs.toMap(),
        'sources': {'javascript:alert(1)': 'Bad'},
      }),
      throwsFormatException,
    );
  });
  test('reference research is one bounded HTTPS request and keeps actual citation sources', () async {
    var calls = 0;
    final result = await researchDesignReferences(
      clientFactory: () => MockClient((request) async {
        calls++;
        final body = jsonDecode(request.body) as Map;
        expect(request.url.host, 'api.openai.com');
        expect(body['max_tool_calls'], 1);
        expect(body['store'], false);
        expect(body.toString(), isNot(contains('input_image')));
        return http.Response(
          jsonEncode({
            'output': [
              {
                'type': 'web_search_call',
                'action': {
                  'sources': [
                    {'url': 'https://example.com/hood', 'title': 'Hoods'},
                  ],
                },
              },
              {
                'type': 'message',
                'content': [
                  {
                    'type': 'output_text',
                    'text': 'Slim hood ideas with source context.',
                  },
                ],
              },
            ],
          }),
          200,
        );
      }),
      key: 'synthetic-fixture',
      model: 'gpt-6-luna',
      query: 'Contemporary kitchen hood ideas',
    );
    expect(calls, 1);
    expect(result.sources.keys, orderedEquals(['https://example.com/hood']));
  });
  test('regional wording is saved locally without rewriting instructions or photos', () async {
    final records = MemoryBox(), photos = MemoryBox();
    final store = RenovisionStore(records: records, photos: photos);
    addTearDown(store.dispose);
    final project = await store.createProject('Home');
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: img.encodePng(img.Image(width: 20, height: 20)),
    );
    await store.setWordingRegion(WordingRegion.us);
    expect(
      store.wordingRegion.text('Replace benchtops'),
      'Replace countertops',
    );
    final draft = RoomDraft(store, room);
    addTearDown(draft.dispose);
    expect(roomTemplatePrompt(room, draft), contains('US English'));
    expect(draft.captureRecipe().toMap()['wordingRegion'], 'us');
    final restarted = RenovisionStore(records: records, photos: photos);
    expect(restarted.wordingRegion, WordingRegion.us);
    restarted.dispose();
    expect(store.roomById(room.id)!.instructions, room.instructions);
  });
  testWidgets(
    'notices replace stale messages, push content and expire without a footer overlay',
    (tester) async {
      late BuildContext inside;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                inside = context;
                return const Text('Controls');
              },
            ),
          ),
        ),
      );
      showAppNotice(inside, 'First');
      await tester.pumpAndSettle();
      showAppNotice(inside, 'Second');
      await tester.pumpAndSettle();
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
