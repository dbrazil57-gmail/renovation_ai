import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/creation_export.dart';
import 'package:renovision_ai/creation_export_native.dart';
import 'package:renovision_ai/creation_export_widgets.dart';
import 'package:renovision_ai/file_transfer.dart';

class ExportFiles implements AppFiles {
  Uint8List? bytes;
  @override
  bool get supported => true;
  @override
  Future<Uint8List?> pickBackup() async => null;
  @override
  Future<FileSaveResult> save(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async {
    this.bytes = bytes;
    expect(mimeType, 'image/png');
    return FileSaveResult.cancelled;
  }
}

class ExportRecorder implements CreationExports {
  @override
  bool get supported => true;
  final called = Completer<void>();
  final release = Completer<CreationExportResult>();
  Uint8List? image;
  String? name;
  int saves = 0, shares = 0;
  bool fail = false;
  @override
  Future<CreationExportResult> save(
    Uint8List png, {
    required String name,
  }) async {
    saves++;
    image = png;
    this.name = name;
    if (!called.isCompleted) called.complete();
    if (fail) throw PlatformException(code: 'full');
    return release.future;
  }

  @override
  Future<CreationExportResult> share(
    Uint8List png, {
    required String name,
  }) async {
    shares++;
    image = png;
    this.name = name;
    if (!called.isCompleted) called.complete();
    if (fail) throw PlatformException(code: 'share');
    return CreationExportResult.shareOpened;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final source = img.Image(width: 40, height: 30)
    ..exif.imageIfd.imageDescription = 'Private original';
  final bytes = img.encodeJpg(source);

  Future<void> startExport(WidgetTester tester, ExportRecorder exports) async {
    await tester.tap(find.text('Save image'));
    // Image encoding runs in a real isolate; pump the widget-test zone after
    // allowing its completion port to deliver the result.
    for (
      var attempt = 0;
      attempt < 100 && !exports.called.isCompleted;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(
      exports.called.isCompleted,
      isTrue,
      reason: 'Image preparation must reach the platform exporter.',
    );
  }

  test(
    'Android exports send only image data and preserve old-device cancellation',
    () async {
      final files = ExportFiles();
      final exports = AndroidCreationExports(files: files);
      final calls = <MethodCall>[];
      var response = 'gallery';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AndroidCreationExports.channel, (
            call,
          ) async {
            calls.add(call);
            return response;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(AndroidCreationExports.channel, null),
      );
      final png = img.encodePng(img.Image(width: 4, height: 4));
      expect(
        await exports.save(png, name: 'Kitchen.png'),
        CreationExportResult.gallerySaved,
      );
      expect(calls.single.method, 'saveGallery');
      expect((calls.single.arguments as Map).keys.toSet(), {'bytes', 'name'});
      expect(calls.single.arguments['bytes'], orderedEquals(png));
      response = 'chooseFile';
      expect(
        await exports.save(png, name: 'Kitchen.png'),
        CreationExportResult.cancelled,
      );
      expect(files.bytes, orderedEquals(png));
      response = 'opened';
      expect(
        await exports.share(png, name: 'Kitchen.png'),
        CreationExportResult.shareOpened,
      );
      expect(calls.last.method, 'shareImage');
      response = 'unexpected';
      await expectLater(
        exports.save(png, name: 'Kitchen.png'),
        throwsA(isA<PlatformException>()),
      );
    },
  );

  testWidgets(
    'save/share strip metadata, block repeat taps and keep original bytes',
    (tester) async {
      final exports = ExportRecorder();
      final original = Uint8List.fromList(bytes);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreationExportControls(
              bytes: bytes,
              title: 'Kitchen / idea',
              exports: exports,
            ),
          ),
        ),
      );
      await startExport(tester, exports);
      await tester.pump();
      expect(find.text('Saving image…'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save image'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Share creation'),
            )
            .onPressed,
        isNull,
      );
      expect(exports.saves, 1);
      expect(exports.name, 'Kitchen-idea.png');
      expect(
        img.decodePng(exports.image!)!.exif.imageIfd.imageDescription,
        isNull,
      );
      expect(bytes, orderedEquals(original));
      expect(
        img.decodeJpg(bytes)!.exif.imageIfd.imageDescription,
        'Private original',
      );
      exports.release.complete(CreationExportResult.gallerySaved);
      await tester.pumpAndSettle();
      expect(
        find.text('Saved to Gallery · Pictures/RenoVision.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Share creation'));
      await tester.pumpAndSettle();
      expect(exports.shares, 1);
      expect(find.textContaining('Share sheet opened.'), findsOneWidget);
      expect(bytes, orderedEquals(original));
    },
  );

  testWidgets(
    'export failure leaves retry available and never reports success',
    (tester) async {
      final exports = ExportRecorder()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreationExportControls(
              bytes: bytes,
              title: 'Kitchen',
              exports: exports,
            ),
          ),
        ),
      );
      await startExport(tester, exports);
      await tester.pumpAndSettle();
      expect(find.textContaining('Image could not be saved.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save image'),
            )
            .onPressed,
        isNotNull,
      );
      expect(find.textContaining('Saved to Gallery'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('export controls wrap on small phones with enlarged text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.8),
          ),
          child: Scaffold(
            body: CreationExportControls(
              bytes: bytes,
              title: 'Kitchen',
              exports: ExportRecorder(),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Save image'), findsOneWidget);
    expect(find.text('Share creation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
