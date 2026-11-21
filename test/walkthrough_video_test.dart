import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:renovision_ai/walkthrough_video.dart';

class RecordedPlayerPlatform extends VideoPlayerPlatform {
  int next = 0;
  final events = <int, StreamController<VideoEvent>>{};
  final sources = <String>[];
  final paused = <int>[], played = <int>[], disposed = <int>[];
  final positions = <int, Duration>{};
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = ++next;
    sources.add(options.dataSource.asset!);
    events[id] = StreamController<VideoEvent>();
    events[id]!.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 24),
        size: const Size(390, 780),
      ),
    );
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int id) => events[id]!.stream;
  @override
  Future<void> dispose(int id) async {
    disposed.add(id);
    await events[id]!.close();
  }

  @override
  Future<void> play(int id) async {
    played.add(id);
  }

  @override
  Future<void> pause(int id) async {
    paused.add(id);
  }

  @override
  Future<void> setLooping(int id, bool value) async {}
  @override
  Future<void> setVolume(int id, double value) async {}
  @override
  Future<void> setPlaybackSpeed(int id, double value) async {}
  @override
  Future<void> setMixWithOthers(bool value) async {}
  @override
  Future<void> setAllowBackgroundPlayback(bool value) async {}
  @override
  Future<void> seekTo(int id, Duration value) async {
    positions[id] = value;
  }

  @override
  Future<Duration> getPosition(int id) async => positions[id] ?? Duration.zero;
  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const ColoredBox(color: Colors.black);
}

void main() {
  Future<void> until(WidgetTester tester, bool Function() ready) async {
    for (var i = 0; i < 100 && !ready(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await tester.pump();
    }
    expect(ready(), isTrue);
  }

  late RecordedPlayerPlatform platform;
  late VideoPlayerPlatform previous;
  setUp(() {
    // Cached bundle futures belong to the previous test's fake-async zone.
    rootBundle.evict('assets/walkthroughs/recordings.json');
    previous = VideoPlayerPlatform.instance;
    platform = RecordedPlayerPlatform();
    VideoPlayerPlatform.instance = platform;
  });
  tearDown(() {
    VideoPlayerPlatform.instance = previous;
  });
  testWidgets(
    'recordings load only on play, seek, share the fullscreen player, pause in background and dispose',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WalkthroughVideo(recording: 'design')),
        ),
      );
      await tester.pumpAndSettle();
      expect(platform.sources, isEmpty);
      await tester.tap(find.byTooltip('Play recording').first);
      await tester.pump();
      await until(tester, () => platform.played.isNotEmpty);
      expect(platform.sources, ['assets/walkthroughs/design.mp4']);
      await tester.tap(find.byTooltip('Pause recording'));
      await tester.pump();
      tester.widget<Slider>(find.byType(Slider)).onChanged!(18000);
      await tester.pump();
      expect(platform.positions[1], const Duration(seconds: 18));
      await tester.tap(find.byTooltip('Full screen recording'));
      await tester.pumpAndSettle();
      expect(platform.sources, hasLength(1));
      await tester.tap(find.byTooltip('Exit full screen'));
      await tester.pumpAndSettle();
      final pauses = platform.paused.length;
      final observer =
          tester.state(find.byType(WalkthroughVideo)) as WidgetsBindingObserver;
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();
      expect(platform.paused.length, greaterThan(pauses));
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await until(tester, () => platform.disposed.contains(1));
      expect(platform.disposed, [1]);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'a decoder failure shows retry instead of a stalled or blank player',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WalkthroughVideo(recording: 'paint')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Play recording').first);
      await until(tester, () => platform.played.isNotEmpty);
      platform.events[1]!.addError(
        PlatformException(
          code: 'fixture-decode',
          message: 'Simulated decoder failure',
        ),
      );
      await tester.pump();
      expect(
        find.textContaining('Recording could not play here'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Retry recording'));
      await until(tester, () => platform.played.contains(2));
      expect(platform.disposed, contains(1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await until(tester, () => platform.disposed.contains(2));
      expect(platform.disposed, contains(2));
      expect(tester.takeException(), isNull);
    },
  );
}
