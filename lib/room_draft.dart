import 'dart:async';

import 'package:flutter/widgets.dart';

import 'models.dart';
import 'room_analysis.dart';
import 'store.dart';
import 'design_styles.dart';
import 'renovation_scope.dart';
import 'room_features.dart';

enum DraftSaveState { saved, pending, saving, failed }

/// Debounced local autosave. Snapshots are captured before queueing and writes
/// are serialised so an older edit cannot finish after and replace a newer edit.
class RoomDraft extends ChangeNotifier {
  final RenovisionStore store;
  final String roomId;
  final TextEditingController changes;
  final TextEditingController correction;
  final TextEditingController protected;
  final TextEditingController otherStyle;
  final TextEditingController aiPrompt;
  final TextEditingController flooringNotes;
  final TextEditingController removeItems;
  Set<String> scopeIds;
  String roomTypeId;
  Map<String, String> roomItemChoices;
  RoomAnalysis? analysis;
  bool useAiPrompt;
  Set<String> styleIds;
  bool preciseEdit;
  bool keepLayout;
  int conceptCount;
  int precisionConceptCount;
  bool compareStyles;
  DraftSaveState state = DraftSaveState.saved;
  Timer? _timer;
  int _revision = 0;
  int _savedRevision = 0;
  bool _disposed = false;
  Future<bool> _queue = Future.value(true);
  late String _lastText;
  late bool _autosave;
  bool get autosaveEnabled => _autosave;

  RoomDraft(this.store, RenovationRoom room)
    : roomId = room.id,
      changes = TextEditingController(text: room.instructions),
      correction = TextEditingController(text: room.correctionInstructions),
      protected = TextEditingController(text: room.protectedFeatures),
      otherStyle = TextEditingController(text: room.otherStyle),
      aiPrompt = TextEditingController(text: room.aiPrompt),
      flooringNotes = TextEditingController(text: room.flooringNotes),
      removeItems = TextEditingController(text: room.removeItems),
      scopeIds = room.renovationScopeIds.toSet(),
      roomTypeId = room.roomTypeId,
      roomItemChoices = {...room.roomItemChoices},
      analysis = room.analysis,
      useAiPrompt = room.useAiPrompt,
      styleIds = canonicalStyleIds(room.designStyleIds).toSet(),
      conceptCount = room.conceptCount,
      precisionConceptCount = room.precisionConceptCount,
      compareStyles = room.compareStyles,
      preciseEdit = room.preciseEdit,
      keepLayout = room.keepLayout {
    _lastText = _text;
    _autosave = store.autosaveEnabled;
    store.addListener(_savingPreferenceChanged);
    changes.addListener(_textChanged);
    correction.addListener(_textChanged);
    protected.addListener(_textChanged);
    otherStyle.addListener(_textChanged);
    aiPrompt.addListener(_textChanged);
    flooringNotes.addListener(_textChanged);
    removeItems.addListener(_textChanged);
  }

  String get _text =>
      '${changes.text}\u0000${correction.text}\u0000${protected.text}\u0000${otherStyle.text}\u0000${aiPrompt.text}\u0000${flooringNotes.text}\u0000${removeItems.text}';
  void _textChanged() {
    if (_lastText == _text) return;
    _lastText = _text;
    _changed();
  }

  bool get dirty => _revision != _savedRevision;
  String get status => switch (state) {
    DraftSaveState.saved => 'Saved locally',
    DraftSaveState.pending =>
      _autosave
          ? 'Unsaved changes · autosave shortly'
          : 'Unsaved changes · autosave off',
    DraftSaveState.saving => 'Saving…',
    DraftSaveState.failed => 'Save failed · use Save now to retry',
  };

  void _savingPreferenceChanged() {
    final enabled = store.autosaveEnabled;
    if (enabled == _autosave) return;
    _autosave = enabled;
    _timer?.cancel();
    if (_autosave && dirty) {
      _timer = Timer(
        const Duration(milliseconds: 600),
        () => unawaited(save()),
      );
    }
    if (!_disposed) notifyListeners();
  }

  void setStyle(String id, bool selected) {
    styleIds = {...styleIds};
    id = canonicalStyleId(id);
    selected ? styleIds.add(id) : styleIds.remove(id);
    _changed();
  }

  void setScope(String id, bool selected) {
    if (!renovationScope.containsKey(id)) return;
    scopeIds = {...scopeIds};
    selected ? scopeIds.add(id) : scopeIds.remove(id);
    _changed();
  }

  String get effectiveRoomType =>
      resolveRoomType(roomTypeId, store.roomById(roomId)?.name ?? '');

  void setRoomType(String value) {
    if (value.isNotEmpty && !roomTypes.containsKey(value)) return;
    roomTypeId = value;
    _changed();
  }

