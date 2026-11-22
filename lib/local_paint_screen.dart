import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'context_help.dart';
import 'design_palettes.dart';
import 'local_paint.dart';
import 'room_features.dart';
import 'wall_selection.dart';

enum _PaintTool { automatic, polygon, brush, erase, move }

class LocalPaintScreen extends StatefulWidget {
  final Uint8List source, before;
  final LocalPaintRecipe? initial;
  final LocalPaintRecipe? savedRecipe;
  final String roomTypeId;
  final Future<void> Function(LocalPaintRecipe) saveDraft;
  final Future<void> Function(PaintRenderResult, LocalPaintRecipe) saveVersion;
  final VoidCallback? requestAiFinish;
  const LocalPaintScreen({
    super.key,
    required this.source,
    required this.before,
    this.initial,
    this.savedRecipe,
    this.roomTypeId = 'other',
    required this.saveDraft,
    required this.saveVersion,
    this.requestAiFinish,
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
  _PaintTool tool = _PaintTool.automatic;
  double brushWidth = .035;
  bool busy = false, rendering = false, queued = false, loading = true;
  bool compare = false, showSelection = false, allowClose = false;
  bool strokeLimitWarned = false;
  bool selectingWall = false;
  double sensitivity = 28;
  String? error;
  Timer? previewTimer, draftTimer;
  Future<void> draftWrites = Future.value();
  PaintRenderResult? fullResult;
  int? fullRevision;
  bool get dirty => revision != savedRevision;
  PaintSurface get wall => recipe!.surfaces.isEmpty
      ? PaintSurface(name: 'Wall 1')
      : recipe!.surfaces[selected];

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
        sensitivity =
            initial.surfaces.firstOrNull?.marks
                .where((mark) => mark.region != null)
                .firstOrNull
                ?.region
                ?.sensitivity ??
            28;
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
      selected = next.surfaces.isEmpty
          ? 0
          : selected.clamp(0, next.surfaces.length - 1);
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
      change(
        recipe!.surfaces.isEmpty
            ? LocalPaintRecipe(
                width: recipe!.width,
                height: recipe!.height,
                surfaces: [next],
              )
            : recipe!.replaceSurface(selected, next),
      );
    } on FormatException {
      tell(
        'This selection is full. Finish the stroke or use Undo before adding more.',
      );
    }
  }

  bool get defaultSurfaceName =>
      RegExp(r'^(Wall|Floor|Splashback|Bathroom wall|Shower wall) \d+$')
          .hasMatch(wall.name);

  void applyWallTiles(LocalSurfaceKind kind, {bool shower = false}) {
    final bathroom = roomFeatureProfile(widget.roomTypeId) == 'bathroom';
    final name = shower
        ? 'Shower wall'
        : kind == LocalSurfaceKind.splashback
        ? 'Splashback'
        : bathroom
        ? 'Bathroom wall'
        : 'Wall';
    changeWall(
      wall.copyWith(
        kind: kind,
        finish: kind == LocalSurfaceKind.splashback
            ? LocalFinish.brickTiles
            : LocalFinish.rectangleTiles,
        tileSize: suggestedTileSize(
          kind,
          kind == LocalSurfaceKind.splashback
              ? LocalFinish.brickTiles
              : LocalFinish.rectangleTiles,
        ),
        name: defaultSurfaceName ? '$name ${selected + 1}' : wall.name,
        coverage: 1,
      ),
    );
    setState(() => showSelection = false);
  }

  Widget wallTileShortcuts() {
    final profile = roomFeatureProfile(widget.roomTypeId);
    final bathroom = profile == 'bathroom';
    return Wrap(
      spacing: 6,
      children: [
        ActionChip(
          avatar: const Icon(Icons.grid_view_outlined, size: 18),
          label: Text(bathroom ? 'Bathroom wall tiles' : 'Wall tiles'),
          tooltip:
              'Apply tiles to the selected wall area. The selection is reused.',
          onPressed: () => applyWallTiles(LocalSurfaceKind.wall),
        ),
        if (const ['kitchen', 'pantry', 'laundry'].contains(profile))
          ActionChip(
            label: const Text('Splashback tiles'),
            tooltip: 'Try subway tiles on the selected splashback. Change pattern or colour below.',
            onPressed: () => applyWallTiles(LocalSurfaceKind.splashback),
          ),
        if (const ['bathroom', 'ensuite'].contains(widget.roomTypeId))
          ActionChip(
            label: const Text('Shower wall tiles'),
            tooltip: 'Select the shower wall area first. Fittings outside the selection stay unchanged in this local preview.',
            onPressed: () =>
                applyWallTiles(LocalSurfaceKind.wall, shower: true),
          ),
      ],
    );
  }

