import 'file_transfer_stub.dart'
    if (dart.library.js_interop) 'file_transfer_web.dart'
    if (dart.library.io) 'file_transfer_native.dart'
    as platform;
import 'file_transfer_types.dart';

export 'file_transfer_types.dart';

AppFiles createAppFiles() => platform.createAppFiles();
