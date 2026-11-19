import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'ai_activity.dart';
import 'ai_activity_widget.dart';
import 'ai_service.dart';
import 'ai_widgets.dart';
import 'colour_palette_widgets.dart';
import 'design_styles.dart';
import 'exit_guard.dart';
import 'models.dart';
import 'room_analysis.dart';
import 'room_camera.dart';
import 'room_draft.dart';
import 'room_features.dart';
import 'room_prompt.dart';
import 'room_start_widgets.dart';
import 'store.dart';

/// One camera reference, one consented analysis, then separately confirmed
/// preview requests. The camera stays in this route; no video is uploaded.
class LiveDesignScreen extends StatefulWidget {
  final RenovisionStore store;
  final String projectId;
  final String? roomId, initialPhotoId;
  final RoomStartChoice? initialRoomChoice;
  final RoomCameraFeed? feed;
  final WidgetBuilder? settingsBuilder;
  final Widget Function(String roomId, String? designId) workspace;
  final Duration settleDuration;
  const LiveDesignScreen({
    super.key,
    required this.store,
    required this.projectId,
    required this.workspace,
    this.roomId,
    this.initialPhotoId,
    this.initialRoomChoice,
    this.feed,
    this.settingsBuilder,
    this.settleDuration = const Duration(seconds: 2),
  });
  @override
  State<LiveDesignScreen> createState() => _LiveDesignScreenState();
}

