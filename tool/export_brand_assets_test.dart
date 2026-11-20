// Preview: flutter test tool/export_brand_assets_test.dart
// Apply only after confirmation: add --dart-define=INSTALL_RENOVISION_ICON=true
// Deterministic vector-to-platform export; no customer image or AI API is used.
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:renovision_ai/brand_mark.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('export selected RenoVision mark', () async {
    Future<Uint8List> png(int size, {bool rounded = false}) async {
      final recorder = ui.PictureRecorder();
      RenoVisionMarkPainter(rounded: rounded)
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
        path = 'output/design-review/icon-a-candidate/$path';
      }
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    }

    Future<void> text(String path, String value) =>
        write(path, utf8.encode(value));
    await text('assets/brand/renovision.svg', renoVisionSvg());
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
    final vector =
        '<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">'
        '<group android:pivotX="54" android:pivotY="54" android:scaleX="0.84" android:scaleY="0.84">'
        '<path android:fillColor="#FFF6E3" android:fillType="evenOdd" android:pathData="$renoVisionRoomPath"/>'
        '<path android:fillColor="#FFF6E3" android:pathData="$renoVisionSparklePath"/></group></vector>';
    await text(
      'android/app/src/main/res/drawable/renovision_foreground.xml',
      vector,
    );
    await text(
      'android/app/src/main/res/values/renovision_brand.xml',
      '<resources><color name="renovision_icon_background">#39491C</color></resources>',
    );
    for (final version in [26, 33]) {
      await text(
        'android/app/src/main/res/mipmap-anydpi-v$version/ic_launcher.xml',
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/renovision_icon_background"/><foreground android:drawable="@drawable/renovision_foreground"/>${version >= 33 ? '<monochrome android:drawable="@drawable/renovision_foreground"/>' : ''}</adaptive-icon>',
      );
    }
    await write('web/favicon.png', await png(32, rounded: true));
    await text('web/icons/renovision.svg', renoVisionSvg());
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
  });
}
