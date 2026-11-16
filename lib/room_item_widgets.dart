import 'package:material_ui/material_ui.dart';

import 'room_draft.dart';
import 'room_features.dart';

class RoomItemControls extends StatelessWidget {
  final RoomDraft draft;
  const RoomItemControls({super.key, required this.draft});

  Widget _choice(String id, RoomFeature feature) {
    final value = itemChoice(
      id,
      draft.roomItemChoices,
      draft.scopeIds.toList(),
    );
    final inherited = isIndividualAppliance(id)
        ? itemChoice(
            '${id.split('_').first}_appliances',
            draft.roomItemChoices,
            draft.scopeIds.toList(),
          )
        : '';
    return DropdownButtonFormField<String>(
      key: ValueKey('room-item-$id-$value-$inherited'),
      initialValue: ['', 'keep', 'replace'].contains(value) ? value : '',
      isExpanded: true,
      decoration: InputDecoration(
        labelText: feature.label,
        border: const OutlineInputBorder(),
        helperText: value.isEmpty && inherited.isNotEmpty
            ? 'Follows all appliances: ${inherited == 'keep' ? 'Keep existing' : 'Replace'}'
            : null,
      ),
      items: const [
        DropdownMenuItem(value: '', child: Text('No preference')),
        DropdownMenuItem(value: 'keep', child: Text('Keep existing')),
        DropdownMenuItem(value: 'replace', child: Text('Replace / update')),
      ],
      onChanged: (value) => draft.setItemChoice(id, value ?? ''),
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
        const Text(
          'Keep existing preserves that item. Replace / update requests a new appearance. No preference follows an appliance group choice, if set. Only visible items are changed.',
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
