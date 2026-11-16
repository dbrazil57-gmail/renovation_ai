import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void main() {
  test('remembered local connection and model restore with health calls only; credentials never enter project files', () async {
    final records = MemoryBox(), photos = MemoryBox();
    final paths = <String>[];
    AiService service() => AiService(
      clientFactory: () => MockClient((request) async {
        paths.add(request.url.path);
        expect(request.headers['Authorization'], 'Bearer synthetic-pairing');
        return http.Response(
          jsonEncode({
            'provider': 'OpenAI',
            'model': 'default',
            'quality': 'low',
            'imageModels': ['default', 'chosen'],
            'imageQualities': ['low', 'high'],
          }),
          200,
        );
      }),
    );
    final first = RenovisionStore(
      records: records,
      photos: photos,
      ai: service(),
    );
    await first.ai.connect(
      url: 'http://127.0.0.1:8787',
      pairingCode: 'synthetic-pairing',
    );
    first.ai.selectImageSettings(imageModel: 'chosen', imageQuality: 'high');
    await Future<void>.delayed(Duration.zero);
    final project = await first.createProject('Portable');
    await first.createRoom(
      projectId: project.id,
      name: 'Office',
      originalImage: Uint8List.fromList([1, 2]),
    );
    expect(
      utf8.decode(first.backupFor(project.id).encode()),
      isNot(contains('synthetic-pairing')),
    );
    first.dispose();
    final next = RenovisionStore(
      records: records,
      photos: photos,
      ai: service(),
    );
    await next.restoreAiConnection();
    expect(next.ai.connected, isTrue);
    expect(next.ai.model, 'chosen');
    expect(next.ai.quality, 'high');
    expect(paths, ['/health', '/health']);
    next.ai.disconnect();
    await Future<void>.delayed(Duration.zero);
    expect(records.get('settings:ai_connection'), isNull);
    next.dispose();
  });

  test(
    'unavailable relay keeps remembered settings and shows a reconnect message',
    () async {
      final records = MemoryBox();
      await records.put('settings:ai_connection', {
        'url': 'http://localhost:8787',
        'pairingCode': 'synthetic-old-code',
      });
      final store = RenovisionStore(
        records: records,
        photos: MemoryBox(),
        ai: AiService(
          clientFactory: () =>
              MockClient((_) async => http.Response('{}', 401)),
        ),
      );
      await store.restoreAiConnection();
      expect(store.ai.connected, isFalse);
      expect(store.ai.relayUrl, 'http://localhost:8787');
      expect(store.ai.connectionNotice, contains('reconnect'));
      expect(
        (records.get('settings:ai_connection') as Map)['pairingCode'],
        'synthetic-old-code',
      );
      store.dispose();
    },
  );
}
