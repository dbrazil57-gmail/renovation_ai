import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_activity.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/ai_widgets.dart';
import 'package:renovision_ai/openai_internet.dart';
import 'package:renovision_ai/secret_store.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

class Vault implements SecretStore {
  String? value;
  bool failWriting = false;
  @override
  bool get persistent => true;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String key) async {
    if (failWriting) throw StateError('Vault unavailable');
    value = key;
  }

  @override
  Future<void> delete() async {
    value = null;
  }
}

class Wire extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest, Uint8List) respond;
  Wire(this.respond);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await request.finalize().toBytes();
    final response = await respond(request, body);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = 'synthetic-unit-test-secret';
  final photo = img.encodePng(img.Image(width: 40, height: 30));
  late Vault vault;
  late AiService ai;
  late List<String> paths;
  late List<AiStage> phases;
  late int status;
  late String? submitted;
  setUp(() {
    vault = Vault();
    paths = [];
    phases = [];
    status = 200;
    submitted = null;
    ai = AiService(
      keyStore: vault,
      clientFactory: () => Wire((request, bytes) async {
        expect(request.url.scheme, 'https');
        expect(request.url.host, 'api.openai.com');
        expect(request.followRedirects, isFalse);
        expect(request.headers['Authorization'], 'Bearer $key');
        paths.add(request.url.path);
        if (status != 200) {
          return http.Response('private upstream $key', status);
        }
        if (request.url.path == '/v1/models') {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': directImageModels.first},
                {'id': 'gpt-6-luna'},
              ],
            }),
            200,
          );
        }
        if (request.url.path == '/v1/images/edits') {
          final multipart = request as http.MultipartRequest;
          expect(multipart.fields['prompt'], 'Retain layout and use charcoal');
          expect(multipart.fields['n'], '1');
          expect(multipart.files.map((f) => f.field), ['image[]', 'image[]']);
          expect(multipart.files.map((f) => f.filename), [
            'room-1.png',
            'room-2.png',
          ]);
          return http.Response(
            jsonEncode({
              'data': [
                {'b64_json': base64Encode(photo)},
              ],
            }),
            200,
            headers: {'x-request-id': 'image-test'},
          );
        }
        expect(request.url.path, '/v1/responses');
        submitted = utf8.decode(bytes);
        final payload = jsonDecode(submitted!) as Map;
        expect(payload['store'], isFalse);
        expect(payload['text']['format']['strict'], isTrue);
        final content = payload['input'][0]['content'] as List;
        final images = content
            .where((item) => item['type'] == 'input_image')
            .toList();
        expect(images, hasLength(2));
        expect(images.first['image_url'], startsWith('data:image/png;base64,'));
        expect(content.first['text'], contains('Room requirements'));
        return http.Response(
          jsonEncode({
            'status': 'completed',
            'output': [
              {
                'type': 'message',
                'content': [
                  {
                    'type': 'output_text',
                    'text': jsonEncode({
                      'observations': 'A kitchen window is visible.',
                      'questions': ['Keep this sink?'],
                      'prompt': 'Modernise the kitchen within its layout.',
                    }),
                  },
                ],
              },
            ],
          }),
          200,
          headers: {'x-request-id': 'analysis-test'},
        );
      }),
    );
  });
  tearDown(() => ai.dispose());

  test(
    'key check, analysis and generation go directly over HTTPS without a relay',
    () async {
      await ai.connectDirect(apiKey: key);
      expect(paths, ['/v1/models']);
      expect(ai.connected && ai.isDirect && ai.supportsAnalysis, isTrue);
      final analysis = await ai.analyse(
        image: photo,
        supportingImages: [photo],
        context: 'Room requirements',
        onProgress: phases.add,
      );
      expect(analysis.requestId, 'analysis-test');
      expect(analysis.observations, contains('window'));
      expect(phases, [AiStage.preparing, AiStage.waiting, AiStage.reading]);
      phases.clear();
      final result = await ai.edit(
        image: photo,
        supportingImages: [photo],
        prompt: 'Retain layout and use charcoal',
        onProgress: phases.add,
      );
      expect(result.image, photo);
      expect(result.requestId, 'image-test');
      expect(phases, [AiStage.preparing, AiStage.waiting, AiStage.reading]);
      expect(paths, ['/v1/models', '/v1/responses', '/v1/images/edits']);
      expect(submitted, isNot(contains(key)));
    },
  );

  test('restart restores vault key without network; project and settings contain no key', () async {
    final records = MemoryBox(), photos = MemoryBox();
    final store = RenovisionStore(records: records, photos: photos, ai: ai);
    await ai.connectDirect(apiKey: key);
    await Future<void>.delayed(Duration.zero);
    final config = Map.from(records.get('settings:ai_connection') as Map);
    expect(jsonEncode(config), isNot(contains(key)));
    final project = await store.createProject('Internet test');
    await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: photo,
    );
    expect(
      utf8.decode(store.backupFor(project.id).encode()),
      isNot(contains(key)),
    );
    final next = AiService(
      keyStore: vault,
      clientFactory: () => throw StateError('No startup network'),
    );
    await next.restoreConnection(config);
    expect(next.connected && next.isDirect, isTrue);
    expect(paths, ['/v1/models']);
    await next.disconnect();
    expect(vault.value, isNull);
    expect(next.connected, isFalse);
    next.dispose();
    // The test shares ai with the store; tearDown disposes the service.
  });

  test(
    'rejected key or unavailable vault leaves connection unchanged',
    () async {
      status = 401;
      await expectLater(
        ai.connectDirect(apiKey: key),
        throwsA(isA<AiFailure>()),
      );
      expect(ai.connected, isFalse);
      expect(vault.value, isNull);
      status = 200;
      vault.failWriting = true;
      await expectLater(
        ai.connectDirect(apiKey: key),
        throwsA(isA<AiFailure>()),
      );
      expect(ai.connected, isFalse);
      expect(vault.value, isNull);
    },
  );

  test('provider errors are sanitised, redirects blocked and requests never retried', () async {
    await ai.connectDirect(apiKey: key);
    for (final failure in [302, 401, 429, 500]) {
      status = failure;
      final before = paths.length;
      try {
        await ai.edit(image: photo, prompt: 'Retain layout and use charcoal');
        fail('Expected failure');
      } on AiFailure catch (error) {
        expect(error.message, isNot(contains(key)));
        expect(error.message, isNot(contains('private upstream')));
      }
      expect(paths.length, before + 1);
    }
  });

  test('photo preparation strips private metadata, resizes copy and preserves original', () {
    final source = img.Image(width: 2500, height: 100);
    source.exif.imageIfd.imageDescription = 'Private location information';
    final original = img.encodeJpg(source);
    final before = Uint8List.fromList(original);
    final prepared = prepareInternetPhotos([original]).single;
    final decoded = img.decodePng(prepared)!;
    expect(decoded.width, 2048);
    expect(decoded.exif.isEmpty, isTrue);
    expect(original, before);
    expect(img.decodeJpg(original)!.exif.isEmpty, isFalse);
  });

  testWidgets(
    'phone defaults to Internet API with an obscured private key field',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AiConnectionCard(ai: ai)),
          ),
        ),
      );
      expect(find.text('OpenAI API key'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      expect(field.enableSuggestions, isFalse);
      expect(find.text('Connect OpenAI over internet'), findsOneWidget);
      expect(paths, isEmpty);
    },
  );
}
