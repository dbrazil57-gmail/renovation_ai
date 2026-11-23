import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show listEquals, kIsWeb;

import 'ai_service.dart';
import 'ai_usage.dart';
import 'ai_usage_widgets.dart';
import 'models.dart';
import 'store.dart';
import 'ai_activity.dart';
import 'image_viewer.dart';
import 'room_draft.dart';
import 'design_concepts.dart';
import 'design_delete_widgets.dart';
import 'context_help.dart';
import 'ai_model_choices.dart';
import 'walkthrough_screen.dart';
import 'design_recipe.dart';
import 'brief_readiness.dart';
import 'brief_readiness_widgets.dart';
import 'tester_access_widgets.dart';

class AiConnectionSettingsCard extends StatelessWidget {
  final AiService ai;
  const AiConnectionSettingsCard({super.key, required this.ai});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ai,
    builder: (context, _) => Card(
      child: ExpansionTile(
        key: const ValueKey('ai-connection-settings'),
        leading: const Icon(Icons.auto_awesome_outlined),
        title: const Text('AI connection and models'),
        subtitle: Text(
          ai.connected
              ? '${ai.providerLabel} · ${imageModelLabel(ai.model!)} · ${imageQualityLabel(ai.provider, ai.quality!)}'
              : 'Connect your API key and choose models',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          TesterAccessCard(ai: ai),
          AiConnectionCard(ai: ai),
        ],
      ),
    ),
  );
}

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
  late AiProvider selectedProvider;
  bool busy = false;
  String? message;
  @override
  void initState() {
    super.initState();
    url = TextEditingController(text: widget.ai.relayUrl);
    selectedProvider = widget.ai.provider;
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
        await widget.ai.connectDirect(
          apiKey: apiKey.text,
          provider: selectedProvider,
        );
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
    final removingTestInvitation = widget.ai.isTester;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (widget.ai.isTester) {
        await widget.ai.disconnect();
      } else {
        await widget.ai.removeProviderKey(selectedProvider);
      }
      if (mounted) {
        setState(
          () => message = removingTestInvitation
              ? 'Test invitation removed. Personal API keys and projects are unchanged.'
              : '${selectedProvider.label} key removed. Projects and other provider keys are unchanged.',
        );
      }
    } on AiFailure catch (error) {
      if (mounted) setState(() => message = error.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _refreshModels() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await widget.ai.refreshModels();
      if (mounted) {
        setState(
          () => message = 'Available models refreshed. No photos were sent or images generated.',
        );
      }
    } on AiFailure catch (error) {
      if (mounted) setState(() => message = error.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _useSavedKey() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await widget.ai.useSavedProvider(selectedProvider);
      if (mounted) {
        setState(
          () => message =
              'Saved ${selectedProvider.label} key connected. No photos were sent.',
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
            DropdownButtonFormField<AiProvider>(
              key: ValueKey('ai-provider-${selectedProvider.name}'),
              initialValue: selectedProvider,
              decoration: const InputDecoration(
                labelText: 'AI provider',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final value in AiProvider.values)
                  DropdownMenuItem(value: value, child: Text(value.label)),
              ],
              onChanged: busy || widget.ai.activity.active
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          selectedProvider = value;
                          direct = true;
                          apiKey.clear();
                          message = null;
                        });
                      }
                    },
            ),
            ExpansionTile(
              key: ValueKey('recommended-models-${selectedProvider.name}'),
              title: const Text('Recommended design models'),
              subtitle: const Text(
                'Starting shortlist for testing · not yet ranked',
              ),
              children: [
                for (final id in selectedProvider.recommendations)
                  ListTile(
                    dense: true,
                    title: Text(imageModelLabel(id)),
                    subtitle: Text(imageModelPurpose(id)),
                  ),
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Browse without a key. Connecting checks listed models; image access and billing depend on your account.',
                  ),
                ),
                TextButton.icon(
                  onPressed: busy || widget.ai.activity.active
                      ? null
                      : () => showModelComparisonWalkthrough(context),
                  icon: const Icon(Icons.balance_outlined),
                  label: const Text('How to compare models'),
                ),
                SwitchListTile(
                  title: const Text('Use fixed brief for model tests'),
                  subtitle: const Text(
                    'One result per test; skips rotating design directions. Reselect the same original each time. Resets off after restart.',
                  ),
                  value: widget.ai.fixedComparisonBrief,
                  onChanged: busy || widget.ai.activity.active
                      ? null
                      : widget.ai.setFixedComparisonBrief,
                ),
              ],
            ),
            Text(
              widget.ai.isTester
                  ? 'Owner-funded HTTPS test access is active. You can use your personal API key instead by disconnecting the invitation.'
                  : direct
                  ? 'Photos and prompts go directly to ${selectedProvider.label} over HTTPS after confirmation. Use a separate ${selectedProvider.label} developer API key; no laptop is needed.'
                  : 'Development option: start the relay on your PC and enter its connection code here. The OpenAI key is entered in the relay terminal. Your phone needs that PC connection in this mode.',
            ),
            const SizedBox(height: 12),
            if (widget.ai.connectionNotice != null)
              Text(widget.ai.connectionNotice!),
            if (widget.ai.connected && widget.ai.provider != selectedProvider)
              Text(
                'Active connection: ${widget.ai.providerLabel}. It stays active until the new provider connects successfully.',
              ),
            if (widget.ai.connected &&
                widget.ai.provider == selectedProvider) ...[
              Text(
                widget.ai.isTester
                    ? 'Connection: owner-funded HTTPS test access'
                    : widget.ai.isDirect
                    ? 'Connection: internet API · ${widget.ai.provider.host}'
                    : 'Connection: laptop relay · development',
              ),
              Text(
                'Connected to ${widget.ai.providerLabel} · ${widget.ai.model} · ${imageQualityLabel(widget.ai.provider, widget.ai.quality!)}',
              ),
              if (widget.ai.isDirect)
                HelpHeading(
                  title: widget.ai.keyRememberedOnDevice
                      ? (kIsWeb
                            ? 'API key remembered in this browser'
                            : 'API key saved securely on this device')
                      : 'API key kept for this session',
                  message: widget.ai.keyRememberedOnDevice
                      ? (kIsWeb
                            ? 'Your key is encrypted in private storage for this browser profile and app address. No login is needed. Reloading retains it; clearing site data removes it. Trusted code in this app can use it. Remove this provider key below to forget it. Keys are excluded from project/backup files.'
                            : 'The key is stored separately from project files. Saving or discarding a project does not remove it.')
                      : 'Switching Room, Style, Refine, Ideas or Settings keeps this connection. Reloading or closing this browser page clears the session key, so you must enter it again. Save project does not save an API key. A browser password-manager Save / Don\'t save choice is separate from RenoVision.',
                ),
              Text(
                widget.ai.supportsAnalysis
                    ? 'Room photo analysis: ${widget.ai.analysisModel}'
                    : 'Photo analysis unavailable on this connection. Reconnect in Settings.',
              ),
              const SizedBox(height: 12),
              if (widget.ai.imageModels.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final preset in [
                      ('Showcase concept', false, 'high'),
                      ('Quick ideas', true, 'low'),
                      ('Final detail', false, 'high'),
                    ])
                      if (widget.ai.imageQualities.contains(preset.$3))
                        ActionChip(
                          label: Text(preset.$1),
                          tooltip:
                              '${imageQualityLabel(widget.ai.provider, preset.$3)}; changes settings only, no generation',
                          onPressed: busy || widget.ai.activity.active
                              ? null
                              : () {
                                  widget.ai.selectImageSettings(
                                    imageModel: recommendedImageModel(
                                      widget.ai.imageModels,
                                      fast: preset.$2,
                                      detailed: preset.$1 == 'Final detail',
                                    ),
                                    imageQuality: preset.$3,
                                  );
                                },
                        ),
                  ],
                ),
              const SizedBox(height: 8),
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
                            child: Tooltip(
                              message: '$value\n${imageModelPurpose(value)}',
                              child: Text(
                                imageModelLabel(value),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                      decoration: InputDecoration(
                        labelText: widget.ai.provider == AiProvider.gemini
                            ? 'Image resolution'
                            : 'Image quality',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final value in widget.ai.imageQualities)
                          DropdownMenuItem(
                            value: value,
                            child: Text(
                              imageQualityLabel(widget.ai.provider, value),
                            ),
                          ),
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
              Text(imageModelPurpose(widget.ai.model)),
              if (widget.ai.isDirect)
                TextButton.icon(
                  onPressed: busy || widget.ai.activity.active
                      ? null
                      : _refreshModels,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    busy ? 'Refreshing models…' : 'Refresh available models',
                  ),
                ),
              const Text(
                'Selection is local and sends no photos. Model access depends on your API account. Higher quality and extra attempts can cost more; review each request before sending.',
              ),
              const Text(
                'Each provider needs its own API key. Claude is not listed as a design renderer because it does not generate images.',
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
                        if (!direct) selectedProvider = AiProvider.openai;
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
                  enabled: !busy && !widget.ai.activity.active,
                  decoration: InputDecoration(
                    labelText: '${selectedProvider.label} API key',
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                Text(
                  widget.ai.storeFor(selectedProvider).persistent
                      ? 'Saved encrypted using Android Keystore. The key stays separate from project files and backups.'
                      : 'Kept in memory for this session only. This browser does not save your API key.',
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy || widget.ai.activity.active
                      ? null
                      : _connect,
                  child: Text(
                    busy
                        ? 'Checking API key…'
                        : 'Connect ${selectedProvider.label} over internet',
                  ),
                ),
                TextButton(
                  onPressed: busy || widget.ai.activity.active
                      ? null
                      : _useSavedKey,
                  child: const Text('Use saved provider key'),
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
  final DesignRecipe? recipe;
  final String roomId;
  final String? parentId;
  final String sourceImageId;
  final Uint8List image;
  final String prompt;
  final String title;
  final String instructions;
  final bool precise;
  final Map<String, Uint8List> supportingImages;
  final bool finishPolish;
  final List<String> styleIds;
  final String otherStyle;
  const AiEditRequest({
    this.recipe,
    required this.roomId,
    required this.parentId,
    required this.sourceImageId,
    required this.image,
    required this.prompt,
    required this.title,
    required this.instructions,
    required this.precise,
    this.supportingImages = const {},
    this.finishPolish = false,
    this.styleIds = const [],
    this.otherStyle = '',
  });

  AiEditRequest concept(
    DesignConcept concept,
    int index,
    int total, {
    DesignRecipe? recipe,
  }) => AiEditRequest(
    recipe:
        recipe?.withValues({'conceptDirection': concept.label}) ?? this.recipe,
    roomId: roomId,
    parentId: parentId,
    sourceImageId: sourceImageId,
    image: image,
    supportingImages: supportingImages,
    finishPolish: finishPolish,
    styleIds: styleIds,
    otherStyle: otherStyle,
    prompt: concept.prompt,
    title: total == 1 ? title : '$title · ${index + 1}/$total ${concept.label}',
    instructions: instructions,
    precise: precise,
  );
}

/// One mounted generation session can be triggered from a pinned workspace action.
/// The same confirmation, request capture and result-save guards remain in charge.
class AiEditController {
  _AiEditCardState? _owner;
  bool get needsAttention =>
      _owner?.pending != null ||
      (_owner?.received.isEmpty == true && _owner?.message != null);
  Future<void> generate({bool briefReviewed = false}) async =>
      _owner?._generate(briefReviewed: briefReviewed);
}

class AiEditCard extends StatefulWidget {
  final RenovisionStore store;
  final AiEditRequest Function() buildRequest;
  final ValueChanged<DesignVersion> onSaved;
  final ValueChanged<bool>? onPendingChanged;
  final bool showSavedPreview;
  final bool compact;
  final bool singleConcept;
  final bool enabled;
  final Future<bool> Function()? beforeSend;
  final String? buttonLabel;
  final RoomDraft? draft;
  final AiEditController? controller;
  final bool showGenerateButton;
  final ValueChanged<BriefTarget>? onImproveBrief;
  const AiEditCard({
    super.key,
    required this.store,
    required this.buildRequest,
    required this.onSaved,
    this.onPendingChanged,
    this.showSavedPreview = true,
    this.compact = false,
    this.singleConcept = false,
    this.enabled = true,
    this.beforeSend,
    this.buttonLabel,
    this.draft,
    this.controller,
    this.showGenerateButton = true,
    this.onImproveBrief,
  });
  @override
  State<AiEditCard> createState() => _AiEditCardState();
}

class _AiEditCardState extends State<AiEditCard>
    with AutomaticKeepAliveClientMixin<AiEditCard> {
  @override
  void initState() {
    super.initState();
    widget.controller?._owner = this;
  }

  @override
  void didUpdateWidget(AiEditCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._owner = null;
      widget.controller?._owner = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._owner == this) widget.controller?._owner = null;
    super.dispose();
  }

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
  int get count => widget.singleConcept
      ? 1
      : precise
      ? widget.draft!.precisionConceptCount
      : widget.draft?.conceptCount ?? localCount;
  bool get compare => widget.draft?.compareStyles ?? localCompare;
  void setCount(int value) => setState(() {
    localCount = value;
    if (precise) {
      widget.draft?.setPrecisionConceptCount(value);
    } else {
      widget.draft?.setConceptCount(value);
    }
  });
  String summary() =>
      '${plannedCount == 1 ? 'AI result saved as a new version. Compare it before approving a new baseline.' : 'Saved ${received.length} of $plannedCount concepts as separate versions. Choose a design below to use it.'}${received.length < plannedCount ? ' Remaining concepts were not requested. Generating again starts a new batch.' : ''}${duplicate ? ' An output is byte-for-byte identical to an existing image. It was retained for history; no automatic replacement was requested.' : ''}';

  Future<void> _generate({bool briefReviewed = false}) async {
    if (!widget.enabled ||
        busy ||
        pending != null ||
        widget.store.ai.activity.active) {
      return;
    }
    final imageModel = widget.store.ai.model;
    final imageQuality = widget.store.ai.quality;
    final fixedBrief = widget.store.ai.fixedComparisonBrief;
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
        fixedBrief: fixedBrief,
      );
      final room = widget.store.roomById(captured.roomId);
      final recipe =
          (widget.draft?.captureRecipe() ??
                  captured.recipe ??
                  (room == null
                      ? null
                      : DesignRecipe({
                          ...room.toMap(),
                          'preciseEdit': captured.precise,
                          if (captured.precise)
                            'correctionInstructions': captured.instructions
                          else
                            'instructions': captured.instructions,
                        })))
              ?.withValues({
                'provider': widget.store.ai.providerLabel,
                'imageModel': ?imageModel,
                'imageQuality': ?imageQuality,
                'fixedBrief': fixedBrief,
              });
      requests = [
        for (final (index, plan) in plans.indexed)
          captured.concept(plan, index, plans.length, recipe: recipe),
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
    } on FormatException {
      setState(
        () => message = 'The design settings could not be captured safely. Review the room choices before generating. No AI request was sent.',
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
    final readiness = widget.draft?.briefReadiness(
      imageAvailable: captured.image.isNotEmpty,
    );
    final showGuidance =
        !briefReviewed &&
        (readiness?.needsReminder(
              previouslyReviewed: widget.store.briefGuidanceReviewed(
                captured.roomId,
                precise: captured.precise,
              ),
            ) ??
            false);
    var improveBrief = false;
    setState(() {
      busy = true;
      message = null;
    });
    widget.onPendingChanged?.call(true);
    var activityStarted = false;
    final connectionRevision = widget.store.ai.connectionRevision;
    final providerLabel = widget.store.ai.providerLabel;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            captured.finishPolish
                ? 'Review AI finish polish'
                : requests.length == 1
                ? 'Send this edit to $providerLabel?'
                : captured.precise
                ? 'Generate ${requests.length} correction variations?'
                : 'Generate ${requests.length} design concepts?',
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (captured.finishPolish) ...[
                    const Text('Instructions to send'),
                    Container(
                      key: const ValueKey('polish-prompt-before-send'),
                      height: 170,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(captured.prompt),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (captured.finishPolish)
                    const Text('Clean design · image 1'),
                  Image.memory(
                    captured.image,
                    height: 130,
                    fit: BoxFit.contain,
                  ),
                  if (captured.supportingImages.isNotEmpty) ...[
                    Text(
                      captured.finishPolish
                          ? 'Rough finish guide · image 2'
                          : '${captured.supportingImages.length} supporting room views will also be sent:',
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
                    '$imageModel · ${imageQualityLabel(widget.store.ai.provider, imageQuality ?? 'not selected')} ${widget.store.ai.provider == AiProvider.gemini ? 'resolution' : 'quality'} · ${captured.supportingImages.length + 1} input views · ${requests.length == 1 ? 'one result' : '${requests.length} separate paid image requests'}',
                  ),
                  const SizedBox(height: 8),
                  if (showGuidance)
                    BriefReadinessGuidance(readiness: readiness!),
                  if (fixedBrief)
                    const Text(
                      'Fixed-brief model test: this sends the prepared prompt without added design directions. Check that the selected photos match your other tests.',
                    ),
                  Text(
                    'The working image, any supporting views shown above, and prompt will leave this device and be sent to $providerLabel. ${widget.store.ai.isTester ? 'This uses one owner-funded test design allowance per image. ${widget.store.ai.testerAllowance?.summary ?? ''}. The test service forwards these inputs to OpenAI.' : 'API charges apply and additional inputs can increase cost.'} Each metadata-free working copy is limited to 2048 pixels on its longest side. Your originals and approved baseline remain unchanged. Precise preservation and a consistent 3D reconstruction are not guaranteed.',
                  ),
                  const SizedBox(height: 12),
                  if (requests.length > 1)
                    Text(
                      captured.precise
                          ? 'Each variation applies the same specific correction to the same starting image. Variation is limited to choices your instruction leaves open; unrelated features stay protected. Each result saves before the next paid request. Stop after this image prevents further requests; the current request may still be billed.'
                          : 'Each option starts from the same room but requests a distinct renovation scheme, not accessory changes. Your Keep choices and layout restrictions still apply. Each result saves before the next request. Stop after this image prevents further requests; the current request may still be billed.',
                    ),
                  for (final item in requests.where(
                    (_) => !captured.finishPolish,
                  ))
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
            if (showGuidance)
              TextButton(
                onPressed: () {
                  improveBrief = true;
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Refine brief'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('Send to $providerLabel'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (confirmed != true) return;
      if (connectionRevision != widget.store.ai.connectionRevision) {
        setState(
          () => message = 'The AI connection changed. Review and confirm the request again. No photos were sent.',
        );
        return;
      }
      if (widget.beforeSend != null && !await widget.beforeSend!()) {
        if (mounted) {
          setState(
            () => message = 'Save the current choices successfully before generating. No AI request was sent.',
          );
        }
        return;
      }
      if (widget.store.ai.activity.active) return;
      if (connectionRevision != widget.store.ai.connectionRevision) return;
      if ((showGuidance || briefReviewed) &&
          readiness != null &&
          readiness.percentage >= BriefReadiness.reminderThreshold) {
        try {
          await widget.store.rememberBriefReview(
            captured.roomId,
            precise: captured.precise,
          );
        } catch (_) {
          // A failed reminder preference must not discard the confirmed request.
          // The reminder simply remains eligible next time; no AI retry is added.
        }
      }
      if (!mounted ||
          widget.store.ai.activity.active ||
          connectionRevision != widget.store.ai.connectionRevision) {
        return;
      }
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
        if (improveBrief) {
          widget.onImproveBrief?.call(readiness!.recommendedTarget);
        }
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
        recipe: captured.recipe?.withValues({
          'provider': result.provider,
          if (result.usage != null) 'usage': result.usage!.toMap(),
          'wordingRegion': widget.store.wordingRegion.name,
          'imageModel': result.model,
          if (result.quality != null) 'imageQuality': result.quality,
        }),
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
          () => message = 'The AI result arrived, but local saving failed. Keep this screen open and retry saving; this does not call AI again. Remaining concepts were not requested.',
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
          padding: EdgeInsets.all(widget.compact ? 10 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.compact)
                const HelpHeading(
                  title: 'Generate inside RenoVision',
                  message: 'The image selected in Working from is sent as the reference. Select an original room photo for fresh alternatives, or a saved design for variations on it. AI variation is requested, not guaranteed.\n\nMultiple design ideas makes 2 or 3 separate paid image requests from the same starting image. Compare styles separately uses one selected style per image; an extra concept blends them. With comparison off, every concept blends the selected influences. Each result saves before the next request; you can stop after the current image.',
                ),
              if (!widget.compact) const SizedBox(height: 8),
              if (!widget.compact)
                Text(
                  widget.store.ai.connected
                      ? '${widget.store.ai.providerLabel} · ${widget.store.ai.model} · ${imageQualityLabel(widget.store.ai.provider, widget.store.ai.quality!)}. Uses the image currently selected in “Working from”.'
                      : 'Connect AI in Settings to generate and save a result here.',
                ),
              if (widget.store.ai.fixedComparisonBrief)
                const Text(
                  'Fixed-brief model test · select one result. Use the same original and brief for each model.',
                ),
              if (widget.compact && !widget.singleConcept) ...[
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(value: 1, label: Text('1 design')),
                    ButtonSegment(
                      value: 2,
                      label: Text(precise ? '2 variations' : '2 ideas'),
                    ),
                    ButtonSegment(
                      value: 3,
                      label: Text(precise ? '3 variations' : '3 ideas'),
                    ),
                  ],
                  selected: {count},
                  onSelectionChanged:
                      busy || pending != null || widget.store.ai.activity.active
                      ? null
                      : (values) => setCount(values.first),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    precise
                        ? '$count paid image request${count == 1 ? '' : 's'} · requested correction only'
                        : '$count paid image request${count == 1 ? '' : 's'} · confirm before sending',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              if (!widget.compact) const SizedBox(height: 10),
              if (!widget.compact)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Multiple design ideas'),
                  subtitle: Text(
                    precise
                        ? '2–3 variations of your specific correction. Unrelated details are requested unchanged.'
                        : '2–3 distinct renovation schemes, not accessory changes. Each is a separate paid request.',
                  ),
                  value: count > 1,
                  onChanged:
                      busy || pending != null || widget.store.ai.activity.active
                      ? null
                      : (value) => setCount(value == true ? 3 : 1),
                ),
              if (count > 1) ...[
                if (!widget.compact)
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 2, label: Text('2 concepts')),
                      ButtonSegment(value: 3, label: Text('3 concepts')),
                    ],
                    selected: {count},
                    onSelectionChanged:
                        busy ||
                            pending != null ||
                            widget.store.ai.activity.active
                        ? null
                        : (values) => setCount(values.first),
                  ),
                if (!precise && (widget.draft?.styleIds.length ?? 0) > 1)
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
              if (widget.showGenerateButton &&
                  pending == null &&
                  (!widget.compact || widget.store.ai.connected))
                FilledButton.icon(
                  onPressed:
                      !widget.enabled ||
                          busy ||
                          !widget.store.ai.connected ||
                          widget.store.ai.activity.active
                      ? null
                      : _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(
                    busy
                        ? 'Generating…'
                        : widget.buttonLabel ??
                              (count > 1
                                  ? (precise
                                        ? 'Generate $count correction variations'
                                        : 'Generate $count redesign options')
                                  : 'Generate AI design'),
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
                  AiUsageSummary(
                    operation: 'Design',
                    model: design.aiModel,
                    usage: design.recipe?.toMap()['usage'] is Map
                        ? AiUsage.fromMap(
                            design.recipe!.toMap()['usage'] as Map,
                          )
                        : null,
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
              '1. Connect AI and choose a model.\n2. Analyse photos and review the proposed prompt.\n3. Generate, compare and approve a design.\n4. Select that design to refine it.',
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
              'Developer API access and billing are separate from chat subscriptions. Connecting checks model metadata; changing settings sends no photos. Analysis and generation each ask before sending.',
            ),
          ],
        ),
      ),
    ),
  );
}
