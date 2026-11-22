import 'package:material_ui/material_ui.dart';

import 'ai_usage.dart';
import 'store.dart';

class AiUsageCard extends StatelessWidget {
  final RenovisionStore store;
  final String? roomId;
  const AiUsageCard({super.key, required this.store, this.roomId});
  @override
  Widget build(BuildContext context) {
    final all = store.storedDesignsForUsage;
    final designs = all
        .where((d) => roomId == null || d.roomId == roomId)
        .toList();
    final seen = <String>{};
    var total = 0.0, unknown = 0, images = 0;
    for (final d in designs.where((d) => d.aiProvider != null)) {
      if (!seen.add('${d.aiProvider}:${d.providerRequestId ?? d.id}')) continue;
      images++;
      final value = d.recipe?.toMap()['usage'];
      final usage = value is Map ? AiUsage.fromMap(value) : null;
      if (usage?.estimatedUsd == null) {
        unknown++;
      } else {
        total += usage!.estimatedUsd!;
      }
    }
    final rawBudget = store.records.get('settings:image_budget_usd');
    final budget = rawBudget is num ? rawBudget.toDouble() : null;
    return Card(
      child: ExpansionTile(
        title: Text(
          roomId == null
              ? 'AI usage & image budget'
              : 'This room · image usage',
        ),
        subtitle: Text(
          '$images images · estimated US\$${total.toStringAsFixed(4)}${unknown > 0 ? ' + $unknown unpriced' : ''}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Image-generation estimates from returned token usage and dated standard USD rates. Not a provider invoice or balance. Analysis, research, failed/interrupted requests, taxes, currency conversion and unpriced models are excluded. Copies with the same provider request ID count once.',
                ),
                if (budget != null)
                  Text(
                    'Tracked image budget: US\$${budget.toStringAsFixed(2)} · estimated remainder US\$${(budget - total).toStringAsFixed(2)}${unknown > 0 ? ' (incomplete: unpriced images)' : ''}',
                  ),
                if (roomId == null)
                  TextFormField(
                    initialValue: budget?.toString() ?? '',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Optional image budget (USD)',
                      helperText:
                          'Enter an amount and submit; blank removes it.',
                    ),
                    onFieldSubmitted: (text) async {
                      final parsed = double.tryParse(text.trim());
                      if (text.trim().isNotEmpty &&
                          (parsed == null || !parsed.isFinite || parsed < 0)) {
                        return;
                      }
                      try {
                        await store.setImageBudget(parsed);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              persist: false,
                              showCloseIcon: true,
                              content: Text('Image budget could not be saved.'),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
