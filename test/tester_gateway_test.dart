import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../tool/tester_gateway.dart';

void main() {
  final token = List.filled(64, 'b').join(),
      hash = invitationHash(List.filled(64, 'b').join());
  Map<String, dynamic> initial() => {
    'version': 1,
    'analyses': 2,
    'designs': 1,
    'attempted': <String, dynamic>{},
    'testers': {
      hash: {
        'analyses': 2,
        'designs': 3,
        'expires': DateTime.now()
            .toUtc()
            .add(const Duration(days: 1))
            .toIso8601String(),
      },
    },
  };
  test('ledger serialises concurrent attempts, enforces global limits and rejects repeated IDs', () async {
    final ledger = TesterLedger(initial(), (_) async {});
    await ledger.reserve(hash, 'first', false);
    await expectLater(
      ledger.reserve(hash, 'first', false),
      throwsFormatException,
    );
    await expectLater(
      ledger.reserve(hash, 'second', false),
      throwsFormatException,
    );
    final results = await Future.wait(
      List.generate(
        3,
        (i) => ledger
            .reserve(hash, 'analysis$i', true)
            .then((_) => true)
            .catchError((_) => false),
      ),
    );
    expect(results.where((v) => v).length, 2);
    expect(ledger.balance(hash)['analyses'], 0);
  });
  test('failed ledger persistence prevents reservation; expired/revoked invitations fail closed', () async {
    final ledger = TesterLedger(initial(), (_) async {
      throw const FileSystemException('Disk full');
    });
    await expectLater(
      ledger.reserve(hash, 'one', false),
      throwsA(isA<FileSystemException>()),
    );
    expect(ledger.balance(hash)['designs'], 1);
    (ledger.data['testers'][hash] as Map)['revoked'] = true;
    expect(() => ledger.balance(hash), throwsFormatException);
    (ledger.data['testers'][hash] as Map)
      ..['revoked'] = false
      ..['expires'] = '2020-01-01T00:00:00Z';
    expect(() => ledger.balance(hash), throwsFormatException);
  });
  test('gateway checks auth/TLS proxy, pins model, decrements once and blocks duplicate upstream calls', () async {
    var calls = 0;
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final upstreamSubscription = upstream.listen((request) async {
      calls++;
      expect(request.headers.value('authorization'), 'Bearer upstream-private');
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      expect(body['quality'], 'low');
      expect(body.containsKey('requestId'), false);
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'provider': 'OpenAI',
          'model': 'gpt-image-2.6-sunburst',
          'image': 'AQI=',
        }),
      );
      await request.response.close();
    });
    final gateway = TesterGateway(
      ledger: TesterLedger(initial(), (_) async {}),
      upstream: Uri.parse('http://127.0.0.1:${upstream.port}'),
      upstreamCode: 'upstream-private',
      model: 'gpt-image-2.6-sunburst',
      quality: 'low',
      analysisModel: 'test-analysis',
    );
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
        client = http.Client();
    final subscription = server.listen(gateway.handle);
    addTearDown(() async {
      client.close();
      await subscription.cancel();
      await server.close(force: true);
      await upstreamSubscription.cancel();
      await upstream.close(force: true);
    });
    final base = Uri.parse('http://127.0.0.1:${server.port}');
    final headers = {
      'Authorization': 'Bearer $token',
      'x-forwarded-proto': 'https',
      'Content-Type': 'application/json',
    };
    expect((await client.get(base.resolve('/health'))).statusCode, 403);
    expect(
      (await client.get(
        base.resolve('/health'),
        headers: {'x-forwarded-proto': 'https'},
      )).statusCode,
      401,
    );
    expect(
      (await client.get(base.resolve('/health'), headers: headers)).statusCode,
      200,
    );
    final body = {
      'confirmed': true,
      'requestId': List.filled(48, 'a').join(),
      'image': 'AQI=',
      'prompt': 'Modernise',
      'supportingImages': [],
      'model': 'gpt-image-2.6-sunburst',
      'quality': 'low',
    };
    final result = await client.post(
      base.resolve('/edit'),
      headers: headers,
      body: jsonEncode(body),
    );
    expect(result.statusCode, 200);
    expect(jsonDecode(result.body)['credits']['designs'], 0);
    expect(
      (await client.post(
        base.resolve('/edit'),
        headers: headers,
        body: jsonEncode(body),
      )).statusCode,
      402,
    );
    expect(calls, 1);
  });
}
