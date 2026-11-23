import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/design_recipe.dart';
import 'package:renovision_ai/local_paint.dart';
import 'package:renovision_ai/local_paint_screen.dart';
import 'package:renovision_ai/project_look_widgets.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/room_prompt.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';
import 'package:renovision_ai/wall_selection.dart';

import 'support/focus_navigation.dart';
import 'support/memory_box.dart';

Future<void> ready(WidgetTester tester, bool Function() predicate) async {
  for (var i = 0; i < 150 && !predicate(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 12)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(predicate(), true);
}

Future<void> settlePaint(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await ready(
    tester,
    () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
  );
  await tester.pumpAndSettle();
}

void main() {
  final photo = img.encodePng(
    img.Image(width: 100, height: 70)..clear(img.ColorRgb8(180, 170, 150)),
  );
  test('directional growth extends right and down without shifting or widening other edges', () {
    final bytes = Uint8List(7);
    final index = 3 * 7 + 3;
    bytes[index >> 3] |= 1 << (index & 7);
    final original = PaintRegion(width: 7, height: 7, bits: bytes);
    final grown = extendWallSelectionEdge(
      original,
      left: 0,
      top: 0,
      right: 2,
      bottom: 1,
    );
    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        expect(grown.contains(x, y), x >= 3 && x <= 5 && y >= 3 && y <= 4);
        expect(original.contains(x, y), x == 3 && y == 3);
      }
    }
  });

  test('approved project look reuses only style/palette, not facts, instructions or geometry, without AI', () async {
    var requests = 0;
    final store = RenovisionStore(
      records: MemoryBox(),
      photos: MemoryBox(),
      ai: AiService(
        clientFactory: () {
          requests++;
          throw StateError('No paid request');
        },
      ),
    );
    addTearDown(store.dispose);
    final project = await store.createProject('Home');
    final source = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: photo,
    );
    final target = await store.createRoom(
      projectId: project.id,
      name: 'Bedroom',
      originalImage: photo,
    );
    final approved = await store.createDesign(
      roomId: source.id,
      image: photo,
      title: 'Approved',
      prompt: 'Kitchen has one large window; remove the oven',
      recipe: DesignRecipe({
        'designStyleIds': ['modern'],
        'colourPaletteId': 'sage_oak',
        'instructions': 'Remove the oven',
        'protectedFeatures': 'Kitchen window',
      }),
    );
    await store.approveBaseline(source.id, designId: approved.id);
    await store.updateRoom(
      target.copyWith(
        instructions: 'Keep the bed',
        protectedFeatures: 'Bedroom door',
      ),
    );
    final draft = RoomDraft(store, store.roomById(target.id)!);
    addTearDown(draft.dispose);
    final look = savedProjectLooks(store, target.id).single;
    expect(look.approved, true);
    expect(await applyProjectLook(store, draft, look), true);
    final saved = store.roomById(target.id)!;
    expect(saved.colourPaletteId, 'sage_oak');
    expect(saved.designStyleIds, ['modern']);
    expect(saved.instructions, 'Keep the bed');
    expect(saved.protectedFeatures, 'Bedroom door');
    expect(saved.analysis, isNull);
    expect(saved.originalId, target.originalId);
    expect(
      roomTemplatePrompt(saved, draft),
      isNot(contains('Remove the oven')),
    );
    expect(store.imageFor(saved.originalId), orderedEquals(photo));
    expect(requests, 0);
  });

  testWidgets(
    'selected result starts a focused update and hides the original broad brief; new design remains explicit',
    (tester) async {
      final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
      addTearDown(store.dispose);
      final project = await store.createProject('Home');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: photo,
      );
      await store.updateRoom(
        room.copyWith(instructions: 'Replace every cupboard and light'),
      );
      final design = await store.createDesign(
        roomId: room.id,
        image: photo,
        title: 'Chosen',
        prompt: 'Original broad brief',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(
            store: store,
            roomId: room.id,
            initialDesignId: design.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('selected-design-update')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextField, 'What should change?'),
        findsNothing,
      );
      expect(find.textContaining('Precision: apply only'), findsOneWidget);
      await tester.tap(find.text('New design'));
      await tester.pumpAndSettle();
      final original = find.widgetWithText(TextField, 'What should change?');
      await ensureFocusVisible(tester, original);
      expect(
        tester.widget<TextField>(original).controller!.text,
        'Replace every cupboard and light',
      );
      expect(
        find.byKey(const ValueKey('selected-design-update')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tile controls stay open after slider changes; four corners replace patchy selection with a full tiled plane',
    (tester) async {
      final initial = LocalPaintRecipe(
        width: 100,
        height: 70,
        surfaces: [
          PaintSurface(
            name: 'Splashback 1',
            kind: LocalSurfaceKind.splashback,
            finish: LocalFinish.brickTiles,
            marks: [
              PaintMark(PaintMarkKind.polygon, const [
                PaintPoint(.1, .1),
                PaintPoint(.3, .1),
                PaintPoint(.3, .4),
                PaintPoint(.1, .4),
              ]),
            ],
          ),
        ],
      );
      LocalPaintRecipe? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: LocalPaintScreen(
            source: photo,
            before: photo,
            initial: initial,
            saveDraft: (value) async {
              saved = value;
            },
            saveVersion: (_, _) async {},
          ),
        ),
      );
      await ready(tester, () => find.text('2 Finish').evaluate().isNotEmpty);
      await tester.tap(find.text('2 Finish'));
      await settlePaint(tester);
      await tester.ensureVisible(find.text('Tile layout & grout'));
      await tester.tap(find.text('Tile layout & grout'));
      await tester.pumpAndSettle();
      final size = find.byKey(const ValueKey('tile-size-slider'));
      await tester.ensureVisible(size);
      await tester.pumpAndSettle();
      tester.widget<Slider>(size).onChanged!(.18);
      await ready(tester, () => saved?.surfaces.single.tileSize == .18);
      expect(size, findsOneWidget);
      tester.widget<Slider>(size).onChanged!(.22);
      await ready(tester, () => saved?.surfaces.single.tileSize == .22);
      await settlePaint(tester);
      final outline = find.text('Outline full splashback');
      if (outline.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          outline,
          150,
          scrollable: find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .first,
        );
      }
      await tester.ensureVisible(outline);
      await tester.pumpAndSettle();
      await tester.tap(outline);
      await settlePaint(tester);
      final bounds = tester.getRect(find.byKey(const ValueKey('paint-canvas')));
      for (final p in const [
        Offset(.1, .1),
        Offset(.9, .1),
        Offset(.9, .9),
        Offset(.1, .9),
      ]) {
        await tester.tapAt(
          bounds.topLeft + Offset(p.dx * bounds.width, p.dy * bounds.height),
        );
        await tester.pump();
      }
      await ready(tester, () => saved?.surfaces.single.fitTilePlane == true);
      expect(saved!.surfaces.single.marks.single.points, hasLength(4));
      expect(saved!.surfaces.single.tileSize, .22);
      expect(
        renderLocalPaint(PaintRenderInput(photo, saved!)).changedPixels,
        greaterThan(
          renderLocalPaint(PaintRenderInput(photo, initial)).changedPixels,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
