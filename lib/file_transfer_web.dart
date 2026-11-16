import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:web/web.dart' as web;

import 'file_transfer_types.dart';
import 'project_backup.dart';

AppFiles createAppFiles() => _WebFiles();

@JS()
extension type _PickerWindow._(JSObject _) implements JSObject {
  external JSPromise<web.FileSystemFileHandle> showSaveFilePicker(
    JSObject options,
  );
  external JSPromise<JSArray<web.FileSystemFileHandle>> showOpenFilePicker(
    JSObject options,
  );
}

class _BrowserFileDestination
    implements ReusableSaveDestination, IdentifiableDestination {
  final web.FileSystemFileHandle handle;
  _BrowserFileDestination(this.handle);
  @override
  Future<bool> sameFile(SaveDestination other) async {
    if (other is! _BrowserFileDestination) return false;
    return (await handle.isSameEntry(other.handle).toDart).toDart;
  }

  @override
  Future<FileSaveResult> write(Uint8List bytes) async {
    final stream = await handle.createWritable().toDart;
    try {
      await stream.write(bytes.toJS).toDart;
      await stream.close().toDart;
      return FileSaveResult.saved;
    } catch (_) {
      try {
        await stream.abort().toDart;
      } catch (_) {
        /* Preserve the original error. */
      }
      rethrow;
    }
  }
}

class _DownloadDestination implements SaveDestination {
  final _WebFiles files;
  final String name;
  final String mimeType;
  _DownloadDestination(this.files, this.name, this.mimeType);
  @override
  Future<FileSaveResult> write(Uint8List bytes) =>
      files.save(bytes, name: name, mimeType: mimeType);
}

class _WebFiles
    implements AppFiles, LocationChoosingFiles, ProjectOpeningFiles {
  @override
  Future<OpenedProjectFile?> openProjectFile() async {
    final picker = web.window.getProperty<JSAny?>('showOpenFilePicker'.toJS);
    if (picker == null ||
        !picker.isA<JSFunction>() ||
        !web.window.isSecureContext) {
      final bytes = await pickBackup();
      return bytes == null ? null : OpenedProjectFile(bytes);
    }
    try {
      final handles = await (web.window as _PickerWindow)
          .showOpenFilePicker(
            {
                  'multiple': false,
                  'types': [
                    {
                      'description': 'Renovision project',
                      'accept': {
                        'application/json': ['.json'],
                      },
                    },
                  ],
                }.jsify()
                as JSObject,
          )
          .toDart;
      if (handles.toDart.isEmpty) return null;
      final handle = handles.toDart.first;
      final file = await handle.getFile().toDart;
      if (file.size > ProjectBackup.maxFileBytes) {
        throw const BackupFailure('Choose a project smaller than 100 MB.');
      }
      final bytes = (await file.arrayBuffer().toDart).toDart.asUint8List();
      return OpenedProjectFile(
        bytes,
        destination: _BrowserFileDestination(handle),
        name: file.name,
      );
    } catch (error) {
      if (error.toString().contains('AbortError')) return null;
      if (error is BackupFailure) rethrow;
      throw const BackupFailure(
        'The project file could not be opened. Existing projects are unchanged.',
      );
    }
  }

  @override
  bool get supported => true;
  @override
  Future<SaveDestination?> chooseSaveLocation({
    required String name,
    required String mimeType,
  }) async {
    final picker = web.window.getProperty<JSAny?>('showSaveFilePicker'.toJS);
    if (picker == null ||
        !picker.isA<JSFunction>() ||
        !web.window.isSecureContext) {
      return _DownloadDestination(this, name, mimeType);
    }
    try {
      final handle = await (web.window as _PickerWindow)
          .showSaveFilePicker(
            {
                  'suggestedName': name,
                  'types': [
                    {
                      'description': mimeType == 'image/png'
                          ? 'PNG image'
                          : 'Renovision project backup',
                      'accept': {
                        mimeType: [mimeType == 'image/png' ? '.png' : '.json'],
                      },
                    },
                  ],
                }.jsify()
                as JSObject,
          )
          .toDart;
      return _BrowserFileDestination(handle);
    } catch (error) {
      if (error.toString().contains('AbortError')) return null;
      throw const BackupFailure(
        'The save location could not be opened. Click Save as again and choose a location.',
      );
    }
  }

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
