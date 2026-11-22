import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'ai_photo_preparation.dart';
export 'ai_photo_preparation.dart' show prepareInternetPhotos;

import 'ai_activity.dart';
import 'ai_types.dart';
import 'room_analysis.dart';
import 'ai_usage.dart';
import 'ai_model_choices.dart';

const directImageModels = preferredRoomImageModels;

/// Direct, fixed-host HTTPS transport. No laptop route or automatic retry.
class OpenAiInternet {
  final http.Client Function() clientFactory;
  OpenAiInternet(this.clientFactory);
  static final Uri base = Uri.parse('https://api.openai.com/v1/');

  Map<String, dynamic> response(http.Response value) {
    if (value.statusCode != 200) {
      throw AiFailure(switch (value.statusCode) {
        401 => 'OpenAI rejected the API key. Replace it in AI settings.',
        403 => 'This API key does not have permission for the requested OpenAI service.',
        429 => 'OpenAI reported a usage, credit or rate limit. Check your API account before retrying.',
        400 || 404 => 'OpenAI rejected the requested model or options. Check model access and your selected settings.',
        >= 300 && < 400 => 'OpenAI returned a redirect. The key was not forwarded to another address.',
        _ =>
          'OpenAI could not complete the request (HTTP ${value.statusCode}). No automatic retry was sent.',
      });
    }
    final decoded = jsonDecode(value.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid response');
    }
    return decoded;
  }

  Future<List<String>> models(String key) async {
    final client = clientFactory();
    try {
      final request = http.Request('GET', base.resolve('models'))
        ..followRedirects = false
        ..headers['Authorization'] = 'Bearer $key';
      final upstream = await (() async => http.Response.fromStream(
        await client.send(request),
      ))().timeout(const Duration(seconds: 20));
      final payload = response(upstream);
      final data = payload['data'];
      if (data is! List) throw const FormatException('Missing models');
      return data
          .whereType<Map>()
          .map((item) => item['id'])
          .whereType<String>()
          .toList();
    } on AiFailure {
      rethrow;
    } catch (_) {
      throw const AiFailure(
        'Could not check the key with OpenAI over HTTPS. Check the internet connection and try again.',
      );
    } finally {
      client.close();
    }
  }

  Future<List<Uint8List>> photos(List<Uint8List> sources) =>
      internetPhotos(sources);

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
      final inputs = await photos(sources);
      final request =
          http.MultipartRequest('POST', base.resolve('images/edits'))
            ..followRedirects = false
            ..headers['Authorization'] = 'Bearer $key'
            ..fields.addAll({
              'model': model,
              'prompt': prompt,
              'quality': quality,
              'n': '1',
              'size': 'auto',
              'output_format': 'png',
            })
            ..files.addAll([
              for (final (index, bytes) in inputs.indexed)
                http.MultipartFile.fromBytes(
                  'image[]',
                  bytes,
                  filename: 'room-${index + 1}.png',
                  contentType: MediaType('image', 'png'),
                ),
            ]);
      onProgress?.call(AiStage.waiting);
      final upstream = await (() async => http.Response.fromStream(
        await client.send(request),
      ))().timeout(const Duration(seconds: 210));
      onProgress?.call(AiStage.reading);
      final payload = response(upstream);
      final data = payload['data'];
      final encoded = data is List && data.isNotEmpty && data.first is Map
          ? (data.first as Map)['b64_json']
          : null;
      if (encoded is! String || encoded.isEmpty) {
        throw const FormatException('Missing image');
      }
      final bytes = base64Decode(encoded);
      if (bytes.isEmpty) throw const FormatException('Empty image');
      return AiResult(
        image: bytes,
        provider: 'OpenAI',
        model: model,
        quality: quality,
        requestId: upstream.headers['x-request-id'],
        usage: payload['usage'] is Map
            ? AiUsage.openAi(payload['usage'] as Map, model)
            : null,
      );
    } on AiFailure {
      rethrow;
    } on TimeoutException {
      throw const AiFailure(
        'OpenAI image generation timed out. A charge may have occurred. Check usage before retrying; no automatic retry was sent.',
      );
    } catch (_) {
      throw const AiFailure(
        'The OpenAI image response could not be received or read. A charge may have occurred. Check usage before retrying.',
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
      final inputs = await photos(sources);
      final request = http.Request('POST', base.resolve('responses'))
        ..followRedirects = false
        ..headers.addAll({
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        })
        ..body = jsonEncode({
          'model': model,
          'store': false,
          'max_output_tokens': 3000,
          if (model.startsWith('gpt-6')) 'reasoning': {'effort': 'none'},
          'instructions': roomAnalysisInstructions,
          'input': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'input_text',
                  'text': 'User requirements and photo roles:\n$prompt',
                },
                for (final (index, bytes) in inputs.indexed) ...[
                  {
                    'type': 'input_text',
                    'text': index == 0
                        ? 'Image 1: working view.'
                        : 'Image ${index + 1}: supporting room angle.',
                  },
                  {
                    'type': 'input_image',
                    'image_url': 'data:image/png;base64,${base64Encode(bytes)}',
                    'detail': 'auto',
                  },
                ],
              ],
            },
          ],
          'text': {
            'format': {
              'type': 'json_schema',
              'name': 'room_analysis',
              'strict': true,
              'schema': roomAnalysisSchema,
            },
          },
        });
      onProgress?.call(AiStage.waiting);
      final upstream = await (() async => http.Response.fromStream(
        await client.send(request),
      ))().timeout(const Duration(seconds: 110));
      onProgress?.call(AiStage.reading);
      final data = response(upstream);
      if (data['status'] != 'completed' || data['output'] is! List) {
        throw const FormatException('Incomplete analysis');
      }
      final output = StringBuffer();
      for (final item in data['output'] as List) {
        if (item is! Map ||
            item['type'] != 'message' ||
            item['content'] is! List) {
          continue;
        }
        for (final part in item['content'] as List) {
          if (part is! Map) continue;
          if (part['type'] == 'refusal') {
            throw const AiFailure(
              'OpenAI did not return a room analysis. No design image was generated.',
            );
          }
          if (part['type'] == 'output_text' && part['text'] is String) {
            output.write(part['text']);
          }
        }
      }
      final result = RoomAnalysisResult.validateOutput(
        jsonDecode(output.toString()),
      );
      return RoomAnalysisResult.fromMap({
        ...result,
        'model': model,
        'requestId': upstream.headers['x-request-id'],
      });
    } on AiFailure {
      rethrow;
    } on TimeoutException {
      throw const AiFailure(
        'OpenAI room analysis timed out. A charge may have occurred. Check usage before retrying; no automatic retry was sent.',
      );
    } catch (_) {
      throw const AiFailure(
        'The OpenAI analysis response could not be received or read. Previous analysis is retained. Check usage before retrying.',
      );
    } finally {
      client.close();
    }
  }
}
