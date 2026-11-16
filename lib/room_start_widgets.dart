import 'package:material_ui/material_ui.dart';

import 'colour_palette_widgets.dart';
import 'design_palettes.dart';
import 'design_styles.dart';
import 'room_features.dart';
import 'room_starters.dart';

const _roomIcons = <String, IconData>{
  'kitchen': Icons.kitchen_outlined,
  'bathroom': Icons.bathtub_outlined,
  'bedroom': Icons.bed_outlined,
  'living': Icons.weekend_outlined,
  'office': Icons.desk_outlined,
  'laundry': Icons.local_laundry_service_outlined,
  'exterior': Icons.yard_outlined,
  'other': Icons.home_work_outlined,
};

class RoomStartChoice {
  final String name, roomTypeId;
  final RoomStarter? starter;
  const RoomStartChoice(this.name, this.roomTypeId, this.starter);
}

class RoomStartDialog extends StatefulWidget {
  final RoomStarter? starter;
  const RoomStartDialog({super.key, this.starter});
  @override
  State<RoomStartDialog> createState() => _RoomStartDialogState();
}

class _RoomStartDialogState extends State<RoomStartDialog> {
  late final TextEditingController name;
  late String type;
  RoomStarter? starter;
  String? error;
  String query = '', category = '';
  @override
  void initState() {
    super.initState();
    starter = widget.starter;
    type = starter?.roomTypeId ?? 'kitchen';
    name = TextEditingController(text: roomTypes[type]);
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  void select(String id) => setState(() {
    if (name.text == roomTypes[type]) name.text = roomTypes[id]!;
    type = id;
    if (starter?.anyRoom != true && starter?.roomTypeId != id) starter = null;
  });
  void submit() {
    final value = name.text.trim();
    if (value.isEmpty || value.length > 80) {
      setState(() => error = 'Use a room name between 1 and 80 characters.');
      return;
    }
    Navigator.pop(context, RoomStartChoice(value, type, starter));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Choose your room'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a room type, then add your own photos.'),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('room-name'),
              controller: name,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: 'Room name',
                errorText: error,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => submit(),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('room-search'),
              decoration: const InputDecoration(
                labelText: 'Search rooms and spaces',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  setState(() => query = value.toLowerCase().trim()),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: category,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Room category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('All home spaces'),
                ),
                for (final label in roomCategories.keys)
                  DropdownMenuItem(value: label, child: Text(label)),
              ],
              onChanged: (value) => setState(() => category = value ?? ''),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in roomTypes.entries)
                    if ((category.isEmpty ||
                            roomCategories[category]!.contains(entry.key)) &&
                        (query.isEmpty ||
                            entry.value.toLowerCase().contains(query) ||
                            entry.key.contains(query)))
                      SizedBox(
                        width: (constraints.maxWidth - 8) / 2,
                        child: Semantics(
                          selected: type == entry.key,
                          child: OutlinedButton(
                            key: ValueKey('room-type-${entry.key}'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: type == entry.key
                                  ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                  : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),
                            ),
                            onPressed: () => select(entry.key),
                            child: Column(
                              children: [
                                Icon(
                                  _roomIcons[roomFeatureProfile(entry.key)] ??
                                      Icons.home_work_outlined,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(entry.value, textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            if (starter != null) ...[
              const SizedBox(height: 8),
              Text('Starting direction: ${starter!.title}'),
              const Text(
                'Only its style and palette are applied. Your photos define the room.',
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: submit, child: const Text('Continue to photos')),
    ],
  );
}

class InspirationGallery extends StatefulWidget {
  final ValueChanged<RoomStarter> onUse;
  const InspirationGallery({super.key, required this.onUse});
  @override
  State<InspirationGallery> createState() => _InspirationGalleryState();
}

class _InspirationGalleryState extends State<InspirationGallery> {
  String room = '', style = '';
  @override
  Widget build(BuildContext context) {
    final samples = roomStarters
        .where(
          (s) =>
              (room.isEmpty || s.roomTypeId == room) &&
              (style.isEmpty || s.styleId == style),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find a starting style',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          '${roomStarters.length} AI-created examples for inspiration. Your room can use all ${roomTypes.length} space types, ${designStyles.length} styles and ${designPalettes.length} colour palettes.',
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          title: const Text('All styles and colour palettes'),
          subtitle: const Text(
            'These choices are not limited to the example images.',
          ),
          maintainState: true,
          children: [DesignDirectionPicker(onUse: widget.onUse)],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                key: ValueKey('sample-room-$room'),
                initialValue: room,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sample room',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All rooms')),
                  for (final entry in roomTypes.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: (value) => setState(() => room = value ?? ''),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                key: ValueKey('sample-style-$style'),
                initialValue: style,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sample style',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All styles')),
                  for (final entry in designStyles.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: (value) => setState(() => style = value ?? ''),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (samples.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No samples match both filters. Your own room can still use any style.',
                ),
                TextButton(
                  onPressed: () => setState(() {
                    room = '';
                    style = '';
                  }),
                  child: const Text('Clear sample filters'),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 360 * MediaQuery.textScalerOf(context).scale(1),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: samples.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final sample = samples[i];
                final palette = paletteById(sample.paletteId)!;
                return SizedBox(
                  width: 264,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InspirationDetail(
                            sample: sample,
                            onUse: widget.onUse,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SampleImage(sample: sample, height: 160),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sample.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(designStyles[sample.styleId]!),
                                const SizedBox(height: 8),
                                PaletteSwatches(palette: palette),
                                const SizedBox(height: 8),
                                const Text(
                                  'View sample',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class DesignDirectionPicker extends StatefulWidget {
  final ValueChanged<RoomStarter> onUse;
  const DesignDirectionPicker({super.key, required this.onUse});
  @override
  State<DesignDirectionPicker> createState() => _DesignDirectionPickerState();
}

class _DesignDirectionPickerState extends State<DesignDirectionPicker> {
  String style = 'modern', palette = 'warm_neutrals';
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a direction for your own room. More styles can be combined in its workspace.',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final entry in designStyles.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: style == entry.key,
                onSelected: (_) => setState(() => style = entry.key),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ColourPalettePicker(
          selectedId: palette,
          onSelected: (id) => setState(() => palette = id),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => widget.onUse(
            RoomStarter(
              id: 'custom_direction',
              title:
                  '${designStyles[style]} / ${paletteById(palette)?.name ?? 'No palette preference'}',
              roomTypeId: 'kitchen',
              styleId: style,
              paletteId: palette,
              asset: '',
              description: '',
              anyRoom: true,
            ),
          ),
          child: const Text('Use these choices with my room'),
        ),
      ],
    ),
  );
}

class SampleImage extends StatelessWidget {
  final RoomStarter sample;
  final double height;
  const SampleImage({super.key, required this.sample, required this.height});
  @override
  Widget build(BuildContext context) => Image.asset(
    sample.asset,
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    cacheWidth: 1000,
    semanticLabel: 'AI-created example: ${sample.title}',
    errorBuilder: (_, _, _) => SizedBox(
      height: height,
      child: const Center(child: Text('Sample image unavailable')),
    ),
  );
}

class InspirationDetail extends StatelessWidget {
  final RoomStarter sample;
  final ValueChanged<RoomStarter> onUse;
  const InspirationDetail({
    super.key,
    required this.sample,
    required this.onUse,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(sample.title)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Chip(label: Text('AI-created inspiration sample')),
            const SizedBox(height: 12),
            SampleImage(sample: sample, height: 330),
            const SizedBox(height: 18),
            Text(
              sample.description,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '${roomTypes[sample.roomTypeId]} · ${designStyles[sample.styleId]}',
            ),
            const SizedBox(height: 12),
            PaletteSwatches(palette: paletteById(sample.paletteId)!),
            const SizedBox(height: 12),
            const Text(
              'Use this direction with your own room photo. We apply the style and colour palette; this sample is not sent as a room image or added to your project. Choose the finishes you want to change in your room.',
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Use this style with my room'),
              onPressed: () {
                Navigator.pop(context);
                onUse(sample);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
