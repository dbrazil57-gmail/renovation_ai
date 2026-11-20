import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'design_styles.dart';
import 'design_palettes.dart';
import 'ai_model_choices.dart';

Future<bool?> showDesignRecipe(BuildContext context, DesignVersion design) {
  final saved = design.recipe?.toMap();
  final styles = saved?['designStyleIds'] as List? ?? [];
  final palette = paletteById(saved?['colourPaletteId'] as String? ?? '');
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Saved design settings'),
      scrollable: true,
      content: SizedBox(
        width: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(design.title),
            const SizedBox(height: 12),
            if (saved == null)
              const Text(
                'This older version has no complete settings snapshot. Its image and recorded prompt are retained.',
              )
            else ...[
              Text(
                'Style: ${styles.map((id) => designStyles[id] ?? id).join(', ')}',
              ),
              Text('Palette: ${palette?.name ?? 'No preset'}'),
              Text(
                'Mode: ${saved['preciseEdit'] == true ? 'Precise correction' : 'New design'}',
              ),
              Text(
                'Keep layout: ${saved['keepLayout'] != false ? 'Yes' : 'No'}',
              ),
              if (saved['imageModel'] is String)
                Text(
                  'Model: ${imageModelLabel(saved['imageModel'] as String)}',
                ),
              if (saved['imageQuality'] is String)
                Text(
                  'Quality / resolution: ${imageQualityLabel(AiProvider.fromId(saved['provider'] == 'Gemini' ? 'gemini' : 'openai'), saved['imageQuality'] as String)}',
                ),
              const SizedBox(height: 12),
              Text('Brief: ${saved['instructions'] ?? ''}'),
              if ((saved['correctionInstructions'] ?? '') != '')
                Text('Correction: ${saved['correctionInstructions']}'),
              Text('Keep: ${saved['protectedFeatures'] ?? ''}'),
              if (design.recipe!.analysis != null)
                ExpansionTile(
                  title: const Text('Saved room analysis'),
                  children: [
                    SelectableText(
                      design.recipe!.analysis!.result.observations,
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              const Text(
                'Applying these settings replaces the current room choices. A saved model is selected only if it is available on the current connection. It does not generate an image or change the approved baseline. AI connection credentials stay separate.',
              ),
            ],
            ExpansionTile(
              title: const Text('Recorded prompt'),
              children: [SelectableText(design.prompt)],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
        if (saved != null) ...[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Use these settings'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Refine this design'),
          ),
        ],
      ],
    ),
  );
}
