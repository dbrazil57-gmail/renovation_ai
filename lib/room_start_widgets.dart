import 'package:material_ui/material_ui.dart';

import 'app_appearance.dart';

import 'colour_palette_widgets.dart';
import 'design_palettes.dart';
import 'design_styles.dart';
import 'room_features.dart';
import 'room_camera.dart';
import 'room_starters.dart';

const _roomIcons = <String, IconData>{
  'kitchen': Icons.kitchen_outlined,
  'bathroom': Icons.bathtub_outlined,
  'bedroom': Icons.bed_outlined,
  'living': Icons.weekend_outlined,
  'office': Icons.desk_outlined,
  'laundry': Icons.local_laundry_service_outlined,
  'pantry': Icons.shelves,
  'storage': Icons.inventory_2_outlined,
  'garage': Icons.garage_outlined,
  'outdoor': Icons.yard_outlined,
  'exterior': Icons.yard_outlined,
  'other': Icons.home_work_outlined,
};

enum RoomStartMethod { camera, photos, liveDesign }

class RoomStartChoice {
  final String name, roomTypeId;
  final RoomStarter? starter;
  final RoomStartMethod method;
  const RoomStartChoice(
    this.name,
    this.roomTypeId,
    this.starter, {
    this.method = RoomStartMethod.photos,
  });
}

class RoomStartDialog extends StatefulWidget {
  final RoomStarter? starter;
  final String? initialRoomTypeId;

  /// Initial source choice; users can switch before continuing.
  final bool? camera;
  const RoomStartDialog({
    super.key,
    this.starter,
    this.initialRoomTypeId,
    this.camera = false,
  });
  @override
  State<RoomStartDialog> createState() => _RoomStartDialogState();
}

class _RoomStartDialogState extends State<RoomStartDialog> {
  late final TextEditingController name;
  late String type;
  late RoomStartMethod method;
  RoomStarter? starter;
  String? error;
  String query = '', category = '';
  bool nameEdited = false;

  List<String> get nameSuggestions {
    if (!nameEdited) return const [];
    final words = RegExp(r'[a-z]+')
        .allMatches(name.text.toLowerCase())
        .map((match) => match.group(0)!)
        .where(
          (word) =>
              word.length >= 3 &&
              !const {
                'room',
                'rooms',
                'the',
                'new',
                'floor',
                'area',
                'space',
                'upstairs',
                'downstairs',
                'ground',
                'first',
                'second',
              }.contains(word),
        )
        .toList();
    const aliases = {
      'exterior': 'outside facade elevation frontage',
      'bathroom': 'washroom',
      'bedroom': 'bed',
      'family': 'lounge',
      'media': 'cinema theatre theater',
      'patio': 'alfresco',
      'verandah': 'veranda porch',
      'utility': 'mudroom',
    };
    final matches = <(String, int)>[];
    for (final entry in roomTypes.entries) {
      final terms = RegExp(r'[a-z]+')
          .allMatches(
            '${entry.key} ${entry.value} ${aliases[entry.key] ?? ''}'
                .toLowerCase(),
          )
          .map((match) => match.group(0)!)
          .toSet();
      var score = 0;
      for (final word in words) {
        if (terms.contains(word)) {
          score += 3;
        } else if (terms.any((term) => term.startsWith(word))) {
          score++;
        }
      }
      if (score > 0) matches.add((entry.key, score));
    }
    matches.sort((a, b) => b.$2.compareTo(a.$2));
    return matches.take(4).map((match) => match.$1).toList();
  }

