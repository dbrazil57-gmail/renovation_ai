import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

String recordingForGuide(String id) => switch (id) {
  'camera' => 'capture',
  'live' => 'live',
  'tools' => 'library',
  'saving' => 'saving',
  'paint' => 'paint',
  'models' || 'model-comparison' => 'models',
  _ => 'design',
};

/// Playback only. Recordings are bundled app demonstrations, never the viewer's
/// projects, camera, provider credentials or network AI responses.
class WalkthroughVideo extends StatefulWidget {
  final String recording;
  const WalkthroughVideo({super.key, required this.recording});
  @override
  State<WalkthroughVideo> createState() => _WalkthroughVideoState();
}

class _WalkthroughVideoState extends State<WalkthroughVideo>
    with WidgetsBindingObserver {
  VideoPlayerController? controller;
  bool opening = false, failed = false, fullScreen = false;
  bool get playbackFailed => failed || controller?.value.hasError == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> play() async {
    if (opening) return;
    final existing = controller;
    if (existing != null && existing.value.isInitialized && !playbackFailed) {
      try {
        if (existing.value.isPlaying) {
          await existing.pause();
        } else {
          if (existing.value.position >= existing.value.duration) {
            await existing.seekTo(Duration.zero);
          }
          await existing.play();
        }
      } catch (_) {
        if (mounted) setState(() => failed = true);
      }
      return;
    }
    setState(() {
      opening = true;
      failed = false;
    });
    try {
      final catalog = jsonDecode(
        await rootBundle.loadString('assets/walkthroughs/recordings.json'),
      ) as Map;
      final filename =
          (catalog['recordings'] as Map)[widget.recording]['file'] as String;
      if (!RegExp(r'^[a-z]+\.(mp4|webm)$').hasMatch(filename)) {
        throw const FormatException('Invalid recording asset');
      }
      if (!mounted) return;
      final candidate = VideoPlayerController.asset(
        'assets/walkthroughs/$filename',
      );
      controller = candidate;
      await existing?.dispose();
      await candidate.initialize();
      if (!mounted) return;
      await candidate.setVolume(0);
      await candidate.play();
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(controller?.pause().catchError((_) {}) ?? Future.value());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(controller?.dispose() ?? Future.value());
    controller = null;
    super.dispose();
  }

  String time(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  Widget surface(VideoPlayerController? player) => ColoredBox(
    color: Colors.black,
    child: Center(
      child: player?.value.isInitialized == true && !playbackFailed
          ? AspectRatio(
              aspectRatio: player!.value.aspectRatio,
              child: VideoPlayer(player),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/walkthroughs/${widget.recording}-poster.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.expand(),
                ),
                if (opening)
                  const CircularProgressIndicator()
                else
                  IconButton.filled(
                    tooltip: playbackFailed
                        ? 'Retry recording'
                        : 'Play recording',
                    iconSize: 52,
                    onPressed: play,
                    icon: const Icon(Icons.play_arrow),
                  ),
              ],
            ),
    ),
  );

  Widget transport(VideoPlayerController? player, {bool overlay = false}) {
    final value = player?.value;
    final initialized = value?.isInitialized == true && !playbackFailed;
    final total = initialized ? value!.duration.inMilliseconds.toDouble() : 1.0;
    final position = initialized
        ? value!.position.inMilliseconds.toDouble().clamp(0.0, total)
        : 0.0;
    return Material(
      color: overlay ? Colors.black87 : Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (initialized)
              Slider(
                semanticFormatterCallback: (value) =>
                    time(Duration(milliseconds: value.round())),
                min: 0,
                max: total > 0 ? total : 1,
                value: position,
                onChanged: (value) =>
                    player!.seekTo(Duration(milliseconds: value.round())),
              ),
            Row(
              children: [
                IconButton(
                  tooltip: value?.isPlaying == true
                      ? 'Pause recording'
                      : 'Play recording',
                  onPressed: opening ? null : play,
                  icon: Icon(
                    value?.isPlaying == true ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                if (initialized)
                  IconButton(
                    tooltip: 'Back 10 seconds',
                    onPressed: () => player!.seekTo(
                      value!.position - const Duration(seconds: 10),
                    ),
                    icon: const Icon(Icons.replay_10),
                  ),
                Expanded(
                  child: Text(
                    initialized
                        ? '${time(value!.position)} / ${time(value.duration)}'
                        : 'Recorded app demo',
                  ),
                ),
                IconButton(
                  tooltip: overlay
                      ? 'Exit full screen'
                      : 'Full screen recording',
                  onPressed: overlay
                      ? () => Navigator.pop(context)
                      : fullScreen || !initialized
                      ? null
                      : openFullScreen,
                  icon: Icon(
                    overlay ? Icons.fullscreen_exit : Icons.fullscreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openFullScreen() async {
    if (fullScreen || controller?.value.isInitialized != true) return;
    fullScreen = true;
    try {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (routeContext) => Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(child: playerLayout(full: true)),
          ),
        ),
      );
    } finally {
      fullScreen = false;
    }
  }

  Widget playerLayout({bool full = false}) {
    Widget content(VideoPlayerController? player) => Column(
      children: [
        if (!full)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Recorded app screens · sample data · simulated AI/camera',
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(full ? 0 : 12),
            child: GestureDetector(onTap: play, child: surface(player)),
          ),
        ),
        if (playbackFailed)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Recording could not play here. Retry or use Read steps.',
            ),
          ),
        if (full)
          Theme(data: ThemeData.dark(), child: transport(player, overlay: true))
        else
          transport(player),
      ],
    );
    final player = controller;
    if (player == null) return content(null);
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: player,
      builder: (_, _, _) => content(player),
    );
  }

  @override
  Widget build(BuildContext context) => playerLayout();
}
