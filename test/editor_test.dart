import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/editors.dart';
import 'package:renovision_ai/reference_markup.dart';

void main() {
  late Uint8List source;
  setUp(() {
    final photo = img.Image(width: 200, height: 100);
    img.fill(photo, color: img.ColorRgb8(40, 90, 120));
    photo.exif.imageIfd.imageDescription = 'Private original metadata';
    source = img.encodeJpg(photo);
  });

  Future<void> openEditor(
    WidgetTester tester, {
    required bool sketch,
    required ValueChanged<Uint8List?> onSave,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final result = await Navigator.push<Uint8List>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FocusEditScreen(bytes: source, sketch: sketch),
                  ),
                );
                onSave(result);
              },
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    for (
      var i = 0;
      i < 30 && find.text('Preparing image preview…').evaluate().isNotEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> reach(
    WidgetTester tester,
    Finder target, {
    bool up = false,
  }) async {
    if (target.hitTestable().evaluate().isNotEmpty && !up) return;
    if (target.evaluate().isEmpty) {
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      for (var i = 0; i < 30 && target.evaluate().isEmpty; i++) {
        position.jumpTo(
          (position.pixels + (up ? -200 : 200)).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
        await tester.pump();
      }
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester, bool Function() finished) async {
    await reach(tester, find.text('Save as new version'));
    await tester.tap(find.text('Save as new version'));
    await tester.pump();
    for (var i = 0; i < 100 && !finished(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();
    expect(finished(), isTrue);
  }

  ReferenceOverlay overlay(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.byKey(const ValueKey('reference-overlay')),
              )
              .painter!
          as ReferenceOverlay;

  testWidgets(
    'crop saves a smaller reference without source metadata or mutation',
    (tester) async {
      Uint8List? result;
      final originalBytes = Uint8List.fromList(source);
      await openEditor(
        tester,
        sketch: false,
        onSave: (bytes) => result = bytes,
      );
      final imageRect = tester.getRect(find.byType(Image));
      await tester.timedDragFrom(
        imageRect.topLeft + Offset(imageRect.width * .2, imageRect.height * .2),
        Offset(imageRect.width * .5, imageRect.height * .5),
        const Duration(milliseconds: 400),
      );
      await tester.pump();
      await save(tester, () => result != null);
      expect(result, isNotNull);
      final crop = img.decodeImage(result!)!;
      expect(crop.width, inInclusiveRange(98, 102));
      expect(crop.height, inInclusiveRange(48, 52));
      expect(crop.exif.imageIfd.imageDescription, isNull);
      expect(source, orderedEquals(originalBytes));
      expect(
        img.decodeImage(source)!.exif.imageIfd.imageDescription,
        'Private original metadata',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sketch supports undo and saves markup without changing original',
    (tester) async {
      Uint8List? result;
      final originalBytes = Uint8List.fromList(source);
      await openEditor(tester, sketch: true, onSave: (bytes) => result = bytes);
      final imageRect = tester.getRect(find.byType(Image));
      final start = imageRect.centerLeft + Offset(imageRect.width * .2, 0);
      final delta = Offset(imageRect.width * .6, 0);
      await tester.timedDragFrom(
        start,
        delta,
        const Duration(milliseconds: 400),
      );
      await tester.pump();
      await reach(tester, find.text('Undo'));
      expect(
        tester
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Undo'))
            .onPressed,
        isNotNull,
      );
      await reach(tester, find.text('Undo'));
      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      expect(
        tester
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Undo'))
            .onPressed,
        isNull,
      );
      await reach(tester, find.byType(Image), up: true);
      final newRect = tester.getRect(find.byType(Image));
      await tester.timedDragFrom(
        newRect.centerLeft + Offset(newRect.width * .2, 0),
        delta,
        const Duration(milliseconds: 400),
      );
      await tester.pump();
      await save(tester, () => result != null);
      final edited = img.decodeImage(result!)!;
      final pixel = edited.getPixel(100, 50);
      expect(pixel.r, greaterThan(pixel.b));
      expect(edited.exif.imageIfd.imageDescription, isNull);
      expect(source, orderedEquals(originalBytes));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'crop corners resize and inside drag moves the existing selection',
    (tester) async {
      await openEditor(tester, sketch: false, onSave: (_) {});
      final area = tester.getRect(find.byType(Image));
      await tester.timedDragFrom(
        area.topLeft + Offset(area.width * .2, area.height * .2),
        Offset(area.width * .5, area.height * .5),
        const Duration(milliseconds: 400),
      );
      await tester.pump();
      await tester.timedDragFrom(
        area.topLeft + Offset(area.width * .7, area.height * .7),
        Offset(area.width * .1, area.height * .1),
        const Duration(milliseconds: 400),
      );
      await tester.pump();
      expect(overlay(tester).crop!.right, closeTo(.8, .01));
      expect(overlay(tester).crop!.left, closeTo(.2, .01));
      await tester.timedDragFrom(
        area.center,
        Offset(-area.width * .1, 0),
        const Duration(milliseconds: 400),
      );
      await tester.pump();
      expect(overlay(tester).crop!.left, closeTo(.1, .01));
      expect(overlay(tester).crop!.width, closeTo(.6, .01));
      final retained = overlay(tester).crop;
      await tester.tapAt(area.center);
      await tester.pump();
      expect(overlay(tester).crop, retained);
    },
  );

  testWidgets(
    'coloured shapes and text notes coexist, move, undo and save at source resolution',
    (tester) async {
      Uint8List? result;
      final original = Uint8List.fromList(source);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await openEditor(tester, sketch: true, onSave: (bytes) => result = bytes);
      Future<void> choose(String label) async {
        final chip = find.widgetWithText(ChoiceChip, label);
        await reach(tester, chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }

      Future<void> draw(Offset from, Offset to) async {
        await reach(tester, find.byType(Image), up: true);
        final box = tester.getRect(find.byType(Image));
        await tester.timedDragFrom(
          box.topLeft + Offset(from.dx * box.width, from.dy * box.height),
          Offset((to.dx - from.dx) * box.width, (to.dy - from.dy) * box.height),
          const Duration(milliseconds: 400),
        );
        await tester.pump();
      }

      await choose('Rectangle');
      await choose('Blue');
      await draw(const Offset(.1, .1), const Offset(.4, .4));
      await choose('Arrow');
      await choose('Green');
      await draw(const Offset(.5, .2), const Offset(.8, .5));
      await choose('Text note');
      await reach(tester, find.byType(Image), up: true);
      await tester.tapAt(
        tester.getRect(find.byType(Image)).bottomLeft + const Offset(30, -30),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Keep this window');
      await tester.tap(find.text('Apply note'));
      await tester.pumpAndSettle();
      expect(overlay(tester).marks, hasLength(3));
      expect(overlay(tester).marks.first.color, Colors.blue);
      expect(overlay(tester).marks[1].color, Colors.green);
      expect(overlay(tester).marks.last.text, 'Keep this window');
      await reach(tester, find.text('Undo'));
      await tester.tap(find.text('Undo'));
      await tester.pump();
      await reach(tester, find.byType(Image), up: true);
      expect(overlay(tester).marks, hasLength(2));
      await reach(tester, find.text('Redo'));
      await tester.tap(find.text('Redo'));
      await tester.pump();
      await reach(tester, find.byType(Image), up: true);
      expect(overlay(tester).marks, hasLength(3));
      await choose('Select / move');
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, 'Select / move'),
            )
            .selected,
        isTrue,
      );
      await draw(const Offset(.2, .2), const Offset(.3, .2));
      expect(
        overlay(tester).selected,
        0,
        reason:
            '${overlay(tester).marks.map((m) => (m.tool, m.points)).toList()}',
      );
      expect(overlay(tester).marks.first.points.first.dx, closeTo(.2, .02));
      final imageArea = tester.getRect(find.byType(Image));
      final noteBox = overlay(tester).marks.last.bounds(imageArea.size);
      await tester.tapAt(imageArea.topLeft + noteBox.center);
      await tester.pump();
      await reach(tester, find.text('Edit note'));
      await tester.tap(find.text('Edit note'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Keep this window exactly',
      );
      await tester.tap(find.text('Apply note'));
      await tester.pumpAndSettle();
      await reach(tester, find.byType(Image), up: true);
      expect(overlay(tester).marks.last.text, 'Keep this window exactly');
      await reach(tester, find.text('Remove selected'));
      await tester.tap(find.text('Remove selected'));
      await tester.pump();
      await reach(tester, find.byType(Image), up: true);
      expect(overlay(tester).marks, hasLength(2));
      await reach(tester, find.text('Undo'));
      await tester.tap(find.text('Undo'));
      await tester.pump();
      await reach(tester, find.byType(Image), up: true);
      expect(overlay(tester).marks.last.text, 'Keep this window exactly');
      await save(tester, () => result != null);
      final output = img.decodeImage(result!)!;
      expect((output.width, output.height), (200, 100));
      expect(output.exif.isEmpty, isTrue);
      expect(output.getPixel(40, 10).b, greaterThan(output.getPixel(40, 10).r));
      expect(source, original);
      expect(tester.takeException(), isNull);
    },
  );

  test('crop handle geometry clamps movement, supports edges and prevents inverted boxes', () {
    const r = Rect.fromLTRB(.2, .2, .8, .8);
    expect(
      cropHandleAt(r, const Offset(.2, .2), const Size(400, 300)),
      CropHandle.topLeft,
    );
    expect(
      cropHandleAt(r, const Offset(.5, .2), const Size(400, 300)),
      CropHandle.top,
    );
    expect(
      cropHandleAt(r, const Offset(.5, .5), const Size(400, 300)),
      CropHandle.move,
    );
    final moved = adjustCrop(
      r,
      CropHandle.move,
      const Offset(.5, .5),
      const Offset(1, 1),
    );
    expect(moved.right, 1);
    expect(moved.bottom, 1);
    final smaller = adjustCrop(
      r,
      CropHandle.topLeft,
      r.topLeft,
      const Offset(.99, .99),
    );
    expect(smaller.width, closeTo(.04, .0001));
    expect(smaller.height, closeTo(.04, .0001));
    expect(
      adjustCrop(
        r,
        CropHandle.right,
        r.centerRight,
        const Offset(.9, .5),
      ).right,
      .9,
    );
  });
}
