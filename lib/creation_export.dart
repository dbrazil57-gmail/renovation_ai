import 'creation_export_stub.dart'
    if (dart.library.js_interop) 'creation_export_web.dart'
    if (dart.library.io) 'creation_export_native.dart'
    as platform;
import 'creation_export_types.dart';

export 'creation_export_types.dart';

CreationExports createCreationExports() => platform.createCreationExports();
