import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'room_analysis.dart';
import 'ai_activity.dart';
import 'ai_types.dart';
export 'ai_types.dart';
import 'secret_store.dart';
import 'openai_internet.dart';
import 'gemini_internet.dart';
import 'ai_model_choices.dart';
export 'ai_model_choices.dart' show AiProvider;

/// Supports a personal internet API key or the development relay. Provider keys
/// stay in the platform vault/session memory, never project/photo records.
class AiService extends ChangeNotifier {
  final AiActivity activity = AiActivity();
  final http.Client Function() clientFactory;
  final SecretStore keyStore;
  final SecretStore geminiKeyStore;
  AiProvider provider = AiProvider.openai;

  /// Deliberate testing aid; resets off on restart and is not exported.
  bool fixedComparisonBrief = false;
  void setFixedComparisonBrief(bool enabled) {
    if (activity.active) {
      throw const AiFailure('Wait for the current AI request to finish.');
    }
    fixedComparisonBrief = enabled;
    notifyListeners();
  }

  int connectionRevision = 0;
  String get providerLabel => provider.label;
  final Map<String, Map<String, dynamic>> _providerSettings = {};
  SecretStore storeFor(AiProvider choice) =>
      choice == AiProvider.openai ? keyStore : geminiKeyStore;
  bool isDirect = false;
  String? _directKey;
  bool get preferDirect => true;
  bool get keyRememberedOnDevice => storeFor(provider).persistent;
  Map<String, dynamic>? get rememberedConnection => !connected
      ? null
      : isDirect
      ? {
          'mode': 'direct',
          'provider': provider.name,
          'model': model,
          'quality': quality,
          'analysisModel': analysisModel,
          'imageModels': imageModels,
          'providerSettings': _providerSettings,
        }
      : {
          'url': _url,
          'pairingCode': _pairingCode,
          'model': model,
          'quality': quality,
          'providerSettings': _providerSettings,
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
  bool get connected => isDirect ? _directKey != null : _url != null;
  String get relayUrl => _url ?? _preferredUrl;

  Future<void> restoreConnection(Map saved) async {
    final preferences = saved['providerSettings'];
    if (preferences is Map) {
      for (final choice in AiProvider.values) {
        final entry = preferences[choice.name];
        if (entry is Map) {
          _providerSettings[choice.name] = _safeSettings(entry, choice);
        }
      }
    }
    if (saved['mode'] == 'direct') {
      provider = AiProvider.fromId(saved['provider']);
      // Remember choices even on web, where the key expires with the session.
      _providerSettings[provider.name] = _safeSettings(saved, provider);
      isDirect = true;
      try {
        final key = await storeFor(provider).read();
        if (key == null || key.isEmpty) {
          connectionNotice =
              'Enter your $providerLabel API key in Settings to reconnect over the internet.';
        } else {
          _directKey = key;
          final listed = saved['imageModels'];
          imageModels = listed is List
              ? provider.imageModels.where(listed.contains).toList()
              : const [];
          if (imageModels.isEmpty &&
              provider.imageModels.contains(saved['model'])) {
            imageModels = [saved['model'] as String];
          }
          if (imageModels.isEmpty) {
            connectionNotice = 'Saved key found, but model settings need to be reconnected in AI settings. No request was sent.';
            _directKey = null;
            notifyListeners();
            return;
          }
          imageQualities = const ['low', 'medium', 'high'];
          model = imageModels.contains(saved['model'])
              ? saved['model'] as String
              : imageModels.first;
          quality = imageQualities.contains(saved['quality'])
              ? saved['quality'] as String
              : 'low';
          analysisModel = provider == AiProvider.openai
              ? (saved['analysisModel'] is String
                    ? saved['analysisModel'] as String
                    : 'gpt-6-luna')
              : (geminiAnalysisModels.contains(saved['analysisModel'])
                    ? saved['analysisModel'] as String
                    : null);
          maxInputImages = 7;
          _rememberProvider();
          connectionRevision++;
          connectionNotice =
              'Saved API key loaded from device storage. Photos go directly to $providerLabel over the internet after confirmation.';
        }
      } catch (_) {
        connectionNotice = 'The device could not read the saved API key. Re-enter it in AI settings.';
      }
      notifyListeners();
      return;
    }
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

  AiService({
    http.Client Function()? clientFactory,
    SecretStore? keyStore,
    SecretStore? geminiKeyStore,
  }) : clientFactory = clientFactory ?? http.Client.new,
       keyStore = keyStore ?? createSecretStore(),
       geminiKeyStore = geminiKeyStore ?? createSecretStore(provider: 'gemini');

  Map<String, dynamic> _safeSettings(Map value, AiProvider choice) => {
    if (choice.imageModels.contains(value['model'])) 'model': value['model'],
    if (['low', 'medium', 'high'].contains(value['quality']))
      'quality': value['quality'],
    if (value['analysisModel'] is String &&
        (choice == AiProvider.openai
                ? ['gpt-6-luna', 'gpt-4.1-mini', 'gpt-4o-mini']
                : geminiAnalysisModels)
            .contains(value['analysisModel']))
      'analysisModel': value['analysisModel'],
    if (value['imageModels'] is List)
      'imageModels': choice.imageModels
          .where((value['imageModels'] as List).contains)
          .toList(),
  };

  void _rememberProvider() {
    if (!isDirect || !connected) return;
    _providerSettings[provider.name] = _safeSettings({
      'model': model,
      'quality': quality,
      'analysisModel': analysisModel,
      'imageModels': imageModels,
    }, provider);
  }

  Future<void> useSavedProvider(AiProvider choice) async {
    String? key;
    try {
      key = await storeFor(choice).read();
    } catch (_) {
      throw const AiFailure(
        'The saved key could not be read. Re-enter it in AI settings.',
      );
    }
    if (key == null || key.isEmpty) {
      throw AiFailure('No saved ${choice.label} key. Enter one to connect.');
    }
    await connectDirect(apiKey: key, provider: choice);
  }

  Future<void> connectDirect({
    required String apiKey,
    AiProvider provider = AiProvider.openai,
  }) async {
    if (activity.active) {
      throw const AiFailure('Wait for the current AI request to finish.');
    }
    final key = apiKey.trim();
    if (key.isEmpty ||
        key.length > 1024 ||
        RegExp(r'[\s\x00-\x1f]').hasMatch(key)) {
      throw AiFailure(
        'Enter your ${provider.label} developer API key without spaces.',
      );
    }
    final available = provider == AiProvider.openai
        ? await OpenAiInternet(clientFactory).models(key)
        : await GeminiInternet(clientFactory).models(key);
    if (activity.active) {
      throw const AiFailure(
        'Wait for the current AI request to finish. No connection was changed.',
      );
    }
    final images = provider.imageModels.where(available.contains).toList();
    if (images.isEmpty) {
      throw AiFailure(
        'This key has no supported image model listed. Check image-model access in your ${provider.label} API account.',
      );
    }
    try {
      await storeFor(provider).write(key);
    } catch (_) {
      throw const AiFailure(
        'The API key could not be saved securely. No connection was changed.',
      );
    }
    if (activity.active) {
      throw const AiFailure(
        'The key was saved, but the connection is unchanged while an AI request is running. Connect again after it finishes.',
      );
    }
    _rememberProvider();
    final saved = _providerSettings[provider.name];
    final previousModel =
        saved?['model'] ?? (this.provider == provider ? model : null);
    final previousQuality =
        saved?['quality'] ?? (this.provider == provider ? quality : null);
    this.provider = provider;
    _directKey = key;
    isDirect = true;
    _url = null;
    _pairingCode = null;
    imageModels = images;
    imageQualities = const ['low', 'medium', 'high'];
    model = images.contains(previousModel)
        ? previousModel as String
        : recommendedImageModel(images);
    quality = imageQualities.contains(previousQuality)
        ? previousQuality as String
        : 'medium';
    analysisModel =
        (provider == AiProvider.openai
                ? ['gpt-6-luna', 'gpt-4.1-mini', 'gpt-4o-mini']
                : geminiAnalysisModels)
            .where(available.contains)
            .firstOrNull ??
        (provider == AiProvider.openai ? 'gpt-6-luna' : null);
    maxInputImages = 7;
    _rememberProvider();
    connectionRevision++;
    connectionNotice =
        'Connected directly to $providerLabel over HTTPS. The key check generated no image. Listed models can still require billing or account approval.';
    notifyListeners();
  }

  Future<void> refreshModels() async {
    final key = _directKey;
    if (!isDirect || key == null) {
      throw const AiFailure(
        'Connect an internet API key before refreshing models.',
      );
    }
    await connectDirect(apiKey: key, provider: provider);
  }

  @override
  void dispose() {
    activity.dispose();
    super.dispose();
  }

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
    if (activity.active) {
      throw const AiFailure('Wait for the current AI request to finish.');
    }
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
      _rememberProvider();
      _url = uri.toString();
      provider = AiProvider.openai;
      isDirect = false;
      _directKey = null;
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
      connectionRevision++;
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

  Future<void> disconnect() async {
    await removeProviderKey(provider);
  }

  Future<void> removeProviderKey(AiProvider choice) async {
    if (activity.active) {
      throw const AiFailure('Wait for the current AI request to finish.');
    }
    try {
      await storeFor(choice).delete();
    } catch (_) {
      throw const AiFailure(
        'The device could not remove the stored key. Try Remove key again in Settings.',
      );
    }
    if (choice != provider) {
      notifyListeners();
      return;
    }
    _rememberProvider();
    _directKey = null;
    _url = null;
    _pairingCode = null;
    model = null;
    quality = null;
    analysisModel = null;
    imageModels = const [];
    imageQualities = const [];
    maxInputImages = 1;
    connectionRevision++;
    connectionNotice =
        '${choice.label} disconnected and its key removed. Projects and other provider keys are unchanged.';
    notifyListeners();
  }

  void selectImageSettings({
    required String imageModel,
    required String imageQuality,
  }) {
    if (activity.active) {
      throw const AiFailure('Wait for the current AI request to finish.');
    }
    if (!connected ||
        !imageModels.contains(imageModel) ||
        !imageQualities.contains(imageQuality)) {
      throw const AiFailure(
        'Choose an available model and quality for this connection.',
      );
    }
    model = imageModel;
    quality = imageQuality;
    _rememberProvider();
    notifyListeners();
  }

  Future<AiResult> edit({
    required Uint8List image,
    required String prompt,
    List<Uint8List> supportingImages = const [],
    String? imageModel,
    String? imageQuality,
    void Function(AiStage)? onProgress,
  }) async {
    if (!connected) {
      throw const AiFailure('Connect AI in Settings first.');
    }
    final chosenModel = imageModel ?? model!;
    final chosenQuality = imageQuality ?? quality!;
    if (!imageModels.contains(chosenModel) ||
        !imageQualities.contains(chosenQuality)) {
      throw const AiFailure(
        'Connect AI in Settings and choose an available image model and quality.',
      );
    }
    if (supportingImages.length + 1 > maxInputImages) {
      throw const AiFailure(
        'This connection cannot accept that many room views. Reduce the selected views or reconnect in Settings.',
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
    if (isDirect) {
      if (provider == AiProvider.gemini) {
        return GeminiInternet(clientFactory).edit(
          key: _directKey!,
          prompt: prompt,
          model: chosenModel,
          quality: chosenQuality,
          sources: [image, ...supportingImages],
          onProgress: onProgress,
        );
      }
      return OpenAiInternet(clientFactory).edit(
        key: _directKey!,
        prompt: prompt,
        model: chosenModel,
        quality: chosenQuality,
        sources: [image, ...supportingImages],
        onProgress: onProgress,
      );
    }
    final uri = Uri.parse(_url!).resolve('/edit');
    final code = _pairingCode!;
    final client = clientFactory();
    try {
      onProgress?.call(AiStage.preparing);
      final body = jsonEncode({
        'image': base64Encode(image),
        'supportingImages': supportingImages.map(base64Encode).toList(),
        'prompt': prompt,
        'confirmed': true,
        'model': chosenModel,
        'quality': chosenQuality,
      });
      onProgress?.call(AiStage.waiting);
      final response = await client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $code',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 210));
      onProgress?.call(AiStage.reading);
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
    void Function(AiStage)? onProgress,
  }) async {
    if (!supportsAnalysis) {
      throw const AiFailure(
        'Connect an AI service with photo analysis in Settings first.',
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
    if (isDirect) {
      if (provider == AiProvider.gemini) {
        return GeminiInternet(clientFactory).analyse(
          key: _directKey!,
          model: analysisModel!,
          prompt: context,
          sources: inputs,
          onProgress: onProgress,
        );
      }
      return OpenAiInternet(clientFactory).analyse(
        key: _directKey!,
        model: analysisModel!,
        prompt: context,
        sources: inputs,
        onProgress: onProgress,
      );
    }
    final client = clientFactory();
    try {
      onProgress?.call(AiStage.preparing);
      final body = jsonEncode({
        'image': base64Encode(image),
        'supportingImages': supportingImages.map(base64Encode).toList(),
        'prompt': context,
        'confirmed': true,
      });
      onProgress?.call(AiStage.waiting);
      final response = await client
          .post(
            Uri.parse(_url!).resolve('/analyse'),
            headers: {
              'Authorization': 'Bearer $_pairingCode',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 110));
      onProgress?.call(AiStage.reading);
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
