import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/editors.dart';

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
      await tester.tap(find.text('Save as new version'));
      await tester.pumpAndSettle();
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
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Undo stroke'),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Undo stroke'));
      await tester.pump();
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Undo stroke'),
            )
            .onPressed,
        isNull,
      );
      await tester.timedDragFrom(
        start,
        delta,
        const Duration(milliseconds: 400),
      );
      await tester.pump();
      await tester.tap(find.text('Save as new version'));
      await tester.pumpAndSettle();
      final edited = img.decodeImage(result!)!;
      final pixel = edited.getPixel(100, 50);
      expect(pixel.r, greaterThan(pixel.b));
      expect(edited.exif.imageIfd.imageDescription, isNull);
      expect(source, orderedEquals(originalBytes));
      expect(tester.takeException(), isNull);
    },
  );
}
