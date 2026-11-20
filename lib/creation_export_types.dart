import 'dart:typed_data';

enum CreationExportResult {
  gallerySaved,
  fileSaved,
  downloadRequested,
  shareOpened,
  cancelled,
}

/// Receives only a prepared image, never a project or its connection settings.
abstract class CreationExports {
  bool get supported;
  Future<CreationExportResult> save(Uint8List png, {required String name});
  Future<CreationExportResult> share(Uint8List png, {required String name});
}

class UnsupportedCreationExports implements CreationExports {
  @override
  bool get supported => false;
  @override
  Future<CreationExportResult> save(Uint8List png, {required String name}) =>
      Future.error(UnsupportedError('Use Chrome or Android to export images.'));
  @override
  Future<CreationExportResult> share(Uint8List png, {required String name}) =>
      save(png, name: name);
}
