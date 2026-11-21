import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_activity.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/ai_widgets.dart';
import 'package:renovision_ai/colour_palette_widgets.dart';
import 'package:renovision_ai/camera_room_view.dart';
import 'package:renovision_ai/live_design_screen.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/room_analysis.dart';
import 'package:renovision_ai/room_camera.dart';
import 'package:renovision_ai/room_start_widgets.dart';
import 'package:renovision_ai/room_starters.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

Uint8List picture(int red) {
  final image = img.Image(width: 40, height: 30);
  img.fill(image, color: img.ColorRgb8(red, 80, 120));
  return Uint8List.fromList(img.encodePng(image));
}

class LiveTestAi extends AiService {
  int analyses = 0, edits = 0;
  final inputs = <Uint8List>[];
  final prompts = <String>[];
  bool failAnalysis = false;
  Completer<void>? holdEdit;
  VoidCallback? afterAnalysis, afterEdit;
  LiveTestAi() {
    model = 'synthetic-image';
    quality = 'low';
    analysisModel = 'synthetic-vision';
    imageModels = [model!];
    imageQualities = ['low'];
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
    analyses++;
    inputs.add(image);
    onProgress?.call(AiStage.waiting);
    if (failAnalysis) {
      throw const AiFailure('Synthetic analysis failure. No automatic retry.');
    }
    afterAnalysis?.call();
    return const RoomAnalysisResult(
      observations: 'A kitchen with a wide window, cabinets and an existing peninsula. Measurements are uncertain.',
      questions: ['Which fixtures should stay?'],
      prompt: 'Renovate this camera view with the existing layout.',
      model: 'synthetic-vision',
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
    edits++;
    inputs.add(image);
    prompts.add(prompt);
    onProgress?.call(AiStage.waiting);
    await holdEdit?.future;
    afterEdit?.call();
    return AiResult(
      image: picture(140 + edits),
      provider: 'OpenAI',
      model: model!,
      quality: imageQuality,
    );
  }
}

class LiveTestFeed extends RoomCameraFeed {
  int captures = 0, starts = 0, stops = 0;
  bool closed = false;
  bool waitUntilReady = false;
  final bytes = picture(20);
  RoomCameraPhase state = RoomCameraPhase.paused;
  @override
  RoomCameraPhase get phase => state;
  @override
  String? get error => null;
  @override
  Widget preview() => const ColoredBox(
    key: ValueKey('live-camera-preview'),
    color: Colors.blueGrey,
  );
  @override
  Future<void> start() async {
    starts++;
    state = waitUntilReady ? RoomCameraPhase.opening : RoomCameraPhase.ready;
    notifyListeners();
  }

  void setPhase(RoomCameraPhase phase) {
    state = phase;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    stops++;
    state = RoomCameraPhase.paused;
    notifyListeners();
  }

  @override
  Future<Uint8List> capture() async {
    captures++;
    return bytes;
  }

  @override
  void dispose() {
    closed = true;
    super.dispose();
  }
}

class LivePhotos extends MemoryBox {
  bool fail = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (fail) throw StateError('Synthetic full storage');
    await super.put(key, value);
  }
}

class LiveRecords extends MemoryBox {
  bool failRoom = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (failRoom && key.toString().startsWith('room:')) {
      throw StateError('Synthetic draft write failure');
    }
    await super.put(key, value);
  }
}

