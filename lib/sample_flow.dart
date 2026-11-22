import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app_store_scope.dart';
import 'models.dart';
import 'project_backup.dart';
import 'image_viewer.dart';
import 'editors.dart';

class SampleFlow {
  final Map<String, dynamic> notes;
  final List<Uint8List> images;
  SampleFlow(this.notes, this.images);
  static Future<SampleFlow> load() async {
    final notes = jsonDecode(
      await rootBundle.loadString('assets/demo/flow.json'),
    ) as Map<String, dynamic>;
    final images = <Uint8List>[];
    for (final name in ['before', 'concept', 'ideas']) {
      images.add(
        (await rootBundle.load('assets/demo/$name.jpg')).buffer.asUint8List(),
      );
    }
    return SampleFlow(notes, images);
  }

  ProjectBackup practiceBackup() {
    final time = DateTime.utc(2026, 11, 22);
    final room = RenovationRoom(
      id: 'sample_room',
      projectId: 'sample_project',
      name: 'Kitchen',
      originalId: 'sample_before',
      instructions: 'Modernise the kitchen with a coordinated design. Keep the room layout.',
      protectedFeatures: 'Window, walls and openings',
      created: time,
      roomTypeId: 'kitchen',
      designStyleIds: const ['modern'],
      colourPaletteId: 'charcoal_walnut',
    );
    final versions = <DesignVersion>[
      DesignVersion(
        id: 'sample_concept',
        roomId: room.id,
        imageId: 'sample_after',
        title: 'Saved concept · sample',
        prompt: notes['historicalPrompt'],
        parentId: null,
        favourite: false,
        rejected: false,
        created: time,
        sourceImageId: room.originalId,
      ),
      DesignVersion(
        id: 'sample_ideas',
        roomId: room.id,
        imageId: 'sample_board',
        title: 'Later idea board · different view',
        prompt:
            '${notes['ideaPromptStatus']}\n${notes['ideaPrompt']}\n${notes['notes']}',
        parentId: 'sample_concept',
        favourite: false,
        rejected: false,
        created: time.add(const Duration(seconds: 1)),
      ),
    ];
    return ProjectBackup.decode(
      ProjectBackup(
        project: RenovationProject(
          id: 'sample_project',
          name: 'Sample kitchen · practice',
          created: time,
        ),
        rooms: [room],
        designs: versions,
        photos: {
          'sample_before': images[0],
          'sample_after': images[1],
          'sample_board': images[2],
        },
      ).encode(),
    );
  }
}

class SampleFlowScreen extends StatefulWidget {
  const SampleFlowScreen({super.key});
  @override
  State<SampleFlowScreen> createState() => _SampleFlowScreenState();
}

class _SampleFlowScreenState extends State<SampleFlowScreen> {
  final content = SampleFlow.load();
  int step = 0;
  Timer? playback;
  bool busy = false, showBrief = false;
  String? error;
  static const titles = [
    'Original kitchen',
    'Saved design brief',
    'Saved renovation result',
    'Later ideas & materials',
  ];
  static const descriptions = [
    'The original photo stays preserved. Choose a clear working view before designing.',
    'Review room, style, palette and what must stay. This historical project recorded the brief below; its external chat/model was not recorded.',
    'This previously saved result is replayed from the app bundle. Compare it, zoom in, or practise refinements on a separate copy.',
    'A later AI idea board explores charcoal, walnut, benchtops and floors. It changes viewpoint and includes an illustrative, unverified plan.',
  ];
  @override
  void dispose() {
    playback?.cancel();
    super.dispose();
  }

  void move(int value) {
    setState(() {
      step = value.clamp(0, 3);
      showBrief = false;
    });
  }

  void play() {
    if (playback != null) {
      playback!.cancel();
      setState(() => playback = null);
      return;
    }
    if (step == 3) {
      move(0);
    }
    setState(() {
      playback = Timer.periodic(const Duration(seconds: 7), (timer) {
        if (step == 3) {
          timer.cancel();
          setState(() => playback = null);
        } else {
          move(step + 1);
        }
      });
    });
  }

  Future<void> practise(SampleFlow flow) async {
    final scope = AppStoreScope.maybeOf(context);
    if (scope == null || scope.store.ai.activity.active) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final remembered = scope.store.records.get(
        'settings:sample_practice_project',
      );
      var rooms = remembered is String
          ? scope.store.roomsFor(remembered)
          : <RenovationRoom>[];
      if (rooms.isEmpty) {
        final project = await scope.store.restoreBackup(flow.practiceBackup());
        await scope.store.renameProject(
          project.id,
          'Sample kitchen · practice',
        );
        await scope.store.records.put(
          'settings:sample_practice_project',
          project.id,
        );
        rooms = scope.store.roomsFor(project.id);
      }
      final room = rooms.first;
      final concept = scope.store
          .designsFor(room.id)
          .where((d) => d.title == 'Saved concept · sample')
          .firstOrNull;
      playback?.cancel();
      playback = null;
      if (mounted) {
        scope.openRoom(context, room.id, concept?.id);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'The practice copy could not open. Existing projects are unchanged; check Projects before retrying.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kitchen sample flow')),
    body: SafeArea(
      child: FutureBuilder<SampleFlow>(
        future: content,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Sample unavailable. Reopen Help to retry.'),
            );
          }
          final flow = snapshot.data;
          if (flow == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final index = step < 2 ? 0 : step - 1;
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Offline replay · saved images · no AI requests or credits',
                ),
              ),
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () => openImageViewer(
                    context,
                    flow.images[index],
                    title: titles[step],
                  ),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: Image.memory(
                      flow.images[index],
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${step + 1}/4 · ${titles[step]}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          descriptions[step],
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (step > 0)
                              TextButton(
                                onPressed: () =>
                                    setState(() => showBrief = !showBrief),
                                child: Text(
                                  showBrief ? 'Hide brief' : 'View saved brief',
                                ),
                              ),
                            if (step == 2)
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => CompareScreen(
                                      original: flow.images[0],
                                      edited: flow.images[1],
                                    ),
                                  ),
                                ),
                                child: const Text('Compare before / after'),
                              ),
                          ],
                        ),
                        if (showBrief)
                          SizedBox(
                            height: 110,
                            child: SingleChildScrollView(
                              child: SelectableText(
                                step == 3
                                    ? '${flow.notes['ideaPromptStatus']}\n${flow.notes['ideaPrompt']}'
                                    : flow.notes['historicalPrompt'] as String,
                              ),
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: 'Previous sample stage',
                              onPressed: step == 0
                                  ? null
                                  : () => move(step - 1),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: play,
                                icon: Icon(
                                  playback == null
                                      ? Icons.play_arrow
                                      : Icons.pause,
                                ),
                                label: Text(
                                  playback == null
                                      ? 'Play replay'
                                      : 'Pause replay',
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Next sample stage',
                              onPressed: step == 3
                                  ? null
                                  : () => move(step + 1),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        if (AppStoreScope.maybeOf(context) != null)
                          FilledButton.icon(
                            onPressed: busy ? null : () => practise(flow),
                            icon: const Icon(Icons.copy_all_outlined),
                            label: Text(
                              busy
                                  ? 'Preparing practice copy…'
                                  : 'Try a separate practice project',
                            ),
                          ),
                        if (error != null) Text(error!),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