  void setItemChoice(String id, String value) {
    if (!['', 'keep', 'replace'].contains(value) ||
        !(roomFeatures[effectiveRoomType]?.containsKey(id) ?? false)) {
      return;
    }
    roomItemChoices = {...roomItemChoices};
    if (value.isEmpty) {
      roomItemChoices.remove(id);
    } else {
      roomItemChoices[id] = value;
    }
    if (isApplianceGroup(id)) {
      scopeIds = {...scopeIds}..remove('appliances');
    }
    _changed();
  }

  String get scopePrompt => [
    buildRenovationScopePrompt(
      scopeIds: scopeIds.toList(),
      flooringNotes: flooringNotes.text,
      removeItems: removeItems.text,
      roomType: effectiveRoomType,
    ),
    buildRoomItemsPrompt(effectiveRoomType, roomItemChoices, scopeIds.toList()),
  ].where((s) => s.isNotEmpty).join('\n');
  bool get hasRequestedChanges =>
      changes.text.trim().isNotEmpty ||
      hasRoomChanges(
        effectiveRoomType,
        roomItemChoices,
        scopeIds.toList(),
        removeItems.text,
      );

  bool get hasBroadRequestedChanges =>
      scopeIds.where((id) => scopeAppliesToRoom(id, effectiveRoomType)).length +
          (roomFeatures[effectiveRoomType]?.keys
                  .where(
                    (id) =>
                        !isApplianceGroup(id) &&
                        effectiveItemChoice(
                              id,
                              roomItemChoices,
                              scopeIds.toList(),
                            ) ==
                            'replace',
                  )
                  .length ??
              0) >
      1;

  void setPrecise(bool value) {
    if (preciseEdit == value) return;
    preciseEdit = value;
    useAiPrompt = false;
    _changed();
  }

  void setKeepLayout(bool value) {
    keepLayout = value;
    _changed();
  }

  void setConceptCount(int value) {
    if (value < 1 || value > 3 || value == conceptCount) return;
    conceptCount = value;
    _changed();
  }

  void setPrecisionConceptCount(int value) {
    if (value < 1 || value > 3 || value == precisionConceptCount) return;
    precisionConceptCount = value;
    _changed();
  }

  void setCompareStyles(bool value) {
    if (value == compareStyles) return;
    compareStyles = value;
    _changed();
  }

  void setAnalysis(RoomAnalysis value) {
    analysis = value;
    useAiPrompt = false;
    aiPrompt.text = value.result.prompt;
    _changed();
  }

  void setUseAiPrompt(bool value) {
    useAiPrompt = value;
    _changed();
  }

  void _changed() {
    _revision++;
    state = DraftSaveState.pending;
    notifyListeners();
    _timer?.cancel();
    if (_autosave) {
      _timer = Timer(
        const Duration(milliseconds: 600),
        () => unawaited(save()),
      );
    }
  }

  Future<bool> save() {
    _timer?.cancel();
    if (!dirty) return _queue;
    final revision = _revision;
    final instructions = changes.text;
    final correctionInstructions = correction.text;
    final protections = protected.text;
    final customStyle = otherStyle.text;
    final styles = styleIds.toList();
    final precise = preciseEdit;
    final layout = keepLayout;
    final countSnapshot = conceptCount;
    final precisionCountSnapshot = precisionConceptCount;
    final compareSnapshot = compareStyles;
    final analysisSnapshot = analysis;
    final editedPrompt = aiPrompt.text;
    final useAnalysis = useAiPrompt;
    final scopeSnapshot = scopeIds.toList();
    final floorSnapshot = flooringNotes.text;
    final removalSnapshot = removeItems.text;
    final typeSnapshot = roomTypeId;
    final itemSnapshot = Map<String, String>.from(roomItemChoices);
    state = DraftSaveState.saving;
    if (!_disposed) notifyListeners();
    final operation = _queue.then((_) async {
      try {
        await store.saveRoomDraft(
          roomId,
          instructions: instructions,
          correctionInstructions: correctionInstructions,
          protectedFeatures: protections,
          designStyleIds: styles,
          otherStyle: customStyle,
          preciseEdit: precise,
          keepLayout: layout,
          conceptCount: countSnapshot,
          precisionConceptCount: precisionCountSnapshot,
          compareStyles: compareSnapshot,
          analysis: analysisSnapshot,
          aiPrompt: editedPrompt,
          useAiPrompt: useAnalysis,
          renovationScopeIds: scopeSnapshot,
          flooringNotes: floorSnapshot,
          removeItems: removalSnapshot,
          roomTypeId: typeSnapshot,
          roomItemChoices: itemSnapshot,
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
    store.removeListener(_savingPreferenceChanged);
    _timer?.cancel();
    // Normal back navigation awaits save; this is a best-effort flush for
    // other widget/lifecycle exits. Browser shutdown cannot guarantee async I/O.
    if (dirty) unawaited(save());
    _disposed = true;
    changes.dispose();
    correction.dispose();
    protected.dispose();
    otherStyle.dispose();
    aiPrompt.dispose();
    flooringNotes.dispose();
    removeItems.dispose();
    super.dispose();
  }
}
