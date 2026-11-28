import 'package:material_ui/material_ui.dart';

import 'walkthrough_content.dart';
import 'walkthrough_video.dart';
import 'sample_flow.dart';

Future<void> showAppWalkthroughs(BuildContext context) => Navigator.push<void>(
  context,
  MaterialPageRoute(builder: (_) => const AppWalkthroughsScreen()),
);

Future<void> showModelComparisonWalkthrough(BuildContext context) =>
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const WalkthroughScreen(guide: modelComparisonWalkthrough),
      ),
    );

class AppWalkthroughsScreen extends StatelessWidget {
  const AppWalkthroughsScreen({super.key});
  void _open(BuildContext context, AppWalkthrough guide) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => WalkthroughScreen(guide: guide)),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Sample walkthroughs',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome_motion_outlined),
                  title: const Text('Try the kitchen sample flow'),
                  subtitle: const Text(
                    'Real before/after, saved brief and later ideas · offline replay',
                  ),
                  trailing: const Icon(Icons.play_circle_outline),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SampleFlowScreen(),
                    ),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/walkthroughs/design-poster.png',
                  height: 125,
                  fit: BoxFit.cover,
                  semanticLabel:
                      'Recorded RenoImagineAI workflow using sample data',
                  cacheWidth: 960,
                  errorBuilder: (_, _, _) => const SizedBox(height: 125),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Watch a complete workflow in the app.'),
              const Text(
                'Examples only · no key needed · no photos sent or projects changed.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.add_a_photo_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Camera & photos',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text('Choose how you want to start your room.'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final (guide, icon) in [
                            (photoWalkthrough, Icons.photo_library_outlined),
                            (cameraWalkthrough, Icons.camera_alt_outlined),
                            (liveWalkthrough, Icons.view_in_ar_outlined),
                          ])
                            OutlinedButton.icon(
                              onPressed: () => _open(context, guide),
                              icon: Icon(icon, size: 18),
                              label: Text(guide.title),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              for (final (guide, icon) in [
                (designWalkthrough, Icons.auto_awesome_outlined),
                (toolsWalkthrough, Icons.compare_outlined),
                (paintWalkthrough, Icons.format_paint_outlined),
                (savingWalkthrough, Icons.save_outlined),
                (modelComparisonWalkthrough, Icons.balance_outlined),
              ])
                Card(
                  child: ListTile(
                    leading: Icon(icon),
                    title: Text(guide.title),
                    subtitle: Text(guide.summary),
                    trailing: const Icon(Icons.play_circle_outline),
                    onTap: () => _open(context, guide),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class WalkthroughScreen extends StatefulWidget {
  final AppWalkthrough guide;
  const WalkthroughScreen({super.key, required this.guide});
  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  int index = 0;
  bool written = false;
  final scroll = ScrollController();
  void move(int value) {
    setState(() => index = value);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guide = widget.guide;
    final step = guide.steps[index];
    final last = index == guide.steps.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(guide.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: written ? 'Watch recording' : 'Read steps',
            onPressed: () => setState(() => written = !written),
            icon: Icon(
              written ? Icons.play_circle_outline : Icons.article_outlined,
            ),
          ),
        ],
      ),
      body: !written
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Expanded(
                      child: WalkthroughVideo(
                        recording: recordingForGuide(guide.id),
                      ),
                    ),
                    OverflowBar(
                      alignment: MainAxisAlignment.spaceBetween,
                      spacing: 8,
                      overflowSpacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() => written = true),
                          icon: const Icon(Icons.article_outlined),
                          label: const Text('Read steps'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step ${index + 1} of ${guide.steps.length}',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: (index + 1) / guide.steps.length,
                              semanticsLabel:
                                  'Walkthrough progress: step ${index + 1} of ${guide.steps.length}',
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scroll,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            key: ValueKey('${guide.id}-step-$index'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  step.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(step.instruction),
                              const SizedBox(height: 16),
                              Card(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sample kitchen',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                      const SizedBox(height: 8),
                                      SelectableText(step.example),
                                    ],
                                  ),
                                ),
                              ),
                              if (step.note != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    step.note!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: OverflowBar(
                          alignment: MainAxisAlignment.spaceBetween,
                          spacing: 12,
                          overflowSpacing: 4,
                          children: [
                            TextButton.icon(
                              onPressed: index == 0
                                  ? null
                                  : () => move(index - 1),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Previous'),
                            ),
                            FilledButton.icon(
                              onPressed: last
                                  ? () => Navigator.pop(context)
                                  : () => move(index + 1),
                              icon: Icon(
                                last ? Icons.check : Icons.arrow_forward,
                              ),
                              label: Text(last ? 'Done' : 'Next'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
