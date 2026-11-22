import 'package:material_ui/material_ui.dart';

import 'brief_readiness.dart';

class BriefReadinessIndicator extends StatelessWidget {
  final BriefReadiness readiness;
  final VoidCallback onReview;
  const BriefReadinessIndicator({
    super.key,
    required this.readiness,
    required this.onReview,
  });
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      key: const ValueKey('brief-readiness-indicator'),
      onPressed: onReview,
      icon: const Icon(Icons.info_outline, size: 16),
      label: Text('Brief ${readiness.percentage}% complete'),
    ),
  );
}

class BriefReadinessGuidance extends StatelessWidget {
  final BriefReadiness readiness;
  const BriefReadinessGuidance({super.key, required this.readiness});
  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('brief-readiness-guidance'),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Brief ${readiness.percentage}% complete',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: readiness.percentage / 100),
          const SizedBox(height: 8),
          Text(
            readiness.missing.isEmpty
                ? 'Your brief includes the key inputs. Review the request below.'
                : 'More direction could help. You can refine the brief or proceed with the current choices.',
          ),
          for (final item in readiness.missing.take(3))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• ${item.suggestion}'),
            ),
          const SizedBox(height: 6),
          Text(
            BriefReadiness.explanation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

enum BriefReviewAction { refine, proceed }

Future<BriefReviewAction?> reviewBrief(
  BuildContext context,
  BriefReadiness readiness,
) {
  var proceed = false;
  return showDialog<BriefReviewAction>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, updateDialog) => AlertDialog(
        title: Text('Brief ${readiness.percentage}% complete'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(BriefReadiness.explanation),
                const SizedBox(height: 8),
                for (final check in readiness.checks)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      check.complete
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(
                      '${check.label} · ${check.points}/${check.possible}',
                    ),
                    subtitle: check.complete ? null : Text(check.suggestion),
                  ),
                const Text(
                  'A narrow precise correction uses its own checklist; style and palette are not required. Reviewed reminders stop repeating at 75% or more for this room and mode. Paid-request confirmation still applies.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CheckboxListTile(
                key: const ValueKey('brief-proceed-checkbox'),
                value: proceed,
                onChanged: (value) =>
                    updateDialog(() => proceed = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Proceed with the current brief'),
              ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                  FilledButton(
                    key: const ValueKey('brief-review-primary'),
                    onPressed: () => Navigator.pop(
                      dialogContext,
                      proceed
                          ? BriefReviewAction.proceed
                          : BriefReviewAction.refine,
                    ),
                    child: Text(proceed ? 'Proceed' : 'Refine brief'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
