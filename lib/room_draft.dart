import 'dart:async';

import 'package:flutter/widgets.dart';

import 'models.dart';
import 'store.dart';

enum DraftSaveState { saved, pending, saving, failed }

/// Debounced local autosave. Snapshots are captured before queueing and writes
/// are serialised so an older edit cannot finish after and replace a newer edit.
class RoomDraft extends ChangeNotifier {
  final RenovisionStore store;
  final String roomId;
  final TextEditingController changes;
  final TextEditingController protected;
  final TextEditingController otherStyle;
  Set<String> styleIds;
  bool preciseEdit;
  bool keepLayout;
  DraftSaveState state = DraftSaveState.saved;
  Timer? _timer;
  int _revision = 0;
  int _savedRevision = 0;
  bool _disposed = false;
  Future<bool> _queue = Future.value(true);
  late String _lastText;

  RoomDraft(this.store, RenovationRoom room)
    : roomId = room.id,
      changes = TextEditingController(text: room.instructions),
      protected = TextEditingController(text: room.protectedFeatures),
      otherStyle = TextEditingController(text: room.otherStyle),
      styleIds = room.designStyleIds.toSet(),
      preciseEdit = room.preciseEdit,
      keepLayout = room.keepLayout {
    _lastText = _text;
    changes.addListener(_textChanged);
    protected.addListener(_textChanged);
    otherStyle.addListener(_textChanged);
  }

  String get _text => '${changes.text}\u0000${protected.text}\u0000${otherStyle.text}';
  void _textChanged() {
    if (_lastText == _text) return;
    _lastText = _text;
    _changed();
  }

  bool get dirty => _revision != _savedRevision;
  String get status => switch (state) {
    DraftSaveState.saved => 'Saved locally',
    DraftSaveState.pending => 'Unsaved changes · autosave shortly',
    DraftSaveState.saving => 'Saving…',
    DraftSaveState.failed => 'Save failed · use Save instructions to retry',
  };

  void setStyle(String id, bool selected) {
    styleIds = {...styleIds};
    selected ? styleIds.add(id) : styleIds.remove(id);
    _changed();
  }

  void setPrecise(bool value) {
    preciseEdit = value;
    _changed();
  }

  void setKeepLayout(bool value) {
    keepLayout = value;
    _changed();
  }

  void _changed() {
    _revision++;
    state = DraftSaveState.pending;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 600), () => unawaited(save()));
  }

  Future<bool> save() {
    _timer?.cancel();
    if (!dirty) return _queue;
    final revision = _revision;
    final instructions = changes.text;
    final protections = protected.text;
    final customStyle = otherStyle.text;
    final styles = styleIds.toList();
    final precise = preciseEdit;
    final layout = keepLayout;
    state = DraftSaveState.saving;
    if (!_disposed) notifyListeners();
    final operation = _queue.then((_) async {
      try {
        await store.saveRoomDraft(
          roomId,
          instructions: instructions,
          protectedFeatures: protections,
          designStyleIds: styles,
          otherStyle: customStyle,
          preciseEdit: precise,
          keepLayout: layout,
        );
        _savedRevision = revision;
        state = dirty ? DraftSaveState.pending : DraftSaveState.saved;
        if (!_disposed) notifyListeners();
        return true;
      } catch (_) {
        state = DraftSaveState.failed;
        if (!_disposed) notifyListeners();
        return false;
      }
    });
    _queue = operation;
    return operation;
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Normal back navigation awaits save; this is a best-effort flush for
    // other widget/lifecycle exits. Browser shutdown cannot guarantee async I/O.
    if (dirty) unawaited(save());
    _disposed = true;
    changes.dispose();
    protected.dispose();
    otherStyle.dispose();
    super.dispose();
  }
}
