import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;

import '../tool/ai_relay.dart';

void main() {
  late HttpServer server;
  late http.Client browser;
  late Uri base;
  late int providerCalls;
  late int providerStatus;
  late http.Request? sentToProvider;
  late Uint8List original;
  late Uint8List result;
  late Map<String, dynamic> analysisBody;

  setUp(() async {
    providerCalls = 0;
    providerStatus = 200;
    sentToProvider = null;
    final image = img.Image(width: 60, height: 40);
    image.exif.imageIfd.imageDescription = 'Private original metadata';
    original = img.encodeJpg(image);
    result = img.encodePng(img.Image(width: 60, height: 40));
    analysisBody = {
      'status': 'completed',
      'output': [
        {
          'type': 'message',
          'content': [
            {
              'type': 'output_text',
              'text': jsonEncode({
                'observations':
                    'A window above the sink and a peninsula are visible.',
                'questions': [
                  'Should the dining-facing side have storage doors?',
                ],
                'prompt':
                    'Keep the window and room layout; modernise the cabinetry.',
              }),
            },
          ],
        },
      ],
    };
    final relay = AiRelay(
      apiKey: 'synthetic-test-key',
      pairingCode: 'test-connection',
      clientFactory: () => MockClient((request) async {
        providerCalls++;
        sentToProvider = request;
        if (request.url.path == '/v1/responses') {
          return http.Response(
            jsonEncode(analysisBody),
            providerStatus,
            headers: {'x-request-id': 'analysis-request'},
          );
        }
        return http.Response(
          jsonEncode({
            'data': [
              {'b64_json': base64Encode(result)},
            ],
          }),
          providerStatus,
          headers: {'x-request-id': 'synthetic-request'},
        );
      }),
    );
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(relay.handle);
    base = Uri.parse('http://127.0.0.1:${server.port}');
    browser = http.Client();
  });
  tearDown(() async {
    browser.close();
    await server.close(force: true);
  });

  Map<String, String> headers({
    String code = 'test-connection',
    String origin = 'http://localhost:7357',
  }) => {
    'Authorization': 'Bearer $code',
    'Origin': origin,
    'Content-Type': 'application/json',
  };
  String editBody({bool confirmed = true}) => jsonEncode({
    'image': base64Encode(original),
    'prompt': 'Change only the skirting',
    'confirmed': confirmed,
  });

  test(
    'local connection check reports config without any provider request',
    () async {
      final response = await browser.get(
        base.resolve('/health'),
        headers: headers(),
      );
      expect(response.statusCode, 200);
      expect(jsonDecode(response.body)['provider'], 'OpenAI');
      expect(jsonDecode(response.body)['analysisModel'], 'gpt-6-luna');
      expect(response.body, isNot(contains('synthetic-test-key')));
      expect(
        response.headers['access-control-allow-origin'],
        'http://localhost:7357',
      );
      expect(response.headers['cache-control'], 'no-store');
      expect(providerCalls, 0);
    },
  );

  test('confirmed edit uses chosen model and quality; unsupported selections never reach provider', () async {
    final response = await browser.get(
      base.resolve('/health'),
      headers: headers(),
    );
    final config = jsonDecode(response.body) as Map;
    expect(config['imageModels'], contains('gpt-image-2.5-flare'));
    expect(config['imageQualities'], contains('medium'));
    final data = jsonDecode(editBody()) as Map<String, dynamic>;
    data['model'] = 'gpt-image-2.5-flare';
    data['quality'] = 'medium';
    final edited = await browser.post(
      base.resolve('/edit'),
      headers: headers(),
      body: jsonEncode(data),
    );
    expect(edited.statusCode, 200);
    expect(jsonDecode(edited.body)['model'], 'gpt-image-2.5-flare');
    expect(jsonDecode(edited.body)['quality'], 'medium');
    final multipart = latin1.decode(sentToProvider!.bodyBytes);
    expect(multipart, contains('name="model"\r\n\r\ngpt-image-2.5-flare'));
    expect(multipart, contains('name="quality"\r\n\r\nmedium'));
    expect(providerCalls, 1);
    data['model'] = 'unadvertised-model';
    final rejected = await browser.post(
      base.resolve('/edit'),
      headers: headers(),
      body: jsonEncode(data),
    );
    expect(rejected.statusCode, 400);
    expect(providerCalls, 1);
    data['model'] = 'gpt-image-2.5-flare';
    data['quality'] = 'unbounded';
    expect(
      (await browser.post(
        base.resolve('/edit'),
        headers: headers(),
        body: jsonEncode(data),
      )).statusCode,
      400,
    );
    expect(providerCalls, 1);
  });

  test(
    'wrong pairing code or non-local browser origin cannot invoke provider',
    () async {
      final wrongCode = await browser.post(
        base.resolve('/edit'),
        headers: headers(code: 'wrong'),
        body: editBody(),
      );
      expect(wrongCode.statusCode, 401);
      final remote = await browser.post(
        base.resolve('/edit'),
        headers: headers(origin: 'https://untrusted.example'),
        body: editBody(),
      );
      expect(remote.statusCode, 403);
      expect(remote.headers['access-control-allow-origin'], isNull);
      expect(providerCalls, 0);
    },
  );

  test(
    'missing confirmation or invalid image cannot invoke provider',
    () async {
      final unconfirmed = await browser.post(
        base.resolve('/edit'),
        headers: headers(),
        body: editBody(confirmed: false),
      );
      expect(unconfirmed.statusCode, 400);
      final invalid = await browser.post(
        base.resolve('/edit'),
        headers: headers(),
        body: jsonEncode({
          'image': base64Encode([1, 2, 3]),
          'prompt': 'Edit',
          'confirmed': true,
        }),
      );
      expect(invalid.statusCode, 400);
      expect(providerCalls, 0);
    },
  );

  test(
    'confirmed edit sends sanitised copy once and returns result metadata',
    () async {
      final response = await browser.post(
        base.resolve('/edit'),
        headers: headers(),
        body: editBody(),
      );
      expect(response.statusCode, 200);
      expect(providerCalls, 1);
      final sent = sentToProvider!;
      expect(sent.url.toString(), 'https://api.openai.com/v1/images/edits');
      expect(sent.headers['Authorization'], 'Bearer synthetic-test-key');
      final multipart = latin1.decode(sent.bodyBytes);
      expect(multipart, contains('Change only the skirting'));
      expect(multipart, isNot(contains('Private original metadata')));
      expect(multipart, contains('image/png'));
      final output = jsonDecode(response.body);
      expect(base64Decode(output['image']), orderedEquals(result));
      expect(output['requestId'], 'synthetic-request');
      expect(output['model'], 'gpt-image-2.5-sunburst');
      expect(
        img.decodeImage(original)!.exif.imageIfd.imageDescription,
        'Private original metadata',
      );
    },
  );

  test(
    'relay sends each room view in order as a separate sanitised image',
    () async {
      final data = jsonDecode(editBody()) as Map<String, dynamic>;
      data['supportingImages'] = [base64Encode(original), base64Encode(result)];
      final response = await browser.post(
        base.resolve('/edit'),
        headers: headers(),
        body: jsonEncode(data),
      );
      expect(response.statusCode, 200);
      expect(providerCalls, 1);
      final multipart = latin1.decode(sentToProvider!.bodyBytes);
      expect(RegExp('filename="room-').allMatches(multipart), hasLength(3));
      expect(
        multipart.indexOf('room-1.png'),
        lessThan(multipart.indexOf('room-2.png')),
      );
      expect(
        multipart.indexOf('room-2.png'),
        lessThan(multipart.indexOf('room-3.png')),
      );
      expect(multipart, isNot(contains('Private original metadata')));
    },
  );

  test(
    'invalid or excessive supporting views do not contact the provider',
    () async {
      for (final support in [
        [123],
        List.filled(7, base64Encode(original)),
        [
          base64Encode([1, 2, 3]),
        ],
      ]) {
        final data = jsonDecode(editBody()) as Map<String, dynamic>;
        data['supportingImages'] = support;
        final response = await browser.post(
          base.resolve('/edit'),
          headers: headers(),
          body: jsonEncode(data),
        );
        expect(response.statusCode, 400);
      }
      expect(providerCalls, 0);
    },
  );

  test(
    'provider key failure is sanitised and never automatically retried',
    () async {
      providerStatus = 401;
      final response = await browser.post(
        base.resolve('/edit'),
        headers: headers(),
        body: editBody(),
      );
      expect(response.statusCode, 402);
      expect(providerCalls, 1);
      expect(response.body, isNot(contains('synthetic-test-key')));
      expect(response.body, isNot(contains(base64Encode(original))));
    },
  );

  test('vision endpoint sends ordered metadata-free images and returns structured analysis once', () async {
    final input = jsonDecode(editBody()) as Map<String, dynamic>;
    input['supportingImages'] = [base64Encode(original)];
    final response = await browser.post(
      base.resolve('/analyse'),
      headers: headers(),
      body: jsonEncode(input),
    );
    expect(response.statusCode, 200);
    expect(providerCalls, 1);
    final sent = jsonDecode(sentToProvider!.body) as Map<String, dynamic>;
    expect(sent['store'], false);
    expect(sent['max_output_tokens'], 3000);
    expect(sent['text']['format']['strict'], true);
    expect(sent['instructions'], contains('not just the room label'));
    final content = sent['input'][0]['content'] as List;
    final inputs = content
        .where((item) => item['type'] == 'input_image')
        .toList();
    expect(inputs, hasLength(2));
    expect(content[0]['text'], contains('Change only the skirting'));
    for (final image in inputs) {
      final bytes = base64Decode(
        (image['image_url'] as String).split(',').last,
      );
      expect(
        latin1.decode(bytes),
        isNot(contains('Private original metadata')),
      );
      expect(img.decodePng(bytes), isNotNull);
    }
    final body = jsonDecode(response.body);
    expect(body['observations'], contains('window above the sink'));
    expect(body['requestId'], 'analysis-request');
    expect(body['model'], 'gpt-6-luna');
    expect(body.containsKey('image'), false);
    expect(
      img.decodeImage(original)!.exif.imageIfd.imageDescription,
      'Private original metadata',
    );
  });

  test(
    'vision working copy preserves camera orientation before removing metadata',
    () async {
      final camera = img.Image(width: 60, height: 40);
      camera.exif.imageIfd.orientation = 6;
      camera.exif.imageIfd.imageDescription = 'Private camera metadata';
      final bytes = img.encodeJpg(camera);
      final response = await browser.post(
        base.resolve('/analyse'),
        headers: headers(),
        body: jsonEncode({
          'image': base64Encode(bytes),
          'prompt': 'Describe this room',
          'confirmed': true,
        }),
      );
      expect(response.statusCode, 200);
      final sent = jsonDecode(sentToProvider!.body);
      final content = sent['input'][0]['content'] as List;
      final url =
          content.singleWhere((p) => p['type'] == 'input_image')['image_url']
              as String;
      final cleanBytes = base64Decode(url.split(',').last);
      final clean = img.decodePng(cleanBytes)!;
      expect(clean.width, 40);
      expect(clean.height, 60);
      expect(
        latin1.decode(cleanBytes),
        isNot(contains('Private camera metadata')),
      );
      // JPEG decoding bakes EXIF rotation into pixels. The original still keeps
      // its private metadata; only the uploaded PNG copy has it removed.
      expect(
        img.decodeJpg(bytes)!.exif.imageIfd.imageDescription,
        'Private camera metadata',
      );
    },
  );

  test('analysis requires consent and a valid local connection before contacting provider', () async {
    for (final (code, confirmed, status) in [
      ('wrong', true, 401),
      ('test-connection', false, 400),
    ]) {
      final response = await browser.post(
        base.resolve('/analyse'),
        headers: headers(code: code),
        body: editBody(confirmed: confirmed),
      );
      expect(response.statusCode, status);
    }
    expect(providerCalls, 0);
  });

  test('incomplete, refused and malformed analyses are rejected without automatic retries', () async {
    for (final bad in [
      {'status': 'incomplete', 'output': []},
      {
        'status': 'completed',
        'output': [
          {
            'type': 'message',
            'content': [
              {'type': 'refusal', 'refusal': 'No'},
            ],
          },
        ],
      },
      {
        'status': 'completed',
        'output': [
          {
            'type': 'message',
            'content': [
              {
                'type': 'output_text',
                'text': '{"observations":"Imagined room"}',
              },
            ],
          },
        ],
      },
    ]) {
      analysisBody = bad;
      final response = await browser.post(
        base.resolve('/analyse'),
        headers: headers(),
        body: editBody(),
      );
      expect(response.statusCode, 502);
    }
    expect(providerCalls, 3);
  });
}
