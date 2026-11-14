import 'dart:typed_data';

enum FileSaveResult { requested, saved, cancelled }

abstract class AppFiles {
  bool get supported;
  Future<FileSaveResult> save(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  });
  Future<Uint8List?> pickBackup();
}
