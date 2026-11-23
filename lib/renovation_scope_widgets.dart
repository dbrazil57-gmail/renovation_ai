import 'package:material_ui/material_ui.dart';

import 'renovation_scope.dart';
import 'room_draft.dart';
import 'room_features.dart';
import 'room_item_widgets.dart';
import 'context_help.dart';

class RenovationScopeControls extends StatelessWidget {
  final RoomDraft draft;
  const RenovationScopeControls({super.key, required this.draft});

  String get partialSummary {
    final names = {
      for (final id in draft.scopeIds)
        if (renovationScope.containsKey(id) &&
            scopeAppliesToRoom(id, draft.effectiveRoomType))
          renovationScope[id]!.label,
      for (final item in roomFeaturesFor(draft.effectiveRoomType).entries)
        if (draft.roomItemChoices[item.key] == 'replace') item.value.label,
    }.toList();
    return names.isEmpty
        ? 'No individual items selected. Choose what to update, or describe a specific change.'
        : 'Selected: ${names.take(3).join(', ')}${names.length > 3 ? ' + ${names.length - 3} more' : ''}. Other items stay.';
  }

  Widget _details() => Column(
    children: [
      if ((draft.fullRenovation || draft.scopeIds.contains('flooring')) &&
          scopeAppliesToRoom('flooring', draft.effectiveRoomType)) ...[
        const SizedBox(height: 8),
        TextField(
          controller: draft.flooringNotes,
          minLines: 1,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'New flooring / finish (optional)',
            hintText: 'For example: large-format warm greige tiles',
            border: OutlineInputBorder(),
          ),
        ),
      ],
      const SizedBox(height: 12),
      TextField(
        controller: draft.removeItems,
        minLines: 1,
        maxLines: 3,
        maxLength: 500,
        decoration: const InputDecoration(
          labelText: 'Other items to remove (optional)',
          hintText: 'For example: wall telephone, old blind, freestanding bin',
          border: OutlineInputBorder(),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: draft,
    builder: (context, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HelpHeading(
              title: 'Renovation scope',
              message: 'Full room includes coordinated finishes, flooring, lighting and visible room fittings. Saved Keep choices and protected features still win. Partial changes only your selected items and written requests. Precise correction in Refine is for one focused change to an existing design.',
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const ValueKey('renovation-extent'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Whole room · include all usual updates'),
              subtitle: const Text('Turn off to choose individual changes.'),
              value: draft.fullRenovation,
              onChanged: draft.setFullRenovation,
            ),
            const SizedBox(height: 8),
            Text(
              draft.fullRenovation
                  ? 'Usual renovation updates are included. Protected items and saved Keep choices stay.'
                  : partialSummary,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey('room-type-${draft.roomTypeId}'),
              initialValue: roomTypes.containsKey(draft.roomTypeId)
                  ? draft.roomTypeId
                  : '',
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Room type',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(
                    'From room name (${roomTypes[resolveRoomType('', draft.store.roomById(draft.roomId)?.name ?? '')]})',
                  ),
                ),
                for (final entry in roomTypes.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) => draft.setRoomType(value ?? ''),
            ),
            if (draft.fullRenovation)
              ExpansionTile(
                key: const ValueKey('full-renovation-items'),
                title: const Text('Included items & saved exceptions'),
                tilePadding: EdgeInsets.zero,
                children: [
                  RoomItemControls(draft: draft),
                  Text(
                    [
                      for (final entry in renovationScope.entries.where(
                        (e) =>
                            e.key != 'dated_fixtures' &&
                            scopeAppliesToRoom(e.key, draft.effectiveRoomType),
                      ))
                        entry.value.label,
                    ].join(' · '),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keep existing makes an exception to the whole-room design. Turn off Whole room to select individual surfaces and updates.',
                  ),
                ],
              )
            else
              ExpansionTile(
                key: const ValueKey('partial-renovation-items'),
                title: const Text('Choose individual changes'),
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                children: [
                  RoomItemControls(draft: draft),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth >= 600
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 12,
                        children: [
                          for (final entry in renovationScope.entries.where(
                            (e) => scopeAppliesToRoom(
                              e.key,
                              draft.effectiveRoomType,
                            ),
                          ))
                            SizedBox(
                              width: width,
                              child: CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  draft.store.wordingRegion.text(
                                    entry.value.label,
                                  ),
                                ),
                                value: draft.scopeIds.contains(entry.key),
                                onChanged: (value) =>
                                    draft.setScope(entry.key, value ?? false),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            if (draft.fullRenovation)
              ExpansionTile(
                key: const ValueKey('renovation-material-details'),
                tilePadding: EdgeInsets.zero,
                title: const Text('Materials & removals (optional)'),
                children: [_details()],
              )
            else
              _details(),
          ],
        ),
      ),
    ),
  );
}
