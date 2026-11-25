import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_activity.dart';
import 'ai_types.dart';
import 'ai_photo_preparation.dart';
import 'room_analysis.dart';
import 'ai_usage.dart';

/// Fixed Google HTTPS endpoint; single-turn generateContent requests.
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
        });

  Map<String, dynamic> _response(http.Response response) {
    if (response.statusCode != 200) {
      // Classify upstream details locally; never show or retain raw provider
      // messages, which can echo keys, request text or other private inputs.
      var problem = switch (response.statusCode) {
        401 => AiProblem.credentials,
        403 => AiProblem.permission,
        429 => AiProblem.quota,
        404 => AiProblem.model,
        400 => AiProblem.options,
        _ => AiProblem.unknown,
      };
      try {
        final data = jsonDecode(response.body);
        final error = data is Map ? data['error'] : null;
        if (error is Map) {
          final details = error['details'];
          final reasons = details is List
              ? details
                    .whereType<Map>()
                    .map((d) => d['reason'])
                    .whereType<String>()
                    .toSet()
              : <String>{};
          final message =
              (error['message'] is String ? error['message'] as String : '')
                  .toLowerCase();
          if (reasons.contains('API_KEY_INVALID') ||
              message.contains('api key not valid')) {
            problem = AiProblem.credentials;
          } else if (reasons.contains('BILLING_DISABLED') ||
              message.contains('billing is not enabled') ||
              message.contains('billing must be enabled')) {
            problem = AiProblem.billing;
          } else if (error['status'] == 'NOT_FOUND') {
            problem = AiProblem.model;
          }
        }
      } catch (_) {
        /* HTTP status remains available for non-JSON errors. */
      }
      final advice = switch (problem) {
        AiProblem.credentials =>
          'The API key was rejected. Replace it in AI settings.',
        AiProblem.permission =>
          'Check Gemini API access, key restrictions and account permissions.',
        AiProblem.billing =>
          'Enable billing for the Google API project attached to this key.',
        AiProblem.quota => 'Check API quota, billing and rate limits in Google AI Studio before retrying.',
        AiProblem.model => 'The selected model is unavailable for this request. Refresh models in AI settings and check model access in Google AI Studio.',
        AiProblem.options => 'Google rejected a request option. Copy AI diagnostics from Settings so the model and HTTP status can be checked.',
        _ =>
          'The request could not complete. Check AI diagnostics in Settings.',
      };
      throw AiFailure(
        'Gemini HTTP ${response.statusCode} (${problem.name}). $advice No automatic retry was sent.',
        problem: problem,
        statusCode: response.statusCode,
      );
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
          final methods = item['supportedGenerationMethods'];
          if (name is String &&
              name.startsWith('models/') &&
              (methods == null ||
                  methods is List && methods.contains('generateContent'))) {
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
        problem: AiProblem.network,
      );
    } finally {
      client.close();
    }
  }

  List<Map<String, dynamic>> _inputs(String prompt, List<Uint8List> images) => [
    {'text': prompt},
    for (final (index, image) in images.indexed) ...[
      {
        'text': index == 0
            ? 'Image 1: working view; retain its camera viewpoint.'
            : 'Image ${index + 1}: supporting room angle.',
      },
      {
        'inlineData': {'mimeType': 'image/png', 'data': base64Encode(image)},
      },
    ],
  ];

  List<Map> _output(Map<String, dynamic> data) {
    final feedback = data['promptFeedback'];
    if (feedback is Map && feedback['blockReason'] != null) {
      throw const AiFailure(
        'Gemini blocked this request. Review the photo and instructions before trying again. See AI diagnostics in Settings.',
        problem: AiProblem.blocked,
      );
    }
    final candidates = data['candidates'];
    if (candidates is! List ||
        candidates.length != 1 ||
        candidates.single is! Map) {
      throw const FormatException('Missing single candidate');
    }
    final candidate = candidates.single as Map;
    if ([
      'SAFETY',
      'IMAGE_SAFETY',
      'PROHIBITED_CONTENT',
      'BLOCKLIST',
      'RECITATION',
    ].contains(candidate['finishReason'])) {
      throw const AiFailure(
        'Gemini could not return this content. Review the photo and instructions. See AI diagnostics in Settings.',
        problem: AiProblem.blocked,
      );
    }
    if (candidate['finishReason'] != 'STOP') {
      throw const FormatException('Incomplete result');
    }
    final content = candidate['content'];
    if (content is! Map || content['parts'] is! List) {
      throw const FormatException('Missing parts');
    }
    return (content['parts'] as List)
        .whereType<Map>()
        .where((part) => part['thought'] != true)
        .toList();
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
      final request =
          _request('POST', base.resolve('models/$model:generateContent'), key)
            ..body = jsonEncode({
              'contents': [
                {'role': 'user', 'parts': _inputs(prompt, photos)},
              ],
              'generationConfig': {
                'responseModalities': ['TEXT', 'IMAGE'],
                'imageConfig': {'imageSize': size},
              },
            });
      onProgress?.call(AiStage.waiting);
      final response = await (() async => http.Response.fromStream(
        await client.send(request),
      ))().timeout(const Duration(seconds: 210));
      onProgress?.call(AiStage.reading);
      final data = _response(response);
      final images = _output(data)
          .map((part) => part['inlineData'])
          .whereType<Map>()
          .toList();
      if (images.length != 1 ||
          images.single['data'] is! String ||
          ![
            'image/png',
            'image/jpeg',
            'image/webp',
          ].contains(images.single['mimeType'])) {
        throw const FormatException('Missing single image');
      }
      final bytes = base64Decode(images.single['data'] as String);
      if (bytes.isEmpty) throw const FormatException('Empty image');
      return AiResult(
        image: bytes,
        provider: 'Gemini',
        model: model,
        quality: quality,
        requestId: data['responseId'] as String?,
        usage: data['usageMetadata'] is Map
            ? AiUsage.gemini(data['usageMetadata'] as Map)
            : null,
      );
    } on AiFailure {
      rethrow;
    } on TimeoutException {
      throw const AiFailure(
        'Gemini image generation timed out. A charge may have occurred. Check usage before retrying; no automatic retry was sent.',
        problem: AiProblem.timeout,
      );
    } on http.ClientException {
      throw const AiFailure(
        'The Gemini connection was interrupted. Check provider usage before retrying. No automatic retry was sent. See AI diagnostics in Settings.',
        problem: AiProblem.network,
      );
    } catch (_) {
      throw const AiFailure(
        'The Gemini image response could not be received or read. A charge may have occurred. Check usage before retrying. See AI diagnostics in Settings.',
        problem: AiProblem.invalidResponse,
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
      final request =
          _request('POST', base.resolve('models/$model:generateContent'), key)
            ..body = jsonEncode({
              'systemInstruction': {
                'parts': [
                  {'text': roomAnalysisInstructions},
                ],
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': _inputs(
                    'User requirements and photo roles:\n$prompt',
                    photos,
                  ),
                },
              ],
              'generationConfig': {
                'maxOutputTokens': 3000,
                'responseMimeType': 'application/json',
                'responseJsonSchema': roomAnalysisSchema,
              },
            });
      onProgress?.call(AiStage.waiting);
      final response = await (() async => http.Response.fromStream(
        await client.send(request),
      ))().timeout(const Duration(seconds: 110));
      onProgress?.call(AiStage.reading);
      final data = _response(response);
      final text = _output(data)
          .map((part) => part['text'])
          .whereType<String>()
          .join();
      final result = RoomAnalysisResult.validateOutput(jsonDecode(text));
      return RoomAnalysisResult.fromMap({
        ...result,
        'model': model,
        'provider': 'Gemini',
        'requestId': data['responseId'],
        'usage': data['usageMetadata'] is Map
            ? AiUsage.gemini(data['usageMetadata'] as Map).toMap()
            : null,
      });
    } on AiFailure {
      rethrow;
    } on TimeoutException {
      throw const AiFailure(
        'Gemini photo analysis timed out. A charge may have occurred. Check usage before retrying; no automatic retry was sent.',
        problem: AiProblem.timeout,
      );
    } on http.ClientException {
      throw const AiFailure(
        'The Gemini connection was interrupted. Previous analysis is retained. Check provider usage before retrying. See AI diagnostics in Settings.',
        problem: AiProblem.network,
      );
    } catch (_) {
      throw const AiFailure(
        'The Gemini analysis response could not be received or read. Previous analysis is retained. Check usage before retrying. See AI diagnostics in Settings.',
        problem: AiProblem.invalidResponse,
      );
    } finally {
      client.close();
    }
  }
}
