import 'package:material_ui/material_ui.dart';

import 'room_draft.dart';

class DesignModeControls extends StatelessWidget {
  final RoomDraft draft;
  final bool enabled;
  const DesignModeControls({
    super.key,
    required this.draft,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: draft,
    builder: (context, _) => SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<RoomDesignMode>(
            key: const ValueKey('design-edit-mode'),
            segments: const [
              ButtonSegment(
                value: RoomDesignMode.newDesign,
                label: Text('New design'),
                tooltip:
                    'A whole-room concept within your layout and Keep choices.',
              ),
              ButtonSegment(
                value: RoomDesignMode.partial,
                label: Text('Partial'),
                tooltip: 'Update only the items chosen under Style and your written instructions.',
              ),
              ButtonSegment(
                value: RoomDesignMode.precise,
                label: Text('Precise correction'),
                tooltip: 'Make one small correction to the selected image. Both briefs stay saved.',
              ),
            ],
            selected: {draft.designMode},
            onSelectionChanged: enabled
                ? (values) => draft.setDesignMode(values.first)
                : null,
          ),
          const SizedBox(height: 6),
          Text(switch (draft.designMode) {
            RoomDesignMode.newDesign => 'Full design: coordinate all usual room updates, within your layout and Keep choices.',
            RoomDesignMode.partial => 'Partial: update only the items you choose in Style and your written requests. Everything else stays.',
            RoomDesignMode.precise => 'Precision: apply only your next change to this image. The original renovation brief, style and palette are not reapplied.',
          }, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}
