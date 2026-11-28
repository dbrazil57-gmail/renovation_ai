import 'package:material_ui/material_ui.dart';

import 'design_styles.dart';
import 'room_draft.dart';
import 'context_help.dart';
import 'australian_design_widgets.dart';

class DesignStyleControls extends StatefulWidget {
  final RoomDraft draft;
  const DesignStyleControls({super.key, required this.draft});
  @override
  State<DesignStyleControls> createState() => _DesignStyleControlsState();
}

class _DesignStyleControlsState extends State<DesignStyleControls> {
  int page = 0;
  RoomDraft get draft => widget.draft;
  List<String> get orderedIds => [
    ...commonStyleIds,
    ...selectableDesignStyles()
        .map((entry) => entry.key)
        .where((id) => !commonStyleIds.contains(id)),
  ];
  int get pageCount => (orderedIds.length / 10).ceil();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HelpHeading(
            title: 'Design style',
            message: 'Choose one style or blend several influences in one design. Style choices apply to your next generation, not an existing image. Use Other for your own direction. For separate style concepts, choose Multiple design ideas and Compare styles separately in AI generation.',
          ),
          const SizedBox(height: 6),
          Text(
            page == 0
                ? 'Common choices · select one or blend styles.'
                : 'More styles · selections stay saved across pages.',
          ),
          if (draft.styleIds.isNotEmpty)
            Text(
              'Selected: ${draft.styleIds.map((id) => designStyles[id] ?? id).join(' + ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          for (final id in draft.styleIds.where(
            legacyAustralianStyleIds.contains,
          ))
            InputChip(
              label: Text('Saved style: ${designStyles[id]}'),
              onDeleted: () => draft.setStyle(id, false),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final id in orderedIds.skip(page * 10).take(10))
                FilterChip(
                  label: Text(designStyles[id]!),
                  selected: draft.styleIds.contains(id),
                  showCheckmark: true,
                  onSelected: (value) => draft.setStyle(id, value),
                ),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Previous styles',
                onPressed: page == 0 ? null : () => setState(() => page--),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${page + 1} / $pageCount',
                  textAlign: TextAlign.center,
                ),
              ),
              TextButton.icon(
                key: const ValueKey('more-design-styles'),
                onPressed: () => setState(() => page = (page + 1) % pageCount),
                icon: Icon(
                  page + 1 == pageCount
                      ? Icons.first_page
                      : Icons.chevron_right,
                ),
                label: Text(
                  page + 1 == pageCount ? 'Common styles' : 'More styles',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (draft.styleIds.contains('modern') &&
              draft.styleIds.contains('classic'))
            const Text('Modern + Classic creates a transitional blend.'),
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
          if (draft.styleIds.any(australianStyleIds.contains) ||
              draft.australianSetting.enabled)
            AustralianDesignControls(draft: draft),
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
