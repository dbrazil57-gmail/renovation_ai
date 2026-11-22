import 'package:material_ui/material_ui.dart';

import 'store.dart';
import 'room_features.dart';
import 'design_references.dart';
import 'ai_types.dart';
import 'ai_activity.dart';
import 'feedback_launch.dart';

class DesignReferenceCard extends StatefulWidget {
  final RenovisionStore store;
  final String roomId;
  final ValueChanged<bool> onPending;
  const DesignReferenceCard({
    super.key,
    required this.store,
    required this.roomId,
    required this.onPending,
  });
  @override
  State<DesignReferenceCard> createState() => _DesignReferenceCardState();
}

class _DesignReferenceCardState extends State<DesignReferenceCard> {
  final query = TextEditingController();
  bool busy = false;
  String? message;
  DesignReferences? pending;
  @override
  void initState() {
    super.initState();
    final room = widget.store.roomById(widget.roomId)!;
    query.text =
        'Current ${roomTypes[resolveRoomType(room.roomTypeId, room.name)]} cabinetry, material and lighting ideas for ${widget.store.wordingRegion.label}. Include concrete contemporary fitting treatments and manufacturer references.';
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> save() async {
    try {
      final room = widget.store.roomById(widget.roomId)!;
      await widget.store.updateRoom(
        room.copyWith(designReferences: pending, useDesignReferences: false),
      );
      pending = null;
      widget.store.ai.activity.update(
        AiStage.completed,
        detail: 'References saved. Review before including them; no image was generated.',
      );
      message = 'References saved. Review and enable them below if useful.';
    } catch (_) {
      message = 'References arrived but saving failed. Retry saving below; it makes no new AI request.';
      widget.store.ai.activity.update(AiStage.saveFailed, detail: message!);
    }
  }

  Future<void> research() async {
    if (busy || widget.store.ai.activity.active) return;
    final ai = widget.store.ai, revision = ai.connectionRevision;
    final text = query.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Research current design references?'),
        content: SingleChildScrollView(
          child: Text(
            'This sends the query below to OpenAI and its web search tool. No room photos, project name or address are attached. Search/model charges apply and are not included in image-cost estimates. This is optional and does not generate an image.\n\n$text',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Research with OpenAI'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || ai.connectionRevision != revision) {
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    widget.onPending(true);
    var started = false;
    try {
      ai.activity.begin(roomId: widget.roomId, operation: 'Reference research');
      started = true;
      pending = await ai.researchReferences(text);
      await save();
    } on AiFailure catch (error) {
      message = error.message;
      if (started) ai.activity.update(AiStage.failed, detail: message!);
    } catch (_) {
      message =
          'Reference research could not finish. No automatic retry was sent.';
      if (started) ai.activity.update(AiStage.failed, detail: message!);
    } finally {
      if (mounted) {
        setState(() => busy = false);
        widget.onPending(pending != null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.store.roomById(widget.roomId)!;
    final references = room.designReferences;
    return Card(
      child: ExpansionTile(
        title: const Text('Current design references (optional)'),
        subtitle: const Text('Research ideas online · separate paid action'),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: query,
                  maxLength: 2000,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Research query',
                  ),
                ),
                FilledButton.tonal(
                  onPressed: busy || !widget.store.ai.supportsResearch
                      ? null
                      : research,
                  child: const Text('Research current ideas'),
                ),
                if (!widget.store.ai.supportsResearch)
                  const Text(
                    'Optional research currently needs a direct OpenAI connection with a search-capable text model. Image generation still supports the other connected models.',
                  ),
                if (busy) const LinearProgressIndicator(),
                if (message != null) Text(message!),
                if (pending != null && !busy)
                  TextButton(
                    onPressed: () async {
                      await save();
                      if (mounted) {
                        widget.onPending(pending != null);
                        setState(() {});
                      }
                    },
                    child: const Text('Retry saving references'),
                  ),
                if (references != null) ...[
                  SelectableText(references.summary),
                  for (final source in references.sources.entries)
                    TextButton(
                      onPressed: () async {
                        await createFeedbackLauncher().open(
                          Uri.parse(source.key),
                        );
                      },
                      child: Text(source.value),
                    ),
                  SwitchListTile(
                    title: const Text(
                      'Include reviewed references in new designs',
                    ),
                    value: room.useDesignReferences,
                    onChanged: busy
                        ? null
                        : (v) async {
                            try {
                              await widget.store.updateRoom(
                                room.copyWith(useDesignReferences: v),
                              );
                            } catch (_) {
                              if (mounted) {
                                setState(
                                  () => message =
                                      'Reference choice could not be saved.',
                                );
                              }
                            }
                          },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
