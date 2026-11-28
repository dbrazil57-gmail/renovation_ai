import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'ai_relay.dart';

String invitationHash(String token) =>
    sha256.convert(utf8.encode(token)).toString();

/// Single-process durable ledger. Persist-before-forward, with no automatic
/// refunds/retries after uncertain provider failures. Amounts count attempts.
class TesterLedger {
  Map<String, dynamic> data;
  final Future<void> Function(Map<String, dynamic>) persist;
  Future<void> _queue = Future.value();
  TesterLedger(this.data, this.persist);
  Map<String, dynamic> balance(String hash) {
    final person = (data['testers'] as Map)[hash];
    if (person is! Map ||
        person['revoked'] == true ||
        !DateTime.parse(person['expires'] as String)
            .isAfter(DateTime.now().toUtc())) {
      throw const FormatException('Invitation unavailable');
    }
    return {
      'analyses': min(person['analyses'] as int, data['analyses'] as int),
      'designs': min(person['designs'] as int, data['designs'] as int),
      'expires': person['expires'],
    };
  }

  Future<void> reserve(String hash, String requestId, bool analysis) {
    final done = Completer<void>();
    _queue = _queue.catchError((_) {}).then((_) async {
      try {
        final key = analysis ? 'analyses' : 'designs';
        if ((balance(hash)[key] as int) < 1) {
          throw const FormatException('Allowance exhausted');
        }
        final marker = '$hash:$requestId';
        if ((data['attempted'] as Map).containsKey(marker)) {
          throw const FormatException('Request already attempted');
        }
        if ((data['attempted'] as Map).length >= 50000) {
          throw const FormatException('Ledger maintenance required');
        }
        final next = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
        next[key] = (next[key] as int) - 1;
        final person = (next['testers'] as Map)[hash] as Map;
        person[key] = (person[key] as int) - 1;
        (next['attempted'] as Map)[marker] = DateTime.now()
            .toUtc()
            .toIso8601String();
        await persist(next); // If storage fails, the provider is never called.
        data = next;
        done.complete();
      } catch (e, stack) {
        done.completeError(e, stack);
      }
    });
    return done.future;
  }
}

class TesterGateway {
  final TesterLedger ledger;
  final Uri upstream;
  final String upstreamCode, model, quality, analysisModel;
  final Set<String> browserOrigins;
  bool _busy = false;
  TesterGateway({
    required this.ledger,
    required this.upstream,
    required this.upstreamCode,
    required this.model,
    required this.quality,
    required this.analysisModel,
    this.browserOrigins = const {},
  });
  Future<void> handle(HttpRequest request) async {
    final response = request.response;
    response.headers.set('Cache-Control', 'no-store');
    Future<void> reply(int status, Map<String, dynamic> body) async {
      response.statusCode = status;
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode(body));
      await response.close();
    }

    if (request.headers.value('x-forwarded-proto') != 'https') {
      await reply(403, {'error': 'HTTPS proxy required'});
      return;
    }
    final origin = request.headers.value('origin');
    if (origin != null) {
      if (!browserOrigins.contains(origin)) {
        await reply(403, {'error': 'Origin unavailable'});
        return;
      }
      response.headers.set('Access-Control-Allow-Origin', origin);
      response.headers.set('Vary', 'Origin');
      response.headers.set(
        'Access-Control-Allow-Headers',
        'Authorization, Content-Type',
      );
      response.headers.set(
        'Access-Control-Allow-Methods',
        'GET, POST, OPTIONS',
      );
    }
    if (request.method == 'OPTIONS') {
      response.statusCode = 204;
      await response.close();
      return;
    }
    final auth = request.headers.value('authorization') ?? '';
    if (!auth.startsWith('Bearer ') || auth.length < 39 || auth.length > 520) {
      await reply(401, {'error': 'Private invitation required'});
      return;
    }
    final hash = invitationHash(auth.substring(7));
    Map<String, dynamic> credits;
    try {
      credits = ledger.balance(hash);
    } catch (_) {
      await reply(403, {'error': 'Invitation unavailable'});
      return;
    }
    Map<String, dynamic> receiptBalance() {
      try {
        return ledger.balance(hash);
      } catch (_) {
        return {...credits, 'analyses': 0, 'designs': 0};
      }
    }

