import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/image_viewer.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void main() {
  final bytes = img.encodePng(img.Image(width: 800, height: 450));
  TransformationController controller(WidgetTester tester) => tester
      .widget<InteractiveViewer>(
        find.byKey(const ValueKey('full-screen-image')),
      )
      .transformationController!;

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpandableImage(bytes: bytes, title: 'Kitchen concept'),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Open image full screen'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'preview opens full-resolution image and closes without changing bytes',
    (tester) async {
      final original = Uint8List.fromList(bytes);
      await show(tester);
      expect(find.byType(ImageViewerScreen), findsOneWidget);
      final displayed = tester.widget<Image>(
        find.descendant(
          of: find.byType(ImageViewerScreen),
          matching: find.byType(Image),
        ),
      );
      expect(displayed.image, isA<MemoryImage>());
      expect((displayed.image as MemoryImage).bytes, same(bytes));
      expect(controller(tester).value.getMaxScaleOnAxis(), 1);
      await tester.tap(find.byTooltip('Close image viewer'));
      await tester.pumpAndSettle();
      expect(find.byType(ImageViewerScreen), findsNothing);
      expect(find.byType(ExpandableImage), findsOneWidget);
      expect(bytes, original);
    },
  );

  testWidgets(
    'zoom controls and double tap zoom around image and reset to fit',
    (tester) async {
      await show(tester);
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      expect(controller(tester).value.getMaxScaleOnAxis(), closeTo(1.5, .001));
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pump();
      expect(controller(tester).value.getMaxScaleOnAxis(), 1);
      final target = find.byKey(const ValueKey('full-screen-image'));
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 70));
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(controller(tester).value.getMaxScaleOnAxis(), closeTo(2.5, .001));
      await tester.tap(find.byTooltip('Fit image'));
      await tester.pump();
      expect(controller(tester).value, Matrix4.identity());
    },
  );

  testWidgets('two-finger pinch and drag work in full screen', (tester) async {
    await show(tester);
    final center = tester.getCenter(
      find.byKey(const ValueKey('full-screen-image')),
    );
    final left = await tester.startGesture(
      center - const Offset(30, 0),
      pointer: 1,
    );
    final right = await tester.startGesture(
      center + const Offset(30, 0),
      pointer: 2,
    );
    await tester.pump();
    await left.moveTo(center - const Offset(80, 0));
    await right.moveTo(center + const Offset(80, 0));
    await tester.pump();
    await left.up();
    await right.up();
    await tester.pumpAndSettle();
    expect(controller(tester).value.getMaxScaleOnAxis(), greaterThan(1));
    final before = controller(tester).value.storage[12];
    await tester.drag(
      find.byKey(const ValueKey('full-screen-image')),
      const Offset(50, 0),
    );
    await tester.pumpAndSettle();
    expect(controller(tester).value.storage[12], isNot(before));
  });

  testWidgets(
    'portrait and landscape resize the viewer and refit a zoomed photo',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await show(tester);
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pump();
      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpAndSettle();
      final area = tester.getSize(
        find.byKey(const ValueKey('full-screen-image')),
      );
      expect(area.width, 844);
      expect(area.height, lessThan(390));
      expect(controller(tester).value, Matrix4.identity());
      expect(find.textContaining('Pinch to zoom'), findsNothing);
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(find.textContaining('Pinch to zoom'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'saved version thumbnail opens without changing the approved baseline or history',
    (tester) async {
      final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
      addTearDown(store.dispose);
      final project = await store.createProject('Viewer test');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: bytes,
      );
      final design = await store.createDesign(
        roomId: room.id,
        image: bytes,
        title: 'Saved kitchen design',
        prompt: 'Keep layout',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      final thumbnail = find.byWidgetPredicate(
        (w) => w is PhotoThumb && w.viewerTitle == design.title,
      );
      await tester.scrollUntilVisible(
        thumbnail,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(thumbnail);
      await tester.pumpAndSettle();
      expect(find.byType(ImageViewerScreen), findsOneWidget);
      expect(find.text(design.title), findsOneWidget);
      await tester.tap(find.byTooltip('Close image viewer'));
      await tester.pumpAndSettle();
      expect(store.roomById(room.id)!.approvedDesignId, isNull);
      expect(store.designsFor(room.id), hasLength(1));
      expect(store.imageFor(room.originalId), bytes);
      expect(store.imageFor(design.imageId), bytes);
    },
  );
}
