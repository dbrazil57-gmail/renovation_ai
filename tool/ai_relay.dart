import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;

/// Local development only. Binds to loopback, accepts local browser origins,
/// requires a random pairing code, and never logs keys, prompts or image bytes.
class AiRelay {
  final String apiKey;
  final String pairingCode;
  final String model;
  final String quality;
  final http.Client Function() clientFactory;
  bool _busy = false;

  AiRelay({
    required this.apiKey,
    required this.pairingCode,
    this.model = 'gpt-image-2.5-sunburst',
    this.quality = 'low',
    http.Client Function()? clientFactory,
  }) : clientFactory = clientFactory ?? http.Client.new;

  Future<void> handle(HttpRequest request) async {
    final response = request.response;
    response.headers.set('Cache-Control', 'no-store');
    final origin = request.headers.value('Origin');
    final host = Uri.tryParse('http://${request.headers.value('Host') ?? ''}')
        ?.host;
    if (!['127.0.0.1', 'localhost', '10.0.2.2'].contains(host)) {
      await _reply(response, 403, {'error': 'Local host required.'});
      return;
    }
    if (origin != null) {
      final uri = Uri.tryParse(origin);
      if (uri == null ||
          uri.scheme != 'http' ||
          !['localhost', '127.0.0.1'].contains(uri.host)) {
        await _reply(response, 403, {
          'error': 'Local browser origin required.',
        });
        return;
      }
      response.headers.set('Access-Control-Allow-Origin', origin);
      response.headers.set('Vary', 'Origin');
      response.headers.set(
        'Access-Control-Allow-Methods',
        'GET, POST, OPTIONS',
      );
      response.headers.set(
        'Access-Control-Allow-Headers',
        'Authorization, Content-Type',
      );
    }
    if (request.method == 'OPTIONS') {
      response.statusCode = 204;
      await response.close();
      return;
    }
    if (request.headers.value('Authorization') != 'Bearer $pairingCode') {
      await _reply(response, 401, {'error': 'Invalid relay code.'});
      return;
    }
    if (request.uri.path == '/health' && request.method == 'GET') {
      await _reply(response, 200, {
        'provider': 'OpenAI',
        'model': model,
        'quality': quality,
        'maxInputImages': 7,
      });
      return;
    }
    if (request.uri.path != '/edit' || request.method != 'POST') {
      await _reply(response, 404, {'error': 'Not found.'});
      return;
    }
    if (_busy) {
      await _reply(response, 429, {'error': 'One edit is already running.'});
      return;
    }
    _busy = true;
    try {
      final chunks = <int>[];
      await for (final chunk in request.timeout(const Duration(seconds: 15))) {
        if (chunks.length + chunk.length > 50 * 1024 * 1024) {
          await _reply(response, 413, {'error': 'Image too large.'});
          return;
        }
        chunks.addAll(chunk);
      }
      final data = jsonDecode(utf8.decode(chunks));
      if (data is! Map ||
          data['confirmed'] != true ||
          data['image'] is! String ||
          data['prompt'] is! String ||
          (data['prompt'] as String).trim().isEmpty ||
          (data['prompt'] as String).length > 16000) {
        await _reply(response, 400, {
          'error': 'Image, prompt and confirmation required.',
        });
        return;
      }
      final supporting = data['supportingImages'] ?? const [];
      if (supporting is! List ||
          supporting.length > 6 ||
          supporting.any((item) => item is! String)) {
        await _reply(response, 400, {'error': 'Choose up to 7 input views.'});
        return;
      }
      final sources = [
        data['image'] as String,
        ...supporting.cast<String>(),
      ].map(base64Decode).toList();
      if (sources.any(
            (bytes) => bytes.isEmpty || bytes.length > 18 * 1024 * 1024,
          ) ||
          sources.fold<int>(0, (size, bytes) => size + bytes.length) >
              36 * 1024 * 1024) {
        await _reply(response, 413, {'error': 'Image too large.'});
        return;
      }
      final inputs = <List<int>>[];
      for (final bytes in sources) {
        var image = img.decodeImage(bytes);
        if (image == null) {
          await _reply(response, 400, {'error': 'Unsupported image.'});
          return;
        }
        // Prepare a metadata-free working copy, never change stored originals.
        if (max(image.width, image.height) > 2048) {
          image = image.width >= image.height
              ? img.copyResize(image, width: 2048)
              : img.copyResize(image, height: 2048);
        }
        image.exif = img.ExifData();
        image.iccProfile = null;
        image.textData?.clear();
        inputs.add(img.encodePng(image));
      }
      final client = clientFactory();
      try {
        final edit =
            http.MultipartRequest(
                'POST',
                Uri.parse('https://api.openai.com/v1/images/edits'),
              )
              ..headers['Authorization'] = 'Bearer $apiKey'
              ..fields.addAll({
                'model': model,
                'prompt': data['prompt'] as String,
                'n': '1',
                'quality': quality,
                'size': 'auto',
                'output_format': 'png',
              })
              ..files.addAll([
                for (final (index, input) in inputs.indexed)
                  http.MultipartFile.fromBytes(
                    'image[]',
                    input,
                    filename: 'room-${index + 1}.png',
                    contentType: MediaType('image', 'png'),
                  ),
              ]);
        final upstream = await (() async => http.Response.fromStream(
          await client.send(edit),
        ))().timeout(const Duration(seconds: 180));
        if (upstream.statusCode != 200) {
          final status = [400, 401, 403].contains(upstream.statusCode)
              ? 402
              : upstream.statusCode == 429
              ? 429
              : 502;
          stderr.writeln(
            'OpenAI edit failed (HTTP ${upstream.statusCode}). Check key, model access, billing or usage limits.',
          );
          await _reply(response, status, {'error': 'Provider request failed.'});
          return;
        }
        final result = jsonDecode(upstream.body) as Map;
        final outputs = result['data'];
        final encoded =
            outputs is List && outputs.isNotEmpty && outputs.first is Map
            ? (outputs.first as Map)['b64_json']
            : null;
        if (encoded is! String || encoded.isEmpty) {
          await _reply(response, 502, {'error': 'No image returned.'});
          return;
        }
        await _reply(response, 200, {
          'image': encoded,
          'provider': 'OpenAI',
          'model': model,
          'requestId': upstream.headers['x-request-id'],
        });
      } finally {
        client.close();
      }
    } on TimeoutException {
      await _reply(response, 504, {
        'error': 'Timed out. Check usage before retrying.',
      });
    } on FormatException {
      await _reply(response, 400, {'error': 'Invalid request.'});
    } catch (_) {
      await _reply(response, 502, {
        'error': 'Edit failed. No automatic retry.',
      });
    } finally {
      _busy = false;
    }
  }

