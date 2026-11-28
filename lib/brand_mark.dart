import 'package:material_ui/material_ui.dart';

import 'app_brand.dart';

// Vector interpretation of the owner's 06 camera-and-house reference.
// Shared geometry keeps launcher, web, desktop and in-app marks consistent.
const brandDarkTeal = Color(0xFF173034);
const brandMint = Color(0xFF91DFCC);
const brandWhite = Color(0xFFF8FCFA);
const _camera = <List<double>>[
  [0, 28, 40],
  [1, 36, 40],
  [1, 42, 30],
  [2, 43, 28, 45, 27, 48, 27],
  [1, 61, 27],
  [2, 64, 27, 66, 28, 67, 30],
  [1, 73, 40],
  [1, 81, 40],
  [2, 86, 40, 90, 44, 90, 49],
  [1, 90, 79],
  [2, 90, 85, 86, 89, 81, 89],
  [1, 27, 89],
  [2, 22, 89, 18, 85, 18, 79],
  [1, 18, 49],
  [2, 18, 44, 22, 40, 28, 40],
  [3],
];
const _roof = <List<double>>[
  [0, 34, 66],
  [1, 54, 48],
  [1, 74, 66],
];
const _walls = <List<double>>[
  [0, 38, 63],
  [1, 38, 79],
  [1, 70, 79],
  [1, 70, 63],
];
const _flash = <List<double>>[
  [0, 26, 55],
  [1, 26, 49],
  [1, 32, 49],
];
const _windows = <List<double>>[
  [0, 49, 64],
  [1, 53, 64],
  [1, 53, 68],
  [1, 49, 68],
  [3],
  [0, 55, 64],
  [1, 59, 64],
  [1, 59, 68],
  [1, 55, 68],
  [3],
  [0, 49, 70],
  [1, 53, 70],
  [1, 53, 74],
  [1, 49, 74],
  [3],
  [0, 55, 70],
  [1, 59, 70],
  [1, 59, 74],
  [1, 55, 74],
  [3],
];

String _svgPath(List<List<double>> segments) => segments
    .map(
      (part) =>
          '${['M', 'L', 'C', 'Z'][part.first.toInt()]}${part.skip(1).map((n) => n % 1 == 0 ? n.toInt().toString() : n.toString()).join(' ')}',
    )
    .join(' ');

String appBrandSvg() =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108">'
    '<title>$appName</title><rect width="108" height="108" fill="#173034"/>'
    '<g transform="translate(54 54) scale(.84) translate(-54 -54)" stroke-linecap="round" stroke-linejoin="round">'
    '<path d="${_svgPath(_camera)}" fill="none" stroke="#F8FCFA" stroke-width="3.2"/>'
    '<path d="${_svgPath(_roof)} ${_svgPath(_walls)} ${_svgPath(_flash)}" fill="none" stroke="#91DFCC" stroke-width="2.8"/>'
    '<path d="${_svgPath(_windows)}" fill="#F8FCFA"/></g></svg>';

String appBrandAndroidVector() =>
    '<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">'
    '<group android:pivotX="54" android:pivotY="54" android:scaleX="0.84" android:scaleY="0.84">'
    '<path android:fillColor="@android:color/transparent" android:strokeColor="#F8FCFA" android:strokeWidth="3.2" android:strokeLineCap="round" android:strokeLineJoin="round" android:pathData="${_svgPath(_camera)}"/>'
    '<path android:fillColor="@android:color/transparent" android:strokeColor="#91DFCC" android:strokeWidth="2.8" android:strokeLineCap="round" android:strokeLineJoin="round" android:pathData="${_svgPath(_roof)} ${_svgPath(_walls)} ${_svgPath(_flash)}"/>'
    '<path android:fillColor="#F8FCFA" android:pathData="${_svgPath(_windows)}"/></group></vector>';

class AppBrandMark extends StatelessWidget {
  final double size;
  const AppBrandMark({super.key, this.size = 28});
  @override
  Widget build(BuildContext context) => Semantics(
    label: appName,
    image: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: const AppBrandMarkPainter(rounded: true),
    ),
  );
}

class AppBrandWordmark extends StatelessWidget {
  const AppBrandWordmark({super.key});
  @override
  Widget build(BuildContext context) => const Text.rich(
    TextSpan(
      children: [
        TextSpan(text: 'Reno'),
        TextSpan(
          text: 'Imagine',
          style: TextStyle(color: brandMint),
        ),
        TextSpan(text: 'AI'),
      ],
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

class AppBrandMarkPainter extends CustomPainter {
  final bool rounded;
  const AppBrandMarkPainter({this.rounded = false});
  Path _path(List<List<double>> segments) {
    final path = Path();
    for (final part in segments) {
      switch (part.first.toInt()) {
        case 0:
          path.moveTo(part[1], part[2]);
        case 1:
          path.lineTo(part[1], part[2]);
        case 2:
          path.cubicTo(part[1], part[2], part[3], part[4], part[5], part[6]);
        case 3:
          path.close();
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 108, size.height / 108);
    const box = Rect.fromLTWH(0, 0, 108, 108);
    final background = Paint()..color = brandDarkTeal;
    if (rounded) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(24)),
        background,
      );
    } else {
      canvas.drawRect(box, background);
    }
    canvas.translate(54, 54);
    canvas.scale(.84);
    canvas.translate(-54, -54);
    final line = Paint()
      ..color = brandWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_path(_camera), line);
    line
      ..color = brandMint
      ..strokeWidth = 2.8;
    canvas.drawPath(_path(_roof), line);
    canvas.drawPath(_path(_walls), line);
    canvas.drawPath(_path(_flash), line);
    final windowPaint = Paint()..color = brandWhite;
    if (size.width < 40) {
      canvas.drawRect(const Rect.fromLTWH(49, 64, 10, 10), windowPaint);
    } else {
      canvas.drawPath(_path(_windows), windowPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(AppBrandMarkPainter old) => old.rounded != rounded;
}
