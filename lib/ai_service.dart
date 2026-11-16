import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'room_analysis.dart';

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
  final String? quality;
  const AiResult({
    required this.image,
    required this.provider,
    required this.model,
    this.requestId,
    this.quality,
  });
}

/// Only the local relay pairing code is held here, in memory. The provider API
/// key is never sent to the Flutter app or written to its project/photo store.
class AiService extends ChangeNotifier {
  final http.Client Function() clientFactory;
  Map<String, dynamic>? get rememberedConnection => _url == null
      ? null
      : {
          'url': _url,
          'pairingCode': _pairingCode,
          'model': model,
          'quality': quality,
        };
  String? connectionNotice;
  String _preferredUrl = 'http://127.0.0.1:8787';
  String? _url;
  String? _pairingCode;
  String? model;
  String? quality;
  String? analysisModel;
  List<String> imageModels = const [];
  List<String> imageQualities = const [];
  bool get supportsAnalysis => connected && analysisModel != null;
  int maxInputImages = 1;
  bool get connected => _url != null;
  String get relayUrl => _url ?? _preferredUrl;

  Future<void> restoreConnection(Map saved) async {
    final url = saved['url'];
    final code = saved['pairingCode'];
    if (url is! String || code is! String) return;
    try {
      localRelay(url);
      _preferredUrl = url;
      await connect(url: url, pairingCode: code);
      if (imageModels.contains(saved['model']) &&
          imageQualities.contains(saved['quality'])) {
        selectImageSettings(
          imageModel: saved['model'] as String,
          imageQuality: saved['quality'] as String,
        );
      }
      connectionNotice =
          'Saved local AI connection restored. No images were sent.';
    } catch (_) {
      connectionNotice = 'Saved AI settings found. Start the relay, then reconnect; a restarted relay may have a new code.';
    }
    notifyListeners();
  }

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
      _preferredUrl = _url!;
      connectionNotice = null;
      _pairingCode = pairingCode.trim();
      model = data['model'] as String;
      quality = data['quality'] as String;
      imageModels = {
        model!,
        ...?((data['imageModels'] as List?)?.whereType<String>()),
      }.toList();
      imageQualities = {
        quality!,
        ...?((data['imageQualities'] as List?)?.whereType<String>()),
      }.toList();
      analysisModel =
          data['analysisModel'] is String &&
              (data['analysisModel'] as String).trim().isNotEmpty
          ? data['analysisModel'] as String
          : null;
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
    analysisModel = null;
    imageModels = const [];
    imageQualities = const [];
    maxInputImages = 1;
    notifyListeners();
  }

  void selectImageSettings({
    required String imageModel,
    required String imageQuality,
  }) {
    if (!connected ||
        !imageModels.contains(imageModel) ||
        !imageQualities.contains(imageQuality)) {
      throw const AiFailure(
        'Choose a model and quality offered by the connected relay.',
      );
    }
    model = imageModel;
    quality = imageQuality;
    notifyListeners();
  }

  Future<AiResult> edit({
    required Uint8List image,
    required String prompt,
    List<Uint8List> supportingImages = const [],
    String? imageModel,
    String? imageQuality,
  }) async {
    if (!connected) {
      throw const AiFailure('Connect your local AI relay in Settings first.');
    }
    final chosenModel = imageModel ?? model!;
    final chosenQuality = imageQuality ?? quality!;
    if (!imageModels.contains(chosenModel) ||
        !imageQualities.contains(chosenQuality)) {
      throw const AiFailure(
        'Reconnect the relay and choose an available image model and quality.',
      );
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
              'model': chosenModel,
              'quality': chosenQuality,
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
        quality: data['quality'] as String?,
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

  Future<RoomAnalysisResult> analyse({
    required Uint8List image,
    required String context,
    List<Uint8List> supportingImages = const [],
  }) async {
    if (!supportsAnalysis) {
      throw const AiFailure(
        'Connect the updated local AI relay in Settings to analyse photos.',
      );
    }
    final inputs = [image, ...supportingImages];
    if (inputs.length > maxInputImages ||
        inputs.any((b) => b.isEmpty || b.length > 18 * 1024 * 1024) ||
        inputs.fold<int>(0, (sum, b) => sum + b.length) > 36 * 1024 * 1024 ||
        context.trim().isEmpty ||
        context.length > 16000) {
      throw const AiFailure(
        'Use up to seven photos (18 MB each, 36 MB combined) and shorter room instructions.',
      );
    }
    final client = clientFactory();
    try {
      final response = await client
          .post(
            Uri.parse(_url!).resolve('/analyse'),
            headers: {
              'Authorization': 'Bearer $_pairingCode',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'image': base64Encode(image),
              'supportingImages': supportingImages.map(base64Encode).toList(),
              'prompt': context,
              'confirmed': true,
            }),
          )
          .timeout(const Duration(seconds: 110));
      final data = _readResponse(response);
      if (data['provider'] != 'OpenAI') throw const FormatException();
      try {
        return RoomAnalysisResult.fromMap(data);
      } on FormatException {
        throw const AiFailure(
          'No complete room analysis was returned. Your previous analysis remains available; no automatic retry was made.',
        );
      }
    } on AiFailure {
      rethrow;
    } catch (_) {
      throw const AiFailure(
        'Room analysis was interrupted or could not be read. A charge may have occurred; check usage before retrying.',
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
        _ => 'The AI request failed. Your original and approved baseline are unchanged. Check your provider account before retrying.',
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
