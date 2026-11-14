import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import 'ai_service.dart';
import 'models.dart';
import 'store.dart';

class AiConnectionCard extends StatefulWidget {
  final AiService ai;
  const AiConnectionCard({super.key, required this.ai});
  @override
  State<AiConnectionCard> createState() => _AiConnectionCardState();
}

class _AiConnectionCardState extends State<AiConnectionCard> {
  late final TextEditingController url;
  final code = TextEditingController();
  bool busy = false;
  String? message;
  @override
  void initState() {
    super.initState();
    url = TextEditingController(text: widget.ai.relayUrl);
  }

  @override
  void dispose() {
    url.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await widget.ai.connect(url: url.text, pairingCode: code.text);
      if (mounted) {
        code.clear();
        setState(
          () => message = 'Relay connected. This check did not contact OpenAI or generate an image.',
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
    listenable: widget.ai,
    builder: (context, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'In-app AI test connection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Start the local relay on your PC and enter its connection code here. Enter your OpenAI API key only in the relay terminal, not in this app. The connection is kept for this app session only.',
            ),
            const SizedBox(height: 12),
            if (widget.ai.connected) ...[
              Text(
                'Connected to OpenAI · ${widget.ai.model} · ${widget.ai.quality} quality',
              ),
              TextButton(
                onPressed: busy ? null : widget.ai.disconnect,
                child: const Text('Disconnect AI'),
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
  });
}

class AiEditCard extends StatefulWidget {
  final RenovisionStore store;
  final AiEditRequest Function() buildRequest;
  final ValueChanged<DesignVersion> onSaved;
  const AiEditCard({
    super.key,
    required this.store,
    required this.buildRequest,
    required this.onSaved,
  });
  @override
  State<AiEditCard> createState() => _AiEditCardState();
}

class _AiEditCardState extends State<AiEditCard> {
  bool busy = false;
  bool generating = false;
  String? message;
  AiResult? pending;
  AiEditRequest? request;

  Future<void> _generate() async {
    if (busy || pending != null) return;
    late AiEditRequest captured;
    try {
      captured = widget.buildRequest();
    } on AiFailure catch (error) {
      setState(() => message = error.message);
      return;
    }
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
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Send this edit to OpenAI?'),
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
                    '${widget.store.ai.model} · ${widget.store.ai.quality} quality · ${captured.supportingImages.length + 1} input views · one result',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The working image, any supporting views shown above, and prompt will leave this device and be sent to OpenAI. API charges apply and additional inputs can increase cost. Each metadata-free working copy is limited to 2048 pixels on its longest side. Your originals and approved baseline remain unchanged. Precise preservation and a consistent 3D reconstruction are not guaranteed.',
                  ),
                  const SizedBox(height: 12),
                  Text(captured.prompt),
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
      setState(() => generating = true);
      request = captured;
      pending = await widget.store.ai.edit(
        image: captured.image,
        prompt: captured.prompt,
        supportingImages: captured.supportingImages.values.toList(),
      );
      await _savePending();
    } on AiFailure catch (error) {
      if (mounted) setState(() => message = error.message);
    } catch (_) {
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
      }
    }
  }

  Future<void> _savePending() async {
    final result = pending;
    final captured = request;
    if (result == null || captured == null) return;
    try {
      final design = await widget.store.createDesign(
        roomId: captured.roomId,
        image: result.image,
        title: captured.title,
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
        widget.onSaved(design);
        setState(
          () => message = 'AI result saved as a new version. Compare it before approving a new baseline.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'The AI result arrived, but local saving failed. Keep this screen open and retry saving; this does not call OpenAI again.',
        );
      }
    }
  }

  Future<void> _retrySave() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await _savePending();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store.ai,
    builder: (context, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate inside Renovision',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.store.ai.connected
                  ? 'OpenAI · ${widget.store.ai.model} · ${widget.store.ai.quality} quality. Uses the image currently selected in “Working from”.'
                  : 'Connect the local AI relay to generate and save a result here.',
            ),
            const SizedBox(height: 10),
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
                onPressed: busy || !widget.store.ai.connected
                    ? null
                    : _generate,
                icon: const Icon(Icons.auto_awesome),
                label: Text(busy ? 'Generating…' : 'Generate AI design'),
              ),
            if (pending != null) ...[
              Image.memory(pending!.image, height: 180),
              FilledButton(
                onPressed: busy ? null : _retrySave,
                child: const Text('Retry saving result'),
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
