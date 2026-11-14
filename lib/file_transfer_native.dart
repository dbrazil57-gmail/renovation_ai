import 'dart:io';

import 'package:flutter/services.dart';

import 'file_transfer_types.dart';

AppFiles createAppFiles() => _NativeFiles();

class _NativeFiles implements AppFiles {
  static const channel = MethodChannel('renovision/files');
  @override
  bool get supported => Platform.isAndroid;
  @override
  Future<FileSaveResult> save(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async {
    if (!supported) {
      throw UnsupportedError('Use Chrome or Android for file export.');
    }
    final saved = await channel.invokeMethod<bool>('save', {
      'bytes': bytes,
      'name': name,
      'mimeType': mimeType,
    });
    return saved == true ? FileSaveResult.saved : FileSaveResult.cancelled;
  }

  @override
  Future<Uint8List?> pickBackup() async {
    if (!supported) {
      throw UnsupportedError('Use Chrome or Android for backup restore.');
    }
    return channel.invokeMethod<Uint8List>('openBackup');
  }
}
