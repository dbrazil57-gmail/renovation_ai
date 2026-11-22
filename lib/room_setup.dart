import 'package:material_ui/material_ui.dart';

import 'ai_service.dart';
import 'ai_widgets.dart';
import 'ai_activity_widget.dart';
import 'colour_palette_widgets.dart';
import 'design_style_widgets.dart';
import 'design_styles.dart';
import 'exit_guard.dart';
import 'models.dart';
import 'project_transfer_widgets.dart';
import 'renovation_scope_widgets.dart';
import 'room_analysis_widgets.dart';
import 'room_draft.dart';
import 'room_photos.dart';
import 'room_prompt.dart';
import 'store.dart';
import 'image_viewer.dart';
import 'design_delete_widgets.dart';
import 'screen_toolbar.dart';
import 'room_save_widgets.dart';
import 'brief_readiness.dart';

class RoomSetupScreen extends StatefulWidget {
  final RenovisionStore store;
  final String roomId;
  final Widget Function(String? designId) workspace;
  final WidgetBuilder? settingsBuilder;
  const RoomSetupScreen({
    super.key,
    required this.store,
    required this.roomId,
    required this.workspace,
    this.settingsBuilder,
  });
  @override
  State<RoomSetupScreen> createState() => _RoomSetupScreenState();
}

class _RoomSetupScreenState extends State<RoomSetupScreen> {
  late final RoomDraft draft;
  late final PageExitGuard exitGuard;
  final scroll = ScrollController();
  bool analysing = false, generating = false, saving = false;
  bool get busy => analysing || generating || saving;
  String? message, designId;
  RenovationRoom get room => widget.store.roomById(widget.roomId)!;
  int get step => room.setupStep;
  static const steps = [
    'Room photos',
    'Design direction',
    'Analyse and review',
    'Finalise and generate',
  ];

