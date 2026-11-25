import 'support/focus_navigation.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:image/image.dart' as img;
import 'package:renovision_ai/ai_activity.dart';
import 'package:renovision_ai/ai_model_choices.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/ai_widgets.dart';
import 'package:renovision_ai/gemini_internet.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/room_analysis.dart';
import 'package:renovision_ai/store.dart';
import 'package:renovision_ai/walkthrough_screen.dart';

import 'openai_internet_test.dart' show Vault, Wire;
import 'support/memory_box.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const googleKey = 'synthetic-google-provider-key';
  const openaiKey = 'synthetic-openai-provider-key';
  final photo = img.encodePng(img.Image(width: 48, height: 32));
  final generated = img.encodePng(img.Image(width: 60, height: 40));
  late AiService ai;
  late Vault googleVault, openaiVault;
  late List<http.BaseRequest> requests;
  late List<Map<String, dynamic>> payloads;
  late int googleStatus;
  late List<String> available;
  late String state;
  late bool imageOutput;
  Map<String, dynamic> analysis() => {
    'observations': 'A kitchen with a window.',
    'questions': [],
    'prompt': 'Update the visible kitchen, keeping its layout.',
  };

  setUp(() {
    requests = [];
    payloads = [];
    googleStatus = 200;
    state = 'STOP';
    imageOutput = true;
    available = [...geminiRoomImageModels, ...geminiAnalysisModels];
    googleVault = Vault();
    openaiVault = Vault();
    ai = AiService(
      keyStore: openaiVault,
      geminiKeyStore: googleVault,
      clientFactory: () => Wire((request, bytes) async {
        requests.add(request);
        expect(request.followRedirects, isFalse);
        expect(request.url.scheme, 'https');
        expect(request.url.toString(), isNot(contains('key=')));
        if (request.url.host == 'api.openai.com') {
          expect(request.headers['Authorization'], 'Bearer $openaiKey');
          expect(request.headers.containsKey('x-goog-api-key'), isFalse);
          expect(request.url.path, '/v1/models');
          return http.Response(
            jsonEncode({
              'data': [
                for (final id in [...preferredRoomImageModels, 'gpt-6-luna'])
                  {'id': id},
              ],
            }),
            200,
          );
        }
        expect(request.url.host, 'generativelanguage.googleapis.com');
        expect(request.headers['x-goog-api-key'], googleKey);
        expect(request.headers.containsKey('Authorization'), isFalse);
        expect(request.headers.containsKey('Api-Revision'), isFalse);
        if (googleStatus != 200) {
          return http.Response('private upstream $googleKey', googleStatus);
        }
        if (request.method == 'GET') {
          expect(request.url.path, '/v1beta/models');
          return http.Response(
            jsonEncode({
              'models': [
                for (final id in available) {'name': 'models/$id'},
              ],
            }),
            200,
          );
        }
        expect(request.url.path, endsWith(':generateContent'));
        final payload = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        payloads.add(payload);
        expect(payload.containsKey('store'), isFalse);
        expect(utf8.decode(bytes), isNot(contains(googleKey)));
        final rendering = payload['generationConfig']['imageConfig'] != null;
        return http.Response(
          jsonEncode({
            'responseId': rendering ? 'google-image' : 'google-analysis',
            'usageMetadata': {
              'promptTokenCount': 120,
              'candidatesTokenCount': 300,
            },
            'candidates': [
              {
                'finishReason': state,
                'content': {
                  'role': 'model',
                  'parts': [
                    {
                      'thought': true,
                      'inlineData': {
                        'data': base64Encode(photo),
                        'mimeType': 'image/png',
                      },
                    },
                    if (rendering && imageOutput)
                      {
                        'inlineData': {
                          'data': base64Encode(generated),
                          'mimeType': 'image/png',
                        },
                      }
                    else
                      {
                        'text': rendering
                            ? 'No image supplied'
                            : jsonEncode(analysis()),
                      },
                  ],
                },
              },
            ],
          }),
          200,
        );
      }),
    );
  });
  tearDown(() => ai.dispose());
  Future<void> connectGoogle() =>
      ai.connectDirect(apiKey: googleKey, provider: AiProvider.gemini);

  test('curated list contains image editors, excluding text assistants and image-lite', () {
    expect(AiProvider.openai.recommendations, preferredRoomImageModels.take(2));
    expect(AiProvider.gemini.recommendations, geminiRoomImageModels);
    expect(
      geminiRoomImageModels,
      isNot(contains('gemini-3.1-flash-lite-image')),
    );
    expect(
      geminiRoomImageModels.toSet().intersection(geminiAnalysisModels.toSet()),
      isEmpty,
    );
    expect(
      recommendedImageModel(geminiRoomImageModels),
      'gemini-nano-banana-2.1',
    );
    expect(
      recommendedImageModel(geminiRoomImageModels, detailed: true),
      'gemini-3-pro-image',
    );
  });

  test('metadata-only connection picks curated defaults and available vision analyst', () async {
    await connectGoogle();
    expect(requests, hasLength(1));
    expect(requests.single.method, 'GET');
    expect(payloads, isEmpty);
    expect(ai.model, geminiRoomImageModels.first);
    expect(ai.quality, 'medium');
    expect(ai.analysisModel, geminiAnalysisModels.first);
    expect(ai.supportsAnalysis, isTrue);
    expect(openaiVault.value, isNull);
    expect(googleVault.value, googleKey);
  });

  test('room analysis uses stripped photo copies, structured schema and real provider provenance', () async {
    await connectGoogle();
    final stages = <AiStage>[];
    final result = await ai.analyse(
      image: photo,
      supportingImages: [photo],
      context: 'Keep the layout',
      onProgress: stages.add,
    );
    expect(result.provider, 'Gemini');
    expect(result.model, geminiAnalysisModels.first);
    expect(RoomAnalysisResult.fromMap(result.toMap()).provider, 'Gemini');
    final legacy = Map.of(result.toMap())..remove('provider');
    expect(RoomAnalysisResult.fromMap(legacy).provider, 'OpenAI');
    expect(result.requestId, 'google-analysis');
    final body = payloads.single;
    expect(
      body['systemInstruction']['parts'][0]['text'],
      roomAnalysisInstructions,
    );
    expect(body['generationConfig']['responseJsonSchema'], roomAnalysisSchema);
    final images = (body['contents'][0]['parts'] as List)
        .map((item) => item['inlineData'])
        .whereType<Map>();
    expect(images, hasLength(2));
    for (final image in images) {
      expect(image['mimeType'], 'image/png');
      expect(
        img.decodePng(base64Decode(image['data'] as String))!.exif.isEmpty,
        isTrue,
      );
    }
    expect(stages, [AiStage.preparing, AiStage.waiting, AiStage.reading]);
  });

  test('generation preserves reference order, maps resolution and ignores thought images', () async {
    await connectGoogle();
    for (final (quality, size) in [
      ('low', '1K'),
      ('medium', '2K'),
      ('high', '4K'),
    ]) {
      final result = await ai.edit(
        image: photo,
        supportingImages: [generated],
        prompt: 'Create a new design',
        imageQuality: quality,
      );
      expect(result.image, generated);
      expect(result.provider, 'Gemini');
      expect(result.quality, quality);
      expect(result.requestId, 'google-image');
      final body = payloads.last;
      expect(body['generationConfig']['imageConfig']['imageSize'], size);
      final parts = body['contents'][0]['parts'] as List;
      expect(parts[1]['text'], startsWith('Image 1: working view'));
      expect(parts[3]['text'], 'Image 2: supporting room angle.');
      expect(base64Decode(parts[2]['inlineData']['data'] as String), photo);
      expect(base64Decode(parts[4]['inlineData']['data'] as String), generated);
      expect(result.usage!.inputTokens, 120);
      expect(result.usage!.outputTokens, 300);
    }
  });

  test('keys and chosen models remain separate across switches and restart without startup network', () async {
    await ai.connectDirect(apiKey: openaiKey);
    ai.selectImageSettings(
      imageModel: 'gpt-image-2.6-flare',
      imageQuality: 'low',
    );
    await connectGoogle();
    ai.selectImageSettings(
      imageModel: 'gemini-3-pro-image',
      imageQuality: 'high',
    );
    await ai.useSavedProvider(AiProvider.openai);
    expect(ai.model, 'gpt-image-2.6-flare');
    expect(ai.quality, 'low');
    final config = jsonDecode(jsonEncode(ai.rememberedConnection)) as Map;
    expect(jsonEncode(config), isNot(contains(googleKey)));
    expect(jsonEncode(config), isNot(contains(openaiKey)));
    final next = AiService(
      keyStore: openaiVault,
      geminiKeyStore: googleVault,
      clientFactory: () => throw StateError('No startup network'),
    );
    addTearDown(next.dispose);
    await next.restoreConnection(config);
    expect(next.provider, AiProvider.openai);
    expect(next.model, 'gpt-image-2.6-flare');
    await ai.useSavedProvider(AiProvider.gemini);
    expect(ai.model, 'gemini-3-pro-image');
    expect(ai.quality, 'high');
    await next.restoreConnection(
      jsonDecode(jsonEncode(ai.rememberedConnection)) as Map,
    );
    expect(next.provider, AiProvider.gemini);
    expect(next.model, 'gemini-3-pro-image');
    expect(next.analysisModel, geminiAnalysisModels.first);
    await next.removeProviderKey(AiProvider.openai);
    expect(next.connected, isTrue);
    expect(googleVault.value, googleKey);
    expect(openaiVault.value, isNull);
    await next.disconnect();
    expect(googleVault.value, isNull);
  });

  test(
    'session key expiry preserves saved model choices for reconnection',
    () async {
      final next = AiService(
        clientFactory: ai.clientFactory,
        geminiKeyStore: Vault(),
      );
      addTearDown(next.dispose);
      await next.restoreConnection({
        'mode': 'direct',
        'provider': 'gemini',
        'model': 'gemini-3-pro-image',
        'quality': 'high',
        'imageModels': geminiRoomImageModels,
        'analysisModel': geminiAnalysisModels.first,
      });
      expect(next.connected, isFalse);
      expect(requests, isEmpty);
      await next.connectDirect(apiKey: googleKey, provider: AiProvider.gemini);
      expect(next.model, 'gemini-3-pro-image');
      expect(next.quality, 'high');
      expect(requests, hasLength(1));
    },
  );

  test('failed provider connection cannot replace a working one', () async {
    await ai.connectDirect(apiKey: openaiKey);
    googleStatus = 403;
    await expectLater(connectGoogle(), throwsA(isA<AiFailure>()));
    expect(ai.connected, isTrue);
    expect(ai.provider, AiProvider.openai);
    googleStatus = 200;
    googleVault.failWriting = true;
    await expectLater(connectGoogle(), throwsA(isA<AiFailure>()));
    expect(ai.provider, AiProvider.openai);
    expect(googleVault.value, isNull);
  });

  test('unsupported image access fails metadata check; missing analysis stays unavailable', () async {
    available = ['gemini-3.5-flash-lite', 'gemini-3.1-flash-lite-image'];
    await expectLater(connectGoogle(), throwsA(isA<AiFailure>()));
    expect(ai.connected, isFalse);
    expect(googleVault.value, isNull);
    available = [geminiRoomImageModels.last];
    await connectGoogle();
    expect(ai.supportsAnalysis, isFalse);
    expect(ai.model, geminiRoomImageModels.last);
  });

  test('both curated image models use the matching generateContent model endpoint without fallback', () async {
    await connectGoogle();
    for (final model in geminiRoomImageModels) {
      final before = requests.length;
      final result = await ai.edit(
        image: photo,
        prompt: 'Redesign',
        imageModel: model,
        imageQuality: 'high',
      );
      expect(requests.length, before + 1);
      expect(requests.last.url.path, '/v1beta/models/$model:generateContent');
      expect(result.model, model);
      expect(result.image, generated);
    }
  });

  test('safe diagnostics persist failures and exclude keys, instructions, images and provider response text', () async {
    final records = MemoryBox(), photos = MemoryBox();
    final sessionAi = AiService(
      clientFactory: ai.clientFactory,
      geminiKeyStore: googleVault,
    );
    final store = RenovisionStore(
      records: records,
      photos: photos,
      ai: sessionAi,
    );
    await sessionAi.connectDirect(
      apiKey: googleKey,
      provider: AiProvider.gemini,
    );
    googleStatus = 400;
    await expectLater(
      sessionAi.edit(image: photo, prompt: 'PRIVATE ROOM INSTRUCTIONS'),
      throwsA(isA<AiFailure>()),
    );
    await Future<void>.delayed(Duration.zero);
    final report = sessionAi.diagnostics.report;
    expect(report, contains('"http": 400'));
    expect(report, contains('"problem": "options"'));
    expect(report, contains('generateContent'));
    for (final secret in [
      googleKey,
      openaiKey,
      'PRIVATE ROOM INSTRUCTIONS',
      'private upstream',
      base64Encode(photo),
    ]) {
      expect(report, isNot(contains(secret)));
    }
    final saved = records.get('settings:ai_diagnostics');
    expect(saved, hasLength(2));
    final next = RenovisionStore(records: records, photos: photos);
    expect(next.ai.diagnostics.entries.first['http'], 400);
    next.ai.diagnostics.clear();
    await Future<void>.delayed(Duration.zero);
    expect(records.get('settings:ai_diagnostics'), isEmpty);
    next.dispose();
    store.dispose();
  });

  test('structured Google errors distinguish credentials, billing and unavailable model without echoing details', () async {
    for (final (status, reason, problem) in [
      (400, 'API_KEY_INVALID', AiProblem.credentials),
      (403, 'BILLING_DISABLED', AiProblem.billing),
      (404, 'NOT_FOUND', AiProblem.model),
    ]) {
      var calls = 0;
      final transport = GeminiInternet(
        () => Wire((request, bytes) async {
          calls++;
          return http.Response(
            jsonEncode({
              'error': {
                'status': reason,
                'message': 'PRIVATE $googleKey',
                'details': [
                  {'reason': reason},
                ],
              },
            }),
            status,
          );
        }),
      );
      await expectLater(
        transport.edit(
          key: googleKey,
          prompt: 'Private prompt',
          model: geminiRoomImageModels.first,
          quality: 'medium',
          sources: [photo],
        ),
        throwsA(
          isA<AiFailure>()
              .having((e) => e.problem, 'problem', problem)
              .having((e) => e.statusCode, 'http', status)
              .having((e) => e.message, 'message', isNot(contains(googleKey))),
        ),
      );
      expect(calls, 1);
    }
  });

  test(
    'provider errors are sanitised; redirects and retries never forward keys',
    () async {
      await connectGoogle();
      for (final status in [302, 400, 401, 403, 429, 500]) {
        googleStatus = status;
        final before = requests.length;
        try {
          await ai.edit(image: photo, prompt: 'Redesign');
          fail('Expected provider error');
        } on AiFailure catch (error) {
          expect(error.message, isNot(contains(googleKey)));
          expect(error.message, isNot(contains('private upstream')));
        }
        expect(requests.length, before + 1);
      }
    },
  );

  test(
    'incomplete or text-only response is not mistaken for a final image',
    () async {
      await connectGoogle();
      state = 'MAX_TOKENS';
      await expectLater(
        ai.edit(image: photo, prompt: 'Redesign'),
        throwsA(isA<AiFailure>()),
      );
      state = 'STOP';
      imageOutput = false;
      await expectLater(
        ai.edit(image: photo, prompt: 'Redesign'),
        throwsA(isA<AiFailure>()),
      );
    },
  );

  test('invalid photos and mismatched provider models never upload', () async {
    await connectGoogle();
    await expectLater(
      ai.edit(image: Uint8List(0), prompt: 'Redesign'),
      throwsA(isA<AiFailure>()),
    );
    await expectLater(
      ai.edit(
        image: photo,
        prompt: 'Redesign',
        imageModel: preferredRoomImageModels.first,
      ),
      throwsA(isA<AiFailure>()),
    );
    expect(requests, hasLength(1));
  });

  test(
    'a timeout is reported without retrying or exposing provider details',
    () async {
      var calls = 0;
      final transport = GeminiInternet(
        () => Wire((request, bytes) async {
          calls++;
          throw TimeoutException('secret $googleKey');
        }),
      );
      await expectLater(
        transport.edit(
          key: googleKey,
          prompt: 'Redesign',
          model: geminiRoomImageModels.first,
          quality: 'low',
          sources: [photo],
        ),
        throwsA(
          isA<AiFailure>().having(
            (e) => e.message,
            'message',
            allOf(contains('timed out'), isNot(contains(googleKey))),
          ),
        ),
      );
      expect(calls, 1);
    },
  );

  test('model listing follows pagination using fixed host and bounded opaque tokens', () async {
    var calls = 0;
    final transport = GeminiInternet(
      () => Wire((request, bytes) async {
        calls++;
        expect(request.url.host, 'generativelanguage.googleapis.com');
        if (calls == 1) {
          return http.Response(
            jsonEncode({
              'models': [
                {'name': 'models/${geminiRoomImageModels.first}'},
              ],
              'nextPageToken': 'opaque token&next',
            }),
            200,
          );
        }
        expect(request.url.queryParameters['pageToken'], 'opaque token&next');
        return http.Response(
          jsonEncode({
            'models': [
              {'name': 'models/${geminiRoomImageModels.last}'},
            ],
          }),
          200,
        );
      }),
    );
    expect(await transport.models(googleKey), geminiRoomImageModels);
    expect(calls, 2);
  });

  test('both keys stay out of projects and portable backups', () async {
    final store = RenovisionStore(
      records: MemoryBox(),
      photos: MemoryBox(),
      ai: ai,
    );
    await ai.connectDirect(apiKey: openaiKey);
    await connectGoogle();
    final project = await store.createProject('Fictional home');
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: photo,
    );
    final backup = ProjectBackup.decode(store.backupFor(project.id).encode());
    expect(backup.rooms.single.id, room.id);
    final encoded = utf8.decode(store.backupFor(project.id).encode());
    expect(encoded, isNot(contains(googleKey)));
    expect(encoded, isNot(contains(openaiKey)));
  });

  test('active paid work blocks provider and model switches', () async {
    await connectGoogle();
    ai.activity.begin(roomId: 'room', operation: 'Design');
    await expectLater(
      ai.connectDirect(apiKey: openaiKey),
      throwsA(isA<AiFailure>()),
    );
    await expectLater(ai.disconnect(), throwsA(isA<AiFailure>()));
    expect(
      () => ai.selectImageSettings(
        imageModel: geminiRoomImageModels.last,
        imageQuality: 'high',
      ),
      throwsA(isA<AiFailure>()),
    );
    expect(requests, hasLength(1));
    expect(ai.provider, AiProvider.gemini);
  });

  testWidgets(
    'recommendations and provider-specific private key entry work without a key on a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AiConnectionCard(ai: ai)),
          ),
        ),
      );
      await tester.tap(find.text('Recommended design models'));
      await tester.pumpAndSettle();
      expect(find.text('GPT Image 2.6 Sunburst'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ai-provider-openai')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gemini').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recommended design models'));
      await tester.pumpAndSettle();
      expect(find.text('Nano Banana 2.1'), findsOneWidget);
      expect(find.text('Nano Banana Pro'), findsOneWidget);
      expect(find.text('Gemini API key'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );
      expect(requests, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'model comparison help preserves the selected model and sends no paid request',
    (tester) async {
      await connectGoogle();
      ai.selectImageSettings(
        imageModel: 'gemini-3-pro-image',
        imageQuality: 'high',
      );
      final saved = jsonEncode(ai.rememberedConnection);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AiConnectionCard(ai: ai)),
          ),
        ),
      );
      await tester.tap(find.text('Recommended design models'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('How to compare models'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('How to compare models'));
      await tester.pumpAndSettle();
      expect(find.byType(WalkthroughScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Read steps'));
      await tester.pumpAndSettle();
      expect(find.text('Start with the image-model shortlist'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(jsonEncode(ai.rememberedConnection), saved);
      expect(requests, hasLength(1));
      expect(payloads, isEmpty);
      await tester.ensureVisible(find.text('Use fixed brief for model tests'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use fixed brief for model tests'));
      await tester.pumpAndSettle();
      expect(ai.fixedComparisonBrief, isTrue);
      final restarted = AiService(
        keyStore: openaiVault,
        geminiKeyStore: googleVault,
        clientFactory: () => throw StateError('No startup request'),
      );
      addTearDown(restarted.dispose);
      await restarted.restoreConnection(jsonDecode(saved) as Map);
      expect(restarted.fixedComparisonBrief, isFalse);
      expect(restarted.model, 'gemini-3-pro-image');
      expect(requests, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'changing provider during design consent requires review again without sending photos',
    (tester) async {
      await connectGoogle();
      final store = RenovisionStore(
        records: MemoryBox(),
        photos: MemoryBox(),
        ai: ai,
      );
      final project = await store.createProject('Home');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: photo,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiEditCard(
                store: store,
                compact: true,
                singleConcept: true,
                buildRequest: () => AiEditRequest(
                  roomId: room.id,
                  parentId: null,
                  sourceImageId: room.originalId,
                  image: photo,
                  prompt: 'Modernise the kitchen within the layout',
                  title: 'Kitchen design',
                  instructions: 'Redesign',
                  precise: false,
                ),
                onSaved: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(aiGenerateAction());
      await tester.pumpAndSettle();
      expect(find.text('Send to Gemini'), findsOneWidget);
      await tester.runAsync(() => ai.connectDirect(apiKey: openaiKey));
      await tester.tap(find.text('Send to Gemini'));
      await tester.pumpAndSettle();
      expect(payloads, isEmpty);
      expect(find.textContaining('connection changed'), findsOneWidget);
    },
  );
}
