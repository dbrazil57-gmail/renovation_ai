import 'package:material_ui/material_ui.dart';

import 'ai_service.dart';
import 'ai_widgets.dart';
import 'room_analysis.dart';
import 'room_draft.dart';
import 'store.dart';
import 'ai_activity.dart';
import 'context_help.dart';

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

  bool get currentPhotos {
    try {
      final request = widget.buildRequest();
      return widget.draft.analysis?.matchesPhotos(
            request.sourceImageId,
            request.supportingImages.keys,
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
      final connectionRevision = widget.store.ai.connectionRevision;
      final providerLabel = widget.store.ai.providerLabel;
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
                  Text(
                    'These photos and your room preferences will be sent to $providerLabel. ${widget.store.ai.isTester ? 'This uses one owner-funded analysis allowance; the test service forwards the inputs to OpenAI.' : 'API charges apply.'} The AI will describe the room, flag uncertainties and draft a prompt. It will not generate a design image in this step. Originals stay saved in the app.',
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
      if (connectionRevision != widget.store.ai.connectionRevision) {
        setState(
          () => message = 'The AI connection changed. Review and confirm again. No photos were sent.',
        );
        return;
      }
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
      final received = RoomAnalysis(
        result: result,
        sourceImageId: request.sourceImageId,
        supportingImageIds: request.supportingImages.keys.toList(),
        context: request.prompt,
        created: DateTime.now().toUtc(),
      );
      var proposalCurrent = false;
      try {
        final latest = widget.buildRequest();
        proposalCurrent = received.matches(
          latest.sourceImageId,
          latest.supportingImages.keys,
          latest.prompt,
        );
      } catch (_) {
        // Retain the response, but do not adopt a proposal for a missing view.
      }
      widget.draft.setAnalysis(received, useProposal: proposalCurrent);
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
              ? 'Analysis and design proposal saved. Review your choices, then Generate to create an image.'
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
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HelpHeading(
                  title: 'Understand this room',
                  message: 'Analysis describes what is visible now. The design plan suggests what it could become using these photos, your style, palette, scope and Keep choices. Questions help refine the plan; no image is generated until you confirm Generate.',
                ),
                const SizedBox(height: 6),
                Text(
                  analysis == null
                      ? 'Photos saved · not analysed yet. AI can identify visible features and help write your design prompt.'
                      : widget.draft.preciseEdit
                      ? 'Saved analysis is available. Precise correction uses your specific instruction and Keep choices.'
                      : matches
                      ? widget.draft.useAiPrompt &&
                                widget.draft.aiPrompt.text.trim().isNotEmpty
                            ? 'Design plan ready · applied when you generate.'
                            : 'Photo observations ready · design plan is off or empty.'
                      : currentPhotos
                      ? 'Photo observations still match. Your next design uses your current choices; the earlier proposal is left out.'
                      : 'Photos have changed. Analyse the current view for fresh observations, or continue without this saved analysis.',
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
                    initiallyExpanded: false,
                    title: const Text('Room observations and design plan'),
                    subtitle: Text(
                      '${analysis.result.provider} · ${analysis.result.model} · ${analysis.created.toLocal()}',
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
                                'Details to refine',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              for (final question in analysis.result.questions)
                                Text('• $question'),
                              const Text(
                                'Add useful answers under What should change. They inform the next design; analyse again only to refresh this saved plan.',
                              ),
                            ],
                            const SizedBox(height: 12),
                            TextField(
                              controller: widget.draft.aiPrompt,
                              minLines: 4,
                              maxLines: 10,
                              maxLength: 8000,
                              decoration: const InputDecoration(
                                labelText: 'Suggested design plan (editable)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Apply this plan when generating',
                              ),
                              subtitle: const Text(
                                'Adds the plan above to your photos and current choices. Turn off to use your choices and photo observations only.',
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
                            if (widget.draft.useAiPrompt &&
                                !matches &&
                                !widget.draft.preciseEdit)
                              const Text(
                                'Earlier proposal retained for reference. It will not be sent with changed photos or choices; you can generate without analysing again.',
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
