import 'package:material_ui/material_ui.dart';

import 'australian_design.dart';
import 'context_help.dart';
import 'room_draft.dart';

class AustralianDesignControls extends StatelessWidget {
  final RoomDraft draft;
  const AustralianDesignControls({super.key, required this.draft});

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: const ValueKey('australian-setting-panel'),
    tilePadding: EdgeInsets.zero,
    title: const Text('Australian property (optional)'),
    subtitle: Text(draft.australianSetting.label),
    children: [
      const HelpHeading(
        title: 'Local setting',
        message: 'Only enable this location context for a property in Australia. Australian styling can be used anywhere and does not select a country. If useful, choose the actual climate and broad conditions such as coastal wind, sun or shade. No GPS or address is needed. Native to Australia does not mean suitable everywhere. This is visual guidance, not a verified planting plan. Focused corrections stay limited to their requested change.',
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        key: ValueKey(
          'australian-climate-${draft.australianSetting.climateId}',
        ),
        initialValue: draft.australianSetting.enabled
            ? draft.australianSetting.climateId
            : '',
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Setting / climate'),
        items: [
          const DropdownMenuItem(
            value: '',
            child: Text('Not selected / global'),
          ),
          for (final entry in australianClimates.entries)
            DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) {
          if (value != null) {
            draft.setAustralianSetting(
              draft.currentAustralianSetting.copyWith(climateId: value),
            );
          }
        },
      ),
      if (draft.australianSetting.enabled) ...[
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Prefer suitable Australian native planting'),
          value: draft.australianSetting.preferNativePlants,
          onChanged: (value) => draft.setAustralianSetting(
            draft.currentAustralianSetting.copyWith(
              preferNativePlants: value == true,
            ),
          ),
        ),
        TextField(
          controller: draft.australianSiteNotes,
          maxLength: 600,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Area / site conditions (optional)',
            hintText: 'For example: Perth, sandy soil, sunny coastal courtyard',
          ),
        ),
      ],
      const SizedBox(height: 8),
    ],
  );
}
