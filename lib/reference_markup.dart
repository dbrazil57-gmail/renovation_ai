import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

enum MarkTool { pen, line, arrow, rectangle, ellipse, note, select }

class ReferenceMark {
  final MarkTool tool;
  final List<Offset> points;
  final Color color;
  final double width;
  final String text;
  ReferenceMark({
    required this.tool,
    required List<Offset> points,
    required this.color,
    required this.width,
    this.text = '',
  }) : points = List.unmodifiable(points);
  ReferenceMark copy({
    List<Offset>? points,
    Color? color,
    double? width,
    String? text,
  }) => ReferenceMark(
    tool: tool,
    points: points ?? this.points,
    color: color ?? this.color,
    width: width ?? this.width,
    text: text ?? this.text,
  );

  Rect bounds(Size size) {
    if (tool == MarkTool.note) {
      final (painter, box) = noteLayout(size);
      painter.dispose();
      return box;
    }
    return Rect.fromLTRB(
      points.map((p) => p.dx).reduce(math.min) * size.width,
      points.map((p) => p.dy).reduce(math.min) * size.height,
      points.map((p) => p.dx).reduce(math.max) * size.width,
      points.map((p) => p.dy).reduce(math.max) * size.height,
    );
  }

  (TextPainter, Rect) noteLayout(Size size) {
    final font = math.min(size.width * .035, size.height * .10);
    final padding = font * .3;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: font,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * .65);
    final boxWidth = math.min(size.width, painter.width + padding * 2);
    final boxHeight = math.min(size.height, painter.height + padding * 2);
    final position = Offset(
      (points.first.dx * size.width).clamp(0, size.width - boxWidth).toDouble(),
      (points.first.dy * size.height)
          .clamp(0, size.height - boxHeight)
          .toDouble(),
    );
    return (painter, position & Size(boxWidth, boxHeight));
  }

  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = math.max(.7, width * size.width)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final first = Offset(
      points.first.dx * size.width,
      points.first.dy * size.height,
    );
    final last = Offset(
      points.last.dx * size.width,
      points.last.dy * size.height,
    );
    switch (tool) {
      case MarkTool.pen:
        if (points.length == 1) {
          canvas.drawCircle(first, p.strokeWidth / 2, Paint()..color = color);
        } else {
          final path = Path()..moveTo(first.dx, first.dy);
          for (final point in points.skip(1)) {
            path.lineTo(point.dx * size.width, point.dy * size.height);
          }
          canvas.drawPath(path, p);
        }
      case MarkTool.line:
        canvas.drawLine(first, last, p);
      case MarkTool.arrow:
        canvas.drawLine(first, last, p);
        final angle = math.atan2(last.dy - first.dy, last.dx - first.dx);
        final length = math.min(
          (last - first).distance * .4,
          math.max(p.strokeWidth * 4, size.width * .035),
        );
        for (final offset in [-.55, .55]) {
          canvas.drawLine(
            last,
            last -
                Offset(math.cos(angle + offset), math.sin(angle + offset)) *
                    length,
            p,
          );
        }
      case MarkTool.rectangle:
        canvas.drawRect(Rect.fromPoints(first, last), p);
      case MarkTool.ellipse:
        canvas.drawOval(Rect.fromPoints(first, last), p);
      case MarkTool.note:
        final (painter, box) = noteLayout(size);
        canvas.drawRRect(
          RRect.fromRectAndRadius(box, Radius.circular(size.width * .006)),
          Paint()
            ..color =
                (color.computeLuminance() > .5 ? Colors.black : Colors.white)
                    .withValues(alpha: .90),
        );
        painter.paint(
          canvas,
          box.topLeft +
              Offset(
                painter.text!.style!.fontSize! * .3,
                painter.text!.style!.fontSize! * .3,
              ),
        );
        painter.dispose();
      case MarkTool.select:
        break;
    }
  }
}

enum CropHandle {
  create,
  move,
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

Map<CropHandle, Offset> cropHandles(Rect rect) => {
  CropHandle.topLeft: rect.topLeft,
  CropHandle.top: rect.topCenter,
  CropHandle.topRight: rect.topRight,
  CropHandle.right: rect.centerRight,
  CropHandle.bottomRight: rect.bottomRight,
  CropHandle.bottom: rect.bottomCenter,
  CropHandle.bottomLeft: rect.bottomLeft,
  CropHandle.left: rect.centerLeft,
};

CropHandle cropHandleAt(Rect? rect, Offset point, Size size) {
  if (rect == null) return CropHandle.create;
  var result = CropHandle.create;
  var distance = 23.0;
  for (final handle in cropHandles(rect).entries) {
    final delta = handle.value - point;
    final pixels = Offset(
      delta.dx * size.width,
      delta.dy * size.height,
    ).distance;
    if (pixels < distance) {
      distance = pixels;
      result = handle.key;
    }
  }
  return result != CropHandle.create
      ? result
      : rect.contains(point)
      ? CropHandle.move
      : CropHandle.create;
}

Rect adjustCrop(Rect initial, CropHandle handle, Offset origin, Offset point) {
  if (handle == CropHandle.create) return Rect.fromPoints(origin, point);
  if (handle == CropHandle.move) {
    return initial.shift(
      Offset(
        (point.dx - origin.dx).clamp(-initial.left, 1 - initial.right),
        (point.dy - origin.dy).clamp(-initial.top, 1 - initial.bottom),
      ),
    );
  }
  const span = .04;
  final left = {
    CropHandle.left,
    CropHandle.topLeft,
    CropHandle.bottomLeft,
  }.contains(handle);
  final right = {
    CropHandle.right,
    CropHandle.topRight,
    CropHandle.bottomRight,
  }.contains(handle);
  final top = {
    CropHandle.top,
    CropHandle.topLeft,
    CropHandle.topRight,
  }.contains(handle);
  final bottom = {
    CropHandle.bottom,
    CropHandle.bottomLeft,
    CropHandle.bottomRight,
  }.contains(handle);
  return Rect.fromLTRB(
    left ? point.dx.clamp(0, initial.right - span) : initial.left,
    top ? point.dy.clamp(0, initial.bottom - span) : initial.top,
    right ? point.dx.clamp(initial.left + span, 1) : initial.right,
    bottom ? point.dy.clamp(initial.top + span, 1) : initial.bottom,
  );
}

class ReferenceOverlay extends CustomPainter {
  final Rect? crop;
  final List<ReferenceMark> marks;
  final ReferenceMark? live;
  final int? selected;
  ReferenceOverlay({this.crop, required this.marks, this.live, this.selected});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final mark in marks) {
      mark.paint(canvas, size);
    }
    live?.paint(canvas, size);
    if (selected != null && selected! < marks.length) {
      canvas.drawRect(
        marks[selected!].bounds(size).inflate(6),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (crop != null) {
      final r = Rect.fromLTRB(
        crop!.left * size.width,
        crop!.top * size.height,
        crop!.right * size.width,
        crop!.bottom * size.height,
      );
      final shade = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRect(r);
      canvas.drawPath(
        shade,
        Paint()..color = Colors.black.withValues(alpha: .45),
      );
      canvas.drawRect(
        r,
        Paint()
          ..color = Colors.tealAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      for (final point in cropHandles(r).values) {
        canvas.drawCircle(point, 7, Paint()..color = Colors.black54);
        canvas.drawCircle(point, 5.5, Paint()..color = Colors.white);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ReferenceOverlay oldDelegate) => true;
}
