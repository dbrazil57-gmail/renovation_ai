import 'package:material_ui/material_ui.dart';

import 'app_appearance.dart';
import 'store.dart';

class AppAppearanceSettingsCard extends StatefulWidget {
  final RenovisionStore store;
  const AppAppearanceSettingsCard({super.key, required this.store});
  @override
  State<AppAppearanceSettingsCard> createState() =>
      _AppAppearanceSettingsCardState();
}

class _AppAppearanceSettingsCardState extends State<AppAppearanceSettingsCard> {
  bool busy = false;
  String? error;
  Future<void> _choose(AppThemeChoice choice) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.store.setAppTheme(choice);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Theme could not be saved. Your previous choice is still active.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ValueListenableBuilder<AppThemeChoice>(
      valueListenable: widget.store.appearance,
      builder: (context, selected, _) => ExpansionTile(
        key: const ValueKey('app-appearance-settings'),
        leading: const Icon(Icons.palette_outlined),
        title: const Text('App appearance'),
        subtitle: Text(selected.label),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RenoImagineAI green matches the logo. Choose another theme any time. Room-design palettes stay separate.',
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: [
              for (final choice in AppThemeChoice.values)
                ChoiceChip(
                  key: ValueKey('app-theme-${choice.name}'),
                  avatar: CircleAvatar(
                    backgroundColor: choice.colours.accent,
                    radius: 8,
                  ),
                  label: Text(choice.label),
                  selected: selected == choice,
                  onSelected: busy ? null : (_) => _choose(choice),
                ),
            ],
          ),
          if (error != null) Text(error!),
        ],
      ),
    ),
  );
}
