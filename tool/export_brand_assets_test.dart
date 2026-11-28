// Preview: flutter test tool/export_brand_assets_test.dart
// Apply only after confirmation: add --dart-define=INSTALL_RENOVISION_ICON=true
// Deterministic vector-to-platform export; no customer image or AI API is used.
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:renovision_ai/brand_mark.dart';
import 'package:renovision_ai/app_brand.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('export selected RenoImagineAI mark', () async {
    Future<Uint8List> png(int size, {bool rounded = false}) async {
      final recorder = ui.PictureRecorder();
      AppBrandMarkPainter(rounded: rounded)
          .paint(ui.Canvas(recorder), ui.Size.square(size.toDouble()));
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      image.dispose();
      picture.dispose();
      return bytes;
    }

    Future<void> write(String path, List<int> bytes) async {
      const install = bool.fromEnvironment('INSTALL_RENOVISION_ICON');
      if (!install) {
        path = 'output/design-review/renoimagineai-camera-candidate/$path';
      }
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    }

    Future<void> text(String path, String value) =>
        write(path, utf8.encode(value));
    await text('assets/brand/renovision.svg', appBrandSvg());
    await write('assets/brand/renovision-1024.png', await png(1024));
    for (final (density, size) in [
      ('mdpi', 48),
      ('hdpi', 72),
      ('xhdpi', 96),
      ('xxhdpi', 144),
      ('xxxhdpi', 192),
    ]) {
      await write(
        'android/app/src/main/res/mipmap-$density/ic_launcher.png',
        await png(size, rounded: true),
      );
    }
    final vector = appBrandAndroidVector();
    await text(
      'android/app/src/main/res/drawable/renovision_foreground.xml',
      vector,
    );
    await text(
      'android/app/src/main/res/values/renovision_brand.xml',
      '<resources><color name="renovision_icon_background">#173034</color></resources>',
    );
    for (final version in [26, 33]) {
      await text(
        'android/app/src/main/res/mipmap-anydpi-v$version/ic_launcher.xml',
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/renovision_icon_background"/><foreground android:drawable="@drawable/renovision_foreground"/>${version >= 33 ? '<monochrome android:drawable="@drawable/renovision_foreground"/>' : ''}</adaptive-icon>',
      );
    }
    await write('web/favicon.png', await png(32, rounded: true));
    await text('web/icons/renovision.svg', appBrandSvg());
    for (final size in [192, 512]) {
      await write('web/icons/Icon-$size.png', await png(size, rounded: true));
      await write('web/icons/Icon-maskable-$size.png', await png(size));
    }
    for (final catalogue in [
      'ios/Runner/Assets.xcassets/AppIcon.appiconset',
      'macos/Runner/Assets.xcassets/AppIcon.appiconset',
    ]) {
      final file = File('$catalogue/Contents.json');
      if (!await file.exists()) continue;
      final images =
          (jsonDecode(await file.readAsString()) as Map)['images'] as List;
      for (final item in images.whereType<Map>()) {
        if (item['filename'] is! String || item['size'] is! String) continue;
        final size =
            (double.parse((item['size'] as String).split('x').first) *
                    double.parse(
                      (item['scale'] as String? ?? '1x').replaceAll('x', ''),
                    ))
                .round();
        await write('$catalogue/${item['filename']}', await png(size));
      }
    }
    final iconPng = await png(256, rounded: true);
    final header = ByteData(22)
      ..setUint16(2, 1, Endian.little)
      ..setUint16(4, 1, Endian.little)
      ..setUint16(10, 1, Endian.little)
      ..setUint16(12, 32, Endian.little)
      ..setUint32(14, iconPng.length, Endian.little)
      ..setUint32(18, 22, Endian.little);
    await write('windows/runner/resources/app_icon.ico', [
      ...header.buffer.asUint8List(),
      ...iconPng,
    ]);

    // Review sheet only; do not bundle system fonts or marketing text in icons.
    final font = File('C:/Windows/Fonts/segoeui.ttf');
    if (await font.exists()) {
      await (FontLoader('BrandPreview')..addFont(
            Future.value(ByteData.sublistView(await font.readAsBytes())),
          ))
          .load();
    }
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1200, 720),
      Paint()..color = const Color(0xFFF1F5F2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 16, 1168, 428),
        const Radius.circular(24),
      ),
      Paint()..color = brandDarkTeal,
    );
    canvas.save();
    canvas.translate(520, 34);
    const AppBrandMarkPainter().paint(canvas, const Size.square(160));
    canvas.restore();
    void label(
      InlineSpan text,
      double y, {
      double size = 24,
      Color colour = brandWhite,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'BrandPreview',
            fontSize: size,
            color: colour,
          ),
          children: [text],
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 1120);
      painter.paint(canvas, Offset((1200 - painter.width) / 2, y));
      painter.dispose();
    }

    label(
      const TextSpan(
        style: TextStyle(fontWeight: FontWeight.w600),
        children: [
          TextSpan(text: 'Reno'),
          TextSpan(
            text: 'Imagine',
            style: TextStyle(color: brandMint),
          ),
          TextSpan(text: 'AI'),
        ],
      ),
      222,
      size: 38,
    );
    label(const TextSpan(text: appTagline), 294, size: 26);
    label(
      const TextSpan(text: appDescription),
      346,
      size: 20,
      colour: const Color(0xFFB6CFC9),
    );
    label(
      const TextSpan(text: 'Camera + home symbol at app sizes'),
      468,
      size: 22,
      colour: brandDarkTeal,
    );
    for (final (x, size) in [
      (160.0, 28.0),
      (370.0, 48.0),
      (590.0, 72.0),
      (820.0, 96.0),
      (1030.0, 128.0),
    ]) {
      canvas.save();
      canvas.translate(x - size / 2, 590 - size / 2);
      const AppBrandMarkPainter(rounded: true).paint(canvas, Size.square(size));
      canvas.restore();
      final painter = TextPainter(
        text: TextSpan(
          text: '${size.toInt()} px',
          style: const TextStyle(
            fontFamily: 'BrandPreview',
            fontSize: 18,
            color: brandDarkTeal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x - painter.width / 2, 668));
      painter.dispose();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(1200, 720);
    final preview = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = await Directory('output/design-review/renoimagineai')
        .create(recursive: true);
    await File('${directory.path}/brand-preview.png')
        .writeAsBytes(preview!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
}
