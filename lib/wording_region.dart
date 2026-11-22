import 'package:material_ui/material_ui.dart';

import 'store.dart';

enum WordingRegion {
  australia('Australian English', 'benchtop', 'tap', 'rangehood', 'splashback'),
  newZealand(
    'New Zealand English',
    'benchtop',
    'tap',
    'rangehood',
    'splashback',
  ),
  uk('UK English', 'worktop', 'tap', 'extractor hood', 'splashback'),
  us('US English', 'countertop', 'faucet', 'range hood', 'backsplash');

  final String label, top, tap, hood, splash;
  const WordingRegion(this.label, this.top, this.tap, this.hood, this.splash);
  String get prompt =>
      'WORDING REGION: $label. Use $top, $tap, $hood and $splash in suggestions. Preserve the meaning of the user\'s own wording; never expand the permitted changes through translation.';
  String text(String original) => original
      .replaceAll(RegExp('benchtops', caseSensitive: false), '${top}s')
      .replaceAll(RegExp('benchtop', caseSensitive: false), top)
      .replaceAll(RegExp('splashback', caseSensitive: false), splash)
      .replaceAll(RegExp('extractor / rangehood', caseSensitive: false), hood)
      .replaceAll(RegExp('taps / mixer', caseSensitive: false), '$tap / mixer');
}

class WordingRegionSettings extends StatelessWidget {
  final RenovisionStore store;
  const WordingRegionSettings({super.key, required this.store});
  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      title: const Text('Language & region'),
      subtitle: Text(store.wordingRegion.label),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              DropdownButtonFormField<WordingRegion>(
                key: ValueKey(store.wordingRegion),
                initialValue: store.wordingRegion,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'English wording'),
                items: [
                  for (final r in WordingRegion.values)
                    DropdownMenuItem(value: r, child: Text(r.label)),
                ],
                onChanged: (r) async {
                  if (r != null) {
                    try {
                      await store.setWordingRegion(r);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            persist: false,
                            content: Text('Region could not be saved.'),
                            duration: Duration(seconds: 4),
                            showCloseIcon: true,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              const Text(
                'Applies to renovation terms and new AI requests. Existing instructions/history stay unchanged. This does not translate the whole interface into another language.',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