  Future<void> selectWall(PaintPoint seed) async {
    if (busy || selectingWall || prepared == null) return;
    setState(() => selectingWall = true);
    try {
      final result = await compute(
        selectWallRegion,
        WallSelectionInput(prepared!.preview, seed, sensitivity: sensitivity),
      );
      if (!mounted) return;
      polygonIndex = null;
      changeWall(
        wall.copyWith(
          marks: [
            PaintMark(PaintMarkKind.region, [seed], region: result.region),
          ],
        ),
      );
      setState(() {
        panel = 1;
        showSelection = true;
      });
      if (result.pixels / (result.region.width * result.region.height) > .65) {
        tell(
          'Large area selected. Check the boundary; lower sensitivity if it includes other surfaces.',
        );
      }
    } on FormatException catch (failure) {
      tell(failure.message.toString());
    } catch (_) {
      tell(
        'This wall could not be selected. Try a clearer point or adjust sensitivity.',
      );
    } finally {
      if (mounted) setState(() => selectingWall = false);
    }
  }

  Future<void> removeWalls({required bool all}) async {
    if (busy || selectingWall || recipe!.surfaces.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          all ? 'Delete all surface layers?' : 'Delete ${wall.name}?',
        ),
        content: const Text(
          'This removes the working surface selection and finish. Original photos and saved versions stay unchanged. You can Undo while this editor is open.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final surfaces = [...recipe!.surfaces];
    if (all) {
      surfaces.clear();
    } else {
      surfaces.removeAt(selected);
    }
    polygonIndex = null;
    live = [];
    change(
      LocalPaintRecipe(
        width: recipe!.width,
        height: recipe!.height,
        surfaces: surfaces,
      ),
    );
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

  Future<void> save({bool finishWithAi = false}) async {
    if (busy || selectingWall || recipe == null) return;
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
      final revertingSavedPaint =
          widget.savedRecipe?.surfaces.any(
            (surface) => surface.marks.isNotEmpty && surface.coverage > 0,
          ) ??
          false;
      if (result.changedPixels == 0 && !revertingSavedPaint) {
        tell('Select a surface and choose a finish before saving a version.');
        return;
      }
      await widget.saveVersion(result, current);
      if (mounted) {
        if (finishWithAi) widget.requestAiFinish?.call();
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
    selected = next.surfaces.isEmpty
        ? 0
        : selected.clamp(0, next.surfaces.length - 1);
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
    setState(() => showSelection = false);
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
                        onTapUp:
                            (tool == _PaintTool.polygon ||
                                    tool == _PaintTool.automatic) &&
                                !compare &&
                                !busy &&
                                !selectingWall
                            ? (tap) {
                                final seed = point(tap.localPosition, size);
                                if (tool == _PaintTool.automatic) {
                                  unawaited(selectWall(seed));
                                } else {
                                  addCorner(seed);
                                }
                              }
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

  Widget controls() {
    final content = <Widget>[
      Text(
        'Local preview · no AI',
        style: Theme.of(context).textTheme.labelMedium,
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                        sensitivity =
                            wall.marks
                                .where((m) => m.region != null)
                                .firstOrNull
                                ?.region
                                ?.sensitivity ??
                            28;
                      }),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Add surface',
            onPressed: recipe!.surfaces.length >= 8
                ? null
                : () {
                    polygonIndex = null;
                    var number = recipe!.surfaces.length + 1;
                    while (recipe!.surfaces.any(
                      (wall) => wall.name == 'Wall $number',
                    )) {
                      number++;
                    }
                    change(
                      LocalPaintRecipe(
                        width: recipe!.width,
                        height: recipe!.height,
                        surfaces: [
                          ...recipe!.surfaces,
                          PaintSurface(name: 'Wall $number'),
                        ],
                      ),
                    );
                    setState(() {
                      selected = recipe!.surfaces.length - 1;
                      panel = 0;
                      tool = _PaintTool.automatic;
                    });
                  },
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Delete selected surface',
            onPressed: recipe!.surfaces.isEmpty
                ? null
                : () => removeWalls(all: false),
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'Delete all surfaces',
            onPressed: recipe!.surfaces.isEmpty
                ? null
                : () => removeWalls(all: true),
            icon: const Icon(Icons.layers_clear_outlined),
          ),
        ],
      ),
      Row(
        children: [
          for (final entry in {0: '1 Select area', 1: '2 Finish'}.entries)
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
              _PaintTool.automatic: (
                Icons.touch_app_outlined,
                'Tap to select surface',
              ),
              _PaintTool.polygon: (Icons.polyline_outlined, 'Surface outline'),
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
            const Text('Tap around a surface, then finish.'),
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
      if (panel == 0 && tool == _PaintTool.automatic) ...[
        const Text(
          'Tap a surface and check its boundary. Patterned floors may need the outline tool.',
        ),
        Text('Selection sensitivity ${sensitivity.round()}'),
        Slider(
          min: 8,
          max: 64,
          divisions: 28,
          value: sensitivity,
          onChanged: (value) => setState(() => sensitivity = value),
          onChangeEnd: (_) {
            final region = wall.marks
                .where((m) => m.region != null)
                .firstOrNull;
            if (region != null) unawaited(selectWall(region.points.single));
          },
        ),
      ],
      if (panel == 0 && (tool == _PaintTool.brush || tool == _PaintTool.erase))
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
      if (panel == 1) ...[
        wallTileShortcuts(),
        DropdownButton<LocalSurfaceKind>(
          isExpanded: true,
          value: wall.kind,
          hint: const Text('Surface'),
          items: [
            for (final kind in LocalSurfaceKind.values)
              DropdownMenuItem(
                value: kind,
                child: Text(localSurfaceLabels[kind]!),
              ),
          ],
          onChanged: (kind) {
            if (kind == null) return;
            changeWall(
              wall.copyWith(
                kind: kind,
                tileSize: wall.finish != LocalFinish.paint && kind != wall.kind
                    ? suggestedTileSize(kind, wall.finish)
                    : wall.tileSize,
                name: defaultSurfaceName
                    ? '${localSurfaceLabels[kind]} ${selected + 1}'
                    : wall.name,
              ),
            );
          },
        ),
        DropdownButton<LocalFinish>(
          isExpanded: true,
          value: wall.finish,
          hint: const Text('Finish'),
          items: [
            for (final finish in LocalFinish.values)
              DropdownMenuItem(
                value: finish,
                child: Text(localFinishLabels[finish]!),
              ),
          ],
          onChanged: (finish) {
            if (finish != null) {
              changeWall(
                wall.copyWith(
                  finish: finish,
                  tileSize:
                      wall.finish == LocalFinish.paint &&
                          finish != LocalFinish.paint
                      ? suggestedTileSize(wall.kind, finish)
                      : wall.tileSize,
                  coverage: finish == LocalFinish.paint ? wall.coverage : 1,
                ),
              );
              setState(() => showSelection = false);
            }
          },
        ),
        if (wall.finish != LocalFinish.paint)
          ExpansionTile(
            title: const Text('Tile layout & grout'),
            children: [
              const Text(
                'Approximate 2D layout, not a realistic material render. Finish with AI can refine material, scale and perspective; review its result.',
              ),
              Text('Pattern size ${(wall.tileSize * 100).round()}%'),
              Slider(
                min: .015,
                max: .5,
                value: wall.tileSize,
                onChanged: (v) => changeWall(wall.copyWith(tileSize: v)),
              ),
              Text('Pattern angle ${wall.tileAngle.round()}°'),
              Slider(
                min: 0,
                max: 180,
                divisions: 36,
                value: wall.tileAngle,
                onChanged: (v) => changeWall(wall.copyWith(tileAngle: v)),
              ),
              Wrap(
                spacing: 4,
                children: [
                  for (final entry in {
                    0xDED8CE: 'Warm grout',
                    0xF0F0EC: 'Light grout',
                    0x555550: 'Dark grout',
                  }.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: wall.groutRgb == entry.key,
                      onSelected: (_) =>
                          changeWall(wall.copyWith(groutRgb: entry.key)),
                    ),
                ],
              ),
            ],
          ),
      ],
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
                    onTap: () {
                      changeWall(wall.copyWith(rgb: colour.rgb));
                      setState(() => showSelection = false);
                    },
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
        Wrap(
          spacing: 6,
          children: [
            TextButton.icon(
              onPressed: customColour,
              icon: const Icon(Icons.color_lens_outlined),
              label: const Text('Custom colour'),
            ),
            if (widget.requestAiFinish != null)
              TextButton.icon(
                onPressed:
                    recipe!.surfaces.any(
                      (wall) =>
                          wall.coverage > 0 &&
                          wall.marks.any(
                            (mark) => mark.kind != PaintMarkKind.erase,
                          ),
                    )
                    ? () => save(finishWithAi: true)
                    : null,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Finish with AI'),
              ),
          ],
        ),
      if (panel == 1 && wall.marks.any((m) => m.region != null))
        TextButton.icon(
          onPressed: busy || selectingWall
              ? null
              : () {
                  changeWall(
                    wall.copyWith(
                      marks: [
                        for (final mark in wall.marks)
                          mark.region == null
                              ? mark
                              : PaintMark(
                                  mark.kind,
                                  mark.points,
                                  width: mark.width,
                                  region: extendWallSelectionEdge(mark.region!),
                                ),
                      ],
                    ),
                  );
                  setState(() => showSelection = true);
                },
          icon: const Icon(Icons.open_in_full),
          label: const Text('Extend selection edge'),
        ),
      if (panel == 1 && wall.marks.any((m) => m.region != null))
        TextButton.icon(
          onPressed: () => setState(() {
            panel = 0;
            tool = _PaintTool.automatic;
            showSelection = true;
          }),
          icon: const Icon(Icons.tune),
          label: const Text('Adjust surface boundary'),
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
              onChanged: (value) => changeWall(wall.copyWith(coverage: value)),
            ),
          ],
        ),
      Wrap(
        spacing: 6,
        children: [
          OutlinedButton.icon(
            onPressed: () => setState(() => compare = !compare),
            icon: const Icon(Icons.compare),
            label: Text(compare ? 'Show finishes' : 'Compare before'),
          ),
          if (panel == 0)
            TextButton(
              onPressed: wall.marks.isEmpty
                  ? null
                  : () {
                      polygonIndex = null;
                      changeWall(wall.copyWith(marks: []));
                    },
              child: const Text('Clear surface selection'),
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
                ? 'Saving finish draft…'
                : 'Finish draft saved · Save version adds it to Ideas'),
      ),
    ];
    return AbsorbPointer(
      absorbing: busy || selectingWall,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: LayoutBuilder(
          builder: (context, bounds) => bounds.maxHeight < 260
              ? ListView(padding: EdgeInsets.zero, children: content)
              : Column(
                  children: [
                    ...content.take(4),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: content.skip(4).toList(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: allowClose || (!busy && !selectingWall && !dirty),
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop || busy || selectingWall) return;
      if (await flush() && context.mounted && !dirty) Navigator.pop(context);
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Surface finishes'),
        actions: [
          IconButton(
            tooltip: 'Undo paint',
            onPressed: busy || selectingWall || undo.isEmpty
                ? null
                : () => history(true),
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo paint',
            onPressed: busy || selectingWall || redo.isEmpty
                ? null
                : () => history(false),
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: 'Save finish version',
            onPressed: busy || selectingWall || loading || recipe == null
                ? null
                : save,
            icon: const Icon(Icons.save_outlined),
          ),
          HelpIcon(
            title: 'Colours & tiles',
            message: 'Select a wall, floor or splashback and check its boundary. In Finish, use Wall tiles, kitchen Splashback tiles, or bathroom/Shower wall tiles shortcuts, then choose a pattern and colour. Add a separate surface layer to keep wall and floor choices independent. Changing colour or pattern reuses the same selection and makes no AI request. Selection uses connected colours and edges; similar surfaces can merge. Use sensitivity, outline or erase for difficult edges and patterned tiles. Tile scale and rotation are approximate 2D visual guidance, not measured installation dimensions or a product catalogue. Delete one surface or all layers, even after reopening. Finish with AI saves all local finishes and prepares one correction for review; only confirmed generation uses your paid AI connection. AI may change unselected details. Undo lasts for this editing session. Back keeps your draft; Save version preserves the original and approval. Colours are approximate.',
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
                if (busy || selectingWall || rendering)
                  const LinearProgressIndicator(),
                if (selectingWall) const Text('Selecting wall…'),
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
        if (mark.region != null) {
          final region = mark.region!;
          final shape = Path();
          for (var y = 0; y < region.height; y++) {
            var x = 0;
            while (x < region.width) {
              if (!region.contains(x, y)) {
                x++;
                continue;
              }
              final start = x;
              while (x < region.width && region.contains(x, y)) {
                x++;
              }
              shape.addRect(
                Rect.fromLTRB(
                  start * size.width / region.width,
                  y * size.height / region.height,
                  x * size.width / region.width,
                  (y + 1) * size.height / region.height,
                ),
              );
            }
          }
          canvas.drawPath(shape, Paint()..color = Colors.white);
          continue;
        }
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
