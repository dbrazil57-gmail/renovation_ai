abstract class SecretStore {
  bool get persistent;
  Future<String?> read();
  Future<void> write(String key);
  Future<void> delete();
}

class SessionSecretStore implements SecretStore {
  String? _key;
  @override
  bool get persistent => false;
  @override
  Future<String?> read() async => _key;
  @override
  Future<void> write(String key) async {
    _key = key;
  }

  @override
  Future<void> delete() async {
    _key = null;
  }
}
