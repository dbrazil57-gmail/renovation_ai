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
      label: Text(readiness.label),
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
          Text(readiness.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          if (readiness.isNewDesign)
            LinearProgressIndicator(value: readiness.percentage / 100),
          const SizedBox(height: 8),
          Text(
            !readiness.canProceed
                ? readiness.blockingReason!
                : readiness.missing.isEmpty
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
            readiness.description,
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
  final complete = readiness.isNewDesign && readiness.percentage == 100;
  var proceed = complete;
  return showDialog<BriefReviewAction>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, updateDialog) => AlertDialog(
        title: Text(readiness.reviewTitle),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(readiness.description),
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
                      readiness.isNewDesign
                          ? '${check.label} · ${check.points}/${check.possible}'
                          : check.label,
                    ),
                    subtitle: check.complete ? null : Text(check.suggestion),
                  ),
                if (readiness.isNewDesign)
                  const Text(
                    'Optional design choices can be left to AI. Reviewed reminders stop repeating at 75% or more for a new design. Sending confirmation still applies.',
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
              if (readiness.isNewDesign && !complete)
                CheckboxListTile(
                  key: const ValueKey('brief-proceed-checkbox'),
                  value: proceed,
                  onChanged: !readiness.canProceed
                      ? null
                      : (value) => updateDialog(() => proceed = value ?? false),
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
                  if (!readiness.isNewDesign && !readiness.canProceed)
                    TextButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        BriefReviewAction.refine,
                      ),
                      child: Text(
                        readiness.blockingCheck?.target == BriefTarget.room
                            ? 'Choose image'
                            : readiness.precise
                            ? 'Add correction'
                            : 'Add changes',
                      ),
                    ),
                  FilledButton(
                    key: const ValueKey('brief-review-primary'),
                    onPressed: !readiness.isNewDesign && !readiness.canProceed
                        ? null
                        : () => Navigator.pop(
                            dialogContext,
                            !readiness.isNewDesign ||
                                    (proceed && readiness.canProceed)
                                ? BriefReviewAction.proceed
                                : BriefReviewAction.refine,
                          ),
                    child: Text(
                      !readiness.isNewDesign || complete
                          ? 'Send to AI'
                          : proceed
                          ? 'Proceed'
                          : 'Refine brief',
                    ),
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
