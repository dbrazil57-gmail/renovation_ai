// Opt-in recordings of the real widgets using disposable sample projects.
// No device camera, customer store, secret store or external AI is used.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_activity.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/main.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';
import 'package:renovision_ai/room_analysis.dart';
import 'package:renovision_ai/room_camera.dart';
import 'package:renovision_ai/room_setup.dart';
import 'package:renovision_ai/room_start_widgets.dart';
import 'package:renovision_ai/live_design_screen.dart';
import 'package:renovision_ai/focus_workspace.dart';
import 'package:renovision_ai/editors.dart';

import '../test/support/memory_box.dart';
import '../test/project_documents_test.dart' show DocumentFiles;
import '../test/support/focus_navigation.dart';

class RecordedAi extends AiService {
  final Uint8List result;
  RecordedAi(this.result)
    : super(
        clientFactory: () => throw StateError('Recordings must stay offline'),
      ) {
    isDirect = true;
    model = 'gpt-image-2.6-sunburst';
    quality = 'medium';
    analysisModel = 'demo-vision';
    imageModels = ['gpt-image-2.6-sunburst', 'gpt-image-2.5-flare'];
    imageQualities = ['low', 'medium', 'high'];
    maxInputImages = 6;
    connectionNotice = 'Demonstration connection. No real key or AI request.';
  }
  @override
  bool get connected => true;
  @override
  Future<RoomAnalysisResult> analyse({
    required Uint8List image,
    required String context,
    List<Uint8List> supportingImages = const [],
    void Function(AiStage)? onProgress,
  }) async {
    onProgress?.call(AiStage.waiting);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const RoomAnalysisResult(
      observations: 'Kitchen: existing window, cabinetry, worktops and flooring. Keep the room geometry; measurements are uncertain.',
      questions: [],
      prompt: 'Modernise this kitchen with coordinated cabinetry, pale worktops and refreshed flooring. Keep the layout, window, walls and camera viewpoint.',
      model: 'demo-vision',
    );
  }

  @override
  Future<AiResult> edit({
    required Uint8List image,
    required String prompt,
    List<Uint8List> supportingImages = const [],
    String? imageModel,
    String? imageQuality,
    void Function(AiStage)? onProgress,
  }) async {
    onProgress?.call(AiStage.waiting);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return AiResult(
      image: result,
      provider: 'OpenAI',
      model: imageModel ?? model!,
      quality: imageQuality,
    );
  }
}

class RecordedCamera extends RoomCameraFeed {
  final Uint8List bytes;
  RecordedCamera(this.bytes);
  RoomCameraPhase current = RoomCameraPhase.paused;
  @override
  RoomCameraPhase get phase => current;
  @override
  String? get error => null;
  @override
  Widget preview() => Image.memory(bytes, fit: BoxFit.cover);
  @override
  Future<void> start() async {
    current = RoomCameraPhase.ready;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    current = RoomCameraPhase.paused;
    notifyListeners();
  }

  @override
  Future<Uint8List> capture() async => bytes;
}