  @override
  void initState() {
    super.initState();
    method = !supportsLiveRoomCamera || widget.camera == false
        ? RoomStartMethod.photos
        : RoomStartMethod.camera;
    starter = widget.starter;
    type =
        starter?.roomTypeId ??
        (roomTypes.containsKey(widget.initialRoomTypeId)
            ? widget.initialRoomTypeId!
            : 'kitchen');
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
    Navigator.pop(
      context,
      RoomStartChoice(value, type, starter, method: method),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    actionsPadding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
    title: const Text('Choose your room', style: TextStyle(fontSize: 20)),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(switch (method) {
              RoomStartMethod.camera =>
                'Choose a room type, then open the camera.',
              RoomStartMethod.photos =>
                'Choose a room type, then choose photos from your device.',
              RoomStartMethod.liveDesign => 'Choose a room type, then analyse and design it in the camera viewer.',
            }, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('room-name'),
              controller: name,
              maxLength: 80,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Room name',
                labelStyle: const TextStyle(fontSize: 13),
                isDense: true,
                counterText: '',
                errorText: error,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => submit(),
              onChanged: (_) => setState(() {
                nameEdited = true;
                error = null;
              }),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('room-search'),
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Search rooms and spaces',
                labelStyle: TextStyle(fontSize: 13),
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  setState(() => query = value.toLowerCase().trim()),
            ),
            if (nameSuggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Suggested from your name',
                style: TextStyle(fontSize: 12),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  for (final id in nameSuggestions)
                    ChoiceChip(
                      key: ValueKey('suggest-room-type-$id'),
                      label: Text(roomTypes[id]!),
                      selected: type == id,
                      onSelected: (_) => select(id),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: category,
              isExpanded: true,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Room category',
                labelStyle: TextStyle(fontSize: 13),
                isDense: true,
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
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale =
                    MediaQuery.textScalerOf(context).scale(13) / 13;
                final columns =
                    ((constraints.maxWidth + 8) / (124 * textScale + 8))
                        .floor()
                        .clamp(1, 3);
                final width =
                    (constraints.maxWidth - 8 * (columns - 1)) / columns;
                final choices = roomTypes.entries
                    .where(
                      (entry) =>
                          (category.isEmpty ||
                              roomCategories[category]!.contains(entry.key)) &&
                          (query.isEmpty ||
                              entry.value.toLowerCase().contains(query) ||
                              entry.key.contains(query)),
                    )
                    .toList();
                if (choices.isEmpty) {
                  return const Text(
                    'No rooms match. Try another search or category.',
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in choices)
                      SizedBox(
                        width: width,
                        child: _RoomChoiceTile(
                          key: ValueKey('room-type-${entry.key}'),
                          type: entry.key,
                          label: entry.value,
                          selected: type == entry.key,
                          onTap: () => select(entry.key),
                        ),
                      ),
                  ],
                );
              },
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
      SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: [
                for (final option in RoomStartMethod.values)
                  if (supportsLiveRoomCamera ||
                      option == RoomStartMethod.photos)
                    ChoiceChip(
                      key: ValueKey('room-start-method-${option.name}'),
                      label: Text(switch (option) {
                        RoomStartMethod.camera => 'Camera',
                        RoomStartMethod.photos => 'Photos',
                        RoomStartMethod.liveDesign => 'Live design',
                      }),
                      avatar: Icon(switch (option) {
                        RoomStartMethod.camera => Icons.camera_alt_outlined,
                        RoomStartMethod.photos => Icons.photo_library_outlined,
                        RoomStartMethod.liveDesign =>
                          Icons.auto_awesome_outlined,
                      }, size: 18),
                      labelStyle: const TextStyle(fontSize: 13),
                      selected: method == option,
                      onSelected: (_) => setState(() => method = option),
                    ),
              ],
            ),
            const SizedBox(height: 6),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submit,
                  child: Text(switch (method) {
                    RoomStartMethod.camera => 'Continue to camera',
                    RoomStartMethod.photos => 'Continue to photos',
                    RoomStartMethod.liveDesign => 'Continue to live design',
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

class _RoomChoiceTile extends StatelessWidget {
  final String type, label;
  final bool selected;
  final VoidCallback onTap;
  const _RoomChoiceTile({
    super.key,
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // These bundled examples decorate the chooser; selecting a type never
    // imports an example or applies its style/palette to the user's room.
    final photoType = switch (type) {
      'main_bedroom' || 'guest_bedroom' => 'bedroom',
      'ensuite' => 'bathroom',
      'family' => 'living',
      'study' => 'office',
      _ => type,
    };
    final sample = roomStarters
        .where((s) => s.roomTypeId == photoType)
        .firstOrNull;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: AppAppearance.of(context).canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              if (sample != null)
                Positioned.fill(
                  child: Ink.image(
                    image: ResizeImage(AssetImage(sample.asset), width: 360),
                    fit: BoxFit.cover,
                  ),
                ),
              Positioned.fill(
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66000000), Color(0xDD000000)],
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 80),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _roomIcons[roomFeatureProfile(type)] ??
                                Icons.home_work_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                          const Spacer(),
                          if (selected)
                            const Icon(
                              Icons.check_circle,
                              size: 20,
                              color: Colors.white,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
