import 'package:material_ui/material_ui.dart';

const renoVisionOlive = Color(0xFF39491C);
const renoVisionCream = Color(0xFFFFF6E3);

// M / L / C / Z commands shared by Canvas, SVG and Android vector exports.
const _room = <List<double>>[
  [0, 27, 31],
  [1, 51, 44],
  [1, 69, 40],
  [1, 69, 45],
  [1, 54, 49],
  [1, 54, 71],
  [1, 84, 76],
  [1, 84, 81],
  [1, 27, 83],
  [3],
  [0, 32, 39],
  [1, 32, 76],
  [1, 49, 70],
  [1, 49, 48],
  [3],
];
const _sparkle = <List<double>>[
  [0, 78, 20],
  [2, 76, 29, 74, 31, 66, 33],
  [2, 74, 35, 76, 38, 78, 46],
  [2, 80, 38, 83, 35, 91, 33],
  [2, 83, 31, 80, 29, 78, 20],
  [3],
];

String _svgPath(List<List<double>> segments) => segments
    .map(
      (part) =>
          '${['M', 'L', 'C', 'Z'][part.first.toInt()]}${part.skip(1).map((n) => n.toStringAsFixed(0)).join(' ')}',
    )
    .join(' ');
String get renoVisionRoomPath => _svgPath(_room);
String get renoVisionSparklePath => _svgPath(_sparkle);

String renoVisionSvg() =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108">'
    '<rect width="108" height="108" fill="#39491C"/>'
    '<g transform="translate(54 54) scale(.84) translate(-54 -54)" fill="#FFF6E3" fill-rule="evenodd">'
    '<path d="$renoVisionRoomPath"/><path d="$renoVisionSparklePath"/></g></svg>';

class RenoVisionMark extends StatelessWidget {
  final double size;
  const RenoVisionMark({super.key, this.size = 28});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'RenoVision',
    image: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: const RenoVisionMarkPainter(rounded: true),
    ),
  );
}

class RenoVisionMarkPainter extends CustomPainter {
  final bool rounded;
  const RenoVisionMarkPainter({this.rounded = false});
  Path _path(List<List<double>> segments) {
    final path = Path()..fillType = PathFillType.evenOdd;
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
    final box = const Rect.fromLTWH(0, 0, 108, 108);
    final background = Paint()..color = renoVisionOlive;
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
    final foreground = Paint()..color = renoVisionCream;
    canvas.drawPath(_path(_room), foreground);
    canvas.drawPath(_path(_sparkle), foreground);
    canvas.restore();
  }

  @override
  bool shouldRepaint(RenoVisionMarkPainter old) => old.rounded != rounded;
}