class AppRecording {
  final WidgetTester tester;
  final String id;
  final frameKey = GlobalKey(), navigator = GlobalKey<NavigatorState>();
  final caption = ValueNotifier(''), pointer = ValueNotifier<Offset?>(null);
  final frames = <Map<String, Object>>[];
  AppRecording(this.tester, this.id);
  String get base => 'output/walkthrough-recording/$id';
  Future<void> mount(Widget home) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 780);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: buildRenovisionTheme(),
        home: home,
        builder: (context, child) => RepaintBoundary(
          key: frameKey,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: child!,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Material(
                    color: const Color(0xFF252720),
                    child: SizedBox(
                      height: 60,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'APP DEMO · sample data · AI/camera simulated',
                              style: TextStyle(
                                color: Color(0xFFD7DFC3),
                                fontSize: 10,
                              ),
                            ),
                            ValueListenableBuilder<String>(
                              valueListenable: caption,
                              builder: (_, text, _) => Text(
                                text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<Offset?>(
                valueListenable: pointer,
                builder: (_, point, _) => point == null
                    ? const SizedBox.shrink()
                    : Positioned(
                        left: point.dx - 12,
                        top: point.dy - 12,
                        child: IgnorePointer(
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0x886F8C37),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
    await quiet();
  }

  Future<void> quiet() async {
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 12)),
      );
    }
  }

  Future<void> frame(int milliseconds) async {
    await tester.pump();
    await tester.runAsync(() async {
      final boundary =
          frameKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(
        '$base/${frames.length.toString().padLeft(4, '0')}.png',
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      frames.add({
        'file': '$id/${file.uri.pathSegments.last}',
        'ms': milliseconds,
      });
    });
  }

  Future<void> bring(Finder target) async {
    if (find.byType(FocusWorkspace).evaluate().isNotEmpty) {
      await ensureFocusVisible(tester, target);
      await tester.pumpAndSettle();
      return;
    }
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        180,
        scrollable: find
            .byWidgetPredicate(
              (w) =>
                  w is Scrollable &&
                  w.axisDirection == AxisDirection.down &&
                  w.restorationId != 'editable',
            )
            .first,
        maxScrolls: 30,
      );
    }
    await tester.ensureVisible(target);
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> tap(Finder target, String text) async {
    stdout.writeln('Recording $id: $text');
    caption.value = text;
    await bring(target);
    pointer.value = tester.getCenter(target);
    await frame(200);
    await tester.tap(target);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await frame(100);
    }
    pointer.value = null;
    await quiet();
    await frame(1000);
    expect(tester.takeException(), isNull);
  }

  Future<void> text(Finder target, String value, String explanation) async {
    await bring(target);
    caption.value = explanation;
    pointer.value = tester.getCenter(target);
    await tester.tap(target);
    await frame(200);
    for (var i = 4; i < value.length + 4; i += 4) {
      await tester.enterText(
        target,
        value.substring(0, i.clamp(0, value.length)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await frame(120);
    }
    pointer.value = null;
    await quiet();
    await frame(900);
  }

  Future<void> poster() async {
    await tester.runAsync(() async {
      await Directory('assets/walkthroughs').create(recursive: true);
      await File('$base/${(frames.length - 1).toString().padLeft(4, '0')}.png')
          .copy('assets/walkthroughs/$id-poster.png');
    });
  }

  Future<void> finish() async {
    await frame(1500);
    await tester.runAsync(
      () =>
          File('$base/frames.json')
              .writeAsString(jsonEncode({'id': id, 'frames': frames})),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    caption.dispose();
    pointer.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('RECORD_APP_DEMOS');
  late Uint8List kitchen, result, bedroom;
  setUpAll(() async {
    if (!enabled) return;
    const fonts = String.fromEnvironment('RECORD_FONT_DIR');
    for (final entry in {
      'Roboto': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final bytes = await File('$fonts/${entry.value}').readAsBytes();
      await (FontLoader(
        entry.key,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
    kitchen = await File('assets/inspiration/charcoal-kitchen.png')
        .readAsBytes();
    result = await File('assets/inspiration/navy-classic-kitchen.png')
        .readAsBytes();
    bedroom = await File('assets/inspiration/white-oak-bedroom.png')
        .readAsBytes();
    await Directory('output/walkthrough-recording').create(recursive: true);
    await File('output/walkthrough-recording/sample-kitchen.png')
        .writeAsBytes(kitchen);
  });
  RenovisionStore fixture({DocumentFiles? files}) => RenovisionStore(
    records: MemoryBox(),
    photos: MemoryBox(),
    ai: RecordedAi(result),
    files: files,
  );
  testWidgets('record photo setup, analysis and design transaction', (
    tester,
  ) async {
    final store = fixture();
    final project = await store.createProject('Sample home');
    final recording = AppRecording(tester, 'design');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/image_picker'),
          (call) async => call.method == 'pickMultiImage'
              ? [
                  File('output/walkthrough-recording/sample-kitchen.png')
                      .absolute
                      .path,
                ]
              : null,
        );
    await recording.mount(ProjectScreen(store: store, project: project));
    recording.caption.value = 'Open a project and choose room photos.';
    await recording.frame(1200);
    await recording.tap(
      find.text('Choose photos'),
      'Add photos of the same room.',
    );
    await recording.tap(
      find.text('Continue to photos'),
      'Choose Kitchen. The device picker is simulated in this demo.',
    );
    await recording.frame(1000);
    await recording.poster();
    await recording.tap(
      find.text('Continue'),
      'Review the imported photo, then continue.',
    );
    await recording.text(
      find.widgetWithText(TextField, 'Your renovation goal (optional)'),
      'Modernise while keeping layout',
      'Describe the renovation and what must stay.',
    );
    await recording.tap(
      find.text('Continue'),
      'Continue to photo analysis and prompt review.',
    );
    await recording.tap(
      find.text('Analyse room photos'),
      'Review before sending photos to your provider.',
    );
    await recording.tap(
      find.text('Send photos for analysis'),
      'Demonstration analysis uses a simulated response.',
    );
    await recording.tap(
      find.text('Room observations and design plan'),
      'Review the observations and editable design plan. The current plan is enabled automatically.',
    );
    await recording.frame(1200);
    await recording.tap(
      find.text('Choose redesign options'),
      'Choose design options. Each real AI request may be billed.',
    );
    await recording.tap(
      find.text('Generate AI design'),
      'Review the source image, model and requested changes.',
    );
    await recording.tap(
      find.text('Send to OpenAI'),
      'Simulated result: this recording sends no AI request.',
    );
    await recording.tap(
      find.text('Open design workspace'),
      'The design is saved as a version. Continue to refine it.',
    );
    expect(
      store.designsFor(store.roomsFor(project.id).single.id),
      hasLength(1),
    );
    await recording.tap(
      find.text('Refine'),
      'Select a design to reveal its own focused update field.',
    );
    await recording.text(
      find.byKey(const ValueKey('selected-design-update')),
      'Change only the tap to brushed brass',
      'Describe just the update. The original renovation brief remains saved.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await recording.quiet();
    await recording.tap(
      find.text('Review & generate change').first,
      'Review this narrow correction before paying for a request.',
    );
    await recording.tap(
      find.text('Cancel'),
      'Cancel sends nothing. Confirming would save a new child version.',
    );
    await recording.finish();
    store.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/image_picker'),
          null,
        );
  }, skip: !enabled);

  testWidgets('record camera capture transaction', (tester) async {
    final store = fixture();
    final project = await store.createProject('Sample home');
    final recording = AppRecording(tester, 'capture');
    await recording.mount(ProjectScreen(store: store, project: project));
    unawaited(
      recording.navigator.currentState!
          .push<Uint8List>(
            MaterialPageRoute(
              builder: (_) => RoomCaptureScreen(feed: RecordedCamera(kitchen)),
            ),
          )
          .then((bytes) async {
            if (bytes == null) return;
            final room = await store.createRoom(
              projectId: project.id,
              name: 'Kitchen',
              roomTypeId: 'kitchen',
              originalImage: bytes,
              guidedSetup: true,
            );
            unawaited(
              recording.navigator.currentState!.push<void>(
                MaterialPageRoute(
                  builder: (_) => RoomSetupScreen(
                    store: store,
                    roomId: room.id,
                    workspace: (id) => WorkspaceScreen(
                      store: store,
                      roomId: room.id,
                      initialDesignId: id,
                    ),
                  ),
                ),
              ),
            );
          }),
    );
    await recording.quiet();
    recording.caption.value =
        'Frame the room. This demonstration camera uses a sample image.';
    await recording.frame(1600);
    await recording.poster();
    await recording.tap(
      find.text('Capture photo'),
      'Capture a clear view of the room.',
    );
    await recording.tap(
      find.text('Use photo'),
      'Accept the photo. The original is saved in your room.',
    );
    await recording.tap(
      find.text('Continue'),
      'Continue into the same guided design workflow.',
    );
    await recording.finish();
    store.dispose();
  }, skip: !enabled);

  testWidgets('record live design transaction', (tester) async {
    final store = fixture();
    final project = await store.createProject('Sample home');
    final recording = AppRecording(tester, 'live');
    await recording.mount(
      LiveDesignScreen(
        store: store,
        projectId: project.id,
        feed: RecordedCamera(kitchen),
        initialRoomChoice: const RoomStartChoice(
          'Kitchen',
          'kitchen',
          null,
          method: RoomStartMethod.liveDesign,
        ),
        settleDuration: const Duration(milliseconds: 100),
        workspace: (id, design) =>
            WorkspaceScreen(store: store, roomId: id, initialDesignId: design),
      ),
    );
    recording.caption.value =
        'Start in Live design. Camera and AI are simulated in this recording.';
    await recording.frame(1500);
    await recording.poster();
    await recording.tap(
      find.text('Start live design'),
      'Confirm before a reference frame is captured and analysed.',
    );
    await recording.tap(
      find.text('Start and analyse'),
      'The selected Kitchen becomes Kitchen (Live).',
    );
    await recording.tap(
      find.text('Generate preview'),
      'Review your choices, then generate a design for this view.',
    );
    await recording.tap(
      find.text('Send to OpenAI'),
      'The simulated design saves and overlays the camera.',
    );
    await recording.frame(1800);
    await recording.tap(
      find.text('Continue to refine'),
      'Continue into the workspace to refine your saved design.',
    );
    await recording.finish();
    store.dispose();
  }, skip: !enabled);

  testWidgets('record paint selection, colour and layer management', (
    tester,
  ) async {
    final store = fixture();
    final project = await store.createProject('Sample home');
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Bedroom',
      roomTypeId: 'bedroom',
      originalImage: bedroom,
    );
    final recording = AppRecording(tester, 'paint');
    await recording.mount(WorkspaceScreen(store: store, roomId: room.id));
    await recording.tap(
      find.byTooltip('Colours & tiles without AI'),
      'Open local paint. No AI connection or key is required.',
    );
    await recording.quiet();
    await recording.poster();
    final canvas = tester.getRect(find.byKey(const ValueKey('paint-canvas')));
    recording.caption.value =
        'Tap a clear wall area. Check the highlighted boundary.';
    recording.pointer.value =
        canvas.topLeft + Offset(canvas.width * .58, canvas.height * .2);
    await recording.frame(300);
    await tester.tapAt(recording.pointer.value!);
    recording.pointer.value = null;
    await recording.quiet();
    await recording.frame(1400);
    await recording.tap(
      find.text('2 Finish'),
      'Choose a finish for the selected surface.',
    );
    await recording.tap(
      find.text('Custom colour'),
      'Choose a paint colour; the selected section repaints locally.',
    );
    await recording.text(
      find.byType(TextFormField),
      '#A6B59B',
      'Try a soft sage wall colour.',
    );
    await recording.tap(
      find.text('Apply'),
      'Review the colour and retained room details.',
    );
    await recording.tap(
      find.text('Custom colour'),
      'Try another colour on the same wall; no new selection is needed.',
    );
    await recording.text(
      find.byType(TextFormField),
      '#8197A8',
      'Replace sage with a muted blue.',
    );
    await recording.tap(
      find.text('Apply'),
      'The same wall now uses the new colour.',
    );
    await recording.tap(
      find.text('Compare before'),
      'Compare with the starting image.',
    );
    await recording.tap(
      find.text('Show finishes'),
      'Return to the painted preview.',
    );
    await recording.tap(
      find.byTooltip('Add surface'),
      'Add a separate wall layer when you need another colour.',
    );
    await recording.tap(
      find.byTooltip('Delete selected surface'),
      'Remove the selected layer without changing the others.',
    );
    await recording.tap(
      find.widgetWithText(FilledButton, 'Delete'),
      'Confirm. Deletion controls also work after reopening.',
    );
    await recording.tap(
      find.text('2 Finish'),
      'Return to colours for the retained wall.',
    );
    await recording.tap(
      find.text('Polish with AI'),
      'Optionally save this rough preview and prepare an AI correction.',
    );
    recording.caption.value =
        'Review the correction before generating. No AI request has started.';
    await recording.frame(2000);
    await recording.finish();
    store.dispose();
  }, skip: !enabled);

  testWidgets('record room deletion, restoration and comparison', (
    tester,
  ) async {
    final store = fixture();
    final project = await store.createProject('Sample home');
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      roomTypeId: 'kitchen',
      originalImage: kitchen,
    );
    await store.createDesign(
      roomId: room.id,
      image: result,
      title: 'Example design',
      prompt: 'Demonstration result',
    );
    final recording = AppRecording(tester, 'library');
    await recording.mount(ProjectScreen(store: store, project: project));
    recording.caption.value =
        'Open a project to see its rooms and saved designs.';
    await recording.frame(1400);
    await recording.poster();
    await recording.tap(
      find.byTooltip('Delete room'),
      'Delete is available beside each room.',
    );
    await recording.text(
      find.byKey(const ValueKey('delete-room-name')),
      'Kitchen',
      'Type the exact room name to confirm.',
    );
    await recording.tap(
      find.byKey(const ValueKey('confirm-delete-room')),
      'The room moves to Deleted rooms. Photos and designs are retained.',
    );
    await recording.tap(
      find.text('Deleted rooms (1)'),
      'Deleted rooms can be restored later, including after reopening.',
    );
    await recording.tap(
      find.byTooltip('Restore Kitchen'),
      'Restore the room with all of its original work.',
    );
    await recording.tap(find.byTooltip('Back'), 'Return to the project.');
    await recording.tap(find.text('Kitchen'), 'Open the restored room.');
    await recording.tap(
      find.byKey(const ValueKey('focus-section-ideas')),
      'Select a saved design from Ideas.',
    );
    await recording.tap(
      find.byType(FocusVersionThumbnail).last,
      'Open the saved design for comparison.',
    );
    await recording.tap(
      find.byTooltip('Compare original'),
      'Compare before and after without changing either image.',
    );
    expect(find.byType(CompareScreen), findsOneWidget);
    await recording.finish();
    store.dispose();
  }, skip: !enabled);

  testWidgets('record saving and opening a complete project', (tester) async {
    final files = DocumentFiles();
    final store = fixture(files: files);
    final project = await store.createProject('Sample home');
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: kitchen,
    );
    await store.createDesign(
      roomId: room.id,
      image: result,
      title: 'Example design',
      prompt: 'Demonstration result',
    );
    final recording = AppRecording(tester, 'saving');
    await recording.mount(ProjectScreen(store: store, project: project));
    recording.caption.value = 'Local autosave keeps your work on this device.';
    await recording.frame(1600);
    await recording.tap(
      find.byTooltip('Save project file'),
      'Use Save for a portable file containing rooms, photos and designs.',
    );
    await recording.poster();
    await recording.tap(
      find.text('Save project'),
      'Choose a destination. The system file picker is simulated here.',
    );
    expect(files.disk.bytes, isNotNull);
    await recording.tap(find.text('Close'), 'The portable file is saved.');
    files.opening = files.disk.bytes;
    final reopened = fixture(files: files);
    unawaited(
      recording.navigator.currentState!.push<void>(
        MaterialPageRoute(builder: (_) => AppShell(store: reopened)),
      ),
    );
    await recording.quiet();
    await recording.tap(
      find.text('Open project file…'),
      'On another device or after reinstalling, open your project file.',
    );
    await recording.tap(
      find.text('Open project'),
      'Review the room, version and image counts before opening.',
    );
    expect(reopened.roomsFor(project.id), hasLength(1));
    expect(reopened.designsFor(room.id), hasLength(1));
    expect(reopened.imageFor(room.originalId), kitchen);
    await recording.tap(
      find.text('Kitchen'),
      'All room photos and designs are back.',
    );
    await recording.frame(1500);
    await recording.finish();
    store.dispose();
    reopened.dispose();
  }, skip: !enabled);

  testWidgets('record model selection settings', (tester) async {
    final store = fixture();
    final recording = AppRecording(tester, 'models');
    await recording.mount(settingsPage(store));
    recording.caption.value =
        'AI connection and models is the first settings section.';
    await recording.frame(1200);
    await recording.poster();
    await recording.tap(
      find.byKey(const ValueKey('ai-connection-settings')),
      'Open AI settings. This demo uses no real API key.',
    );
    await recording.tap(
      find.text('Recommended design models'),
      'Review the available design model presets.',
    );
    await recording.tap(
      find.text('Quick ideas'),
      'Quick ideas changes the model or quality for the next request.',
    );
    await recording.tap(
      find.text('Showcase concept'),
      'Choose a starting preset, then compare the same photo and brief.',
    );
    await recording.finish();
    store.dispose();
  }, skip: !enabled);
}
