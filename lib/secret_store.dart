import 'secret_store_session.dart'
    if (dart.library.js_interop) 'secret_store_web.dart'
    if (dart.library.io) 'secret_store_native.dart'
    as platform;
export 'secret_store_types.dart';
import 'secret_store_types.dart';

SecretStore createSecretStore({String provider = 'openai'}) =>
    platform.createSecretStore(provider: provider);
