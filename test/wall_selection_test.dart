import 'package:flutter_test/flutter_test.dart';

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/local_paint.dart';
import 'package:renovision_ai/local_paint_screen.dart';
import 'package:renovision_ai/wall_selection.dart';

void main() {
  test('extending a selection grows one pixel, clips edges and preserves its source', () {
    final region = PaintRegion(
      width: 5,
      height: 5,
      bits: Uint8List.fromList([1, 0, 0, 0]),
    );
    final extended = extendWallSelectionEdge(region);
    for (var y = 0; y < 5; y++) {
      for (var x = 0; x < 5; x++) {
        expect(extended.contains(x, y), x <= 1 && y <= 1);
        expect(region.contains(x, y), x == 0 && y == 0);
      }
    }
    expect(extended.sensitivity, region.sensitivity);
    expect(
      PaintRegion.fromMap(extended.toMap()).bits,
      orderedEquals(extended.bits),
    );
  });
  final image = img.Image(width: 100, height: 70, numChannels: 4);
  for (final p in image) {
    final tone = p.x == 49 || p.x == 50 ? 30 : 180;
    p
      ..r = tone
      ..g = tone
      ..b = tone
      ..a = 255;
  }
  final bytes = img.encodePng(image);
  test('sample wall selection excludes the bed, artwork and window, with compact high-resolution persistence', () async {
    final sample = (await rootBundle.load(
      'assets/inspiration/white-oak-bedroom.png',
    )).buffer.asUint8List();
    final selected = selectWallRegion(
      WallSelectionInput(sample, const PaintPoint(.58, .2)),
    );
    bool at(double x, double y) => selected.region.contains(
      (x * (selected.region.width - 1)).round(),
      (y * (selected.region.height - 1)).round(),
    );
    expect(at(.58, .2), isTrue);
    for (final point in const [
      PaintPoint(.55, .65),
      PaintPoint(.37, .25),
      PaintPoint(.8, .3),
      PaintPoint(.3, .9),
    ]) {
      expect(at(point.x, point.y), isFalse);
    }
    expect(selected.region.width, 1000);
    final encoded = selected.region.toMap();
    expect((encoded['rows'] as String).length, lessThan(50000));
    expect(
      PaintRegion.fromMap(encoded).bits,
      orderedEquals(selected.region.bits),
    );
    expect(
      () => PaintRegion.fromMap({...encoded, 'rows': 'AQ=='}),
      throwsFormatException,
    );
  });
  test('tap selects a connected surface, respects a strong edge and preserves every unselected pixel', () {
    final selected = selectWallRegion(
      WallSelectionInput(bytes, const PaintPoint(.25, .5)),
    );
    expect(selected.region.contains(20, 30), isTrue);
    expect(selected.region.contains(80, 30), isFalse);
    final recipe = LocalPaintRecipe(
      width: 100,
      height: 70,
      surfaces: [
        PaintSurface(
          name: 'Wall 1',
          rgb: 0x507040,
          marks: [
            PaintMark(PaintMarkKind.region, const [
              PaintPoint(.25, .5),
            ], region: selected.region),
          ],
        ),
      ],
    );
    final roundTrip = LocalPaintRecipe.fromMap(recipe.toMap());
    final output = img.decodePng(
      renderLocalPaint(PaintRenderInput(bytes, roundTrip)).bytes,
    )!;
    expect(output.getPixel(20, 30).r, isNot(180));
    for (final pixel in output) {
      if (!selected.region.contains(pixel.x, pixel.y)) {
        final original = image.getPixel(pixel.x, pixel.y);
        expect(
          [pixel.r, pixel.g, pixel.b, pixel.a],
          [original.r, original.g, original.b, original.a],
        );
      }
    }
    expect(() => selected.region.bits[0] = 0, throwsUnsupportedError);
    expect(
      () => PaintRegion.fromMap({
        'width': 512,
        'height': 512,
        'bits': 'AA==',
        'sensitivity': 28,
      }),
      throwsFormatException,
    );
    expect(
      () => selectWallRegion(
        WallSelectionInput(bytes, const PaintPoint(double.nan, 0)),
      ),
      throwsFormatException,
    );
    expect(
      renderLocalPaint(PaintRenderInput(bytes, LocalPaintRecipe.empty(100, 70)))
          .changedPixels,
      0,
    );
  });

  Future<void> ready(WidgetTester tester, bool Function() check) async {
    for (var i = 0; i < 200 && !check(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(check(), isTrue);
  }

  Future<void> quiet(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    await ready(
      tester,
      () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'clearing all layers of a saved paint version can save the unpainted base as a new child',
    (tester) async {
      final selected = selectWallRegion(
        WallSelectionInput(bytes, const PaintPoint(.25, .5)),
      );
      final recipe = LocalPaintRecipe(
        width: 100,
        height: 70,
        surfaces: [
          PaintSurface(
            name: 'Wall 1',
            marks: [
              PaintMark(PaintMarkKind.region, const [
                PaintPoint(.25, .5),
              ], region: selected.region),
            ],
          ),
        ],
      );
      final painted = renderLocalPaint(PaintRenderInput(bytes, recipe)).bytes;
      PaintRenderResult? savedImage;
      LocalPaintRecipe? savedLayers;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => LocalPaintScreen(
                      source: bytes,
                      before: painted,
                      initial: recipe,
                      savedRecipe: recipe,
                      saveDraft: (_) async {},
                      saveVersion: (result, layers) async {
                        savedImage = result;
                        savedLayers = layers;
                      },
                    ),
                  ),
                ),
                child: const Text('Edit saved paint'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit saved paint'));
      await tester.pump();
      await ready(
        tester,
        () => find.byKey(const ValueKey('paint-canvas')).evaluate().isNotEmpty,
      );
      await quiet(tester);
      await tester.tap(find.byTooltip('Delete all surfaces'));
      await quiet(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await quiet(tester);
      await tester.tap(find.byTooltip('Save finish version'));
      await tester.pump();
      await ready(tester, () => savedImage != null);
      await tester.pumpAndSettle();
      expect(savedLayers!.surfaces, isEmpty);
      expect(savedImage!.changedPixels, 0);
      final reverted = img.decodePng(savedImage!.bytes)!;
      for (final pixel in reverted) {
        final source = image.getPixel(pixel.x, pixel.y);
        expect(
          [pixel.r, pixel.g, pixel.b, pixel.a],
          [source.r, source.g, source.b, source.a],
        );
      }
    },
  );

  testWidgets(
    'one tap creates a wall; per-wall and clear-all controls survive draft reopening without undo history',
    (tester) async {
      LocalPaintRecipe? saved;
      Future<void> show(int key) => tester.pumpWidget(
        MaterialApp(
          home: LocalPaintScreen(
            key: ValueKey(key),
            source: bytes,
            before: bytes,
            initial: saved,
            saveDraft: (recipe) async {
              saved = recipe;
            },
            saveVersion: (_, _) async {},
          ),
        ),
      );
      await show(1);
      await ready(
        tester,
        () => find.byKey(const ValueKey('paint-canvas')).evaluate().isNotEmpty,
      );
      final bounds = tester.getRect(find.byKey(const ValueKey('paint-canvas')));
      await tester.tapAt(
        bounds.topLeft + Offset(bounds.width * .25, bounds.height * .5),
      );
      await tester.pump();
      await ready(
        tester,
        () => find.text('Adjust surface boundary').evaluate().isNotEmpty,
      );
      await tester.pump(const Duration(milliseconds: 600));
      await ready(tester, () => saved?.surfaces.length == 1);
      expect(saved!.surfaces.single.marks.single.kind, PaintMarkKind.region);
      final selection = saved!.surfaces.single.marks.single.region!.bits;
      await Scrollable.ensureVisible(
        tester.element(find.text('Extend selection edge')),
        alignment: .5,
      );
      await quiet(tester);
      await tester.tap(find.text('Extend selection edge'));
      await quiet(tester);
      expect(
        saved!.surfaces.single.marks.single.region!.bits,
        isNot(orderedEquals(selection)),
      );
      await tester.tap(find.byTooltip('Undo paint'));
      await quiet(tester);
      expect(
        saved!.surfaces.single.marks.single.region!.bits,
        orderedEquals(selection),
      );
      Future<void> colour(String hex) async {
        await quiet(tester);
        await tester.ensureVisible(find.text('Custom colour'));
        await tester.pump();
        await tester.tap(find.text('Custom colour'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(find.byType(TextFormField), hex);
        await tester.tap(find.text('Apply'));
        await tester.pump(const Duration(milliseconds: 600));
        await ready(
          tester,
          () =>
              saved!.surfaces.single.rgb ==
              int.parse(hex.substring(1), radix: 16),
        );
      }

      await colour('#A6B59B');
      await colour('#5070A0');
      expect(saved!.surfaces, hasLength(1));
      expect(saved!.surfaces.single.marks, hasLength(1));
      expect(
        saved!.surfaces.single.marks.single.region!.bits,
        orderedEquals(selection),
      );
      await tester.tap(find.byTooltip('Add surface'));
      await tester.pump(const Duration(milliseconds: 600));
      await ready(tester, () => saved?.surfaces.length == 2);
      await show(2);
      await ready(
        tester,
        () => find.byKey(const ValueKey('paint-canvas')).evaluate().isNotEmpty,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await ready(
        tester,
        () => find.byType(LinearProgressIndicator).evaluate().isEmpty,
      );
      await tester.tap(find.byTooltip('Delete selected surface'));
      await quiet(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pump(const Duration(milliseconds: 600));
      await ready(tester, () => saved?.surfaces.length == 1);
      await tester.tap(find.byTooltip('Delete all surfaces'));
      await quiet(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pump(const Duration(milliseconds: 600));
      await ready(tester, () => saved?.surfaces.isEmpty ?? false);
      await show(3);
      await ready(
        tester,
        () => find.byKey(const ValueKey('paint-canvas')).evaluate().isNotEmpty,
      );
      expect(find.text('Wall 1'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
