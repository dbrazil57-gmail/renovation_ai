import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'creation_export_types.dart';
import 'file_transfer.dart';

CreationExports createCreationExports() => _WebCreationExports();

class _WebCreationExports implements CreationExports {
  @override
  bool get supported => true;
  @override
  Future<CreationExportResult> save(
    Uint8List png, {
    required String name,
  }) async {
    await createAppFiles().save(png, name: name, mimeType: 'image/png');
    return CreationExportResult.downloadRequested;
  }

  @override
  Future<CreationExportResult> share(
    Uint8List png, {
    required String name,
  }) async {
    final navigator = web.window.navigator;
    final share = navigator.getProperty<JSAny?>('share'.toJS);
    final canShare = navigator.getProperty<JSAny?>('canShare'.toJS);
    final data = web.ShareData(
      files: [
        web.File([png.toJS].toJS, name, web.FilePropertyBag(type: 'image/png')),
      ].toJS,
    );
    if (!web.window.isSecureContext ||
        share == null ||
        !share.isA<JSFunction>() ||
        canShare == null ||
        !canShare.isA<JSFunction>() ||
        !navigator.canShare(data)) {
      return save(png, name: name);
    }
    try {
      await navigator.share(data).toDart;
      return CreationExportResult.shareOpened;
    } catch (error) {
      if (error.toString().contains('AbortError')) {
        return CreationExportResult.cancelled;
      }
      // Keep the prepared PNG so a second tap can retry with fresh user
      // activation; never silently send it elsewhere or claim it was shared.
      rethrow;
    }
  }
}
