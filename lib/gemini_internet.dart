import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_activity.dart';
import 'ai_types.dart';
import 'ai_photo_preparation.dart';
import 'room_analysis.dart';
import 'ai_usage.dart';

/// Fixed Google HTTPS endpoint; stateless Interactions API (2026-05-20).
/// No automatic retries, URL keys, remote image downloads or provider fallback.
class GeminiInternet {
  final http.Client Function() clientFactory;
  GeminiInternet(this.clientFactory);
  static final base = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/',
  );

  http.Request _request(String method, Uri uri, String key) =>
      http.Request(method, uri)
        ..followRedirects = false
        ..headers.addAll({
          'x-goog-api-key': key,
          'Content-Type': 'application/json',
          'Api-Revision': '2026-05-20',
        });

  Map<String, dynamic> _response(http.Response response) {
    if (response.statusCode != 200) {
      throw AiFailure(switch (response.statusCode) {
        401 => 'Gemini rejected the API key. Replace it in AI settings.',
        403 => 'This Google API key lacks permission. Check Gemini API access, key restrictions and your account.',
        429 => 'Gemini reported a quota, credit or rate limit. Check your Google API account before retrying.',
        400 || 404 => 'Gemini rejected the requested model or options. Check model access and your selected settings.',
        >= 300 && < 400 => 'Gemini returned a redirect. The key was not forwarded to another address.',
        _ =>
          'Gemini could not complete the request (HTTP ${response.statusCode}). No automatic retry was sent.',
      });
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid response');
    }
    return data;
  }

  Future<List<String>> models(String key) async {
    final client = clientFactory();
    try {
      final models = <String>{};
      final visited = <String>{};
      String? token;
      do {
        final request = _request(
          'GET',
          base
              .resolve('models')
              .replace(
                queryParameters: {'pageSize': '1000', 'pageToken': ?token},
              ),
          key,
        );
        final data = _response(
          await (() async => http.Response.fromStream(
            await client.send(request),
          ))().timeout(const Duration(seconds: 20)),
        );
        final listed = data['models'];
        if (listed is! List) throw const FormatException('Missing models');
        for (final item in listed.whereType<Map>()) {
          final name = item['name'];
          if (name is String && name.startsWith('models/')) {
            models.add(name.substring(7));
          }
        }
        token = data['nextPageToken'] as String?;
        if (token != null &&
            token.isNotEmpty &&
            (!visited.add(token) || visited.length > 10)) {
          throw const FormatException('Invalid model pagination');
        }
      } while (token != null && token.isNotEmpty);
      return models.toList();
    } on AiFailure {
      rethrow;
    } catch (_) {
      throw const AiFailure(
        'Could not check the key with Gemini over HTTPS. Check the internet connection and try again.',
      );
    } finally {
      client.close();
    }
  }

  List<Map<String, String>> _inputs(String prompt, List<Uint8List> images) => [
    {'type': 'text', 'text': prompt},
    for (final (index, image) in images.indexed) ...[
      {
        'type': 'text',
        'text': index == 0
            ? 'Image 1: working view; retain its camera viewpoint.'
            : 'Image ${index + 1}: supporting room angle.',
      },
      {'type': 'image', 'mime_type': 'image/png', 'data': base64Encode(image)},
    ],
  ];

  List<Map> _output(Map<String, dynamic> data) {
    if (data['status'] != 'completed' || data['steps'] is! List) {
      throw const FormatException('Incomplete interaction');
    }
    // Ignore thoughts and intermediate/tool content, even when they contain images.
    return [
      for (final step in (data['steps'] as List).whereType<Map>())
        if (step['type'] == 'model_output' && step['content'] is List)
          ...(step['content'] as List).whereType<Map>(),
    ];
  }

  Future<AiResult> edit({
    required String key,
    required String prompt,
    required String model,
    required String quality,
    required List<Uint8List> sources,
    void Function(AiStage)? onProgress,
  }) async {
    final client = clientFactory();
    try {
      onProgress?.call(AiStage.preparing);
      final photos = await internetPhotos(sources);
      final size = switch (quality) {
        'low' => '1K',
        'medium' => '2K',
        'high' => '4K',
        _ => throw const AiFailure('Choose an available Gemini resolution.'),
      };
      final request = _request('POST', base.resolve('interactions'), key)
        ..body = jsonEncode({
          'model': model,
          'store': false,
          'input': _inputs(prompt, photos),
          'response_format': {
            'type': 'image',
            'image_size': size,
            'mime_type': 'image/png',
          },
        });
      onProgress?.call(AiStage.waiting);
      final response = await (() async => http.Response.fromStream(
        await client.send(request),
      ))().timeout(const Duration(seconds: 210));
      onProgress?.call(AiStage.reading);
      final data = _response(response);
      final images = _output(data)
          .where((part) => part['type'] == 'image')
          .toList();
      if (images.length != 1 ||
          images.single['data'] is! String ||
          ![
            'image/png',
            'image/jpeg',
            'image/webp',
          ].contains(images.single['mime_type'])) {
        throw const FormatException('Missing single image');
      }
      final bytes = base64Decode(images.single['data'] as String);
      if (bytes.isEmpty) throw const FormatException('Empty image');
      return AiResult(
        image: bytes,
        provider: 'Gemini',
        model: model,
        quality: quality,
        requestId: data['id'] as String?,
        usage: data['usage'] is Map
            ? AiUsage.gemini(data['usage'] as Map)
            : null,
      );
    } on AiFailure {
      rethrow;
    } on TimeoutException {
      throw const AiFailure(
        'Gemini image generation timed out. A charge may have occurred. Check usage before retrying; no automatic retry was sent.',
      );
    } catch (_) {
      throw const AiFailure(
        'The Gemini image response could not be received or read. A charge may have occurred. Check usage before retrying.',
      );
    } finally {
      client.close();
    }
  }

  Future<RoomAnalysisResult> analyse({
    required String key,
    required String model,
    required String prompt,
    required List<Uint8List> sources,
    void Function(AiStage)? onProgress,
  }) async {
    final client = clientFactory();
    try {
      onProgress?.call(AiStage.preparing);
      final photos = await internetPhotos(sources);
      final request = _request('POST', base.resolve('interactions'), key)
        ..body = jsonEncode({
          'model': model,
          'store': false,
          'system_instruction': roomAnalysisInstructions,
          'input': _inputs(
            'User requirements and photo roles:\n$prompt',
            photos,
          ),
          'generation_config': {'max_output_tokens': 3000},
          'response_format': {
            'type': 'text',
            'mime_type': 'application/json',
            'schema': roomAnalysisSchema,
          },
        });
      onProgress?.call(AiStage.waiting);
      final response = await (() async => http.Response.fromStream(
        await client.send(request),
      ))().timeout(const Duration(seconds: 110));
      onProgress?.call(AiStage.reading);
      final data = _response(response);
      final text = _output(data)
          .where((part) => part['type'] == 'text')
          .map((part) => part['text'])
          .whereType<String>()
          .join();
      final result = RoomAnalysisResult.validateOutput(jsonDecode(text));
      return RoomAnalysisResult.fromMap({
        ...result,
        'model': model,
        'provider': 'Gemini',
        'requestId': data['id'],
        'usage': data['usage'] is Map
            ? AiUsage.gemini(data['usage'] as Map).toMap()
            : null,
      });
    } on AiFailure {
      rethrow;
    } on TimeoutException {
      throw const AiFailure(
        'Gemini photo analysis timed out. A charge may have occurred. Check usage before retrying; no automatic retry was sent.',
      );
    } catch (_) {
      throw const AiFailure(
        'The Gemini analysis response could not be received or read. Previous analysis is retained. Check usage before retrying.',
      );
    } finally {
      client.close();
    }
  }
}
