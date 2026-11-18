import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show listEquals;

import 'ai_service.dart';
import 'models.dart';
import 'store.dart';
import 'ai_activity.dart';
import 'image_viewer.dart';
import 'room_draft.dart';
import 'design_concepts.dart';
import 'design_delete_widgets.dart';
import 'context_help.dart';

class AiConnectionCard extends StatefulWidget {
  final AiService ai;
  const AiConnectionCard({super.key, required this.ai});
  @override
  State<AiConnectionCard> createState() => _AiConnectionCardState();
}

class _AiConnectionCardState extends State<AiConnectionCard> {
  late final TextEditingController url;
  final code = TextEditingController();
  final apiKey = TextEditingController();
  late bool direct;
  bool busy = false;
  String? message;
  @override
  void initState() {
    super.initState();
    url = TextEditingController(text: widget.ai.relayUrl);
    direct =
        widget.ai.isDirect || (!widget.ai.connected && widget.ai.preferDirect);
  }

  @override
  void dispose() {
    url.dispose();
    code.dispose();
    apiKey.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (direct) {
        await widget.ai.connectDirect(apiKey: apiKey.text);
      } else {
        await widget.ai.connect(url: url.text, pairingCode: code.text);
      }
      if (mounted) {
        code.clear();
        apiKey.clear();
        setState(
          () => message = direct
              ? 'Internet API connected. The key check generated no image. No laptop is needed for analysis or design generation.'
              : 'Relay connected. This check did not contact OpenAI or generate an image.',
        );
      }
    } on AiFailure catch (error) {
      if (mounted) setState(() => message = error.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await widget.ai.disconnect();
      if (mounted) {
        setState(
          () => message = 'AI disconnected and any saved API key removed. Projects are unchanged.',
        );
      }
    } on AiFailure catch (error) {
      if (mounted) setState(() => message = error.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.ai, widget.ai.activity]),
    builder: (context, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI connection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              (widget.ai.connected ? widget.ai.isDirect : direct)
                  ? 'Internet API sends photos and prompts directly from this device to OpenAI over HTTPS. No PC, local gateway or tunnel is needed. Enter your own OpenAI developer API key.'
                  : 'Development option: start the relay on your PC and enter its connection code here. The OpenAI key is entered in the relay terminal. Your phone needs that PC connection in this mode.',
            ),
            const SizedBox(height: 12),
            if (widget.ai.connectionNotice != null)
              Text(widget.ai.connectionNotice!),
            if (widget.ai.connected) ...[
              Text(
                widget.ai.isDirect
                    ? 'Connection: internet API · api.openai.com'
                    : 'Connection: laptop relay · development',
              ),
              Text(
                'Connected to OpenAI · ${widget.ai.model} · ${widget.ai.quality} quality',
              ),
              Text(
                widget.ai.supportsAnalysis
                    ? 'Room photo analysis: ${widget.ai.analysisModel}'
                    : 'Photo analysis unavailable on this connection. Reconnect in Settings.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('image-model-${widget.ai.model}'),
                      initialValue: widget.ai.model,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Image model',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final value in widget.ai.imageModels)
                          DropdownMenuItem(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: busy || widget.ai.activity.active
                          ? null
                          : (value) {
                              if (value != null) {
                                widget.ai.selectImageSettings(
                                  imageModel: value,
                                  imageQuality: widget.ai.quality!,
                                );
                              }
                            },
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('image-quality-${widget.ai.quality}'),
                      initialValue: widget.ai.quality,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Image quality',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final value in widget.ai.imageQualities)
                          DropdownMenuItem(value: value, child: Text(value)),
                      ],
                      onChanged: busy || widget.ai.activity.active
                          ? null
                          : (value) {
                              if (value != null) {
                                widget.ai.selectImageSettings(
                                  imageModel: widget.ai.model!,
                                  imageQuality: value,
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Selection is local and sends no photos. Model access depends on your API account. Higher quality and extra attempts can cost more; review each request before sending.',
              ),
              TextButton(
                onPressed: busy || widget.ai.activity.active
                    ? null
                    : _disconnect,
                child: Text(
                  widget.ai.isDirect
                      ? 'Disconnect and remove API key'
                      : 'Disconnect AI',
                ),
              ),
            ] else ...[
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Internet API')),
                  ButtonSegment(value: false, label: Text('Laptop relay')),
                ],
                selected: {direct},
                onSelectionChanged: busy || widget.ai.activity.active
                    ? null
                    : (values) => setState(() {
                        direct = values.first;
                        message = null;
                      }),
              ),
              const SizedBox(height: 12),
              if (direct) ...[
                TextField(
                  controller: apiKey,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  autofillHints: const [],
                  maxLength: 1024,
                  decoration: const InputDecoration(
                    labelText: 'OpenAI API key',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                Text(
                  widget.ai.keyRememberedOnDevice
                      ? 'Saved encrypted using Android Keystore. The key stays separate from project files and backups.'
                      : 'Kept in memory for this session only. This browser does not save your API key.',
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy || widget.ai.activity.active
                      ? null
                      : _connect,
                  child: Text(
                    busy ? 'Checking API key…' : 'Connect OpenAI over internet',
                  ),
                ),
                TextButton(
                  onPressed: busy || widget.ai.activity.active
                      ? null
                      : _disconnect,
                  child: const Text('Remove saved API key'),
                ),
              ] else ...[
                TextField(
                  controller: url,
                  decoration: const InputDecoration(
                    labelText: 'Local relay address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: code,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Relay connection code (not your API key)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy ? null : _connect,
                  child: Text(busy ? 'Connecting…' : 'Connect local AI'),
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
      ),
    ),
  );
}

class AiEditRequest {
  final String roomId;
  final String? parentId;
  final String sourceImageId;
  final Uint8List image;
  final String prompt;
  final String title;
  final String instructions;
  final bool precise;
  final Map<String, Uint8List> supportingImages;
  final List<String> styleIds;
  final String otherStyle;
  const AiEditRequest({
    required this.roomId,
    required this.parentId,
    required this.sourceImageId,
    required this.image,
    required this.prompt,
    required this.title,
    required this.instructions,
    required this.precise,
    this.supportingImages = const {},
    this.styleIds = const [],
    this.otherStyle = '',
  });

  AiEditRequest concept(DesignConcept concept, int index, int total) =>
      AiEditRequest(
        roomId: roomId,
        parentId: parentId,
        sourceImageId: sourceImageId,
        image: image,
        supportingImages: supportingImages,
        styleIds: styleIds,
        otherStyle: otherStyle,
        prompt: concept.prompt,
        title: total == 1
            ? title
            : '$title · ${index + 1}/$total ${concept.label}',
        instructions: instructions,
        precise: precise,
      );
}

class AiEditCard extends StatefulWidget {
  final RenovisionStore store;
  final AiEditRequest Function() buildRequest;
  final ValueChanged<DesignVersion> onSaved;
  final ValueChanged<bool>? onPendingChanged;
  final bool showSavedPreview;
  final RoomDraft? draft;
  const AiEditCard({
    super.key,
    required this.store,
    required this.buildRequest,
    required this.onSaved,
    this.onPendingChanged,
    this.showSavedPreview = true,
    this.draft,
  });
  @override
  State<AiEditCard> createState() => _AiEditCardState();
}

class _AiEditCardState extends State<AiEditCard>
    with AutomaticKeepAliveClientMixin<AiEditCard> {
  @override
  bool get wantKeepAlive => true;
  bool busy = false;
  bool generating = false;
  String? message;
  AiResult? pending;
  AiEditRequest? request;
  int localCount = 1;
  bool localCompare = true;
  int plannedCount = 1;
  bool stopAfterCurrent = false;
  bool duplicate = false;
  final received = <DesignVersion>[];
  bool get precise => widget.draft?.preciseEdit ?? false;
  int get count => precise ? 1 : widget.draft?.conceptCount ?? localCount;
  bool get compare => widget.draft?.compareStyles ?? localCompare;
  void setCount(int value) => setState(() {
    localCount = value;
    widget.draft?.setConceptCount(value);
  });
  String summary() =>
      '${plannedCount == 1 ? 'AI result saved as a new version. Compare it before approving a new baseline.' : 'Saved ${received.length} of $plannedCount concepts as separate versions. Choose a design below to use it.'}${received.length < plannedCount ? ' Remaining concepts were not requested. Generating again starts a new batch.' : ''}${duplicate ? ' An output is byte-for-byte identical to an existing image. It was retained for history; no automatic replacement was requested.' : ''}';

  Future<void> _generate() async {
    if (busy || pending != null || widget.store.ai.activity.active) return;
    final imageModel = widget.store.ai.model;
    final imageQuality = widget.store.ai.quality;
    late AiEditRequest captured;
    late List<AiEditRequest> requests;
    try {
      captured = widget.buildRequest();
      final plans = planDesignConcepts(
        prompt: captured.prompt,
        precise: captured.precise,
        count: count,
        styleIds: captured.styleIds,
        compareStyles: compare,
        otherStyle: captured.otherStyle,
        previousConcepts: widget.store
            .designsFor(captured.roomId)
            .where((v) => v.aiProvider != null)
            .length,
      );
      requests = [
        for (final (index, plan) in plans.indexed)
          captured.concept(plan, index, plans.length),
      ];
    } on AiFailure catch (error) {
      setState(() => message = null);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Check the design request'),
          content: Text(error.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (!mounted) return;
    if (captured.precise && captured.instructions.trim().isEmpty) {
      setState(
        () => message =
            'Describe the specific change before generating a precision edit.',
      );
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    widget.onPendingChanged?.call(true);
    var activityStarted = false;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            requests.length == 1
                ? 'Send this edit to OpenAI?'
                : 'Generate ${requests.length} design concepts?',
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.memory(
                    captured.image,
                    height: 130,
                    fit: BoxFit.contain,
                  ),
                  if (captured.supportingImages.isNotEmpty) ...[
                    Text(
                      '${captured.supportingImages.length} supporting room views will also be sent:',
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final bytes in captured.supportingImages.values)
                          Image.memory(
                            bytes,
                            width: 85,
                            height: 65,
                            fit: BoxFit.contain,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    '$imageModel · $imageQuality quality · ${captured.supportingImages.length + 1} input views · ${requests.length == 1 ? 'one result' : '${requests.length} separate paid image requests'}',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The working image, any supporting views shown above, and prompt will leave this device and be sent to OpenAI. API charges apply and additional inputs can increase cost. Each metadata-free working copy is limited to 2048 pixels on its longest side. Your originals and approved baseline remain unchanged. Precise preservation and a consistent 3D reconstruction are not guaranteed.',
                  ),
                  const SizedBox(height: 12),
                  if (requests.length > 1)
                    const Text(
                      'The same starting image and settings are used for every concept. Each result is saved before the next request. Stop after this image prevents further requests; the current request may still be billed.',
                    ),
                  for (final item in requests)
                    if (requests.length == 1)
                      Text(item.prompt)
                    else
                      ExpansionTile(
                        title: Text(item.title),
                        children: [SelectableText(item.prompt)],
                      ),
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
              child: const Text('Send to OpenAI'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      if (widget.store.ai.activity.active) return;
      widget.store.ai.activity.begin(
        roomId: captured.roomId,
        operation: 'Design',
      );
      activityStarted = true;
      setState(() {
        generating = true;
        plannedCount = requests.length;
        stopAfterCurrent = false;
        duplicate = false;
        received.clear();
      });
      await WidgetsBinding.instance.endOfFrame;
      for (final (index, item) in requests.indexed) {
        if (!mounted || (index > 0 && stopAfterCurrent)) break;
        request = item;
        widget.store.ai.activity.operation = requests.length == 1
            ? 'Design'
            : 'Design ${index + 1}/${requests.length}';
        pending = await widget.store.ai.edit(
          image: item.image,
          prompt: item.prompt,
          supportingImages: item.supportingImages.values.toList(),
          imageModel: imageModel,
          imageQuality: imageQuality,
          onProgress: (stage) {
            if (mounted) widget.store.ai.activity.update(stage);
          },
        );
        duplicate =
            duplicate ||
            listEquals(pending!.image, item.image) ||
            widget.store
                .designsFor(item.roomId)
                .any(
                  (v) => listEquals(
                    pending!.image,
                    widget.store.imageFor(v.imageId),
                  ),
                );
        if (!await _savePending(finish: false)) break;
      }
      if (mounted && pending == null) {
        widget.store.ai.activity.update(AiStage.completed);
        setState(() => message = summary());
      }
    } on AiFailure catch (error) {
      if (activityStarted && mounted) {
        widget.store.ai.activity.update(AiStage.failed, detail: error.message);
      }
      if (mounted) {
        setState(
          () => message =
              '${received.length} concepts saved. ${error.message} Remaining concepts were not requested.',
        );
      }
    } catch (_) {
      if (activityStarted && mounted) {
        widget.store.ai.activity.update(
          AiStage.failed,
          detail: 'The request did not finish. No automatic retry was sent. Check usage before generating again.',
        );
      }
      if (mounted) {
        setState(
          () => message = 'The edit could not be completed. No automatic retry was made. Check your provider usage before trying again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          generating = false;
        });
        widget.onPendingChanged?.call(pending != null);
      }
    }
  }

  Future<bool> _savePending({bool finish = true}) async {
    final result = pending;
    final captured = request;
    if (result == null || captured == null) return false;
    try {
      if (mounted) widget.store.ai.activity.update(AiStage.saving);
      await WidgetsBinding.instance.endOfFrame;
      final design = await widget.store.createDesign(
        roomId: captured.roomId,
        image: result.image,
        title: result.quality == null
            ? captured.title
            : '${captured.title} · ${result.model} / ${result.quality}',
        prompt: captured.prompt,
        parentId: captured.parentId,
        sourceImageId: captured.sourceImageId,
        supportingImageIds: captured.supportingImages.keys.toList(),
        aiProvider: result.provider,
        aiModel: result.model,
        providerRequestId: result.requestId,
      );
      pending = null;
      request = null;
      if (mounted) {
        if (finish) widget.store.ai.activity.update(AiStage.completed);
        received.add(design);
        widget.onSaved(design);
        setState(
          () => message = finish
              ? summary()
              : 'Saved concept ${received.length} of $plannedCount.',
        );
      }
      return true;
    } catch (_) {
      if (mounted) {
        widget.store.ai.activity.update(
          AiStage.saveFailed,
          detail: 'Keep this screen open and use Retry saving result. Retrying this save does not call AI again.',
        );
        setState(
          () => message = 'The AI result arrived, but local saving failed. Keep this screen open and retry saving; this does not call OpenAI again. Remaining concepts were not requested.',
        );
      }
      return false;
    }
  }

  Future<void> _retrySave() async {
    if (busy || widget.store.ai.activity.active || request == null) return;
    widget.store.ai.activity.begin(
      roomId: request!.roomId,
      operation: 'Design',
    );
    setState(() => busy = true);
    try {
      await _savePending();
    } finally {
      if (mounted) setState(() => busy = false);
      if (mounted) widget.onPendingChanged?.call(pending != null);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.store,
        widget.store.ai,
        widget.store.ai.activity,
      ]),
      builder: (context, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HelpHeading(
                title: 'Generate inside Renovision',
                message: 'The image selected in Working from is sent as the reference. Select an original room photo for fresh alternatives, or a saved design for variations on it. AI variation is requested, not guaranteed.\n\nMultiple design ideas makes 2 or 3 separate paid image requests from the same starting image. Compare styles separately uses one selected style per image; an extra concept blends them. With comparison off, every concept blends the selected influences. Each result saves before the next request; you can stop after the current image.',
              ),
              const SizedBox(height: 8),
              Text(
                widget.store.ai.connected
                    ? 'OpenAI · ${widget.store.ai.model} · ${widget.store.ai.quality} quality. Uses the image currently selected in “Working from”.'
                    : 'Connect AI in Settings to generate and save a result here.',
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Multiple design ideas'),
                subtitle: Text(
                  precise
                      ? 'One image in precise correction mode.'
                      : '2–3 images; each is a separate paid request.',
                ),
                value: count > 1,
                onChanged:
                    busy ||
                        pending != null ||
                        precise ||
                        widget.store.ai.activity.active
                    ? null
                    : (value) => setCount(value == true ? 3 : 1),
              ),
              if (count > 1) ...[
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 2, label: Text('2 concepts')),
                    ButtonSegment(value: 3, label: Text('3 concepts')),
                  ],
                  selected: {count},
                  onSelectionChanged:
                      busy || pending != null || widget.store.ai.activity.active
                      ? null
                      : (values) => setCount(values.first),
                ),
                if ((widget.draft?.styleIds.length ?? 0) > 1)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Compare styles separately'),
                    subtitle: const Text(
                      'One style per image; an extra image blends them.',
                    ),
                    value: compare,
                    onChanged:
                        busy ||
                            pending != null ||
                            widget.store.ai.activity.active
                        ? null
                        : (value) => setState(() {
                            localCompare = value ?? true;
                            widget.draft?.setCompareStyles(localCompare);
                          }),
                  ),
              ],
              if (!widget.store.ai.connected)
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('AI connection')),
                        body: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: AiConnectionCard(ai: widget.store.ai),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Set up AI connection'),
                ),
              if (pending == null)
                FilledButton.icon(
                  onPressed:
                      busy ||
                          !widget.store.ai.connected ||
                          widget.store.ai.activity.active
                      ? null
                      : _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    busy
                        ? 'Generating…'
                        : count > 1
                        ? 'Generate $count redesign options'
                        : 'Generate AI design',
                  ),
                ),
              if (pending != null) ...[
                ExpandableImage(
                  bytes: pending!.image,
                  title: 'Generated design · not yet saved',
                ),
                FilledButton(
                  onPressed: busy ? null : _retrySave,
                  child: const Text('Retry saving result'),
                ),
              ],
              if (generating && plannedCount > 1)
                TextButton(
                  onPressed: stopAfterCurrent
                      ? null
                      : () => setState(() => stopAfterCurrent = true),
                  child: Text(
                    stopAfterCurrent
                        ? 'Stopping after current image…'
                        : 'Stop after this image',
                  ),
                ),
              if (widget.showSavedPreview)
                for (final design in received.where(
                  (d) => !widget.store.isDesignDeleted(d.id),
                )) ...[
                  Text(
                    design.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ExpandableImage(
                    bytes: widget.store.imageFor(design.imageId)!,
                    title: design.title,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: busy ? null : () => widget.onSaved(design),
                        child: const Text('Use this design'),
                      ),
                      DeleteDesignButton(
                        store: widget.store,
                        design: design,
                        enabled: !busy,
                      ),
                    ],
                  ),
                ],
              if (generating)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(),
                ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(message!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AiTestJourneyCard extends StatelessWidget {
  final AiService ai;
  final bool requestPending;
  const AiTestJourneyCard({
    super.key,
    required this.ai,
    this.requestPending = false,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ai,
    builder: (context, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test AI with this room',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              ai.connected ? 'Connected · ${ai.model} · ${ai.quality} quality' : 'Connect AI in Settings to analyse photos and generate inside the app.',
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Connect AI and choose a model.\n2. Analyse room photos and review the proposed prompt.\n3. Generate, compare and approve a design.\n4. Select that design to refine it.',
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: requestPending
                  ? null
                  : () => showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AiConnectionCard(ai: ai),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Done'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
              icon: const Icon(Icons.settings_input_component_outlined),
              label: Text(
                ai.connected ? 'AI model and connection' : 'Connect AI',
              ),
            ),
            const Text(
              'API access and billing are separate from a ChatGPT subscription. Connecting and changing settings do not call OpenAI; analysis and generation each ask before sending photos.',
            ),
          ],
        ),
      ),
    ),
  );
}
