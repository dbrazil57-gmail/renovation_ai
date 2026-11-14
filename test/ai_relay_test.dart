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

  setUp(() async {
    providerCalls = 0;
    providerStatus = 200;
    sentToProvider = null;
    final image = img.Image(width: 60, height: 40);
    image.exif.imageIfd.imageDescription = 'Private original metadata';
    original = img.encodeJpg(image);
    result = img.encodePng(img.Image(width: 60, height: 40));
    final relay = AiRelay(
      apiKey: 'synthetic-test-key',
      pairingCode: 'test-connection',
      clientFactory: () => MockClient((request) async {
        providerCalls++;
        sentToProvider = request;
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
      expect(response.body, isNot(contains('synthetic-test-key')));
      expect(
        response.headers['access-control-allow-origin'],
        'http://localhost:7357',
      );
      expect(response.headers['cache-control'], 'no-store');
      expect(providerCalls, 0);
    },
  );

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
}
