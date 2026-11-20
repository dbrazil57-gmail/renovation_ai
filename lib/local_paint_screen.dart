import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'context_help.dart';
import 'design_palettes.dart';
import 'local_paint.dart';

enum _PaintTool { polygon, brush, erase, move }

class LocalPaintScreen extends StatefulWidget {
  final Uint8List source, before;
  final LocalPaintRecipe? initial;
  final LocalPaintRecipe? savedRecipe;
  final Future<void> Function(LocalPaintRecipe) saveDraft;
  final Future<void> Function(PaintRenderResult, LocalPaintRecipe) saveVersion;
  const LocalPaintScreen({
    super.key,
    required this.source,
    required this.before,
    this.initial,
    this.savedRecipe,
    required this.saveDraft,
    required this.saveVersion,
  });
  @override
  State<LocalPaintScreen> createState() => _LocalPaintScreenState();
}

class _LocalPaintScreenState extends State<LocalPaintScreen>
    with WidgetsBindingObserver {
  LocalPaintRecipe? recipe;
  PaintPrepared? prepared;
  Uint8List? rendered, beforePreview;
  final undo = <LocalPaintRecipe>[], redo = <LocalPaintRecipe>[];
  final zoom = TransformationController();
  List<PaintPoint> live = [];
  int selected = 0, panel = 0, revision = 0, savedRevision = 0, serial = 0;
  int? polygonIndex;
  _PaintTool tool = _PaintTool.polygon;
  double brushWidth = .035;
  bool busy = false, rendering = false, queued = false, loading = true;
  bool compare = false, showSelection = false, allowClose = false;
  bool strokeLimitWarned = false;
  String? error;
  Timer? previewTimer, draftTimer;
  Future<void> draftWrites = Future.value();
  PaintRenderResult? fullResult;
  int? fullRevision;
  bool get dirty => revision != savedRevision;
  PaintSurface get wall => recipe!.surfaces[selected];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(load());
  }

  Future<void> load() async {
    try {
      final image = await compute(preparePaintImage, widget.source);
      final initial =
          widget.initial ?? LocalPaintRecipe.empty(image.width, image.height);
      if (initial.width != image.width || initial.height != image.height) {
        throw const FormatException(
          'The saved paint selection belongs to a different image size.',
        );
      }
      final before = identical(widget.source, widget.before)
          ? image.preview
          : (await compute(preparePaintImage, widget.before)).preview;
      if (!mounted) return;
      setState(() {
        prepared = image;
        beforePreview = before;
        recipe = initial;
        rendered = image.preview;
        loading = false;
      });
      requestPreview();
    } catch (failure) {
      if (mounted) {
        setState(() {
          loading = false;
          error = failure is FormatException
              ? failure.message.toString()
              : 'This image could not be opened for paint.';
        });
      }
    }
  }

  void tell(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void change(LocalPaintRecipe next, {bool remember = true}) {
    if (remember) {
      undo.add(recipe!);
      if (undo.length > 60) undo.removeAt(0);
      redo.clear();
    }
    setState(() {
      recipe = next;
      selected = selected.clamp(0, next.surfaces.length - 1);
      revision++;
      error = null;
      compare = false;
      fullResult = null;
    });
    draftTimer?.cancel();
    draftTimer = Timer(const Duration(milliseconds: 400), flush);
    requestPreview();
  }

  void changeWall(PaintSurface next) {
    try {
      change(recipe!.replaceSurface(selected, next));
    } on FormatException {
      tell(
        'This selection is full. Finish the stroke or use Undo before adding more.',
      );
    }
  }

  void requestPreview() {
    serial++;
    previewTimer?.cancel();
    previewTimer = Timer(const Duration(milliseconds: 130), renderPreview);
  }

  Future<void> renderPreview() async {
    previewTimer?.cancel();
    if (!mounted || recipe == null || prepared == null) return;
    if (rendering) {
      queued = true;
      return;
    }
    final version = serial, current = recipe!;
    setState(() => rendering = true);
    try {
      final result = await compute(
        renderLocalPaint,
        PaintRenderInput(prepared!.preview, current, preview: true),
      );
      if (mounted && version == serial) setState(() => rendered = result.bytes);
    } catch (_) {
      if (mounted) {
        tell(
          'Preview could not update. Your paint draft is retained; try another edit.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => rendering = false);
        if (queued || version != serial) {
          queued = false;
          unawaited(renderPreview());
        }
      }
    }
  }

  Future<bool> flush() async {
    draftTimer?.cancel();
    if (recipe == null || !dirty) return true;
    final current = recipe!, version = revision;
    final write = draftWrites
        .catchError((_) {})
        .then((_) => widget.saveDraft(current));
    draftWrites = write.catchError((_) {});
    try {
      await write;
      if (mounted) {
        setState(() {
          savedRevision = version;
          error = null;
        });
      }
      return true;
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Paint draft could not be saved. Keep this screen open and retry.',
        );
      }
      tell('Paint draft could not be saved. Keep this screen open and retry.');
      return false;
    }
  }

  Future<void> save() async {
    if (busy || recipe == null) return;
    setState(() => busy = true);
    try {
      if (!await flush() || !mounted) return;
      final current = recipe!, version = revision;
      final result = fullResult != null && fullRevision == version
          ? fullResult!
          : await compute(
              renderLocalPaint,
              PaintRenderInput(widget.source, current),
            );
      fullResult = result;
      fullRevision = version;
      if (result.changedPixels == 0) {
        tell('Select a wall and choose a colour before saving a version.');
        return;
      }
      await widget.saveVersion(result, current);
      if (mounted) {
        setState(() => allowClose = true);
        Navigator.pop(context, true);
      }
    } catch (_) {
      tell(
        'Paint version could not be saved. Your draft is retained; tap Save version to retry.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void history(bool back) {
    final from = back ? undo : redo, to = back ? redo : undo;
    if (from.isEmpty) return;
    to.add(recipe!);
    final next = from.removeLast();
    selected = selected.clamp(0, next.surfaces.length - 1);
    polygonIndex = null;
    live = [];
    change(next, remember: false);
  }

  PaintPoint point(Offset position, Size size) => PaintPoint(
    (position.dx / size.width).clamp(0, 1),
    (position.dy / size.height).clamp(0, 1),
  );
  void addCorner(PaintPoint point) {
    if (busy) return;
    final marks = [...wall.marks];
    if (polygonIndex == null &&
        marks.isNotEmpty &&
        marks.last.kind == PaintMarkKind.polygon &&
        marks.last.points.length < 3) {
      polygonIndex = marks.length - 1;
    }
    final index = polygonIndex;
    if (index != null && index < marks.length) {
      if (marks[index].points.length >= 64) {
        tell('Finish this wall selection before adding another.');
        return;
      }
      marks[index] = PaintMark(PaintMarkKind.polygon, [
        ...marks[index].points,
        point,
      ]);
    } else {
      polygonIndex = marks.length;
      marks.add(PaintMark(PaintMarkKind.polygon, [point]));
    }
    changeWall(wall.copyWith(marks: marks));
  }

  void endStroke() {
    if (live.isEmpty || busy) return;
    final mark = PaintMark(
      tool == _PaintTool.erase ? PaintMarkKind.erase : PaintMarkKind.brush,
      live,
      width: brushWidth,
    );
    setState(() => live = []);
    changeWall(wall.copyWith(marks: [...wall.marks, mark]));
  }

  Future<void> customColour() async {
    var input = wall.rgb.toRadixString(16).padLeft(6, '0').toUpperCase();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Custom paint colour'),
        content: TextFormField(
          initialValue: input,
          onChanged: (value) => input = value,
          maxLength: 7,
          decoration: const InputDecoration(
            labelText: 'Hex colour',
            hintText: '#RRGGBB',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, input),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final text = result.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(text)) {
      tell('Use six hexadecimal digits, for example #98A58E.');
      return;
    }
    changeWall(wall.copyWith(rgb: int.parse(text, radix: 16)));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(flush());
    }
  }

  @override
  void dispose() {
    previewTimer?.cancel();
    draftTimer?.cancel();
    zoom.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget image() => ColoredBox(
    color: Colors.black,
    child: Center(
      child: prepared == null
          ? const CircularProgressIndicator()
          : AspectRatio(
              aspectRatio: prepared!.width / prepared!.height,
              child: ClipRect(
                child: InteractiveViewer(
                  transformationController: zoom,
                  minScale: 1,
                  maxScale: 6,
                  panEnabled: tool == _PaintTool.move,
                  scaleEnabled: tool == _PaintTool.move,
                  child: LayoutBuilder(
                    builder: (context, bounds) {
                      final size = bounds.biggest;
                      return GestureDetector(
                        key: const ValueKey('paint-canvas'),
                        behavior: HitTestBehavior.opaque,
                        onTapUp: tool == _PaintTool.polygon && !compare
                            ? (tap) => addCorner(point(tap.localPosition, size))
                            : null,
                        onPanStart:
                            (tool == _PaintTool.brush ||
                                    tool == _PaintTool.erase) &&
                                !compare &&
                                !busy
                            ? (drag) => setState(() {
                                live = [point(drag.localPosition, size)];
                                strokeLimitWarned = false;
                              })
                            : null,
                        onPanUpdate:
                            (tool == _PaintTool.brush ||
                                    tool == _PaintTool.erase) &&
                                !compare &&
                                !busy
                            ? (drag) {
                                if (live.length < 512) {
                                  setState(
                                    () => live = [
                                      ...live,
                                      point(drag.localPosition, size),
                                    ],
                                  );
                                } else if (!strokeLimitWarned) {
                                  strokeLimitWarned = true;
                                  tell(
                                    'Finish this stroke, then draw another to continue.',
                                  );
                                }
                              }
                            : null,
                        onPanEnd:
                            (tool == _PaintTool.brush ||
                                    tool == _PaintTool.erase) &&
                                !compare
                            ? (_) => endStroke()
                            : null,
                        onPanCancel:
                            (tool == _PaintTool.brush ||
                                    tool == _PaintTool.erase) &&
                                !compare
                            ? () => setState(() => live = [])
                            : null,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              compare ? beforePreview! : rendered!,
                              fit: BoxFit.fill,
                              gaplessPlayback: true,
                            ),
                            if (!compare)
                              CustomPaint(
                                painter: _PaintOverlay(
                                  marks: showSelection ? wall.marks : const [],
                                  live: live,
                                  erasing: tool == _PaintTool.erase,
                                  width: brushWidth,
                                  polygon: polygonIndex == null
                                      ? null
                                      : wall.marks
                                            .elementAtOrNull(polygonIndex!)
                                            ?.points,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
    ),
  );

  Widget controls() => AbsorbPointer(
    absorbing: busy,
    child: ListView(
      padding: const EdgeInsets.all(10),
      children: [
        const Text('Local paint · no AI requests'),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < recipe!.surfaces.length; i++)
                ChoiceChip(
                  label: Text(recipe!.surfaces[i].name),
                  selected: selected == i,
                  onSelected: (_) => setState(() {
                    selected = i;
                    polygonIndex = null;
                    live = [];
                  }),
                ),
              IconButton(
                tooltip: 'Add wall',
                onPressed: recipe!.surfaces.length >= 8
                    ? null
                    : () {
                        polygonIndex = null;
                        change(
                          LocalPaintRecipe(
                            width: recipe!.width,
                            height: recipe!.height,
                            surfaces: [
                              ...recipe!.surfaces,
                              PaintSurface(
                                name: 'Wall ${recipe!.surfaces.length + 1}',
                              ),
                            ],
                          ),
                        );
                        setState(() => selected = recipe!.surfaces.length - 1);
                      },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Row(
          children: [
            for (final entry in {
              0: '1 Select area',
              1: '2 Paint colour',
            }.entries)
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => panel = entry.key),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontWeight: panel == entry.key
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (panel == 0)
          Wrap(
            spacing: 3,
            children: [
              for (final entry in {
                _PaintTool.polygon: (Icons.polyline_outlined, 'Wall outline'),
                _PaintTool.brush: (Icons.brush_outlined, 'Paint brush'),
                _PaintTool.erase: (Icons.auto_fix_normal, 'Erase selection'),
                _PaintTool.move: (Icons.pan_tool_outlined, 'Move / zoom'),
              }.entries)
                IconButton.filledTonal(
                  tooltip: entry.value.$2,
                  isSelected: tool == entry.key,
                  onPressed: () => setState(() {
                    tool = entry.key;
                    polygonIndex = null;
                    live = [];
                  }),
                  icon: Icon(entry.value.$1),
                ),
              IconButton(
                tooltip: 'Show selection',
                isSelected: showSelection,
                onPressed: () => setState(() => showSelection = !showSelection),
                icon: const Icon(Icons.select_all),
              ),
            ],
          ),
        if (panel == 0 && tool == _PaintTool.polygon)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tap around a wall, then finish.'),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: polygonIndex == null
                      ? null
                      : () => setState(() => polygonIndex = null),
                  child: const Text('Finish outline'),
                ),
              ),
            ],
          ),
        if (panel == 0 &&
            (tool == _PaintTool.brush || tool == _PaintTool.erase))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Brush size'),
              Slider(
                min: .008,
                max: .15,
                value: brushWidth,
                onChanged: (value) => setState(() => brushWidth = value),
              ),
            ],
          ),
        if (panel == 1)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final colour in {
                  for (final palette in designPalettes)
                    for (final colour in palette.colours) colour.rgb: colour,
                }.values)
                  Tooltip(
                    message: '${colour.name} ${colour.hex}',
                    child: InkWell(
                      onTap: () => changeWall(wall.copyWith(rgb: colour.rgb)),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(5),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF000000 | colour.rgb),
                            border: Border.all(
                              width: wall.rgb == colour.rgb ? 3 : 1,
                              color: wall.rgb == colour.rgb
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (panel == 1)
          TextButton.icon(
            onPressed: customColour,
            icon: const Icon(Icons.color_lens_outlined),
            label: const Text('Custom colour'),
          ),
        if (panel == 1 && widget.savedRecipe != null)
          TextButton(
            onPressed: widget.savedRecipe == null
                ? null
                : () {
                    polygonIndex = null;
                    change(widget.savedRecipe!);
                  },
            child: const Text('Use saved version colours and selection'),
          ),
        if (panel == 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Coverage ${(wall.coverage * 100).round()}%'),
              Slider(
                min: 0,
                max: 1,
                divisions: 20,
                value: wall.coverage,
                onChanged: (value) =>
                    changeWall(wall.copyWith(coverage: value)),
              ),
            ],
          ),
        Wrap(
          spacing: 6,
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => compare = !compare),
              icon: const Icon(Icons.compare),
              label: Text(compare ? 'Show painted' : 'Compare before'),
            ),
            if (panel == 0)
              TextButton(
                onPressed: wall.marks.isEmpty
                    ? null
                    : () {
                        polygonIndex = null;
                        changeWall(wall.copyWith(marks: []));
                      },
                child: const Text('Clear wall selection'),
              ),
            TextButton(
              onPressed: () async {
                await flush();
              },
              child: const Text('Save draft'),
            ),
          ],
        ),
        Text(
          error ??
              (dirty
                  ? 'Saving paint draft…'
                  : 'Paint draft saved · Save version adds it to Ideas'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: allowClose || (!busy && !dirty),
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop || busy) return;
      if (await flush() && context.mounted && !dirty) Navigator.pop(context);
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Paint walls'),
        actions: [
          IconButton(
            tooltip: 'Undo paint',
            onPressed: busy || undo.isEmpty ? null : () => history(true),
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo paint',
            onPressed: busy || redo.isEmpty ? null : () => history(false),
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: 'Save paint version',
            onPressed: busy || loading || recipe == null ? null : save,
            icon: const Icon(Icons.save_outlined),
          ),
          HelpIcon(
            title: 'Local paint',
            message: 'Select a wall with an outline or brush. Erase windows, trim and foreground objects from the selection. Use Move / zoom to magnify, then switch back to a drawing tool. Colour changes run locally without AI. Existing shadows and texture guide the preview; it is not an exact paint-brand match. Back keeps your draft; Save version adds a new image without changing the original or approving it.',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : recipe == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(error!),
              ),
            )
          : Column(
              children: [
                if (busy || rendering) const LinearProgressIndicator(),
                if (busy) const Text('Saving full-resolution paint version…'),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, bounds) => bounds.maxWidth > 650
                        ? Row(
                            children: [
                              Expanded(child: image()),
                              SizedBox(width: 300, child: controls()),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(child: image()),
                              SizedBox(
                                height: math.min(290, bounds.maxHeight * .48),
                                child: controls(),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    ),
  );
}

class _PaintOverlay extends CustomPainter {
  final List<PaintMark> marks;
  final List<PaintPoint> live;
  final List<PaintPoint>? polygon;
  final bool erasing;
  final double width;
  _PaintOverlay({
    required this.marks,
    required this.live,
    required this.erasing,
    required this.width,
    this.polygon,
  });
  Path path(List<PaintPoint> points, Size size) {
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.x * size.width, points.first.y * size.height);
      for (final point in points.skip(1)) {
        path.lineTo(point.x * size.width, point.y * size.height);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (marks.isNotEmpty) {
      canvas.saveLayer(Offset.zero & size, Paint());
      for (final mark in marks) {
        final paint = Paint()
          ..color = Colors.white
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = mark.width * math.min(size.width, size.height)
          ..style = mark.kind == PaintMarkKind.polygon
              ? PaintingStyle.fill
              : PaintingStyle.stroke
          ..blendMode = mark.kind == PaintMarkKind.erase
              ? BlendMode.clear
              : BlendMode.srcOver;
        if (mark.kind == PaintMarkKind.polygon && mark.points.length < 3) {
          continue;
        }
        final shape = path(mark.points, size);
        if (mark.kind == PaintMarkKind.polygon) shape.close();
        if (mark.points.length == 1) {
          canvas.drawCircle(
            Offset(
              mark.points.first.x * size.width,
              mark.points.first.y * size.height,
            ),
            paint.strokeWidth / 2,
            paint..style = PaintingStyle.fill,
          );
        } else {
          canvas.drawPath(shape, paint);
        }
      }
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Colors.cyan.withValues(alpha: .25)
          ..blendMode = BlendMode.srcIn,
      );
      canvas.restore();
    }
    if (polygon != null && polygon!.isNotEmpty) {
      canvas.drawPath(
        path(polygon!, size),
        Paint()
          ..color = Colors.cyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      for (final point in polygon!) {
        canvas.drawCircle(
          Offset(point.x * size.width, point.y * size.height),
          4,
          Paint()..color = Colors.cyan,
        );
      }
    }
    if (live.isNotEmpty) {
      canvas.drawPath(
        path(live, size),
        Paint()
          ..color = (erasing ? Colors.red : Colors.cyan).withValues(alpha: .6)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width * math.min(size.width, size.height),
      );
    }
  }

  @override
  bool shouldRepaint(_PaintOverlay oldDelegate) => true;
}
