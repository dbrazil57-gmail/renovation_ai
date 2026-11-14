import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:image/image.dart' as img;

/// A deliberately limited prototype editor. Crops and annotated references
/// are saved as NEW image versions; they never alter the original bytes.
class FocusEditScreen extends StatefulWidget {
  final Uint8List bytes;
  final bool sketch;
  const FocusEditScreen({super.key, required this.bytes, required this.sketch});

  @override
  State<FocusEditScreen> createState() => _FocusEditScreenState();
}

class _FocusEditScreenState extends State<FocusEditScreen> {
  Rect? crop;
  Offset? start;
  final List<List<Offset>> strokes = [];
  bool processing = false;
  late final img.Image? decoded;

  @override
  void initState() {
    super.initState();
    decoded = img.decodeImage(widget.bytes);
  }

  Offset _normalise(Offset offset, Size size) => Offset(
    (offset.dx / size.width).clamp(0.0, 1.0),
    (offset.dy / size.height).clamp(0.0, 1.0),
  );

  Future<void> _save() async {
    if (processing) return;
    setState(() => processing = true);
    try {
      final original = decoded?.clone();
      if (original == null) {
        throw StateError(
          'Image format could not be decoded. Try a JPEG or PNG.',
        );
      }
      img.Image output = original;
      if (widget.sketch) {
        final brush = img.ColorRgba8(245, 112, 25, 230);
        for (final stroke in strokes) {
          for (var i = 1; i < stroke.length; i++) {
            img.drawLine(
              output,
              x1: (stroke[i - 1].dx * output.width).round(),
              y1: (stroke[i - 1].dy * output.height).round(),
              x2: (stroke[i].dx * output.width).round(),
              y2: (stroke[i].dy * output.height).round(),
              thickness: math.max(3, (output.width / 220).round()),
              color: brush,
            );
          }
        }
      } else {
        final selection = crop;
        if (selection == null ||
            selection.width < 0.04 ||
            selection.height < 0.04) {
          throw StateError(
            'Drag to select a rectangular part of the image first.',
          );
        }
        final x = (selection.left * output.width).floor();
        final y = (selection.top * output.height).floor();
        final width = math.max(1, (selection.width * output.width).floor());
        final height = math.max(1, (selection.height * output.height).floor());
        output = img.copyCrop(output, x: x, y: y, width: width, height: height);
      }
      // The JPEG encoder retains EXIF unless it is explicitly cleared.
      output.exif = img.ExifData();
      final bytes = Uint8List.fromList(img.encodeJpg(output, quality: 92));
      if (mounted) Navigator.pop(context, bytes);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = decoded;
    if (image == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit reference')),
        body: const Center(
          child: Text(
            'This image format is not supported by the editing engine.',
          ),
        ),
      );
    }
    final ratio = image.width / image.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sketch ? 'Sketch / mark up' : 'Crop / focus'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                widget.sketch
                    ? 'Draw directly over the image to guide the AI. The annotated copy is saved as a new version.'
                    : 'Drag a rectangular selection over the detail you want to focus on. This creates a new cropped reference; it does not replace the full-room image.',
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.min(720.0, constraints.maxWidth);
                  return Center(
                    child: SizedBox(
                      width: width,
                      child: AspectRatio(
                        aspectRatio: ratio,
                        child: LayoutBuilder(
                          builder: (context, imageConstraints) {
                            final canvasSize = Size(
                              imageConstraints.maxWidth,
                              imageConstraints.maxHeight,
                            );
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(widget.bytes, fit: BoxFit.fill),
                                  IgnorePointer(
                                    child: CustomPaint(
                                      painter: _OverlayPainter(
                                        crop: crop,
                                        strokes: strokes,
                                        sketch: widget.sketch,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    dragStartBehavior: DragStartBehavior.down,
                                    onPanStart: (details) {
                                      final pt = _normalise(
                                        details.localPosition,
                                        canvasSize,
                                      );
                                      setState(() {
                                        if (widget.sketch) {
                                          strokes.add([pt]);
                                        } else {
                                          start = pt;
                                          crop = Rect.fromPoints(pt, pt);
                                        }
                                      });
                                    },
                                    onPanUpdate: (details) {
                                      final pt = _normalise(
                                        details.localPosition,
                                        canvasSize,
                                      );
                                      setState(() {
                                        if (widget.sketch) {
                                          if (strokes.isNotEmpty) {
                                            strokes.last.add(pt);
                                          }
                                        } else if (start != null) {
                                          crop = Rect.fromPoints(start!, pt);
                                        }
                                      });
                                    },
                                    onPanEnd: (_) => start = null,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.sketch)
                    OutlinedButton.icon(
                      onPressed: strokes.isEmpty
                          ? null
                          : () => setState(() => strokes.removeLast()),
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo stroke'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      crop = null;
                      strokes.clear();
                    }),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset selection'),
                  ),
                  FilledButton.icon(
                    onPressed: processing ? null : _save,
                    icon: const Icon(Icons.save_alt),
                    label: Text(
                      processing ? 'Processing…' : 'Save as new version',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Stage 1 note: crop/markup produces a reference image. The app does not yet blend an edited crop back into the unchanged whole-room photo.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect? crop;
  final List<List<Offset>> strokes;
  final bool sketch;
  const _OverlayPainter({
    required this.crop,
    required this.strokes,
    required this.sketch,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!sketch && crop != null) {
      final r = Rect.fromLTRB(
        crop!.left * size.width,
        crop!.top * size.height,
        crop!.right * size.width,
        crop!.bottom * size.height,
      );
      canvas.drawRect(
        r,
        Paint()..color = Colors.tealAccent.withValues(alpha: .15),
      );
      final border = Paint()
        ..color = Colors.tealAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRect(r, border);
    }
    if (sketch) {
      final p = Paint()
        ..color = Colors.deepOrange
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      for (final points in strokes) {
        if (points.isEmpty) continue;
        final path = Path()
          ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
        for (final pt in points.skip(1)) {
          path.lineTo(pt.dx * size.width, pt.dy * size.height);
        }
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) => true;
}

class CompareScreen extends StatefulWidget {
  final Uint8List original;
  final Uint8List edited;
  const CompareScreen({
    super.key,
    required this.original,
    required this.edited,
  });

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  double amount = 0.5;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Before / after')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Slide to reveal the selected design against the original. Crops or changed camera angles will not align perfectly.',
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, bounds) {
                final width = bounds.maxWidth;
                const height = 420.0;
                return SizedBox(
                  height: height,
                  width: width,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(widget.original, fit: BoxFit.contain),
                      ClipRect(
                        clipper: _FractionClipper(amount),
                        child: Image.memory(widget.edited, fit: BoxFit.contain),
                      ),
                      Align(
                        alignment: Alignment(amount * 2 - 1, 0),
                        child: const VerticalDivider(
                          thickness: 3,
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Slider(
              value: amount,
              onChanged: (value) => setState(() => amount = value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [Text('Original'), Text('Selected design')],
            ),
          ],
        ),
      ),
    ),
  );
}

class _FractionClipper extends CustomClipper<Rect> {
  final double fraction;
  const _FractionClipper(this.fraction);
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);
  @override
  bool shouldReclip(covariant _FractionClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
