import 'dart:io';

import 'package:flutter/services.dart';

import 'creation_export_types.dart';
import 'file_transfer.dart';

CreationExports createCreationExports() => Platform.isAndroid
    ? AndroidCreationExports()
    : UnsupportedCreationExports();

class AndroidCreationExports implements CreationExports {
  static const channel = MethodChannel('renovision/creations');
  final AppFiles files;
  AndroidCreationExports({AppFiles? files}) : files = files ?? createAppFiles();
  @override
  bool get supported => true;

  @override
  Future<CreationExportResult> save(
    Uint8List png, {
    required String name,
  }) async {
    final result = await channel.invokeMethod<String>('saveGallery', {
      'bytes': png,
      'name': name,
    });
    if (result == 'gallery') return CreationExportResult.gallerySaved;
    // Android 9 and older use the existing system chooser instead of requesting
    // broad access to the user's photo library.
    if (result == 'chooseFile') {
      return switch (await files.save(png, name: name, mimeType: 'image/png')) {
        FileSaveResult.saved => CreationExportResult.fileSaved,
        FileSaveResult.requested => CreationExportResult.downloadRequested,
        FileSaveResult.cancelled => CreationExportResult.cancelled,
      };
    }
    throw PlatformException(code: 'export', message: 'Save did not finish.');
  }

  @override
  Future<CreationExportResult> share(
    Uint8List png, {
    required String name,
  }) async {
    final result = await channel.invokeMethod<String>('shareImage', {
      'bytes': png,
      'name': name,
    });
    if (result == 'opened') return CreationExportResult.shareOpened;
    throw PlatformException(code: 'export', message: 'Sharing did not open.');
  }
}
