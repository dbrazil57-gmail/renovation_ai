import 'package:material_ui/material_ui.dart';

import 'design_styles.dart';
import 'room_draft.dart';

class DesignStyleControls extends StatelessWidget {
  final RoomDraft draft;
  const DesignStyleControls({super.key, required this.draft});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Design style', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text(
            'Tick a style or mix a couple of influences. Use Other for your own direction.',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final entry in designStyles.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: draft.styleIds.contains(entry.key),
                  showCheckmark: true,
                  onSelected: (value) => draft.setStyle(entry.key, value),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.otherStyle,
            maxLength: 500,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Other style / extra direction',
              hintText: 'For example: warm contemporary, practical storage, no glossy finishes',
              border: OutlineInputBorder(),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Keep existing layout and walls'),
            subtitle: Text(
              draft.preciseEdit
                  ? 'Always retained during a focused precision edit.'
                  : 'Update finishes and fittings without moving the main room elements.',
            ),
            value: draft.preciseEdit || draft.keepLayout,
            onChanged: draft.preciseEdit
                ? null
                : (value) => draft.setKeepLayout(value ?? true),
          ),
        ],
      ),
    ),
  );
}