class _LiveDesignScreenState extends State<LiveDesignScreen>
    with WidgetsBindingObserver {
  late final RoomCameraFeed feed = widget.feed ?? DeviceRoomCamera();
  late final PageExitGuard guard;
  Timer? settle;
  RoomDraft? draft;
  String? roomId, sourceId, message, selectedDesignId, appliedSettings;
  Uint8List? pendingFrame;
  bool starting = false,
      capturing = false,
      analysing = false,
      generating = false,
      saving = false;
  bool foreground = true,
      overlay = false,
      original = false,
      settingsOpen = false;
  bool overlayRequested = false;
  bool analysisAttempted = false;
  Size? lastViewSize;
  int ticks = 0, totalTicks = 1, panel = 0;
  double opacity = .9;
  bool get busy =>
      settingsOpen ||
      starting ||
      settle != null ||
      capturing ||
      analysing ||
      generating ||
      saving;
  RenovationRoom? get room =>
      roomId == null ? null : widget.store.roomById(roomId!);
  DesignVersion? get selectedDesign => roomId == null
      ? null
      : widget.store
            .designsFor(roomId!)
            .where((d) => d.id == selectedDesignId)
            .firstOrNull;
  bool get hasAnalysis =>
      sourceId != null && draft?.analysis?.sourceImageId == sourceId;
  String get settingsKey => jsonEncode([
    room?.colourPaletteId,
    draft?.roomTypeId,
    (draft?.styleIds.toList() ?? <String>[])..sort(),
    draft?.changes.text,
    draft?.protected.text,
    draft?.keepLayout,
    (draft?.scopeIds.toList() ?? <String>[])..sort(),
    draft?.roomItemChoices,
  ]);

  @override
  void initState() {
    super.initState();
    roomId = widget.roomId;
    guard = createPageExitGuard(() {
      draft?.save();
    });
    final savedRoom = room;
    if (savedRoom != null &&
        savedRoom.photoIds.contains(widget.initialPhotoId) &&
        widget.store.imageFor(widget.initialPhotoId!) != null) {
      sourceId = widget.initialPhotoId;
      draft = RoomDraft(widget.store, savedRoom);
      draft!.setPrecise(false);
      draft!.addListener(_changed);
    }
    widget.store.addListener(_changed);
    widget.store.ai.addListener(_changed);
    widget.store.documents.addListener(_changed);
    feed.addListener(_cameraChanged);
    WidgetsBinding.instance.addObserver(this);
    unawaited(feed.start());
  }

  void _changed() {
    guard.setPending(
      busy ||
          pendingFrame != null ||
          (draft?.dirty ?? false) ||
          widget.store.documents.hasPending(widget.projectId),
    );
    if (mounted) setState(() {});
  }

  void _cameraChanged() {
    if (!mounted) return;
    setState(() {
      overlay =
          overlayRequested &&
          foreground &&
          !settingsOpen &&
          feed.phase == RoomCameraPhase.ready;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    lastViewSize ??= View.of(context).physicalSize;
  }

  void _showSavedDesignOnCamera() {
    if (!mounted || selectedDesign == null) return;
    setState(() {
      overlayRequested = true;
      original = false;
      overlay =
          foreground && !settingsOpen && feed.phase == RoomCameraPhase.ready;
      if (opacity <= .05) opacity = .9;
    });
    if (foreground &&
        !settingsOpen &&
        feed.phase != RoomCameraPhase.ready &&
        feed.phase != RoomCameraPhase.opening) {
      unawaited(feed.start().catchError((Object _) {}));
    }
  }

  void _showCameraOnly() => setState(() {
    overlayRequested = false;
    overlay = false;
    original = false;
  });

  Future<void> _stopCamera() async {
    try {
      await feed.stop();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (foreground) {
      if (!settingsOpen) {
        unawaited(
          feed
              .start()
              .then((_) {
                if (mounted) _cameraChanged();
              })
              .catchError((Object _) {}),
        );
      }
    } else if (!(state == AppLifecycleState.inactive &&
        feed.phase == RoomCameraPhase.opening)) {
      final wasSettling = settle != null;
      settle?.cancel();
      settle = null;
      if (mounted) {
        setState(() {
          overlayRequested = false;
          overlay = false;
          if (wasSettling) {
            message = 'Preparation paused. Start again when ready.';
          }
        });
      }
      _changed();
      unawaited(_stopCamera());
    }
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final size = View.of(context).physicalSize;
    if (size != lastViewSize) {
      setState(() {
        overlayRequested = false;
        overlay = false;
      });
    }
    lastViewSize = size;
  }

  @override
  void dispose() {
    settle?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.store.removeListener(_changed);
    widget.store.ai.removeListener(_changed);
    widget.store.documents.removeListener(_changed);
    feed.removeListener(_cameraChanged);
    draft?.removeListener(_changed);
    guard.dispose();
    draft?.dispose();
    feed.dispose();
    super.dispose();
  }

  Future<bool> _analysisConsent() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            sourceId == null
                ? 'Start live design?'
                : analysisAttempted
                ? 'Analyse this view again?'
                : 'Analyse this saved view?',
          ),
          content: SingleChildScrollView(
            child: Text(
              sourceId == null
                  ? 'The app will automatically capture one reference frame and save it in this project. One photo and the room brief are sent to your connected AI for a paid analysis. Video stays on this device. Each design or palette update is a separate request that you confirm.'
                  : analysisAttempted
                  ? 'Send the saved reference and brief for one more paid analysis. A failed request may already have been charged; check provider usage before retrying. No new camera frame is captured.'
                  : 'Send this saved reference and brief for one paid analysis while staying in the camera viewer. No new camera frame is captured. Image generation has its own confirmation.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Start and analyse'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _start() async {
    if (busy ||
        sourceId != null ||
        pendingFrame != null ||
        feed.phase != RoomCameraPhase.ready ||
        !widget.store.ai.supportsAnalysis ||
        widget.store.ai.activity.active) {
      return;
    }
    if ((room?.photoIds.length ?? 0) >= RenovisionStore.maxRoomPhotos) {
      setState(
        () => message = 'This room has 6 photos. Start Live design from the project to create another room.',
      );
      return;
    }
    setState(() => starting = true);
    _changed();
    final confirmed = await _analysisConsent();
    if (!mounted) return;
    setState(() => starting = false);
    if (!confirmed || !foreground || feed.phase != RoomCameraPhase.ready) {
      _changed();
      return;
    }
    totalTicks = (widget.settleDuration.inMilliseconds / 100).ceil().clamp(
      1,
      100,
    );
    setState(() {
      ticks = 0;
      message = null;
    });
    settle = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || !foreground) return;
      setState(() => ticks++);
      if (ticks >= totalTicks) {
        settle?.cancel();
        settle = null;
        unawaited(_captureAndAnalyse());
      }
    });
    _changed();
  }

  Future<void> _captureAndAnalyse() async {
    if (capturing || !foreground || feed.phase != RoomCameraPhase.ready) return;
    setState(() {
      capturing = true;
      message = 'Capturing the reference view…';
    });
    _changed();
    try {
      final bytes = await feed.capture();
      validateRoomCapture(bytes);
      if (!mounted) return;
      pendingFrame = bytes;
      await _saveFrame();
      if (!mounted) return;
      await _analyse();
    } catch (_) {
      if (mounted) {
        setState(
          () => message = pendingFrame == null
              ? 'Camera capture did not finish. Start again to retry.'
              : 'Reference frame has not saved. Retry saving before analysis; no AI request was sent.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => capturing = false);
        _changed();
      }
    }
  }

  Future<void> _saveFrame() async {
    final bytes = pendingFrame!;
    if (roomId == null) {
      final choice = widget.initialRoomChoice;
      final starter = choice?.starter;
      final created = await widget.store.createRoom(
        projectId: widget.projectId,
        name: choice?.name ?? 'Live room',
        originalImage: bytes,
        roomTypeId: choice?.roomTypeId ?? 'other',
        colourPaletteId: starter?.paletteId ?? '',
        designStyleIds: starter == null || starter.styleId.isEmpty
            ? []
            : [starter.styleId],
      );
      roomId = created.id;
      sourceId = created.originalId;
    } else {
      sourceId = (await widget.store.addRoomPhotos(roomId!, [bytes])).single;
    }
    if (!mounted) return;
    pendingFrame = null;
    draft = RoomDraft(widget.store, room!);
    draft!.setPrecise(false);
    draft!.addListener(_changed);
    _changed();
  }

  Future<void> _retryFrameSave() async {
    if (busy || pendingFrame == null) return;
    setState(() => saving = true);
    _changed();
    try {
      await _saveFrame();
      if (mounted) await _analyse();
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Reference frame has not saved. Retry saving; analysis has not started.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
        _changed();
      }
    }
  }

  Future<void> _analyse() async {
    if (draft == null || sourceId == null || widget.store.ai.activity.active) {
      return;
    }
    var started = false;
    setState(() {
      analysing = true;
      message = null;
    });
    _changed();
    try {
      if (!await draft!.save()) {
        setState(
          () =>
              message = 'Room choices have not saved. No AI request was sent.',
        );
        return;
      }
      if (!mounted) return;
      final context =
          'Identify the likely room type from this camera reference and describe visible features, uncertainty and useful renovation questions. This is one view, not a spatial scan.\n${roomTemplatePrompt(room!, draft!, includeRoomContext: false)}';
      widget.store.ai.activity.begin(
        roomId: roomId!,
        operation: 'Live room analysis',
      );
      started = true;
      analysisAttempted = true;
      final result = await widget.store.ai.analyse(
        image: widget.store.imageFor(sourceId!)!,
        context: context,
        onProgress: (stage) {
          if (mounted) widget.store.ai.activity.update(stage);
        },
      );
      if (!mounted) return;
      draft!.setAnalysis(
        RoomAnalysis(
          result: result,
          sourceImageId: sourceId!,
          supportingImageIds: const [],
          context: context,
          created: DateTime.now().toUtc(),
        ),
      );
      widget.store.ai.activity.update(AiStage.saving);
      final saved = await draft!.save();
      if (mounted) {
        widget.store.ai.activity.update(
          saved ? AiStage.completed : AiStage.saveFailed,
        );
        setState(
          () => message = saved
              ? 'Room analysed. Confirm the room type and choose a direction below.'
              : 'Analysis received. Retry saving it; no new AI analysis is needed.',
        );
      }
    } on AiFailure catch (error) {
      if (mounted) {
        if (started) {
          widget.store.ai.activity.update(
            AiStage.failed,
            detail: error.message,
          );
        }
        setState(() => message = error.message);
      }
    } catch (_) {
      if (mounted) {
        if (started) widget.store.ai.activity.update(AiStage.failed);
        setState(
          () => message = 'Analysis did not finish. No automatic retry was sent; check usage before trying again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => analysing = false);
        _changed();
      }
    }
  }

  Future<void> _retryAnalysis() async {
    if (busy || sourceId == null || hasAnalysis) return;
    setState(() => starting = true);
    _changed();
    final confirmed = await _analysisConsent();
    if (!mounted) return;
    setState(() => starting = false);
    _changed();
    if (confirmed) await _analyse();
  }

  Future<bool> _saveChoices() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await draft!.save();
    if (saved &&
        !generating &&
        widget.store.ai.activity.stage == AiStage.saveFailed) {
      widget.store.ai.activity.update(AiStage.completed);
    }
    if (mounted) _changed();
    return saved;
  }

  AiEditRequest _request() {
    if (saving || analysing || capturing || starting || settle != null) {
      throw const AiFailure(
        'Wait for the reference and current choices to finish saving.',
      );
    }
    if (!hasAnalysis || draft!.state == DraftSaveState.failed) {
      throw const AiFailure(
        'Save the camera analysis before generating a preview.',
      );
    }
    final template = roomTemplatePrompt(
      room!,
      draft!,
      includeRoomContext: false,
    );
    final prompt =
        '$template\n\nPHOTO ANALYSIS (observations about this reference, not permission to change protected features):\n${draft!.analysis!.result.observations}\nThe photo and CURRENT user choices above take priority over uncertain observations. Return one photorealistic renovation from this exact camera viewpoint.';
    if (prompt.length > 16000) {
      throw const AiFailure('Shorten the brief before generating.');
    }
    return AiEditRequest(
      roomId: roomId!,
      parentId: null,
      sourceImageId: sourceId!,
      image: widget.store.imageFor(sourceId!)!,
      prompt: prompt,
      instructions: draft!.changes.text.trim().isEmpty
          ? 'Create a coordinated renovation using the selected style, palette and protected features.'
          : draft!.changes.text,
      precise: false,
      styleIds: draft!.styleIds.toList(),
      otherStyle: draft!.otherStyle.text,
      title: 'Live camera design',
    );
  }

  Future<void> _palette(String id) async {
    if (busy || draft == null) return;
    setState(() => saving = true);
    _changed();
    try {
      await widget.store.setRoomPalette(roomId!, id);
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Palette could not be saved. Retry the selection.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
        _changed();
      }
    }
  }

  Future<void> _continue() async {
    if (busy ||
        appliedSettings != settingsKey ||
        selectedDesign == null ||
        !await _saveChoices() ||
        !mounted) {
      return;
    }
    setState(() => saving = true);
    _changed();
    try {
      if (widget.store.documents.hasPending(widget.projectId)) {
        await widget.store.documents.save(widget.projectId);
      }
      await _stopCamera();
      if (!mounted) return;
      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute(
          builder: (_) => widget.workspace(roomId!, selectedDesignId),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Design saved locally. Project file could not be updated; retry saving.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
        _changed();
      }
    }
  }

  Future<void> _settings() async {
    if (busy || widget.settingsBuilder == null) return;
    setState(() => settingsOpen = true);
    _changed();
    try {
      await _stopCamera();
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: widget.settingsBuilder!),
      );
    } finally {
      if (mounted) {
        setState(() => settingsOpen = false);
        _changed();
        if (foreground) await feed.start();
      }
    }
  }

  Future<void> _leave() async {
    if (busy) return;
    if (pendingFrame != null) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard unsaved reference?'),
          content: const Text(
            'The captured reference has not saved. Existing project images are safe.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep reference'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard reference'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
      pendingFrame = null;
    }
    if (draft != null && !await _saveChoices()) return;
    if (!mounted) return;
    setState(() => saving = true);
    _changed();
    try {
      if (widget.store.documents.hasPending(widget.projectId)) {
        await widget.store.documents.save(widget.projectId);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Project file needs saving. Retry Back or reconnect it in Settings.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
        _changed();
      }
    }
  }

  Widget _controls() => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sourceId == null) ...[
          const Text(
            'Aim at the room and hold this viewpoint. The app captures the reference for you.',
          ),
          if (settle != null) ...[
            LinearProgressIndicator(value: ticks / totalTicks),
            const Text('Preparing reference view…'),
          ],
          if (pendingFrame != null)
            FilledButton(
              onPressed: busy ? null : _retryFrameSave,
              child: const Text('Retry save and analyse'),
            )
          else
            ListenableBuilder(
              listenable: feed,
              builder: (context, _) => FilledButton.icon(
                onPressed:
                    busy ||
                        feed.phase != RoomCameraPhase.ready ||
                        !widget.store.ai.supportsAnalysis
                    ? null
                    : _start,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Start live design'),
              ),
            ),
          if (!widget.store.ai.supportsAnalysis)
            const Text('Connect AI in Settings to start analysis.'),
        ] else if (!hasAnalysis) ...[
          if (analysing) const LinearProgressIndicator(),
          Text(
            analysing
                ? 'Analysing the reference…'
                : analysisAttempted
                ? 'Reference saved. Analysis can be retried with confirmation.'
                : 'Saved view selected. Analyse it here while the camera stays open.',
          ),
          if (!busy)
            OutlinedButton(
              onPressed: _retryAnalysis,
              child: Text(
                analysisAttempted ? 'Retry analysis' : 'Analyse saved view',
              ),
            ),
        ] else ...[
          Wrap(
            spacing: 6,
            children: [
              for (final (i, label) in [
                'Room & style',
                'Palette',
                'Brief',
              ].indexed)
                ChoiceChip(
                  label: Text(label),
                  selected: panel == i,
                  onSelected: busy ? null : (_) => setState(() => panel = i),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (panel == 0) ...[
            DropdownButtonFormField<String>(
              key: ValueKey('live-room-type-${draft!.roomTypeId}'),
              initialValue: draft!.roomTypeId.isEmpty
                  ? 'other'
                  : draft!.roomTypeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Confirm room type'),
              items: [
                for (final type in roomTypes.entries)
                  DropdownMenuItem(
                    value: type.key,
                    child: Text(
                      type.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      if (value != null) draft!.setRoomType(value);
                    },
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('live-style-${draft!.styleIds.join()}'),
              initialValue: draft!.styleIds.length == 1
                  ? draft!.styleIds.single
                  : '',
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Design style'),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text(
                    'Keep current influences',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (final style in designStyles.entries)
                  DropdownMenuItem(
                    value: style.key,
                    child: Text(
                      style.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      if (value != null && value.isNotEmpty) {
                        for (final id in draft!.styleIds.toList()) {
                          draft!.setStyle(id, false);
                        }
                        draft!.setStyle(value, true);
                      }
                    },
            ),
          ],
          if (panel == 1)
            AbsorbPointer(
              absorbing: busy,
              child: ColourPalettePicker(
                selectedId: room!.colourPaletteId,
                onSelected: _palette,
                horizontal: true,
              ),
            ),
          if (panel == 2) ...[
            TextField(
              controller: draft!.changes,
              enabled: !busy,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'What would you like to change?',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Keep layout'),
              value: draft!.keepLayout,
              onChanged: busy ? null : draft!.setKeepLayout,
            ),
            TextField(
              controller: draft!.protected,
              enabled: !busy,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Must keep'),
            ),
            ExpansionTile(
              title: const Text('AI observations & questions'),
              children: [
                SelectableText(draft!.analysis!.result.observations),
                for (final q in draft!.analysis!.result.questions) Text(q),
              ],
            ),
          ],
          if (draft!.state == DraftSaveState.failed)
            FilledButton(
              onPressed: busy ? null : _saveChoices,
              child: const Text('Retry saving analysis and choices'),
            ),
          if (selectedDesign != null && appliedSettings != settingsKey)
            const Text('Choices changed · generate an update to apply them.'),
          AiEditCard(
            key: const ValueKey('live-preview-generator'),
            enabled:
                !saving &&
                !analysing &&
                !capturing &&
                !starting &&
                settle == null &&
                draft!.state != DraftSaveState.failed,
            store: widget.store,
            draft: draft,
            compact: true,
            singleConcept: true,
            showSavedPreview: false,
            buttonLabel: selectedDesign == null
                ? 'Generate preview'
                : 'Update preview',
            beforeSend: _saveChoices,
            buildRequest: _request,
            onPendingChanged: (value) {
              if (mounted) {
                setState(() => generating = value);
                _changed();
              }
            },
            onSaved: (design) {
              if (mounted) {
                setState(() {
                  selectedDesignId = design.id;
                  appliedSettings = settingsKey;
                  message = 'Design saved. View it over the live camera here; continue to refine when ready.';
                });
                _showSavedDesignOnCamera();
              }
            },
          ),
          if (selectedDesign != null) ...[
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Live camera'),
                  selected: !overlay && !original,
                  onSelected: (_) => _showCameraOnly(),
                ),
                ChoiceChip(
                  label: const Text('Reference'),
                  selected: original,
                  onSelected: (_) => setState(() {
                    overlayRequested = false;
                    original = true;
                    overlay = false;
                  }),
                ),
                ChoiceChip(
                  label: const Text('Design overlay'),
                  selected: overlay,
                  onSelected: (_) => _showSavedDesignOnCamera(),
                ),
              ],
            ),
            if (overlay)
              Slider(
                value: opacity,
                label: '${(opacity * 100).round()}%',
                onChanged: (value) => setState(() => opacity = value),
              ),
            FilledButton.icon(
              onPressed: busy || appliedSettings != settingsKey
                  ? null
                  : _continue,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Continue to refine'),
            ),
          ],
        ],
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message!),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final result = selectedDesign == null
        ? null
        : widget.store.imageFor(selectedDesign!.imageId);
    final reference = sourceId == null
        ? pendingFrame
        : widget.store.imageFor(sourceId!);
    final stage = sourceId == null
        ? 0
        : !hasAnalysis
        ? 1
        : selectedDesign == null
        ? 2
        : 3;
    return PopScope(
      canPop:
          !busy &&
          pendingFrame == null &&
          !(draft?.dirty ?? false) &&
          !widget.store.documents.hasPending(widget.projectId),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Live design'),
          actions: [
            if (widget.settingsBuilder != null)
              IconButton(
                tooltip: 'Settings',
                onPressed: busy ? null : _settings,
                icon: const Icon(Icons.settings_outlined),
              ),
          ],
        ),
        bottomNavigationBar: roomId == null
            ? null
            : AiActivityStrip(
                activity: widget.store.ai.activity,
                roomId: roomId!,
              ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final (i, name) in [
                      'View',
                      'Analyse',
                      'Direction',
                      'Preview',
                    ].indexed)
                      Chip(
                        label: Text('${i + 1} $name'),
                        backgroundColor: stage == i
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side = constraints.maxWidth >= 700;
                    final canvas = ColoredBox(
                      color: Colors.black,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RoomCameraSurface(feed: feed),
                          if (original && reference != null)
                            IgnorePointer(
                              child: Image.memory(
                                reference,
                                fit: BoxFit.contain,
                              ),
                            ),
                          if (overlay && result != null)
                            IgnorePointer(
                              child: Opacity(
                                key: const ValueKey('live-design-overlay'),
                                opacity: opacity,
                                child: Image.memory(
                                  result,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          if (settle != null)
                            const Center(
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('Hold this viewpoint…'),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 8,
                            left: 8,
                            right: 8,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    overlay
                                        ? 'Live camera + saved design · match the reference view'
                                        : original
                                        ? 'Saved reference photo'
                                        : overlayRequested && result != null
                                        ? 'Design saved · waiting for camera'
                                        : 'Live camera · on this device',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      backgroundColor: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (result != null)
                                  IconButton(
                                    tooltip: overlay
                                        ? 'Show camera only'
                                        : 'Show saved design on camera',
                                    onPressed: overlay
                                        ? _showCameraOnly
                                        : _showSavedDesignOnCamera,
                                    style: IconButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.black54,
                                    ),
                                    icon: Icon(
                                      overlay
                                          ? Icons.visibility_off_outlined
                                          : Icons.layers_outlined,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                    return Flex(
                      direction: side ? Axis.horizontal : Axis.vertical,
                      children: [
                        Expanded(child: canvas),
                        SizedBox(
                          width: side ? 360 : null,
                          height: side ? null : constraints.maxHeight * .5,
                          child: SingleChildScrollView(child: _controls()),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