    if (request.uri.path == '/health' && request.method == 'GET') {
      await reply(200, {
        'service': 'renovision.tester.v1',
        'provider': 'OpenAI',
        'model': model,
        'quality': quality,
        'analysisModel': analysisModel,
        'credits': credits,
      });
      return;
    }
    if (request.method != 'POST' ||
        !const ['/edit', '/analyse'].contains(request.uri.path)) {
      await reply(404, {'error': 'Not found'});
      return;
    }
    if (_busy) {
      await reply(429, {
        'error': 'One test request is already running',
        'credits': credits,
      });
      return;
    }
    _busy = true;
    final client = http.Client();
    try {
      final bytes = <int>[];
      await for (final part in request.timeout(const Duration(seconds: 15))) {
        if (bytes.length + part.length > 50 * 1024 * 1024) {
          throw const FormatException('Input too large');
        }
        bytes.addAll(part);
      }
      final body = jsonDecode(utf8.decode(bytes));
      if (body is! Map ||
          body['confirmed'] != true ||
          body['image'] is! String ||
          body['prompt'] is! String ||
          (body['prompt'] as String).isEmpty ||
          (body['prompt'] as String).length > 16000 ||
          body['requestId'] is! String ||
          !RegExp(r'^[a-f0-9]{48}$').hasMatch(body['requestId'] as String)) {
        throw const FormatException('Invalid confirmed request');
      }
      final support = body['supportingImages'] ?? [];
      if (support is! List ||
          support.length > 6 ||
          support.any((v) => v is! String)) {
        throw const FormatException('Invalid views');
      }
      final sources = [
        body['image'],
        ...support,
      ].map((v) => base64Decode(v as String)).toList();
      if (sources.any((b) => b.isEmpty || b.length > 18 * 1024 * 1024) ||
          sources.fold<int>(0, (sum, b) => sum + b.length) > 36 * 1024 * 1024) {
        throw const FormatException('Input too large');
      }
      final analysis = request.uri.path == '/analyse';
      if (!analysis && (body['model'] != model || body['quality'] != quality)) {
        throw const FormatException('Fixed test model required');
      }
      await ledger.reserve(hash, body['requestId'] as String, analysis);
      // No client-selected URLs, provider credentials, prices or model upgrades.
      final forwarded = http.Request('POST', upstream.resolve(request.uri.path))
        ..followRedirects = false
        ..headers.addAll({
          'Authorization': 'Bearer $upstreamCode',
          'Content-Type': 'application/json',
        })
        ..body = jsonEncode({
          'image': body['image'],
          'supportingImages': support,
          'prompt': body['prompt'],
          'confirmed': true,
          'model': model,
          'quality': quality,
        });
      final result = await http.Response.fromStream(
        await client.send(forwarded),
      ).timeout(const Duration(seconds: 220));
      final payload = jsonDecode(result.body);
      await reply(result.statusCode, {
        ...(payload as Map).cast<String, dynamic>(),
        'credits': receiptBalance(),
      });
    } on FormatException {
      await reply(402, {
        'error': 'Invalid, repeated or exhausted test request',
        'credits': receiptBalance(),
      });
    } catch (_) {
      await reply(502, {
        'error': 'Test attempt failed; no automatic refund or retry',
        'credits': receiptBalance(),
      });
    } finally {
      _busy = false;
      client.close();
    }
  }
}

Future<void> main() async {
  final env = Platform.environment;
  final key = env['OPENAI_API_KEY'], path = env['RENOVISION_TESTER_LEDGER'];
  if (env['RENOVISION_ENABLE_TESTER_SERVICE'] != '1' ||
      key == null ||
      path == null) {
    stderr.writeln(
      'Not activated. Supply the private provider key, durable ledger path and explicit enable flag.',
    );
    exitCode = 1;
    return;
  }
  final file = File(path),
      data =
          jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
  final ledger = TesterLedger(data, (next) async {
    final pending = File('$path.pending');
    await pending.writeAsString(jsonEncode(next), flush: true);
    await pending.rename(file.path);
  });
  final code = List.generate(
    32,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  final relay = AiRelay(
    apiKey: key,
    pairingCode: code,
    model: env['RENOVISION_TESTER_MODEL'] ?? 'gpt-image-2.6-sunburst',
    quality: 'low',
  );
  final internal = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  internal.listen(relay.handle);
  final gateway = TesterGateway(
    ledger: ledger,
    upstream: Uri.parse('http://127.0.0.1:${internal.port}'),
    upstreamCode: code,
    model: relay.model,
    quality: relay.quality,
    analysisModel: relay.analysisModel,
    browserOrigins: (env['RENOVISION_TESTER_ORIGINS'] ?? '')
        .split(',')
        .where((v) => v.isNotEmpty)
        .toSet(),
  );
  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    int.parse(env['RENOVISION_TESTER_PORT'] ?? '8788'),
  );
  server.listen(gateway.handle);
  stdout.writeln(
    'RenoImagineAI tester service listens on loopback behind a required HTTPS proxy. Single process; request allowances are not a dollar billing cap.',
  );
}
