import 'package:material_ui/material_ui.dart';

import 'renovation_scope.dart';
import 'room_draft.dart';
import 'room_features.dart';
import 'room_item_widgets.dart';

class RenovationScopeControls extends StatelessWidget {
  final RoomDraft draft;
  const RenovationScopeControls({super.key, required this.draft});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Include in this renovation',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose what to keep or replace, then tick other changes. Protected features take priority.',
          ),
          const SizedBox(height: 8),
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
                    (e) => scopeAppliesToRoom(e.key, draft.effectiveRoomType),
                  ))
                    SizedBox(
                      width: width,
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(entry.value.label),
                        value: draft.scopeIds.contains(entry.key),
                        onChanged: (value) =>
                            draft.setScope(entry.key, value ?? false),
                      ),
                    ),
                ],
              );
            },
          ),
          if (draft.scopeIds.contains('flooring') &&
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
              hintText:
                  'For example: wall telephone, old blind, freestanding bin',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    ),
  );
}
