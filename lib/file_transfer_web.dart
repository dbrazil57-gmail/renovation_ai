import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:web/web.dart' as web;

import 'file_transfer_types.dart';
import 'project_backup.dart';

AppFiles createAppFiles() => _WebFiles();

class _WebFiles implements AppFiles {
  @override
  bool get supported => true;
  @override
  Future<FileSaveResult> save(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async {
    await XFile.fromData(bytes, name: name, mimeType: mimeType).saveTo(name);
    // Browsers do not tell us whether the user actually kept the download.
    return FileSaveResult.requested;
  }

  @override
  Future<Uint8List?> pickBackup() async {
    final result = Completer<Uint8List?>();
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = '.json,application/json';
    input.style.display = 'none';
    input.addEventListener(
      'cancel',
      ((web.Event _) {
        if (!result.isCompleted) result.complete(null);
      }).toJS,
    );
    input.addEventListener(
      'change',
      ((web.Event _) {
        unawaited(() async {
          try {
            final file = input.files?.item(0);
            if (file == null) {
              result.complete(null);
              return;
            }
            if (file.size > ProjectBackup.maxFileBytes) {
              throw const BackupFailure('Choose a backup smaller than 100 MB.');
            }
            final buffer = await file.arrayBuffer().toDart;
            result.complete(buffer.toDart.asUint8List());
          } catch (error, stack) {
            if (!result.isCompleted) result.completeError(error, stack);
          }
        }());
      }).toJS,
    );
    web.document.body!.appendChild(input);
    try {
      input.click();
      return await result.future;
    } finally {
      input.remove();
    }
  }
}
