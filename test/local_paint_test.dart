import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/design_recipe_widgets.dart';
import 'package:renovision_ai/design_styles.dart';
import 'package:renovision_ai/local_paint.dart';
import 'package:renovision_ai/local_paint_screen.dart';
import 'package:renovision_ai/main.dart' show buildRenovisionTheme;
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/protected_backup.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void main() {
  final image = img.Image(width: 80, height: 60, numChannels: 4);
  for (final pixel in image) {
    pixel
      ..r = 80 + pixel.x
      ..g = 90 + pixel.x
      ..b = 100 + pixel.x
      ..a = 220;
  }
  final original = img.encodePng(image);
  PaintMark outline() => PaintMark(PaintMarkKind.polygon, const [
    PaintPoint(.2, .2),
    PaintPoint(.8, .2),
    PaintPoint(.8, .8),
    PaintPoint(.2, .8),
  ]);
  LocalPaintRecipe recipe({List<PaintMark>? marks, double coverage = 1}) =>
      LocalPaintRecipe(
        width: 80,
        height: 60,
        surfaces: [
          PaintSurface(
            name: 'Back wall',
            rgb: 0x507040,
            coverage: coverage,
            marks: marks ?? [outline()],
          ),
        ],
      );
  void samePixel(img.Image a, img.Image b, int x, int y) {
    final p = a.getPixel(x, y), q = b.getPixel(x, y);
    expect(
      [q.r, q.g, q.b, q.a],
      [p.r, p.g, p.b, p.a],
      reason: 'Pixel $x,$y must stay unchanged',
    );
  }

  test('local paint preserves every pixel outside the mask and alpha, with visible shading', () {
    final result = renderLocalPaint(PaintRenderInput(original, recipe()));
    final painted = img.decodePng(result.bytes)!;
    expect(result.changedPixels, greaterThan(0));
    expect([painted.width, painted.height], [80, 60]);
    for (var y = 0; y < 60; y++) {
      for (var x = 0; x < 80; x++) {
        if (x < 16 || x > 63 || y < 12 || y > 47) {
          samePixel(image, painted, x, y);
        }
      }
    }
    expect(painted.getPixel(30, 30).g, greaterThan(painted.getPixel(30, 30).r));
    expect(painted.getPixel(20, 30).g, lessThan(painted.getPixel(55, 30).g));
    expect(painted.getPixel(30, 30).a, 220);
    expect(original, orderedEquals(img.encodePng(image)));
  });

  test('eraser exclusions and zero coverage preserve the selected source', () {
    final painted = img.decodePng(
      renderLocalPaint(
        PaintRenderInput(
          original,
          recipe(
            marks: [
              outline(),
              PaintMark(PaintMarkKind.erase, const [
                PaintPoint(.5, .5),
              ], width: .15),
            ],
          ),
        ),
      ).bytes,
    )!;
    samePixel(image, painted, 40, 30);
    expect(painted.getPixel(20, 20).g, isNot(image.getPixel(20, 20).g));
    final empty = renderLocalPaint(
      PaintRenderInput(original, recipe(coverage: 0)),
    );
    expect(empty.changedPixels, 0);
    final decoded = img.decodePng(empty.bytes)!;
    for (var y = 0; y < 60; y++) {
      for (var x = 0; x < 80; x++) {
        samePixel(image, decoded, x, y);
      }
    }
  });

  LocalPaintRecipe tiled({
    LocalFinish finish = LocalFinish.rectangleTiles,
    double angle = 0,
    int rgb = 0x507040,
  }) => LocalPaintRecipe(
    width: 80,
    height: 60,
    surfaces: [
      PaintSurface(
        name: 'Floor 1',
        kind: LocalSurfaceKind.floor,
        finish: finish,
        rgb: rgb,
        groutRgb: 0xF0F0EC,
        coverage: 1,
        tileSize: .2,
        tileAngle: angle,
        marks: [outline()],
      ),
    ],
  );

  test('tile previews show grout, reuse masks and preserve every outside pixel and alpha', () {
    final result = renderLocalPaint(PaintRenderInput(original, tiled()));
    final tiles = img.decodePng(result.bytes)!;
    expect(result.changedPixels, greaterThan(100));
    // The grid origin is at the image centre; this is a grout crossing.
    final grout = tiles.getPixel(40, 30), tile = tiles.getPixel(44, 32);
    expect((grout.r - grout.g).abs(), lessThan(10));
    expect(tile.g, greaterThan(tile.r));
    for (var y = 0; y < 60; y++) {
      for (var x = 0; x < 80; x++) {
        expect(tiles.getPixel(x, y).a, image.getPixel(x, y).a);
        if (x < 16 || x > 63 || y < 12 || y > 47) samePixel(image, tiles, x, y);
      }
    }
    final rotated = renderLocalPaint(
      PaintRenderInput(original, tiled(angle: 35)),
    );
    final brick = renderLocalPaint(
      PaintRenderInput(original, tiled(finish: LocalFinish.brickTiles)),
    );
    final recoloured = renderLocalPaint(
      PaintRenderInput(original, tiled(rgb: 0xA06030)),
    );
    expect(rotated.bytes, isNot(orderedEquals(result.bytes)));
    expect(brick.bytes, isNot(orderedEquals(result.bytes)));
    expect(recoloured.bytes, isNot(orderedEquals(result.bytes)));
    expect(
      tiled(rgb: 0xA06030).surfaces.single.marks.single.toMap(),
      outline().toMap(),
    );
    expect(original, orderedEquals(img.encodePng(image)));
  });

  test('tile recipes retain finish settings while legacy paint maps stay unchanged and invalid imports fail', () {
    final settings = tiled(angle: 35).toMap();
    expect(LocalPaintRecipe.fromMap(settings).toMap(), settings);
    final legacy = recipe().surfaces.single.toMap();
    expect(legacy.keys.toSet(), {'name', 'rgb', 'coverage', 'marks'});
    expect(
      LocalPaintRecipe.fromMap(recipe().toMap()).surfaces.single.finish,
      LocalFinish.paint,
    );
    for (final entry in <String, dynamic>{
      'surfaceKind': 'unknown',
      'finish': 'unknown',
      'tileSize': 0,
      'tileAngle': double.infinity,
      'groutRgb': -1,
    }.entries) {
      final bad = tiled().toMap();
      (bad['surfaces'] as List).single[entry.key] = entry.value;
      expect(() => LocalPaintRecipe.fromMap(bad), throwsFormatException);
    }
    final polish = paintRefinementPrompt(tiled());
    expect(polish, contains('Floor 1 (Floor)'));
    expect(polish, contains('grout #F0F0EC'));
    expect(polish, contains('tile perspective'));
    expect(polish, contains('not measured installation dimensions'));
    expect(polish, contains('Do not redesign the approved concept'));
  });

  test('tile layers and drafts round trip through project and protected backups without changing originals', () async {
    final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    addTearDown(store.dispose);
    final project = await store.createProject('Tile test');
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Bathroom',
      originalImage: original,
    );
    final settings = tiled(angle: 35);
    await store.savePaintDraft(room.id, room.originalId, settings);
    await store.createDesign(
      roomId: room.id,
      image: renderLocalPaint(PaintRenderInput(original, settings)).bytes,
      title: 'Local finishes',
      prompt: 'No AI request',
      sourceImageId: room.originalId,
      paintRecipe: settings,
    );
    final protected = await protectBackup(
      store.backupFor(project.id).encode(),
      'tile-fixture-password',
    );
    final decoded = ProjectBackup.decode(
      await unlockBackup(protected, 'tile-fixture-password'),
    );
    final copy = await store.restoreBackup(decoded);
    final restored = store.roomsFor(copy.id).single;
    expect(
      restored.paintDrafts[restored.originalId]!.toMap(),
      settings.toMap(),
    );
    final version = store.designsFor(restored.id).single;
    expect(version.paintRecipe!.toMap(), settings.toMap());
    expect(version.sourceImageId, restored.originalId);
    expect(restored.originalId, isNot(room.originalId));
    expect(restored.approvedDesignId, isNull);
    expect(store.imageFor(restored.originalId), original);
    expect(store.imageFor(room.originalId), original);
  });

  test('indexed PNG colours cannot leak outside a painted selection', () {
    final indexed = img.Image(
      width: 80,
      height: 60,
      withPalette: true,
      numChannels: 3,
    );
    indexed.palette!.setRgb(0, 140, 140, 140);
    final bytes = img.encodePng(indexed);
    final painted = img.decodePng(
      renderLocalPaint(PaintRenderInput(bytes, recipe())).bytes,
    )!;
    samePixel(img.decodePng(bytes)!, painted, 0, 0);
    expect(painted.getPixel(40, 30).g, isNot(140));
  });

  test(
    'paint settings are immutable, bounded and never retain connection fields',
    () {
      final current = recipe();
      final map = current.toMap();
      (map['surfaces'] as List).first['rgb'] = 0;
      expect(current.surfaces.single.rgb, 0x507040);
      expect(() => current.surfaces.clear(), throwsUnsupportedError);
      expect(
        () => current.surfaces.single.marks.clear(),
        throwsUnsupportedError,
      );
      final withUnknown = current.toMap()
        ..['apiKey'] = 'private-connection-marker';
      expect(
        jsonEncode(LocalPaintRecipe.fromMap(withUnknown).toMap()),
        isNot(contains('private-connection')),
      );
      for (final invalid in [
        current.toMap()..['width'] = -1,
        current.toMap()
          ..['surfaces'] = List.generate(
            9,
            (_) => PaintSurface(name: 'Wall').toMap(),
          ),
        current.toMap()
          ..['surfaces'] = [
            PaintSurface(name: 'x', coverage: double.nan).toMap(),
          ],
      ]) {
        expect(() => LocalPaintRecipe.fromMap(invalid), throwsFormatException);
      }
      expect(
        () => renderLocalPaint(
          PaintRenderInput(original, LocalPaintRecipe.empty(90, 60)),
        ),
        throwsFormatException,
      );
    },
  );

  test('legacy records, local provenance, drafts and copied project IDs remain compatible', () async {
    final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    addTearDown(store.dispose);
    final project = await store.createProject('Paint tests');
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: original,
    );
    await store.savePaintDraft(room.id, room.originalId, recipe());
    final result = renderLocalPaint(PaintRenderInput(original, recipe()));
    final version = await store.createDesign(
      roomId: room.id,
      image: result.bytes,
      title: 'Local paint',
      prompt: 'Local paint; no AI request',
      sourceImageId: room.originalId,
      paintRecipe: recipe(),
    );
    expect(version.aiModel, isNull);
    expect(version.providerRequestId, isNull);
    final backup = ProjectBackup.decode(store.backupFor(project.id).encode());
    expect(
      backup.rooms.single.paintDrafts[room.originalId]!.toMap(),
      recipe().toMap(),
    );
    expect(backup.designs.single.paintRecipe!.toMap(), recipe().toMap());
    final copy = await store.restoreBackup(backup);
    final copiedRoom = store.roomsFor(copy.id).single;
    final copiedVersion = store.designsFor(copiedRoom.id).single;
    expect(copiedRoom.originalId, isNot(room.originalId));
    expect(copiedRoom.paintDrafts.keys, [copiedRoom.originalId]);
    expect(copiedVersion.sourceImageId, copiedRoom.originalId);
    expect(copiedVersion.paintRecipe!.toMap(), recipe().toMap());
    final protected = await protectBackup(
      store.backupFor(copy.id).encode(),
      'paint-fixture-password',
    );
    final unlocked = ProjectBackup.decode(
      await unlockBackup(protected, 'paint-fixture-password'),
    );
    expect(unlocked.designs.single.paintRecipe!.toMap(), recipe().toMap());
    expect(unlocked.rooms.single.paintDrafts.keys, [copiedRoom.originalId]);
    final foreign = await store.createRoom(
      projectId: project.id,
      name: 'Other',
      originalImage: original,
    );
    await expectLater(
      store.savePaintDraft(room.id, foreign.originalId, recipe()),
      throwsFormatException,
    );
    await expectLater(
      store.createDesign(
        roomId: room.id,
        image: original,
        title: 'Bad',
        prompt: '',
        sourceImageId: room.originalId,
        paintRecipe: recipe(),
        aiModel: 'fake-ai',
      ),
      throwsFormatException,
    );
    expect(store.imageFor(room.originalId), orderedEquals(original));
  });

  Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
    for (var attempt = 0; attempt < 160 && !ready(); attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(ready(), isTrue);
  }

  Future<void> drawWall(WidgetTester tester) async {
    await waitFor(
      tester,
      () => find.byKey(const ValueKey('paint-canvas')).evaluate().isNotEmpty,
    );
    await tester.tap(find.byTooltip('Surface outline'));
    await tester.pump();
    final bounds = tester.getRect(find.byKey(const ValueKey('paint-canvas')));
    for (final p in const [
      Offset(.2, .2),
      Offset(.8, .2),
      Offset(.8, .8),
      Offset(.2, .8),
    ]) {
      await tester.tapAt(
        bounds.topLeft + Offset(bounds.width * p.dx, bounds.height * p.dy),
      );
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 600));
    await waitFor(
      tester,
      () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
    );
  }

  testWidgets(
    'paint version saves from the chosen design with no AI request or baseline change',
    (tester) async {
      var requests = 0;
      final store = RenovisionStore(
        records: MemoryBox(),
        photos: MemoryBox(),
        ai: AiService(
          clientFactory: () {
            requests++;
            throw StateError('Local paint must stay offline');
          },
        ),
      );
      addTearDown(store.dispose);
      final project = await store.createProject('Local test');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: original,
      );
      final source = await store.createDesign(
        roomId: room.id,
        image: original,
        title: 'Chosen design',
        prompt: 'Kept prompt',
        aiProvider: 'OpenAI',
        aiModel: 'fixture-model',
        sourceImageId: room.originalId,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(
            store: store,
            roomId: room.id,
            initialDesignId: source.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Colours & tiles without AI'));
      await tester.pump();
      await drawWall(tester);
      await tester.tap(find.byTooltip('Save finish version'));
      await tester.pump();
      await waitFor(tester, () => store.designsFor(room.id).length == 2);
      await tester.pumpAndSettle();
      final painted = store
          .designsFor(room.id)
          .firstWhere((design) => design.paintRecipe != null);
      expect(painted.parentId, source.id);
      expect(painted.sourceImageId, source.imageId);
      expect(painted.aiModel, isNull);
      expect(painted.providerRequestId, isNull);
      expect(store.roomById(room.id)!.approvedDesignId, isNull);
      expect(store.imageFor(room.originalId), orderedEquals(original));
      expect(store.imageFor(source.imageId), orderedEquals(original));
      expect(requests, 0);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDesignRecipe(context, painted),
                child: const Text('View settings'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('View settings'));
      await tester.pumpAndSettle();
      expect(find.text('Local paint · no AI request'), findsOneWidget);
      expect(find.textContaining('older version'), findsNothing);
    },
  );

  testWidgets(
    'Finish with AI saves a local preview and prepares a correction without making a provider call',
    (tester) async {
      var requests = 0;
      final store = RenovisionStore(
        records: MemoryBox(),
        photos: MemoryBox(),
        ai: AiService(
          clientFactory: () {
            requests++;
            throw StateError('AI must wait for confirmed generation');
          },
        ),
      );
      addTearDown(store.dispose);
      final project = await store.createProject('Paint test');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Bedroom',
        originalImage: original,
      );
      await store.updateRoom(
        room.copyWith(
          correctionInstructions: 'Keep the wall art.',
          precisionConceptCount: 3,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Colours & tiles without AI'));
      await tester.pump();
      await drawWall(tester);
      await tester.tap(find.text('2 Finish'));
      await tester.pump();
      await tester.ensureVisible(find.text('Finish with AI'));
      await tester.pump();
      await tester.tap(find.text('Finish with AI'));
      await tester.pump();
      await waitFor(
        tester,
        () =>
            store.designsFor(room.id).isNotEmpty &&
            store.roomById(room.id)!.preciseEdit,
      );
      await tester.pumpAndSettle();
      final painted = store.designsFor(room.id).single;
      final current = store.roomById(room.id)!;
      expect(painted.paintRecipe, isNotNull);
      expect(painted.aiModel, isNull);
      expect(current.correctionInstructions, startsWith('Keep the wall art.'));
      expect(current.correctionInstructions, contains('#D7C7AC'));
      expect(
        current.correctionInstructions,
        contains('rough local paint preview'),
      );
      expect(current.useAiPrompt, isFalse);
      expect(current.precisionConceptCount, 1);
      expect(find.byKey(const ValueKey('instructions-true')), findsOneWidget);
      expect(store.imageFor(room.originalId), original);
      expect(requests, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tile controls reuse a saved selection and prepare a single final AI polish without a request',
    (tester) async {
      Future<void> settlePreview() async {
        await tester.pump(const Duration(milliseconds: 600));
        await waitFor(
          tester,
          () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
        );
        await tester.pumpAndSettle();
      }

      var requests = 0;
      final store = RenovisionStore(
        records: MemoryBox(),
        photos: MemoryBox(),
        ai: AiService(
          clientFactory: () {
            requests++;
            throw StateError('No paid calls');
          },
        ),
      );
      addTearDown(store.dispose);
      final project = await store.createProject('Tile control test');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Bathroom',
        originalImage: original,
      );
      await store.savePaintDraft(room.id, room.originalId, tiled());
      await store.updateRoom(
        store.roomById(room.id)!.copyWith(precisionConceptCount: 3),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Colours & tiles without AI'));
      await tester.pump();
      await waitFor(tester, () => find.text('2 Finish').evaluate().isNotEmpty);
      await settlePreview();
      await tester.tap(find.text('2 Finish'));
      await tester.pumpAndSettle();
      expect(find.text('Bathroom wall tiles'), findsOneWidget);
      expect(find.text('Shower wall tiles'), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<LocalFinish>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Square tiles').last);
      await settlePreview();
      await tester.ensureVisible(find.text('Tile layout & grout'));
      await tester.tap(find.text('Tile layout & grout'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Dark grout'));
      await tester.tap(find.text('Dark grout'));
      await settlePreview();
      final finish = find.text('Finish with AI');
      await tester.scrollUntilVisible(
        finish,
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(finish);
      await tester.pump();
      await waitFor(tester, () => store.designsFor(room.id).isNotEmpty);
      await tester.pumpAndSettle();
      final version = store.designsFor(room.id).single;
      final saved = version.paintRecipe!.surfaces.single;
      expect(saved.finish, LocalFinish.squareTiles);
      expect(saved.groutRgb, 0x555550);
      expect(saved.kind, LocalSurfaceKind.floor);
      expect(saved.marks.single.toMap(), outline().toMap());
      final current = store.roomById(room.id)!;
      expect(current.preciseEdit, true);
      expect(current.precisionConceptCount, 1);
      expect(current.correctionInstructions, contains('grout #555550'));
      expect(current.correctionInstructions, contains('tile perspective'));
      expect(version.sourceImageId, room.originalId);
      expect(version.aiModel, isNull);
      expect(store.imageFor(room.originalId), original);
      expect(requests, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final (type, shortcut, expectedKind, expectedFinish, expectedName) in [
    (
      'kitchen',
      'Splashback tiles',
      LocalSurfaceKind.splashback,
      LocalFinish.brickTiles,
      'Splashback 1',
    ),
    (
      'bathroom',
      'Shower wall tiles',
      LocalSurfaceKind.wall,
      LocalFinish.rectangleTiles,
      'Shower wall 1',
    ),
    (
      'ensuite',
      'Bathroom wall tiles',
      LocalSurfaceKind.wall,
      LocalFinish.rectangleTiles,
      'Bathroom wall 1',
    ),
    (
      'powder_room',
      'Bathroom wall tiles',
      LocalSurfaceKind.wall,
      LocalFinish.rectangleTiles,
      'Bathroom wall 1',
    ),
  ]) {
    testWidgets(
      '$type wall tile shortcut keeps the same area and colour through save and reopen',
      (tester) async {
        LocalPaintRecipe? saved;
        final initial = recipe().replaceSurface(
          0,
          recipe().surfaces.single.copyWith(name: 'Wall 1'),
        );
        Future<void> show(int key) async {
          await tester.pumpWidget(
            MaterialApp(
              home: LocalPaintScreen(
                key: ValueKey(key),
                roomTypeId: type,
                source: original,
                before: original,
                initial: saved ?? initial,
                saveDraft: (value) async {
                  saved = value;
                },
                saveVersion: (_, _) async {},
              ),
            ),
          );
          await tester.pump();
          await waitFor(
            tester,
            () => find.text('2 Finish').evaluate().isNotEmpty,
          );
          await tester.pump(const Duration(milliseconds: 600));
          await waitFor(
            tester,
            () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
          );
          await tester.tap(find.text('2 Finish'));
          await tester.pump();
        }

        await show(1);
        if (type == 'powder_room') {
          expect(find.text('Shower wall tiles'), findsNothing);
        }
        await tester.tap(find.text(shortcut));
        await tester.pump(const Duration(milliseconds: 700));
        await waitFor(
          tester,
          () => saved?.surfaces.single.finish == expectedFinish,
        );
        await waitFor(
          tester,
          () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
        );
        final surface = saved!.surfaces.single;
        expect(surface.kind, expectedKind);
        expect(surface.name, expectedName);
        expect(surface.rgb, 0x507040);
        expect(surface.coverage, 1);
        expect(surface.marks.single.toMap(), outline().toMap());
        expect(paintRefinementPrompt(saved!), contains(expectedName));
        final retained = saved!.toMap();
        await show(2);
        expect(find.text(expectedName), findsOneWidget);
        expect(
          tester
              .widget<DropdownButton<LocalFinish>>(
                find.byType(DropdownButton<LocalFinish>),
              )
              .value,
          expectedFinish,
        );
        expect(saved!.toMap(), retained);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'paint draft reopens and failed version save can retry without losing selections',
    (tester) async {
      LocalPaintRecipe? saved;
      var attempts = 0;
      Future<void> show() async => tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => LocalPaintScreen(
                      source: original,
                      before: original,
                      initial: saved,
                      saveDraft: (value) async {
                        saved = value;
                      },
                      saveVersion: (result, recipe) async {
                        attempts++;
                        if (attempts == 1) throw StateError('Disk full');
                      },
                    ),
                  ),
                ),
                child: const Text('Paint'),
              ),
            ),
          ),
        ),
      );
      await show();
      await tester.tap(find.text('Paint'));
      await tester.pump();
      await drawWall(tester);
      await waitFor(tester, () => saved != null);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paint'));
      await tester.pump();
      await waitFor(
        tester,
        () => find.byKey(const ValueKey('paint-canvas')).evaluate().isNotEmpty,
      );
      expect(saved!.surfaces.single.marks.single.points, hasLength(4));
      await tester.pump(const Duration(milliseconds: 400));
      await waitFor(
        tester,
        () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
      );
      await tester.tap(find.byTooltip('Save finish version'));
      await tester.pump();
      await waitFor(tester, () => attempts == 1);
      await tester.pumpAndSettle();
      expect(find.byType(LocalPaintScreen), findsOneWidget);
      expect(
        find.textContaining('Paint version could not be saved.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Save finish version'));
      await tester.pump();
      await waitFor(tester, () => attempts == 2);
      await tester.pumpAndSettle();
      expect(find.byType(LocalPaintScreen), findsNothing);
    },
  );

  testWidgets(
    'restoring saved paint layers safely removes an added active wall',
    (tester) async {
      final saved = recipe();
      await tester.pumpWidget(
        MaterialApp(
          home: LocalPaintScreen(
            source: original,
            before: original,
            initial: saved,
            savedRecipe: saved,
            saveDraft: (_) async {},
            saveVersion: (_, _) async {},
          ),
        ),
      );
      await tester.pump();
      await waitFor(
        tester,
        () => find.byTooltip('Add surface').evaluate().isNotEmpty,
      );
      await tester.tap(find.byTooltip('Add surface'));
      await tester.pump();
      expect(find.text('Wall 2'), findsOneWidget);
      await tester.tap(find.text('2 Finish'));
      await tester.pump();
      final restore = find.text('Use saved version colours and selection');
      await tester.ensureVisible(restore);
      await tester.tap(restore);
      await tester.pump(const Duration(milliseconds: 600));
      await waitFor(
        tester,
        () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
      );
      expect(find.text('Wall 2'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Undo paint'));
      await tester.pump(const Duration(milliseconds: 600));
      await waitFor(
        tester,
        () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
      );
      expect(find.text('Wall 2'), findsOneWidget);
    },
  );

  testWidgets('paint tools fit a small phone and landscape with enlarged text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    if (const bool.fromEnvironment('PAINT_REVIEW')) {
      await tester.runAsync(() async {
        const fontRoot = String.fromEnvironment('PAINT_REVIEW_FONT_DIR');
        for (final entry in {
          'Roboto': 'Roboto-Regular.ttf',
          'MaterialIcons': 'MaterialIcons-Regular.otf',
        }.entries) {
          final bytes = await File('$fontRoot/${entry.value}').readAsBytes();
          await (FontLoader(
            entry.key,
          )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
        }
      });
    }
    for (final size in const [Size(320, 568), Size(844, 390)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildRenovisionTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: const ValueKey('paint-layout-review'),
            child: LocalPaintScreen(
              key: ValueKey(size),
              roomTypeId: 'bathroom',
              source: const bool.fromEnvironment('PAINT_REVIEW')
                  ? File('assets/inspiration/charcoal-kitchen.png')
                        .readAsBytesSync()
                  : original,
              before: const bool.fromEnvironment('PAINT_REVIEW')
                  ? File('assets/inspiration/charcoal-kitchen.png')
                        .readAsBytesSync()
                  : original,
              saveDraft: (_) async {},
              saveVersion: (_, _) async {},
            ),
          ),
        ),
      );
      await tester.pump();
      await waitFor(
        tester,
        () => find.byKey(const ValueKey('paint-canvas')).evaluate().isNotEmpty,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await waitFor(
        tester,
        () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
      );
      for (final tool in ['Paint brush', 'Erase selection', 'Move / zoom']) {
        await tester.ensureVisible(find.byTooltip(tool));
        await tester.pump();
        await tester.tap(find.byTooltip(tool));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      await tester.scrollUntilVisible(
        find.text('2 Finish'),
        -100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('2 Finish'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('PAINT_REVIEW')) {
        await tester.runAsync(() async {
          final capture = tester.renderObject(
            find.byKey(const ValueKey('paint-layout-review')),
          ) as RenderRepaintBoundary;
          final image = await capture.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            'output/design-review/paint-${size.width.toInt()}x${size.height.toInt()}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
  });

  test('Japanese and Italian influences blend without replacing protected features', () {
    expect(designStyles['japanese'], 'Japanese');
    expect(designStyles['italian'], 'Italian');
    final prompt = styleDirection(['modern', 'japanese', 'italian']);
    expect(prompt, contains('Modern / Contemporary + Japanese + Italian'));
    expect(
      prompt,
      contains('Protected features and explicit Keep choices take priority'),
    );
    expect(prompt, contains('Japanese-inspired'));
    expect(prompt, contains('Italian-inspired'));
  });
}
