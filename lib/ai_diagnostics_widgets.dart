import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'ai_diagnostics.dart';

class AiDiagnosticsCard extends StatelessWidget {
  final AiDiagnostics diagnostics;
  const AiDiagnosticsCard({super.key, required this.diagnostics});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: diagnostics,
    builder: (context, _) => Card(
      child: ExpansionTile(
        title: const Text('AI diagnostics'),
        subtitle: Text(
          '${diagnostics.entries.length} recent checks and requests',
        ),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          const Text(
            'Saved only on this device: provider, model, timing, result and error category. No API keys, photos or prompts. Copy this report when reporting an AI failure.',
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: diagnostics.entries.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(text: diagnostics.report),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('AI diagnostics copied'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.copy),
                label: const Text('Copy diagnostics'),
              ),
              TextButton(
                onPressed: diagnostics.entries.isEmpty
                    ? null
                    : diagnostics.clear,
                child: const Text('Clear log'),
              ),
            ],
          ),
          for (final entry in diagnostics.entries.take(15))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                entry['ok'] == true
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
              ),
              title: Text(
                '${entry['provider']} · ${entry['operation']} · ${entry['ok'] == true ? 'completed' : entry['problem']}',
              ),
              subtitle: Text(
                '${DateTime.parse(entry['time'] as String).toLocal().toString().split('.').first}\n${entry['model']} · ${entry['elapsedMs']} ms${entry['http'] == null ? '' : ' · HTTP ${entry['http']}'}',
              ),
            ),
        ],
      ),
    ),
  );
}