  Future<void> _reply(
    HttpResponse response,
    int status,
    Map<String, dynamic> data,
  ) async {
    try {
      response.statusCode = status;
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode(data));
      await response.close();
    } catch (_) {
      /* The local browser may have closed the connection. */
    }
  }
}

Future<void> main() async {
  final key = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';
  if (key.isEmpty) {
    stderr.writeln(
      'No API key configured. Run tool/start_ai_relay.ps1 to enter it privately.',
    );
    exitCode = 1;
    return;
  }
  final random = Random.secure();
  final code = base64UrlEncode(List.generate(32, (_) => random.nextInt(256)));
  final relay = AiRelay(
    apiKey: key,
    pairingCode: code,
    model:
        Platform.environment['RENOVISION_IMAGE_MODEL'] ??
        'gpt-image-2.5-sunburst',
    quality: 'low',
  );
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8787);
  stdout.writeln('Renovision local AI relay: http://127.0.0.1:8787');
  stdout.writeln('Connection code (enter in app Settings): $code');
  stdout.writeln(
    'Model: ${relay.model}; quality: low; one image per button press.',
  );
  stdout.writeln(
    'The key stays on this PC. Images are sent to OpenAI only for confirmed edits.',
  );
  await for (final request in server) {
    unawaited(relay.handle(request));
  }
}
