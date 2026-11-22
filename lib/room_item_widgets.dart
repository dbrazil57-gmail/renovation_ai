import 'package:material_ui/material_ui.dart';

import 'room_draft.dart';
import 'room_features.dart';

class RoomItemControls extends StatelessWidget {
  final RoomDraft draft;
  final bool enabled;
  const RoomItemControls({super.key, required this.draft, this.enabled = true});

  Widget _choice(String id, RoomFeature feature) {
    final value = itemChoice(
      id,
      draft.fullRenovation
          ? draft.effectiveRoomItemChoices
          : draft.roomItemChoices,
      draft.scopeIds.toList(),
    );
    final inherited = isIndividualAppliance(id)
        ? itemChoice(
            '${id.split('_').first}_appliances',
            draft.fullRenovation
                ? draft.effectiveRoomItemChoices
                : draft.roomItemChoices,
            draft.scopeIds.toList(),
          )
        : '';
    return DropdownButtonFormField<String>(
      key: ValueKey('room-item-$id-$value-$inherited'),
      initialValue: ['', 'keep', 'replace'].contains(value) ? value : '',
      isExpanded: true,
      decoration: InputDecoration(
        labelText: draft.store.wordingRegion.text(feature.label),
        border: const OutlineInputBorder(),
        helperText: value.isEmpty && inherited.isNotEmpty
            ? 'Follows all appliances: ${inherited == 'keep' ? 'Keep existing' : 'Replace'}'
            : null,
      ),
      items: [
        DropdownMenuItem(
          value: '',
          child: Text(
            draft.fullRenovation ? 'Use whole-room default' : 'No preference',
          ),
        ),
        const DropdownMenuItem(value: 'keep', child: Text('Keep existing')),
        const DropdownMenuItem(
          value: 'replace',
          child: Text('Replace / update'),
        ),
      ],
      onChanged: enabled
          ? (value) => draft.setItemChoice(id, value ?? '')
          : null,
    );
  }

  Widget _grid(Map<String, RoomFeature> features) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 600
          ? (constraints.maxWidth - 12) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 12,
        runSpacing: 16,
        children: [
          for (final entry in features.entries)
            SizedBox(width: width, child: _choice(entry.key, entry.value)),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final type = draft.effectiveRoomType;
    final features = roomFeaturesFor(type);
    final group = features.entries.where((e) => isApplianceGroup(e.key));
    if (features.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          '${roomTypes[type]} items',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          draft.fullRenovation
              ? 'Visible items are included. Choose Keep existing for anything you want to retain.'
              : 'Keep existing preserves an item; Replace / update changes it. No preference follows the appliance group, if set.',
        ),
        const SizedBox(height: 14),
        if (group.isNotEmpty) ...[
          for (final entry in group) _choice(entry.key, entry.value),
          const SizedBox(height: 8),
          ExpansionTile(
            key: ValueKey('individual-items-$type'),
            title: const Text('Individual appliances (optional)'),
            subtitle: const Text(
              'Keep or replace specific appliances; individual choices take priority.',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
                child: _grid({
                  for (final entry in features.entries.where(
                    (e) => !isApplianceGroup(e.key),
                  ))
                    entry.key: entry.value,
                }),
              ),
            ],
          ),
        ] else
          _grid(features),
        const SizedBox(height: 14),
      ],
    );
  }
}
