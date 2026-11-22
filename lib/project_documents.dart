import 'dart:async';

import 'package:flutter/foundation.dart';

import 'file_transfer_types.dart';

/// File destinations stay separate from portable project records and credentials.
class ProjectDocuments extends ChangeNotifier {
  final Uint8List Function(String projectId) encode;
  final bool Function() autosave;
  final Map<String, SaveDestination> _destinations = {};
  final Map<String, String> _messages = {};
  final Map<String, int> _revisions = {};
  final Map<String, int> _saved = {};
  final Map<String, Future<void>> _queues = {};
  Timer? _timer;
  bool _disposed = false;
  ProjectDocuments({required this.encode, required this.autosave});
  bool linked(String id) => _destinations.containsKey(id);
  bool hasPending(String id) => linked(id) && _revisions[id] != _saved[id];
  String status(String id) =>
      _messages[id] ??
      'Saved on this device. Save a project file to keep a portable copy.';
  bool get pending =>
      _destinations.keys.any((id) => _revisions[id] != _saved[id]);

  Future<void> flushAndDetach(
    String id, {
    Future<void> Function()? beforeDetach,
  }) async {
    if (hasPending(id)) await save(id);
    await (_queues[id] ?? Future<void>.value());
    await beforeDetach?.call();
    _destinations.remove(id);
    notifyListeners();
  }

  Future<void> link(
    String id,
    SaveDestination destination, {
    bool alreadySaved = false,
  }) async {
    for (final entry in _destinations.entries.toList()) {
      if (entry.key == id) continue;
      final same =
          identical(entry.value, destination) ||
          (destination is IdentifiableDestination &&
              await (destination as IdentifiableDestination).sameFile(
                entry.value,
              ));
      if (same) {
        await (_queues[entry.key] ?? Future<void>.value()).catchError((_) {});
        _destinations.remove(entry.key);
        _messages[entry.key] = 'This file is now open for another project copy. Local work is retained; choose Save project as to save it separately.';
      }
    }
    attach(id, destination, alreadySaved: alreadySaved);
  }

  void attach(
    String id,
    SaveDestination destination, {
    bool alreadySaved = false,
  }) {
    _destinations[id] = destination;
    _revisions[id] = (_revisions[id] ?? 0) + 1;
    if (alreadySaved) _saved[id] = _revisions[id]!;
    _messages[id] = alreadySaved
        ? 'Project file opened. Save updates this file during this session.'
        : 'Project file selected; save pending.';
    notifyListeners();
  }

  void changed() {
    if (_disposed || _destinations.isEmpty) return;
    for (final id in _destinations.keys) {
      _revisions[id] = (_revisions[id] ?? 0) + 1;
      _messages[id] = autosave()
          ? 'Project file changes pending…'
          : 'Unsaved project file changes · use Save project';
    }
    _timer?.cancel();
    if (autosave()) {
      _timer = Timer(const Duration(seconds: 2), () {
        for (final id in _destinations.keys.toList()) {
          unawaited(save(id).catchError((_) {}));
        }
      });
    }
    notifyListeners();
  }

  Future<void> save(String id) {
    final destination = _destinations[id];
    if (destination == null) {
      return Future.error(StateError('Choose Save project as first.'));
    }
    final operation = (_queues[id] ?? Future.value()).catchError((_) {}).then((
      _,
    ) async {
      final revision = _revisions[id] ?? 0;
      _messages[id] = 'Saving project file…';
      if (!_disposed) notifyListeners();
      try {
        await Future<void>.delayed(const Duration(milliseconds: 16));
        final result = await destination.write(encode(id));
        if (result == FileSaveResult.cancelled) {
          throw StateError('Save cancelled.');
        }
        if (result == FileSaveResult.saved) _saved[id] = revision;
        _messages[id] = result == FileSaveResult.saved
            ? (_revisions[id] == revision
                  ? 'Project file saved.'
                  : 'Newer changes still need saving.')
            : 'Download requested. Check Downloads; automatic file updates are unavailable.';
        // A download cannot be silently overwritten or autosaved.
        if (result == FileSaveResult.requested ||
            destination is! ReusableSaveDestination) {
          _destinations.remove(id);
          if (result == FileSaveResult.saved) {
            _messages[id] = 'Project file saved. App-local autosave continues; use Save project to choose a destination for the next file copy.';
          }
        }
      } catch (_) {
        if (destination is! ReusableSaveDestination) {
          _destinations.remove(id);
        }
        _messages[id] = 'Project file save failed. Local work is retained. Use Save project or Save as to retry.';
        rethrow;
      } finally {
        if (!_disposed) notifyListeners();
      }
    });
    _queues[id] = operation;
    return operation;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
