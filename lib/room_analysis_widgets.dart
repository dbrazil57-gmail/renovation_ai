import 'package:material_ui/material_ui.dart';

import 'ai_service.dart';
import 'ai_widgets.dart';
import 'room_analysis.dart';
import 'room_draft.dart';
import 'store.dart';
import 'ai_activity.dart';

class RoomAnalysisCard extends StatefulWidget {
  final RenovisionStore store;
  final RoomDraft draft;
  final AiEditRequest Function() buildRequest;
  final ValueChanged<bool> onBusyChanged;
  final VoidCallback? onContinue;
  const RoomAnalysisCard({
    super.key,
    required this.store,
    required this.draft,
    required this.buildRequest,
    required this.onBusyChanged,
    this.onContinue,
  });
  @override
  State<RoomAnalysisCard> createState() => _RoomAnalysisCardState();
}

class _RoomAnalysisCardState extends State<RoomAnalysisCard>
    with AutomaticKeepAliveClientMixin<RoomAnalysisCard> {
  bool busy = false;
  bool analysing = false;
  String? message;
  @override
  bool get wantKeepAlive => true;

  bool get current {
    try {
      final request = widget.buildRequest();
      return widget.draft.analysis?.matches(
            request.sourceImageId,
            request.supportingImages.keys,
            request.prompt,
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _analyse() async {
    if (busy ||
        !widget.store.ai.supportsAnalysis ||
        widget.store.ai.activity.active) {
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    widget.onBusyChanged(true);
    var activityStarted = false;
    try {
      final request = widget.buildRequest();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Analyse these room photos?'),
          content: SizedBox(
            width: 470,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final bytes in [
                        request.image,
                        ...request.supportingImages.values,
                      ])
                        Image.memory(
                          bytes,
                          width: 110,
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.store.ai.analysisModel} · ${request.supportingImages.length + 1} photos',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These photos and your room preferences will be sent to OpenAI. API charges apply. The AI will describe the room, flag uncertainties and draft a prompt. It will not generate a design image in this step. Originals stay saved in the app.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Working copies have metadata removed and are resized to at most 2048 pixels. Review any uncertain observations; photos do not establish verified measurements.',
                  ),
                  const SizedBox(height: 8),
                  Text(request.prompt),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Send photos for analysis'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      if (widget.store.ai.activity.active) return;
      widget.store.ai.activity.begin(
        roomId: request.roomId,
        operation: 'Room analysis',
      );
      activityStarted = true;
      await WidgetsBinding.instance.endOfFrame;
      // Save local preferences first. Never pay for a request when storage is
      // already known to be failing. Keep a received result in the draft on failure.
      if (!await widget.draft.save()) {
        if (mounted) {
          widget.store.ai.activity.update(
            AiStage.failed,
            detail:
                'Local settings could not be saved. No AI request was sent.',
          );
        }
        if (mounted) {
          setState(
            () => message =
                'Save your pending changes successfully before analysing.',
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() => analysing = true);
      final result = await widget.store.ai.analyse(
        image: request.image,
        supportingImages: request.supportingImages.values.toList(),
        context: request.prompt,
        onProgress: (stage) {
          if (mounted) widget.store.ai.activity.update(stage);
        },
      );
      if (!mounted) return;
      widget.draft.setAnalysis(
        RoomAnalysis(
          result: result,
          sourceImageId: request.sourceImageId,
          supportingImageIds: request.supportingImages.keys.toList(),
          context: request.prompt,
          created: DateTime.now().toUtc(),
        ),
      );
      widget.store.ai.activity.update(AiStage.saving);
      await WidgetsBinding.instance.endOfFrame;
      final saved = await widget.draft.save();
      if (mounted) {
        widget.store.ai.activity.update(
          saved ? AiStage.completed : AiStage.saveFailed,
          detail: saved ? '' : 'Analysis received. Keep this screen open and retry saving; this does not call AI again.',
        );
        setState(
          () => message = saved
              ? 'Analysis saved. Review the observations and prompt before using it.'
              : 'Analysis received but not saved. Keep this room open and use Retry saving analysis; this will not call AI again.',
        );
      }
    } on AiFailure catch (error) {
      if (activityStarted && mounted) {
        widget.store.ai.activity.update(AiStage.failed, detail: error.message);
      }
      if (mounted) setState(() => message = error.message);
    } catch (_) {
      if (mounted) {
        if (activityStarted) {
          widget.store.ai.activity.update(
            AiStage.failed,
            detail: 'Analysis did not finish. No automatic retry was sent. Check usage before analysing again.',
          );
        }
        setState(
          () => message = 'Analysis could not finish. Previous results are retained. No automatic retry was made; check provider usage before trying again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          analysing = false;
        });
        widget.onBusyChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.store.ai,
        widget.draft,
        widget.store.ai.activity,
      ]),
      builder: (context, _) {
        final analysis = widget.draft.analysis;
        final matches = current;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Understand this room',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  analysis == null
                      ? 'Photos saved · not analysed yet. AI can identify visible features and help write your design prompt.'
                      : matches
                      ? 'Analysis available for the current photos and preferences.'
                      : 'Photos or preferences have changed. Review a new analysis before using an AI prompt.',
                ),
                if (!widget.store.ai.supportsAnalysis) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.store.ai.connected
                        ? 'Reconnect AI in Settings to enable photo analysis.'
                        : 'Photo analysis needs an AI connection with developer API access. Uploading alone does not contact AI.',
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('AI connection'),
                              content: SizedBox(
                                width: 470,
                                child: SingleChildScrollView(
                                  child: AiConnectionCard(ai: widget.store.ai),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Done'),
                                ),
                              ],
                            ),
                          ),
                    child: const Text('Connect AI'),
                  ),
                ],
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed:
                      busy ||
                          widget.store.ai.activity.active ||
                          !widget.store.ai.supportsAnalysis ||
                          widget.draft.state == DraftSaveState.failed
                      ? null
                      : _analyse,
                  icon: const Icon(Icons.image_search),
                  label: Text(
                    busy
                        ? 'Analysing room…'
                        : analysis == null
                        ? 'Analyse room photos'
                        : 'Analyse again',
                  ),
                ),
                if (analysing) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                  const Text(
                    'Waiting for room analysis. No design image is being generated.',
                  ),
                ],
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(message!),
                  ),
                if (widget.draft.state == DraftSaveState.failed)
                  TextButton(
                    onPressed: busy || widget.store.ai.activity.active
                        ? null
                        : () async {
                            widget.store.ai.activity.begin(
                              roomId: widget.draft.roomId,
                              operation: 'Room analysis',
                            );
                            widget.store.ai.activity.update(AiStage.saving);
                            final saved = await widget.draft.save();
                            if (mounted) {
                              widget.store.ai.activity.update(
                                saved ? AiStage.completed : AiStage.saveFailed,
                                detail: saved ? '' : 'Local saving still failed. No new AI request was sent.',
                              );
                              setState(
                                () => message = saved
                                    ? 'Analysis and room preferences saved locally.'
                                    : 'Saving still failed. Keep this room open and try again.',
                              );
                            }
                          },
                    child: const Text('Retry saving analysis'),
                  ),
                if (analysis != null &&
                    matches &&
                    !widget.draft.preciseEdit) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Choose your redesign options',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1 design')),
                      ButtonSegment(value: 2, label: Text('2 ideas')),
                      ButtonSegment(value: 3, label: Text('3 ideas')),
                    ],
                    selected: {widget.draft.conceptCount},
                    onSelectionChanged:
                        busy ||
                            widget.store.ai.activity.active ||
                            widget.draft.state == DraftSaveState.failed
                        ? null
                        : (values) =>
                              widget.draft.setConceptCount(values.first),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Review the brief below, then generate your options. Each image is a separate paid request. Choose a result with Use this design, then refine it. Selecting a count does not generate images.',
                  ),
                  if (widget.onContinue != null)
                    TextButton.icon(
                      onPressed: busy || widget.store.ai.activity.active
                          ? null
                          : widget.onContinue,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continue to design options'),
                    ),
                ],
                if (analysis != null)
                  ExpansionTile(
                    initiallyExpanded: true,
                    title: const Text('Room observations and AI prompt'),
                    subtitle: Text(
                      'OpenAI · ${analysis.result.model} · ${analysis.created.toLocal()}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(analysis.result.observations),
                            if (analysis.result.questions.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Details to confirm',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              for (final question in analysis.result.questions)
                                Text('• $question'),
                              const Text(
                                'Add your answers to the room instructions, then analyse again.',
                              ),
                            ],
                            const SizedBox(height: 12),
                            TextField(
                              controller: widget.draft.aiPrompt,
                              minLines: 4,
                              maxLines: 10,
                              maxLength: 8000,
                              decoration: const InputDecoration(
                                labelText:
                                    'AI-prepared design prompt (editable)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Use this AI prompt for the next design',
                              ),
                              subtitle: const Text(
                                'Review it first. Your current room requirements remain attached to every design request.',
                              ),
                              value: widget.draft.useAiPrompt,
                              onChanged:
                                  busy ||
                                      (!widget.draft.useAiPrompt &&
                                          (!matches ||
                                              widget.draft.aiPrompt.text
                                                  .trim()
                                                  .isEmpty))
                                  ? null
                                  : (value) => widget.draft.setUseAiPrompt(
                                      value ?? false,
                                    ),
                            ),
                            if (widget.draft.useAiPrompt && !matches)
                              const Text(
                                'This prompt is out of date. Analyse again or untick it to use the local prompt.',
                              ),
                            Text(widget.draft.status),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