  @override
  void initState() {
    super.initState();
    draft = RoomDraft(widget.store, room);
    exitGuard = createPageExitGuard(() {
      draft.save();
    });
    draft.addListener(updateGuard);
    widget.store.documents.addListener(updateGuard);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await widget.store.rememberRoom(widget.roomId);
      } catch (_) {
        /* Local room still available. */
      }
    });
  }

  void updateGuard() => exitGuard.setPending(
    draft.dirty || busy || widget.store.documents.pending,
  );

  Future<bool> save() async {
    if (!await draft.save()) {
      if (mounted) {
        setState(
          () => message = 'Saving failed. Keep this screen open and try again.',
        );
      }
      return false;
    }
    return true;
  }

  Future<void> move(int next) async {
    if (busy) return;
    setState(() {
      saving = true;
      message = null;
    });
    try {
      if (!await save()) return;
      await widget.store.updateRoom(room.copyWith(setupStep: next.clamp(0, 3)));
      if (scroll.hasClients) scroll.jumpTo(0);
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Could not save your setup progress. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
      updateGuard();
    }
  }

  Future<void> leave({bool finish = false}) async {
    if (busy) return;
    setState(() => saving = true);
    try {
      if (!await save()) return;
      if (finish) {
        await widget.store.updateRoom(
          room.copyWith(setupComplete: true, setupStep: 3),
        );
      }
      if (widget.store.documents.linked(room.projectId)) {
        await widget.store.documents.save(room.projectId);
      }
      if (!mounted) return;
      if (finish) {
        Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute(
            builder: (_) => widget.workspace(
              designId != null && widget.store.isDesignDeleted(designId!)
                  ? null
                  : designId,
            ),
          ),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Could not finish saving. Your local work is retained; retry saving or choose a project file in Settings.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
      if (mounted) updateGuard();
    }
  }

  AiEditRequest request({bool analysis = false}) {
    final current = room;
    final sourceDesign = widget.store
        .designsFor(current.id)
        .where((d) => d.id == designId)
        .firstOrNull;
    final sourceId = sourceDesign?.imageId ?? current.primaryId;
    final supporting = {
      for (final id in current.photoIds.where((id) => id != sourceId))
        id:
            widget.store.imageFor(id) ??
            (throw const AiFailure('A room photo is unavailable.')),
    };
    final text = draft.preciseEdit ? draft.correction.text : draft.changes.text;
    if (draft.preciseEdit &&
        (text.trim().isEmpty || isWholeRoomRequest(text))) {
      throw const AiFailure(
        'Describe one specific correction, or choose Whole-room renovation.',
      );
    }
    final template = roomTemplatePrompt(current, draft);
    if (!analysis &&
        draft.useAiPrompt &&
        (draft.aiPrompt.text.trim().isEmpty ||
            !(draft.analysis?.matches(sourceId, supporting.keys, template) ??
                false))) {
      throw const AiFailure(
        'The reviewed AI prompt is out of date. Analyse again or untick Use this AI prompt.',
      );
    }
    final prompt = analysis ? template : reviewedRoomPrompt(template, draft);
    if (prompt.length > 16000) {
      throw const AiFailure('Shorten the prompt before generating.');
    }
    return AiEditRequest(
      roomId: current.id,
      parentId: sourceDesign?.id,
      sourceImageId: sourceId,
      image: widget.store.imageFor(sourceId)!,
      supportingImages: supporting,
      styleIds: draft.styleIds.toList(),
      otherStyle: draft.otherStyle.text,
      prompt: prompt,
      instructions: text,
      precise: draft.preciseEdit,
      title: draft.preciseEdit ? 'AI precision edit' : 'AI renovation concept',
    );
  }

  @override
  void dispose() {
    draft.removeListener(updateGuard);
    widget.store.documents.removeListener(updateGuard);
    exitGuard.dispose();
    draft.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> openSettings() async {
    if (busy || widget.settingsBuilder == null) return;
    setState(() => saving = true);
    updateGuard();
    try {
      if (await save() && mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: widget.settingsBuilder!),
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
        updateGuard();
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.store,
      draft,
      widget.store.documents,
      widget.store.ai,
    ]),
    builder: (context, _) {
      final current = room;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) leave();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Set up ${current.displayName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              ScreenToolbar(
                tools: [
                  ScreenTool(
                    ScreenAction.save,
                    label: 'Save project file',
                    onPressed: busy
                        ? null
                        : () => showProjectSaveDialog(
                            context,
                            store: widget.store,
                            projectId: current.projectId,
                            beforeSave: save,
                          ),
                  ),
                  if (widget.settingsBuilder != null)
                    ScreenTool(
                      ScreenAction.settings,
                      label: 'Room settings',
                      onPressed: busy ? null : openSettings,
                    ),
                  autosaveMenuTool(context, widget.store, enabled: !busy),
                  ScreenTool(
                    ScreenAction.finishLater,
                    label: 'Finish later',
                    onPressed: busy ? null : () => leave(),
                  ),
                  ScreenTool.help(
                    context,
                    title: 'Room setup tools',
                    message: 'Save keeps a complete project file. Settings opens saving and AI options. Finish later saves your current setup step so you can continue later. The bottom buttons move through the four steps.',
                  ),
                ],
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 950),
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(12),
                children: [
                  Text(
                    'Step ${step + 1} of 4 · ${steps[step]}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: (step + 1) / 4),
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      analysing
                          ? 'Analysing room photos…'
                          : generating
                          ? 'Generating design and saving the result…'
                          : saving
                          ? 'Saving your work…'
                          : draft.status,
                    ),
                  ),
                  if (message != null) Text(message!),
                  const SizedBox(height: 16),
                  if (step == 0) ...[
                    const Text(
                      'Your first photos are saved. Add more angles if useful and choose the primary view. This sets the camera viewpoint for the design.',
                    ),
                    RoomPhotosCard(
                      store: widget.store,
                      room: current,
                      selectedPhotoId: current.primaryId,
                      onView: (id) {
                        widget.store.setPrimaryPhoto(current.id, id).catchError(
                          (_) {
                            if (mounted) {
                              setState(
                                () => message =
                                    'Could not save the primary view.',
                              );
                            }
                          },
                        );
                      },
                      includeContext: true,
                      onContextChanged: null,
                    ),
                    ProjectFileControls(
                      store: widget.store,
                      projectId: current.projectId,
                      beforeSave: save,
                    ),
                  ],
                  if (step == 1 || step == 3) ...[
                    if (step == 3)
                      ExpandableImage(
                        bytes: widget.store.imageFor(current.primaryId)!,
                        title: '${current.displayName} · original',
                        height: 220,
                      ),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Whole-room renovation'),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Precise correction'),
                        ),
                      ],
                      selected: {draft.preciseEdit},
                      onSelectionChanged: busy
                          ? null
                          : (values) => draft.setPrecise(values.first),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: ValueKey('setup-goal-${draft.preciseEdit}'),
                      controller: draft.preciseEdit
                          ? draft.correction
                          : draft.changes,
                      minLines: 2,
                      maxLines: 5,
                      enabled: !busy,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: draft.preciseEdit
                            ? 'Specific correction'
                            : 'Your renovation goal (optional)',
                        hintText: 'Modernise the whole room; keep the layout.',
                      ),
                    ),
                    if (!draft.preciseEdit)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () {
                                draft.changes.text = 'Suggest a coordinated whole-room design using these photos.';
                              },
                        child: const Text('Suggest a design for me'),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: draft.protected,
                      minLines: 2,
                      maxLines: 4,
                      enabled: !busy,
                      decoration: const InputDecoration(
                        labelText: 'What must stay? (optional)',
                        hintText: 'Layout, windows, favourite furniture…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Keep the existing layout'),
                      value: draft.keepLayout,
                      onChanged: busy ? null : draft.setKeepLayout,
                    ),
                    if (!draft.preciseEdit) ...[
                      RoomColourPaletteCard(
                        store: widget.store,
                        room: current,
                        preview: widget.store.imageFor(current.primaryId),
                      ),
                      DesignStyleControls(draft: draft),
                      ExpansionTile(
                        key: const ValueKey('setup-advanced'),
                        title: const Text('Advanced Keep / Replace controls'),
                        children: [RenovationScopeControls(draft: draft)],
                      ),
                    ],
                  ],
                  if (step == 2 || step == 3) ...[
                    if (!widget.store.ai.supportsAnalysis)
                      const Text(
                        'AI analysis is optional. Your room is saved; connect AI below or continue with a clearly labelled prepared brief.',
                      ),
                    RoomAnalysisCard(
                      store: widget.store,
                      draft: draft,
                      buildRequest: () => request(analysis: true),
                      onBusyChanged: (value) {
                        setState(() => analysing = value);
                        updateGuard();
                      },
                    ),
                    AiConnectionSettingsCard(ai: widget.store.ai),
                  ],
                  if (step == 3) ...[
                    ExpansionTile(
                      title: const Text('Preview final prompt'),
                      children: [
                        SelectableText(
                          reviewedRoomPrompt(
                            roomTemplatePrompt(current, draft),
                            draft,
                          ),
                        ),
                      ],
                    ),
                    AiEditCard(
                      store: widget.store,
                      draft: draft,
                      onImproveBrief: (target) =>
                          move(target == BriefTarget.room ? 0 : 1),
                      buildRequest: request,
                      onPendingChanged: (value) {
                        if (mounted) setState(() => generating = value);
                        updateGuard();
                      },
                      onSaved: (design) {
                        if (mounted) setState(() => designId = design.id);
                      },
                    ),
                    if (designId != null &&
                        !widget.store.isDesignDeleted(designId!)) ...[
                      const Text(
                        'Design saved. Open the workspace to compare, approve or refine it.',
                      ),
                    ],
                    DeletedDesignsCard(store: widget.store, roomId: current.id),
                    ProjectFileControls(
                      store: widget.store,
                      projectId: current.projectId,
                      beforeSave: save,
                    ),
                  ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AiActivityStrip(
                  activity: widget.store.ai.activity,
                  roomId: current.id,
                  safeArea: false,
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      if (step > 0)
                        OutlinedButton(
                          onPressed: busy ? null : () => move(step - 1),
                          child: const Text('Back'),
                        ),
                      if (step < 3)
                        FilledButton(
                          onPressed: busy ? null : () => move(step + 1),
                          child: Text(
                            step == 2 ? 'Choose redesign options' : 'Continue',
                          ),
                        ),
                      if (step == 3)
                        FilledButton(
                          onPressed: busy ? null : () => leave(finish: true),
                          child: const Text('Open design workspace'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
