import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/secret_store.dart';
import 'package:renovision_ai/tester_access.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void main() {
  final token = List.filled(64, 'a').join();
  final expiry = DateTime.now()
      .toUtc()
      .add(const Duration(days: 30))
      .toIso8601String();
  Map<String, dynamic> health({int designs = 1}) => {
    'service': 'renovision.tester.v1',
    'provider': 'OpenAI',
    'model': 'gpt-image-2.6-sunburst',
    'quality': 'low',
    'analysisModel': 'test-analysis',
    'credits': {'analyses': 1, 'designs': designs, 'expires': expiry},
  };
  test('tester access uses HTTPS, keeps invitations out of settings/backups and restores by vault/health only', () async {
    final vault = SessionSecretStore(), personal = SessionSecretStore();
    await personal.write('personal-key-marker');
    final requests = <String>[];
    AiService service() => AiService(
      testerKeyStore: vault,
      keyStore: personal,
      clientFactory: () => MockClient((request) async {
        requests.add(request.url.path);
        expect(request.headers['authorization'], 'Bearer $token');
        expect(request.followRedirects, false);
        return http.Response(jsonEncode(health()), 200);
      }),
    );
    final records = MemoryBox(), photos = MemoryBox();
    final first = RenovisionStore(
      records: records,
      photos: photos,
      ai: service(),
    );
    await first.ai.restoreConnection({
      'mode': 'direct',
      'provider': 'openai',
      'model': 'gpt-image-2.6-flare',
      'quality': 'high',
      'imageModels': ['gpt-image-2.6-flare'],
    });
    await first.ai.connectTester(
      url: 'https://trial.example.test',
      invitation: token,
    );
    await Future<void>.delayed(Duration.zero);
    expect(first.ai.isTester, true);
    expect(jsonEncode(first.ai.rememberedConnection), isNot(contains(token)));
    final project = await first.createProject('Private');
    await first.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: Uint8List.fromList([1, 2]),
    );
    expect(
      utf8.decode(first.backupFor(project.id).encode()),
      isNot(contains(token)),
    );
    first.dispose();
    final next = RenovisionStore(
      records: records,
      photos: photos,
      ai: service(),
    );
    addTearDown(next.dispose);
    await next.restoreAiConnection();
    expect(next.ai.isTester, true);
    final preferences =
        next.ai.rememberedConnection!['providerSettings'] as Map;
    expect(preferences['openai']['model'], 'gpt-image-2.6-flare');
    expect(preferences['openai']['quality'], 'high');
    expect(requests, ['/health', '/health']);
    await next.ai.disconnect();
    expect(await vault.read(), isNull);
    expect(await personal.read(), 'personal-key-marker');
  });
  test('test credits update after one confirmed attempt, zero blocks more sends and requests do not follow redirects', () async {
    var edits = 0;
    final source = img.Image(width: 10, height: 10)
      ..textData = {'Comment': 'private-location-marker'};
    final original = img.encodePng(source);
    final ai = AiService(
      clientFactory: () => MockClient((request) async {
        expect(request.followRedirects, false);
        if (request.method == 'GET') {
          return http.Response(jsonEncode(health()), 200);
        }
        edits++;
        final body = jsonDecode(request.body) as Map;
        expect(body['confirmed'], true);
        expect(body['requestId'], matches(RegExp(r'^[0-9a-f]{48}$')));
        final prepared = img.decodeImage(
          base64Decode(body['image'] as String),
        )!;
        expect(
          prepared.textData?.values.join(),
          isNot(contains('private-location-marker')),
        );
        return http.Response(
          jsonEncode({
            ...health(designs: 0),
            'image': base64Encode([1, 2, 3]),
          }),
          200,
        );
      }),
    );
    addTearDown(ai.dispose);
    await ai.connectTester(
      url: 'https://trial.example.test',
      invitation: token,
    );
    await ai.edit(image: original, prompt: 'Modernise');
    expect(ai.testerAllowance!.designs, 0);
    await expectLater(
      ai.edit(image: Uint8List.fromList([1]), prompt: 'Again'),
      throwsA(isA<AiFailure>()),
    );
    expect(edits, 1);
  });
  test('invalid/expired/revoked invitations and insecure endpoints never activate a test connection', () async {
    for (final url in [
      'http://example.test',
      'https://localhost',
      'https://127.0.0.1',
      'https://example.test/path',
      'https://user:secret@example.test',
    ]) {
      expect(() => testerServiceUri(url), throwsA(isA<AiFailure>()));
    }
    final ai = AiService(
      clientFactory: () => MockClient((_) async => http.Response('{}', 403)),
    );
    addTearDown(ai.dispose);
    await expectLater(
      ai.connectTester(url: 'https://trial.example.test', invitation: token),
      throwsA(isA<AiFailure>()),
    );
    expect(ai.connected, false);
    expect(
      () => TesterAllowance.fromMap({
        'analyses': -1,
        'designs': 2,
        'expires': expiry,
      }),
      throwsA(isA<AiFailure>()),
    );
  });
}
