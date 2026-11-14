import 'dart:typed_data';

import 'file_transfer_types.dart';

AppFiles createAppFiles() => _UnavailableFiles();

class _UnavailableFiles implements AppFiles {
  @override
  bool get supported => false;
  @override
  Future<FileSaveResult> save(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async => throw UnsupportedError('Use Chrome or Android for file export.');
  @override
  Future<Uint8List?> pickBackup() async =>
      throw UnsupportedError('Use Chrome or Android for backup restore.');
}
