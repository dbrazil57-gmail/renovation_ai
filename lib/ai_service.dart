import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiFailure implements Exception {
  final String message;
  const AiFailure(this.message);
  @override
  String toString() => message;
}

class AiResult {
  final Uint8List image;
  final String provider;
  final String model;
  final String? requestId;
  const AiResult({
    required this.image,
    required this.provider,
    required this.model,
    this.requestId,
  });
}

/// Only the local relay pairing code is held here, in memory. The provider API
/// key is never sent to the Flutter app or written to its project/photo store.
class AiService extends ChangeNotifier {
  final http.Client Function() clientFactory;
  String? _url;
  String? _pairingCode;
  String? model;
  String? quality;
  int maxInputImages = 1;
  bool get connected => _url != null;
  String get relayUrl => _url ?? 'http://127.0.0.1:8787';

  AiService({http.Client Function()? clientFactory})
    : clientFactory = clientFactory ?? http.Client.new;

  static Uri localRelay(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme != 'http' ||
        !['127.0.0.1', 'localhost', '10.0.2.2'].contains(uri.host) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const AiFailure(
        'Use a local relay address, such as http://127.0.0.1:8787.',
      );
    }
    return uri.replace(path: '');
  }

  Future<void> connect({
    required String url,
    required String pairingCode,
  }) async {
    final uri = localRelay(url);
    if (pairingCode.trim().isEmpty) {
      throw const AiFailure('Enter the connection code shown by the relay.');
    }
    final client = clientFactory();
    try {
      final response = await client
          .get(
            uri.resolve('/health'),
            headers: {'Authorization': 'Bearer ${pairingCode.trim()}'},
          )
          .timeout(const Duration(seconds: 8));
      final data = _readResponse(response);
      if (data['provider'] != 'OpenAI' ||
          data['model'] is! String ||
          data['quality'] is! String) {
        throw const AiFailure(
          'The relay returned an unsupported configuration.',
        );
      }
      _url = uri.toString();
      _pairingCode = pairingCode.trim();
      model = data['model'] as String;
      quality = data['quality'] as String;
      maxInputImages = data['maxInputImages'] is int
          ? (data['maxInputImages'] as int).clamp(1, 7)
          : 1;
      notifyListeners();
    } on AiFailure {
      rethrow;
    } catch (_) {
      throw const AiFailure(
        'Cannot reach the relay. Start it on your PC and check the address and connection code.',
      );
    } finally {
      client.close();
    }
  }

  void disconnect() {
    _url = null;
    _pairingCode = null;
    model = null;
    quality = null;
    maxInputImages = 1;
    notifyListeners();
  }

  Future<AiResult> edit({
    required Uint8List image,
    required String prompt,
    List<Uint8List> supportingImages = const [],
  }) async {
    if (!connected) {
      throw const AiFailure('Connect your local AI relay in Settings first.');
    }
    if (supportingImages.length + 1 > maxInputImages) {
      throw const AiFailure(
        'Restart the updated local relay and reconnect to send multiple room views.',
      );
    }
    if ([
          image,
          ...supportingImages,
        ].fold<int>(0, (size, bytes) => size + bytes.length) >
        36 * 1024 * 1024) {
      throw const AiFailure(
        'Selected room views exceed the 36 MB AI input limit. Use smaller photos or turn off other views.',
      );
    }
    final uri = Uri.parse(_url!).resolve('/edit');
    final code = _pairingCode!;
    final client = clientFactory();
    try {
      final response = await client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $code',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'image': base64Encode(image),
              'supportingImages': supportingImages.map(base64Encode).toList(),
              'prompt': prompt,
              'confirmed': true,
            }),
          )
          .timeout(const Duration(seconds: 210));
      final data = _readResponse(response);
      if (data['image'] is! String ||
          data['model'] is! String ||
          data['provider'] != 'OpenAI') {
        throw const AiFailure('The relay did not return a valid image result.');
      }
      final bytes = base64Decode(data['image'] as String);
      if (bytes.isEmpty) {
        throw const AiFailure('The AI returned an empty image.');
      }
      return AiResult(
        image: bytes,
        model: data['model'] as String,
        provider: 'OpenAI',
        requestId: data['requestId'] as String?,
      );
    } on AiFailure {
      rethrow;
    } on TimeoutException {
      throw const AiFailure(
        'The request timed out. It may still have been charged. Check provider usage before trying again; no automatic retry was made.',
      );
    } catch (_) {
      throw const AiFailure(
        'The connection was interrupted or the result could not be read. A charge may have occurred; check provider usage before trying again.',
      );
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> _readResponse(http.Response response) {
    if (response.statusCode != 200) {
      final message = switch (response.statusCode) {
        401 => 'Connection code rejected. Reconnect in Settings using the relay code.',
        402 => 'The AI key was rejected, billing is unavailable, or the model is not accessible. Check the relay terminal and your provider account.',
        413 => 'This image is too large for the local AI test.',
        429 => 'The relay or AI provider is busy or rate-limited. No automatic retry was made.',
        504 => 'The provider timed out. A charge may have occurred; check usage before retrying.',
        _ => 'AI generation failed. Your original and approved baseline are unchanged. Check your provider account before retrying.',
      };
      throw AiFailure(message);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AiFailure('Invalid relay response.');
    }
    return decoded;
  }
}
