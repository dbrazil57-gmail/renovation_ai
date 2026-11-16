import 'dart:typed_data';

enum FileSaveResult { requested, saved, cancelled }

/// An explicitly chosen destination. Creating one must not write file content.
abstract class SaveDestination {
  Future<FileSaveResult> write(Uint8List bytes);
}

/// Can be written again without opening another platform file chooser.
abstract class ReusableSaveDestination implements SaveDestination {}

abstract class IdentifiableDestination {
  Future<bool> sameFile(SaveDestination other);
}

abstract class LocationChoosingFiles {
  Future<SaveDestination?> chooseSaveLocation({
    required String name,
    required String mimeType,
  });
}

class OpenedProjectFile {
  final Uint8List bytes;
  final SaveDestination? destination;
  final String? name;
  const OpenedProjectFile(this.bytes, {this.destination, this.name});
}

abstract class ProjectOpeningFiles {
  Future<OpenedProjectFile?> openProjectFile();
}

/// Existing/native file providers retain their standard save flow as fallback.
class _DeferredDestination implements SaveDestination {
  final AppFiles files;
  final String name;
  final String mimeType;
  _DeferredDestination(this.files, this.name, this.mimeType);
  @override
  Future<FileSaveResult> write(Uint8List bytes) =>
      files.save(bytes, name: name, mimeType: mimeType);
}

Future<SaveDestination?> chooseSaveDestination(
  AppFiles files, {
  required String name,
  required String mimeType,
}) {
  if (files is LocationChoosingFiles) {
    return (files as LocationChoosingFiles).chooseSaveLocation(
      name: name,
      mimeType: mimeType,
    );
  }
  return Future.value(_DeferredDestination(files, name, mimeType));
}

abstract class AppFiles {
  bool get supported;
  Future<FileSaveResult> save(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  });
  Future<Uint8List?> pickBackup();
}
