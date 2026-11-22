// Compile with dart compile js and serve over localhost, then open in an isolated
// Chrome profile. Exercises the production file bridge against real OPFS files;
// no customer project, file picker, credentials or Flutter rendering is needed.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;
import 'package:renovision_ai/file_transfer_types.dart';
import 'package:renovision_ai/file_transfer_web.dart' as browser;
import 'package:renovision_ai/project_backup.dart';

void check(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<void> main() async {
  final original = web.window.getProperty<JSAny?>('showSaveFilePicker'.toJS);
  web.FileSystemDirectoryHandle? directory;
  final results = <String>[];
  try {
    directory = await web.window.navigator.storage.getDirectory().toDart;
    final handle = await directory
        .getFileHandle(
          'renovision-large-save-check.json',
          web.FileSystemGetFileOptions(create: true),
        )
        .toDart;
    web.window.setProperty(
      'showSaveFilePicker'.toJS,
      ((JSObject _) => Future.value(handle).toJS).toJS,
    );
    final destination =
        await (browser.createAppFiles() as LocationChoosingFiles)
            .chooseSaveLocation(
              name: 'fixture.json',
              mimeType: 'application/json',
            );
    final bytes = Uint8List(16 * 1024 * 1024);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = i % 251;
    }
    check(
      await destination!.write(bytes) == FileSaveResult.saved,
      'Write result',
    );
    final saved = await handle.getFile().toDart;
    check(saved.size == bytes.length, '16 MB file size');
    final read = (await saved.arrayBuffer().toDart).toDart.asUint8List();
    check(read.length == bytes.length, 'Read-back length');
    for (var i = 0; i < read.length; i++) {
      check(read[i] == bytes[i], 'Read-back mismatch at $i');
    }
    results.add('PASS: 16 MB write, close and every-byte read-back');

    // Simulate a browser/provider acknowledging write/close without writing.
    final empty = await directory
        .getFileHandle(
          'renovision-empty-save-check.json',
          web.FileSystemGetFileOptions(create: true),
        )
        .toDart;
    final stream = JSObject();
    stream.setProperty(
      'write'.toJS,
      ((JSAny? _) => Future<JSAny?>.value(null).toJS).toJS,
    );
    stream.setProperty(
      'close'.toJS,
      (() => Future<JSAny?>.value(null).toJS).toJS,
    );
    stream.setProperty(
      'abort'.toJS,
      (() => Future<JSAny?>.value(null).toJS).toJS,
    );
    empty.setProperty(
      'createWritable'.toJS,
      (() => Future.value(stream).toJS).toJS,
    );
    web.window.setProperty(
      'showSaveFilePicker'.toJS,
      ((JSObject _) => Future.value(empty).toJS).toJS,
    );
    final broken = await (browser.createAppFiles() as LocationChoosingFiles)
        .chooseSaveLocation(name: 'fixture.json', mimeType: 'application/json');
    var rejected = false;
    try {
      await broken!.write(Uint8List.fromList([1, 2, 3]));
    } on BackupFailure {
      rejected = true;
    }
    check(rejected, 'Empty file must not report successful saving');
    check((await empty.getFile().toDart).size == 0, 'Empty fixture size');
    results.add('PASS: false-success empty write rejected');
    web.document.body!.textContent = results.join('\n');
    web.window.setProperty('renovisionFileCheck'.toJS, 'passed'.toJS);
  } catch (error, stack) {
    web.document.body!.textContent =
        '${results.join('\n')}\nFAIL: $error\n$stack';
    web.window.setProperty('renovisionFileCheck'.toJS, 'failed'.toJS);
  } finally {
    web.window.setProperty('showSaveFilePicker'.toJS, original);
    if (directory != null) {
      for (final name in [
        'renovision-large-save-check.json',
        'renovision-empty-save-check.json',
      ]) {
        try {
          await directory.removeEntry(name).toDart;
        } catch (_) {
          /* Retain test failure, if any. */
        }
      }
    }
  }
}
