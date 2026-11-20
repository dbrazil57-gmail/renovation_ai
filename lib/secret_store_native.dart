import 'dart:io';

import 'package:flutter/services.dart';

import 'secret_store_types.dart';

SecretStore createSecretStore({String provider = 'openai'}) {
  if (!['openai', 'gemini'].contains(provider)) {
    throw ArgumentError('Unsupported provider');
  }
  return Platform.isAndroid ? _AndroidSecrets(provider) : SessionSecretStore();
}

class _AndroidSecrets implements SecretStore {
  final String provider;
  _AndroidSecrets(this.provider);
  String get suffix => provider == 'gemini' ? 'GeminiKey' : 'OpenAiKey';
  static const channel = MethodChannel('renovision/secrets');
  @override
  bool get persistent => true;
  @override
  Future<String?> read() => channel.invokeMethod<String>('read$suffix');
  @override
  Future<void> write(String key) =>
      channel.invokeMethod<void>('write$suffix', {'key': key});
  @override
  Future<void> delete() => channel.invokeMethod<void>('delete$suffix');
}
