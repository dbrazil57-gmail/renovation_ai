import 'dart:io';

import 'package:flutter/services.dart';

import 'secret_store_types.dart';

SecretStore createSecretStore() =>
    Platform.isAndroid ? _AndroidSecrets() : SessionSecretStore();

class _AndroidSecrets implements SecretStore {
  static const channel = MethodChannel('renovision/secrets');
  @override
  bool get persistent => true;
  @override
  Future<String?> read() => channel.invokeMethod<String>('readOpenAiKey');
  @override
  Future<void> write(String key) =>
      channel.invokeMethod<void>('writeOpenAiKey', {'key': key});
  @override
  Future<void> delete() => channel.invokeMethod<void>('deleteOpenAiKey');
}
