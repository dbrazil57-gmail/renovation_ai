import 'secret_store_types.dart';

SecretStore createSecretStore({String provider = 'openai'}) =>
    SessionSecretStore();
