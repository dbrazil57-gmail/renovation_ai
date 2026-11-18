import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/camera_room_view.dart';
import 'package:renovision_ai/file_transfer.dart';
import 'package:renovision_ai/image_viewer.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/room_camera.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

final photo = Uint8List.fromList(
  img.encodePng(img.Image(width: 32, height: 24)),
);
const rear = CameraDescription(
  name: 'rear',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);
const front = CameraDescription(
  name: 'front',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 90,
);

class TestController extends CameraController {
  final Completer<void>? opening;
  bool closed = false;
  TestController(CameraDescription description, {this.opening})
    : super(description, ResolutionPreset.high, enableAudio: false);
  @override
  Future<void> initialize() async {
    await opening?.future;
    value = value.copyWith(
      isInitialized: true,
      previewSize: const Size(640, 480),
    );
  }

  @override
  Future<XFile> takePicture() async =>
      XFile.fromData(photo, mimeType: 'image/png');
  @override
  Future<void> dispose() async {
    closed = true;
    super.dispose();
  }
}

class FakeFeed extends RoomCameraFeed {
  int starts = 0, stops = 0, captures = 0;
  bool closed = false;
  Uint8List bytes = photo;
  RoomCameraPhase state = RoomCameraPhase.paused;
  @override
  RoomCameraPhase get phase => state;
  @override
  String? get error =>
      state == RoomCameraPhase.unavailable ? 'Camera access is blocked.' : null;
  @override
  Widget preview() =>
      const ColoredBox(key: ValueKey('fake-preview'), color: Colors.blue);
  @override
  Future<void> start() async {
    starts++;
    state = RoomCameraPhase.ready;
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

class FailPhotos extends MemoryBox {
  bool fail = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (fail) throw StateError('disk full');
    await super.put(key, value);
  }
}

class CameraProjectFile implements SaveDestination {
  Uint8List? bytes;
  @override
  Future<FileSaveResult> write(Uint8List value) async {
    bytes = value;
    return FileSaveResult.saved;
  }
}

void main() {
  test(
    'camera selects rear lens, captures a still and releases on stop',
    () async {
      late TestController controller;
      final feed = DeviceRoomCamera(
        cameras: () async => [front, rear],
        controllerFactory: (d) => controller = TestController(d),
      );
      await feed.start();
      expect(controller.description, rear);
      expect(controller.enableAudio, isFalse);
      expect(feed.phase, RoomCameraPhase.ready);
      expect(await feed.capture(), photo);
      await feed.stop();
      expect(controller.closed, isTrue);
      expect(feed.phase, RoomCameraPhase.paused);
      await expectLater(feed.capture(), throwsStateError);
      feed.dispose();
    },
  );

  test('stop during initialization cannot revive an obsolete camera', () async {
    final opening = Completer<void>();
    final constructed = Completer<TestController>();
    final feed = DeviceRoomCamera(
      cameras: () async => [rear],
      controllerFactory: (d) {
        final controller = TestController(d, opening: opening);
        constructed.complete(controller);
        return controller;
      },
    );
    final start = feed.start();
    final controller = await constructed.future;
    final stop = feed.stop();
    opening.complete();
    await Future.wait([start, stop]);
    expect(feed.phase, RoomCameraPhase.paused);
    expect(controller.closed, isTrue);
    feed.dispose();
  });

  test('dispose during initialization releases the camera without notifying disposed listeners', () async {
    final opening = Completer<void>();
    final constructed = Completer<TestController>();
    final feed = DeviceRoomCamera(
      cameras: () async => [rear],
      controllerFactory: (d) {
        final controller = TestController(d, opening: opening);
        constructed.complete(controller);
        return controller;
      },
    );
    final start = feed.start();
    final controller = await constructed.future;
    feed.dispose();
    opening.complete();
    await start;
    expect(controller.closed, isTrue);
  });

  test(
    'permission denial and missing camera are recoverable, with no capture',
    () async {
      var denied = true;
      final feed = DeviceRoomCamera(
        cameras: () async {
          if (denied) throw CameraException('CameraAccessDenied', 'private');
          return [];
        },
      );
      await feed.start();
      expect(feed.phase, RoomCameraPhase.unavailable);
      expect(feed.error, contains('access is blocked'));
      denied = false;
      await feed.start();
      expect(feed.error, contains('unavailable'));
      await expectLater(feed.capture(), throwsStateError);
      feed.dispose();
    },
  );

  test('capture validation rejects empty and oversized files', () {
    expect(() => validateRoomCapture(Uint8List(0)), throwsArgumentError);
    expect(
      () => validateRoomCapture(Uint8List(18 * 1024 * 1024 + 1)),
      throwsArgumentError,
    );
  });

  group('camera room workflow', () {
    late RenovisionStore store;
    late RenovationRoom room;
    late FailPhotos photos;
    late FakeFeed feed;
    setUp(() async {
      photos = FailPhotos();
      store = RenovisionStore(records: MemoryBox(), photos: photos);
      final project = await store.createProject('Camera test');
      room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: photo,
      );
      feed = FakeFeed();
    });
    tearDown(() => store.dispose());

    Future<void> show(
      WidgetTester tester, {
      Widget Function(String, ValueChanged<String?>)? workspace,
      String? initialDesignId,
      double textScale = 1,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: CameraRoomView(
            store: store,
            roomId: room.id,
            feed: feed,
            initialDesignId: initialDesignId,
            workspace:
                workspace ??
                (_, _) => const Scaffold(body: Text('Design workspace')),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tap(WidgetTester tester, String text) async {
      final target = find.text(text);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'capture saves a new view, preserves originals and approval, and survives project restore',
      (tester) async {
        await show(tester);
        await tap(tester, 'Capture new view');
        final saved = store.roomById(room.id)!;
        expect(saved.photoIds, hasLength(2));
        expect(saved.originalId, room.originalId);
        expect(saved.approvedDesignId, room.approvedDesignId);
        expect(store.imageFor(saved.photoIds.last), photo);
        expect(feed.captures, 1);
        expect(feed.stops, greaterThanOrEqualTo(1));
        expect(
          find.textContaining('Capture saved in this room'),
          findsOneWidget,
        );
        final restored = await store.restoreBackup(
          ProjectBackup.decode(store.backupFor(room.projectId).encode()),
        );
        expect(store.roomsFor(restored.id).single.photoIds, hasLength(2));
        expect(store.designsFor(room.id), isEmpty);
      },
    );

    testWidgets(
      'failed save retains capture, retries locally, and blocks accidental Back',
      (tester) async {
        await show(tester);
        photos.fail = true;
        await tap(tester, 'Capture new view');
        expect(store.roomById(room.id)!.photoIds, hasLength(1));
        expect(find.text('Unsaved capture'), findsOneWidget);
        final context = tester.element(find.byType(CameraRoomView));
        await Navigator.maybePop(context);
        await tester.pumpAndSettle();
        expect(find.text('Discard unsaved capture?'), findsOneWidget);
        await tap(tester, 'Keep capture');
        photos.fail = false;
        await tap(tester, 'Retry saving capture');
        expect(store.roomById(room.id)!.photoIds, hasLength(2));
        expect(feed.captures, 1);
        expect(find.text('Unsaved capture'), findsNothing);
      },
    );

    testWidgets(
      'capture -> design -> compare uses the exact saved source and never a second camera',
      (tester) async {
        String? capturedId;
        await show(
          tester,
          workspace: (id, select) {
            capturedId = id;
            return Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () async {
                    final design = await store.createDesign(
                      roomId: room.id,
                      image: photo,
                      title: 'New design',
                      prompt: 'Kitchen',
                      sourceImageId: id,
                      aiProvider: 'Test',
                    );
                    select(design.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save test design'),
                ),
              ),
            );
          },
        );
        await tap(tester, 'Capture new view');
        await tap(tester, 'Design saved view');
        expect(capturedId, store.roomById(room.id)!.photoIds.last);
        expect(feed.phase, RoomCameraPhase.paused);
        await tap(tester, 'Save test design');
        expect(find.text('Captured before / design after'), findsOneWidget);
        expect(find.byType(Slider), findsOneWidget);
        await tap(tester, 'Live view');
        expect(feed.starts, 2);
        expect(find.text('Show design'), findsNothing);
        await tap(tester, 'Enable manual overlay');
        expect(find.text('Align original'), findsOneWidget);
        await tap(tester, 'Show design');
        expect(find.textContaining('Manual overlay ·'), findsOneWidget);
        await tester.drag(find.byType(Slider), const Offset(30, 0));
        await tester.pumpAndSettle();
        expect(feed.captures, 1);
        expect(store.designsFor(room.id), hasLength(1));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pumpAndSettle();
        expect(feed.phase, RoomCameraPhase.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(feed.phase, RoomCameraPhase.ready);
        expect(find.text('Show design'), findsNothing);
      },
    );

    testWidgets(
      'six photos prevent further capture and leave saved views usable',
      (tester) async {
        await store.addRoomPhotos(room.id, [photo, photo, photo, photo, photo]);
        await show(tester);
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Capture new view'),
        );
        expect(button.onPressed, isNull);
        expect(feed.captures, 0);
        await tap(tester, 'Compare');
        expect(find.text('Saved room photo'), findsOneWidget);
      },
    );

    testWidgets(
      'Back flushes captures into the linked project file even with autosave off',
      (tester) async {
        final file = CameraProjectFile();
        await store.setAutosaveEnabled(false);
        store.documents.attach(room.projectId, file, alreadySaved: true);
        await show(tester);
        await tap(tester, 'Capture new view');
        expect(store.documents.hasPending(room.projectId), isTrue);
        await Navigator.maybePop(tester.element(find.byType(CameraRoomView)));
        await tester.pumpAndSettle();
        expect(store.documents.hasPending(room.projectId), isFalse);
        expect(
          ProjectBackup.decode(file.bytes!).rooms.single.additionalPhotoIds,
          hasLength(1),
        );
        expect(feed.captures, 1);
      },
    );

    testWidgets(
      'designing a camera photo starts from that capture rather than the approved baseline',
      (tester) async {
        final capture = Uint8List.fromList(
          img.encodePng(img.Image(width: 28, height: 21)),
        );
        final id = (await store.addRoomPhotos(room.id, [capture])).single;
        final baseline = await store.createDesign(
          roomId: room.id,
          image: photo,
          title: 'Approved',
          prompt: '',
          sourceImageId: room.originalId,
          aiProvider: 'Test',
        );
        await store.approveBaseline(room.id, designId: baseline.id);
        await tester.pumpWidget(
          MaterialApp(
            home: WorkspaceScreen(
              store: store,
              roomId: room.id,
              initialPhotoId: id,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<ExpandableImage>(find.byType(ExpandableImage)).bytes,
          capture,
        );
        expect(store.roomById(room.id)!.approvedDesignId, baseline.id);
        expect(find.text('Room photo · View 2'), findsWidgets);
      },
    );

    testWidgets(
      'camera UI fits narrow phones, landscape and large text without overflow',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        tester.view.physicalSize = const Size(320, 568);
        await show(tester, textScale: 1.7);
        expect(tester.takeException(), isNull);
        tester.view.physicalSize = const Size(740, 340);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    test('lineage resolves refinements and ignores other views, deleted results, and cycles', () async {
      final second = (await store.addRoomPhotos(room.id, [photo])).single;
      final a = await store.createDesign(
        roomId: room.id,
        image: photo,
        title: 'A',
        prompt: '',
        sourceImageId: room.originalId,
        aiProvider: 'Test',
      );
      final b = await store.createDesign(
        roomId: room.id,
        image: photo,
        title: 'B',
        prompt: '',
        sourceImageId: a.imageId,
        parentId: a.id,
        aiProvider: 'Test',
      );
      final c = await store.createDesign(
        roomId: room.id,
        image: photo,
        title: 'C',
        prompt: '',
        sourceImageId: second,
        aiProvider: 'Test',
      );
      await store.createDesign(
        roomId: room.id,
        image: photo,
        title: 'Unrecorded import',
        prompt: '',
      );
      final versions = store.designsFor(room.id);
      expect(
        cameraDesignsForPhoto(
          store.roomById(room.id)!,
          versions,
          room.originalId,
        ).map((d) => d.id).toSet(),
        {a.id, b.id},
      );
      expect(
        roomPhotoForDesign(store.roomById(room.id)!, versions, c.id),
        second,
      );
      final reference = await store.createDesign(
        roomId: room.id,
        image: photo,
        title: 'Reference',
        prompt: '',
        sourceImageId: room.originalId,
      );
      final croppedResult = await store.createDesign(
        roomId: room.id,
        image: photo,
        title: 'Cropped result',
        prompt: '',
        sourceImageId: reference.imageId,
        parentId: reference.id,
        aiProvider: 'Test',
      );
      expect(
        roomPhotoForDesign(
          store.roomById(room.id)!,
          store.designsFor(room.id),
          croppedResult.id,
        ),
        isNull,
      );
      final cycle = DesignVersion(
        id: 'cycle',
        roomId: room.id,
        imageId: 'image-cycle',
        title: '',
        prompt: '',
        parentId: 'cycle',
        aiProvider: 'Test',
        favourite: false,
        rejected: false,
        created: DateTime(2026),
      );
      expect(roomPhotoForDesign(room, [cycle], cycle.id), isNull);
      expect(
        cameraDesignsForPhoto(room, [
          a.copyWith(deleted: true),
        ], room.originalId),
        isEmpty,
      );
    });
  });

  testWidgets(
    'standalone capture can retake then return bytes; it releases resources on exit',
    (tester) async {
      final feed = FakeFeed();
      Uint8List? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                captured = await Navigator.push<Uint8List>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomCaptureScreen(feed: feed),
                  ),
                );
              },
              child: const Text('Open camera'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open camera'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Capture photo'));
      await tester.pumpAndSettle();
      expect(captured, isNull);
      await tester.tap(find.text('Retake'));
      await tester.pumpAndSettle();
      expect(feed.starts, 2);
      await tester.tap(find.text('Capture photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use photo'));
      await tester.pumpAndSettle();
      expect(captured, photo);
      expect(feed.closed, isTrue);
    },
  );
}
