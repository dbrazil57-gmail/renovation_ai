import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'ai_activity.dart';

class AiActivityStrip extends StatefulWidget {
  final AiActivity activity;
  final String roomId;
  final bool safeArea;
  const AiActivityStrip({
    super.key,
    required this.activity,
    required this.roomId,
    this.safeArea = true,
  });
  @override
  State<AiActivityStrip> createState() => _AiActivityStripState();
}

class _AiActivityStripState extends State<AiActivityStrip> {
  Timer? ticker;
  @override
  void initState() {
    super.initState();
    widget.activity.addListener(changed);
    syncTicker();
  }

  @override
  void didUpdateWidget(AiActivityStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activity != widget.activity) {
      oldWidget.activity.removeListener(changed);
      widget.activity.addListener(changed);
    }
    syncTicker();
  }

  void syncTicker() {
    final visible = widget.activity.roomId == widget.roomId;
    if (widget.activity.active && visible) {
      ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      ticker?.cancel();
      ticker = null;
    }
  }

  void changed() {
    syncTicker();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ticker?.cancel();
    widget.activity.removeListener(changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    if (activity.stage == AiStage.idle || activity.roomId != widget.roomId) {
      return const SizedBox.shrink();
    }
    final duration = activity.elapsed;
    final elapsed =
        '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    final content = Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  activity.active
                      ? Icons.hourglass_top
                      : activity.stage == AiStage.completed
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      activity.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '$elapsed elapsed',
                      key: const ValueKey('ai-elapsed'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                if (!activity.active)
                  IconButton(
                    tooltip: 'Dismiss activity',
                    onPressed: activity.dismiss,
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (activity.active) const LinearProgressIndicator(),
            const SizedBox(height: 4),
            Text(
              activity.detail.isNotEmpty
                  ? activity.detail
                  : activity.stage == AiStage.waiting
                  ? 'The request is pending. No second request has been sent.'
                  : activity.stage == AiStage.completed
                  ? 'Your result is saved locally.'
                  : 'Keep this screen open until saving finishes.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
    return widget.safeArea ? SafeArea(top: false, child: content) : content;
  }
}