void main() {
  late LiveTestAi ai;
  late LiveTestFeed feed;
  late LivePhotos photos;
  late LiveRecords records;
  late RenovisionStore store;
  late RenovationProject project;
  setUp(() async {
    ai = LiveTestAi();
    feed = LiveTestFeed();
    photos = LivePhotos();
    records = LiveRecords();
    store = RenovisionStore(records: records, photos: photos, ai: ai);
    project = await store.createProject('Live test');
  });
  tearDown(() => store.dispose());

  Future<void> show(
    WidgetTester tester, {
    String? roomId,
    double scale = 1,
    bool realWorkspace = false,
    RoomStartChoice? initialChoice,
    Duration settleDuration = const Duration(milliseconds: 100),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveDesignScreen(
                    store: store,
                    projectId: project.id,
                    roomId: roomId,
                    initialRoomChoice: initialChoice,
                    feed: feed,
                    settleDuration: settleDuration,
                    workspace: (id, design) => realWorkspace
                        ? WorkspaceScreen(
                            store: store,
                            roomId: id,
                            initialDesignId: design,
                            startInPrecision: true,
                          )
                        : Scaffold(body: Text('Continue $id $design')),
                  ),
                ),
              ),
              child: const Text('Enter live design'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Enter live design'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> start(WidgetTester tester) async {
    await tap(tester, 'Start live design');
    await tap(tester, 'Start and analyse');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
  }

  Future<void> generate(WidgetTester tester, {bool update = false}) async {
    await tap(tester, update ? 'Update preview' : 'Generate preview');
    await tap(tester, 'Send to OpenAI');
  }

  testWidgets(
    'room-first live capture retains name, room type and selected sample preferences through analysis and generation',
    (tester) async {
      final starter = roomStarters.first;
      await show(
        tester,
        initialChoice: RoomStartChoice(
          'Dining-side kitchen',
          'kitchen',
          starter,
          method: RoomStartMethod.liveDesign,
        ),
      );
      expect(store.roomsFor(project.id), isEmpty);
      expect(feed.captures, 0);
      expect(ai.analyses, 0);
      await start(tester);
      final room = store.roomsFor(project.id).single;
      expect(room.name, 'Dining-side kitchen');
      expect(room.automaticLiveName, isFalse);
      expect(room.displayName, 'Dining-side kitchen');
      expect(room.roomTypeId, 'kitchen');
      expect(room.colourPaletteId, starter.paletteId);
      expect(room.designStyleIds, [starter.styleId]);
      expect(room.analysis!.context, contains('Kitchen'));
      expect(room.photoIds, hasLength(1));
      expect(store.imageFor(room.originalId), feed.bytes);
      await generate(tester);
      expect(ai.analyses, 1);
      expect(ai.edits, 1);
      expect(ai.prompts.single, contains('Kitchen'));
      expect(ai.prompts.single, contains('Charcoal'));
      expect(store.designsFor(room.id), hasLength(1));
      expect(find.byKey(const ValueKey('live-design-overlay')), findsOneWidget);
    },
  );

  testWidgets(
    'a room-picker default bedroom gets a type-based Live label without changing its stored name',
    (tester) async {
      await show(
        tester,
        initialChoice: const RoomStartChoice(
          'Bedroom',
          'bedroom',
          null,
          method: RoomStartMethod.liveDesign,
        ),
      );
      await start(tester);
      final room = store.roomsFor(project.id).single;
      expect(room.name, 'Bedroom');
      expect(room.roomTypeId, 'bedroom');
      expect(room.automaticLiveName, isTrue);
      expect(room.displayName, 'Bedroom (Live)');
      expect(store.imageFor(room.originalId), feed.bytes);
    },
  );

  testWidgets(
    'live room type is saved immediately even when general autosave is off',
    (tester) async {
      await store.setAutosaveEnabled(false);
      await show(
        tester,
        initialChoice: const RoomStartChoice(
          'Kitchen',
          'kitchen',
          null,
          method: RoomStartMethod.liveDesign,
        ),
      );
      await start(tester);
      final room = store.roomsFor(project.id).single;
      expect(room.displayName, 'Kitchen (Live)');
      final picker = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const ValueKey('live-room-type-kitchen')),
      );
      picker.onChanged!('bedroom');
      await tester.pumpAndSettle();
      expect(store.roomById(room.id)!.displayName, 'Bedroom (Live)');
      expect(ai.analyses, 1);
    },
  );

  testWidgets(
    'opening/cancelling sends nothing; consent automatically captures and analyses once without a shutter',
    (tester) async {
      await show(tester);
      expect(ai.analyses, 0);
      expect(feed.captures, 0);
      expect(store.roomsFor(project.id), isEmpty);
      await tap(tester, 'Start live design');
      await tap(tester, 'Cancel');
      expect(ai.analyses, 0);
      expect(feed.captures, 0);
      await start(tester);
      expect(feed.captures, 1);
      expect(ai.analyses, 1);
      expect(ai.edits, 0);
      expect(find.text('Confirm room type'), findsOneWidget);
      expect(find.byKey(const ValueKey('live-camera-preview')), findsOneWidget);
      expect(feed.stops, 0);
      final room = store.roomsFor(project.id).single;
      expect(store.imageFor(room.originalId), feed.bytes);
      expect(room.analysis!.sourceImageId, room.originalId);
    },
  );

  testWidgets(
    'palette updates stay in the viewer, reuse analysis and require a separate confirmed generation',
    (tester) async {
      await show(tester);
      await start(tester);
      await generate(tester);
      final room = store.roomsFor(project.id).single;
      expect(ai.edits, 1);
      expect(find.text('Design overlay'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, 'Design overlay'),
            )
            .selected,
        isTrue,
      );
      expect(find.byKey(const ValueKey('live-design-overlay')), findsOneWidget);
      expect(find.byType(LiveDesignScreen), findsOneWidget);
      expect(find.byType(WorkspaceScreen), findsNothing);
      expect(feed.stops, 0);
      await tap(tester, 'Live camera');
      final showSaved = find.byTooltip('Show saved design on camera');
      expect(showSaved.hitTestable(), findsOneWidget);
      await tester.tap(showSaved);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('live-design-overlay')), findsOneWidget);
      expect(ai.edits, 1);
      await tap(tester, 'Palette');
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Palette'))
            .selected,
        isTrue,
      );
      await tester.ensureVisible(find.byType(ColourPalettePicker));
      await tester.drag(
        find.descendant(
          of: find.byType(ColourPalettePicker),
          matching: find.byType(ListView),
        ),
        const Offset(-260, 0),
      );
      await tester.pumpAndSettle();
      final palette = find.byKey(
        const ValueKey('quick-palette-charcoal_walnut'),
      );
      await tester.ensureVisible(palette);
      await tester.tap(palette);
      await tester.pumpAndSettle();
      expect(ai.analyses, 1);
      expect(ai.edits, 1);
      expect(feed.captures, 1);
      expect(find.textContaining('Choices changed'), findsOneWidget);
      await tap(tester, 'Update preview');
      await tap(tester, 'Cancel');
      expect(ai.edits, 1);
      await generate(tester, update: true);
      expect(ai.edits, 2);
      expect(ai.analyses, 1);
      expect(feed.captures, 1);
      expect(ai.prompts.last, contains('Charcoal & walnut'));
      expect(ai.prompts.last, contains('A kitchen with a wide window'));
      expect(ai.inputs.every((bytes) => listEquals(bytes, feed.bytes)), isTrue);
      expect(store.designsFor(room.id), hasLength(2));
      expect(
        store
            .designsFor(room.id)
            .every((d) => d.sourceImageId == room.originalId),
        isTrue,
      );
      final backup = ProjectBackup.decode(store.backupFor(project.id).encode());
      expect(backup.designs, hasLength(2));
      await tap(tester, 'Continue to refine');
      expect(find.textContaining('Continue ${room.id}'), findsOneWidget);
      expect(feed.closed, isTrue);
    },
  );

  testWidgets(
    'saved result waits for a restarting camera and then overlays without navigation or another request',
    (tester) async {
      await show(tester);
      await start(tester);
      ai.holdEdit = Completer<void>();
      await tap(tester, 'Generate preview');
      await tester.tap(find.text('Send to OpenAI'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      feed.waitUntilReady = true;
      feed.setPhase(RoomCameraPhase.paused);
      ai.holdEdit!.complete();
      await tester.pumpAndSettle();
      expect(
        store.designsFor(store.roomsFor(project.id).single.id),
        hasLength(1),
      );
      expect(find.byKey(const ValueKey('live-design-overlay')), findsNothing);
      expect(
        find.byTooltip('Show saved design on camera').hitTestable(),
        findsOneWidget,
      );
      feed.setPhase(RoomCameraPhase.ready);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('live-design-overlay')), findsOneWidget);
      expect(find.byType(LiveDesignScreen), findsOneWidget);
      expect(ai.edits, 1);
      expect(ai.analyses, 1);
      expect(feed.captures, 1);
    },
  );

  testWidgets('keyboard metrics keep a saved design over the live camera', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await show(tester);
    await start(tester);
    await generate(tester);
    expect(find.byKey(const ValueKey('live-design-overlay')), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('live-design-overlay')), findsOneWidget);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('live-design-overlay')), findsOneWidget);
    expect(ai.edits, 1);
    expect(feed.phase, RoomCameraPhase.ready);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a new saved result is visible even if the previous opacity was zero',
    (tester) async {
      await show(tester);
      await start(tester);
      await generate(tester);
      final slider = find.byType(Slider);
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      await tester.drag(slider, const Offset(-700, 0));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Opacity>(find.byKey(const ValueKey('live-design-overlay')))
            .opacity,
        0,
      );
      await generate(tester, update: true);
      expect(
        tester
            .widget<Opacity>(find.byKey(const ValueKey('live-design-overlay')))
            .opacity,
        greaterThan(.05),
      );
      expect(find.byType(WorkspaceScreen), findsNothing);
    },
  );

  testWidgets(
    'only Continue to refine leaves the viewer and starts correction of the selected saved design',
    (tester) async {
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: picture(7),
      );
      await store.updateRoom(
        room.copyWith(
          instructions: 'Modernise the kitchen with walnut cupboards.',
        ),
      );
      await show(tester, roomId: room.id, realWorkspace: true);
      await start(tester);
      await generate(tester);
      final saved = store.designsFor(room.id).single;
      expect(find.byType(WorkspaceScreen), findsNothing);
      expect(find.byKey(const ValueKey('live-design-overlay')), findsOneWidget);
      await tap(tester, 'Continue to refine');
      expect(
        tester
            .widget<WorkspaceScreen>(find.byType(WorkspaceScreen))
            .initialDesignId,
        saved.id,
      );
      final edit = tester.widget<AiEditCard>(find.byType(AiEditCard));
      expect(edit.draft!.preciseEdit, isTrue);
      edit.draft!.correction.text = 'Change only the pendant light.';
      final request = edit.buildRequest();
      expect(request.precise, isTrue);
      expect(request.sourceImageId, saved.imageId);
      expect(
        store.roomById(room.id)!.instructions,
        'Modernise the kitchen with walnut cupboards.',
      );
      expect(ai.edits, 1);
      expect(feed.closed, isTrue);
      await edit.draft!.save();
    },
  );

  for (final savedReference in [false, true]) {
    testWidgets(
      'camera primary action designs ${savedReference ? 'a saved reference' : 'the live view'} without opening the workspace',
      (tester) async {
        final room = await store.createRoom(
          projectId: project.id,
          name: 'Kitchen',
          roomTypeId: 'kitchen',
          originalImage: picture(3),
        );
        if (savedReference) {
          await store.addRoomPhotos(room.id, [
            picture(4),
            picture(5),
            picture(6),
            picture(7),
            picture(8),
          ]);
        }
        final oldFeed = LiveTestFeed();
        await tester.pumpWidget(
          MaterialApp(
            home: CameraRoomView(
              store: store,
              roomId: room.id,
              feed: oldFeed,
              workspace: (_, _) =>
                  const Scaffold(body: Text('Separate saved-view editor')),
              liveDesignBuilder: (photoId) => LiveDesignScreen(
                store: store,
                projectId: project.id,
                roomId: room.id,
                initialPhotoId: photoId,
                feed: feed,
                settleDuration: const Duration(milliseconds: 100),
                workspace: (id, design) =>
                    Scaffold(body: Text('Continue $id $design')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Edit saved view in workspace'), findsOneWidget);
        if (savedReference) await tap(tester, 'Compare');
        await tap(tester, 'Design in live camera');
        expect(find.byType(LiveDesignScreen), findsOneWidget);
        expect(find.text('Separate saved-view editor'), findsNothing);
        expect(oldFeed.closed, isTrue);
        expect(ai.analyses, 0);
        if (savedReference) {
          await tap(tester, 'Analyse saved view');
          await tap(tester, 'Start and analyse');
        } else {
          await start(tester);
        }
        await generate(tester);
        expect(
          find.byKey(const ValueKey('live-design-overlay')),
          findsOneWidget,
        );
        expect(find.byType(WorkspaceScreen), findsNothing);
        expect(ai.analyses, 1);
        expect(ai.edits, 1);
        expect(feed.captures, savedReference ? 0 : 1);
        expect(
          store.roomById(room.id)!.photoIds,
          hasLength(savedReference ? 6 : 2),
        );
        expect(store.roomById(room.id)!.originalId, room.originalId);
      },
    );
  }

  testWidgets(
    'failed reference save retries the same frame before any AI call',
    (tester) async {
      photos.fail = true;
      await show(tester);
      await start(tester);
      expect(feed.captures, 1);
      expect(ai.analyses, 0);
      expect(store.roomsFor(project.id), isEmpty);
      photos.fail = false;
      await tap(tester, 'Retry save and analyse');
      expect(feed.captures, 1);
      expect(ai.analyses, 1);
      expect(store.roomsFor(project.id), hasLength(1));
    },
  );

  testWidgets(
    'received analysis can retry saving without a second analysis charge',
    (tester) async {
      ai.afterAnalysis = () => records.failRoom = true;
      await show(tester);
      await start(tester);
      expect(ai.analyses, 1);
      expect(store.roomsFor(project.id).single.analysis, isNull);
      records.failRoom = false;
      await tap(tester, 'Retry saving analysis and choices');
      expect(ai.analyses, 1);
      expect(store.roomsFor(project.id).single.analysis, isNotNull);
      expect(ai.activity.stage, AiStage.completed);
    },
  );

  testWidgets('failed analysis is never automatically retried', (tester) async {
    ai.failAnalysis = true;
    await show(tester);
    await start(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(ai.analyses, 1);
    expect(ai.edits, 0);
    await tap(tester, 'Retry analysis');
    await tap(tester, 'Cancel');
    expect(ai.analyses, 1);
    ai.failAnalysis = false;
    await tap(tester, 'Retry analysis');
    await tap(tester, 'Start and analyse');
    expect(ai.analyses, 2);
    expect(feed.captures, 1);
  });

  testWidgets(
    'generated-result save failure blocks leaving and retries locally',
    (tester) async {
      await show(tester);
      await start(tester);
      ai.afterEdit = () => photos.fail = true;
      await generate(tester);
      expect(ai.edits, 1);
      expect(find.text('Retry saving result'), findsOneWidget);
      await Navigator.maybePop(tester.element(find.byType(LiveDesignScreen)));
      await tester.pumpAndSettle();
      expect(find.byType(LiveDesignScreen), findsOneWidget);
      photos.fail = false;
      await tap(tester, 'Retry saving result');
      expect(ai.edits, 1);
      expect(find.text('Design overlay'), findsOneWidget);
    },
  );

  testWidgets(
    'existing originals and approval survive automatic reference capture',
    (tester) async {
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Existing kitchen',
        originalImage: picture(5),
      );
      await store.updateRoom(room.copyWith(conceptCount: 3));
      final design = await store.createDesign(
        roomId: room.id,
        image: picture(9),
        title: 'Approved',
        prompt: 'Old brief',
      );
      await store.approveBaseline(room.id, designId: design.id);
      await show(tester, roomId: room.id);
      await start(tester);
      final current = store.roomById(room.id)!;
      expect(current.originalId, room.originalId);
      expect(current.primaryId, room.primaryId);
      expect(current.approvedDesignId, design.id);
      expect(current.photoIds, hasLength(2));
      expect(
        current.analysis!.sourceImageId,
        current.additionalPhotoIds.single,
      );
      await generate(tester);
      expect(ai.edits, 1);
      expect(store.roomById(room.id)!.conceptCount, 3);
    },
  );

  testWidgets(
    'backgrounding during preparation cancels automatic capture and does not restart AI on resume',
    (tester) async {
      await show(tester, settleDuration: const Duration(seconds: 2));
      await tap(tester, 'Start live design');
      await tester.tap(find.text('Start and analyse'));
      await tester.pump(const Duration(milliseconds: 20));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      expect(feed.captures, 0);
      expect(ai.analyses, 0);
      expect(ai.edits, 0);
      expect(store.roomsFor(project.id), isEmpty);
    },
  );

  testWidgets(
    'phone large-text controls remain usable while the camera stays visible',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await show(tester, scale: 1.5);
      await start(tester);
      expect(tester.takeException(), isNull);
      await generate(tester);
      expect(find.byKey(const ValueKey('live-camera-preview')), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(740, 340);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rotation during a pending generation retains the request and resets overlay on background',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 780);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await show(tester);
      await start(tester);
      ai.holdEdit = Completer<void>();
      await tap(tester, 'Generate preview');
      await tester.tap(find.text('Send to OpenAI'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      tester.view.physicalSize = const Size(850, 390);
      await tester.pump(const Duration(milliseconds: 300));
      expect(ai.edits, 1);
      expect(tester.takeException(), isNull);
      ai.holdEdit!.complete();
      await tester.pumpAndSettle();
      expect(
        store.designsFor(store.roomsFor(project.id).single.id),
        hasLength(1),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(feed.phase, RoomCameraPhase.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(ai.edits, 1);
      expect(ai.analyses, 1);
      expect(feed.phase, RoomCameraPhase.ready);
      final overlay = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Design overlay'),
      );
      expect(overlay.selected, isFalse);
    },
  );
}
