import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:image/image.dart' as img;

import 'reference_markup.dart';
import 'screen_toolbar.dart';

Uint8List cropReference((Uint8List, Rect) input) {
  final decoded = img.decodeImage(input.$1);
  if (decoded == null) throw const FormatException('Unsupported image');
  var image = img.bakeOrientation(decoded);
  final rect = input.$2;
  image = img.copyCrop(
    image,
    x: (rect.left * image.width).floor(),
    y: (rect.top * image.height).floor(),
    width: math.max(1, (rect.width * image.width).floor()),
    height: math.max(1, (rect.height * image.height).floor()),
  );
  image.exif = img.ExifData();
  image.iccProfile = null;
  image.textData?.clear();
  return img.encodeJpg(image, quality: 92);
}

class _NoteDialog extends StatefulWidget {
  final String? initial;
  const _NoteDialog({this.initial});
  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController text = TextEditingController(
    text: widget.initial ?? '',
  );
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Add text note' : 'Edit text note'),
    content: SingleChildScrollView(
      child: TextField(
        controller: text,
        autofocus: true,
        maxLength: 100,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(labelText: 'Comment on the image'),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, text.text.trim()),
        child: const Text('Apply note'),
      ),
    ],
  );
}

class FocusEditScreen extends StatefulWidget {
  final Uint8List bytes;
  final bool sketch;
  const FocusEditScreen({super.key, required this.bytes, required this.sketch});
  @override
  State<FocusEditScreen> createState() => _FocusEditScreenState();
}

class _FocusEditScreenState extends State<FocusEditScreen> {
  Rect? crop, initialCrop;
  Offset? origin;
  CropHandle handle = CropHandle.create;
  List<ReferenceMark> marks = [];
  final undo = <List<ReferenceMark>>[], redo = <List<ReferenceMark>>[];
  List<ReferenceMark>? beforeDrag;
  ReferenceMark? live, dragging;
  int? selected;
  bool moved = false, processing = false, loading = true;
  MarkTool tool = MarkTool.pen;
  Color color = Colors.red;
  double width = .009, ratio = 1;
  String? loadError;
  Size canvasSize = Size.zero;
  ImageStream? previewStream;
  ImageStreamListener? previewListener;
  static const previewWidth = 1600;
  static const colors = {
    'Red': Colors.red,
    'Blue': Colors.blue,
    'Green': Colors.green,
    'Yellow': Colors.yellow,
    'White': Colors.white,
    'Black': Colors.black,
  };
  static const tools = {
    MarkTool.pen: 'Pen',
    MarkTool.line: 'Line',
    MarkTool.arrow: 'Arrow',
    MarkTool.rectangle: 'Rectangle',
    MarkTool.ellipse: 'Ellipse',
    MarkTool.note: 'Text note',
    MarkTool.select: 'Select / move',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      previewStream = ResizeImage.resizeIfNeeded(
        previewWidth,
        null,
        MemoryImage(widget.bytes),
      ).resolve(createLocalImageConfiguration(context));
      previewListener = ImageStreamListener(
        (info, _) {
          if (mounted) {
            setState(() {
              ratio = info.image.width / info.image.height;
              loading = false;
            });
          }
          info.dispose();
        },
        onError: (Object error, StackTrace? stack) {
          if (mounted) {
            setState(() {
              loading = false;
              loadError = 'This image could not be opened. Try a JPEG or PNG.';
            });
          }
        },
      );
      previewStream!.addListener(previewListener!);
    });
  }

  @override
  void dispose() {
    if (previewListener != null) {
      previewStream?.removeListener(previewListener!);
    }
    super.dispose();
  }

  Offset normalise(Offset p, Size size) =>
      Offset((p.dx / size.width).clamp(0, 1), (p.dy / size.height).clamp(0, 1));

  void commit(List<ReferenceMark> next, {int? selection}) => setState(() {
    undo.add(List.of(marks));
    redo.clear();
    marks = next;
    selected = selection;
  });

  int? hit(Offset point, Size size) {
    final pixels = Offset(point.dx * size.width, point.dy * size.height);
    for (var i = marks.length - 1; i >= 0; i--) {
      if (marks[i].bounds(size).inflate(12).contains(pixels)) return i;
    }
    return null;
  }

  void begin(Offset point, Size size) => setState(() {
    origin = point;
    moved = false;
    if (!widget.sketch) {
      initialCrop = crop;
      handle = cropHandleAt(crop, point, size);
      if (handle == CropHandle.create) crop = Rect.fromPoints(point, point);
    } else if (tool == MarkTool.select) {
      selected = hit(point, size);
      dragging = selected == null ? null : marks[selected!];
      beforeDrag = List.of(marks);
    } else if (tool != MarkTool.note) {
      live = ReferenceMark(
        tool: tool,
        points: [point],
        color: color,
        width: width,
      );
    }
  });

  void update(Offset point) {
    if (origin == null) return;
    setState(() {
      moved = true;
      if (!widget.sketch) {
        crop = adjustCrop(initialCrop ?? Rect.zero, handle, origin!, point);
      } else if (tool == MarkTool.select &&
          dragging != null &&
          selected != null) {
        final pixels = dragging!.bounds(canvasSize);
        final bounds = Rect.fromLTRB(
          pixels.left / canvasSize.width,
          pixels.top / canvasSize.height,
          pixels.right / canvasSize.width,
          pixels.bottom / canvasSize.height,
        );
        final delta = Offset(
          (point.dx - origin!.dx).clamp(-bounds.left, 1 - bounds.right),
          (point.dy - origin!.dy).clamp(-bounds.top, 1 - bounds.bottom),
        );
        marks[selected!] = dragging!.copy(
          points: dragging!.points.map((p) => p + delta).toList(),
        );
      } else if (live != null) {
        live = live!.copy(
          points: tool == MarkTool.pen
              ? [...live!.points, point]
              : [origin!, point],
        );
      }
    });
  }

  void end({bool cancel = false}) {
    if (origin == null) return;
    setState(() {
      if (cancel) {
        if (beforeDrag != null) marks = beforeDrag!;
        if (!widget.sketch) crop = initialCrop;
      } else if (live != null) {
        undo.add(List.of(marks));
        redo.clear();
        marks = [...marks, live!];
        selected = null;
      } else if (dragging != null && moved && beforeDrag != null) {
        undo.add(beforeDrag!);
        redo.clear();
      }
      if (!widget.sketch &&
          crop != null &&
          (crop!.width < .04 - 1e-9 || crop!.height < .04 - 1e-9)) {
        crop = null;
      }
      origin = null;
      live = null;
      dragging = null;
      beforeDrag = null;
    });
  }

  Future<void> note(Offset position, {int? index}) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) =>
          _NoteDialog(initial: index == null ? null : marks[index].text),
    );
    if (!mounted || value == null || value.isEmpty) return;
    if (index != null) {
      final next = List.of(marks);
      next[index] = next[index].copy(text: value);
      commit(next, selection: index);
    } else {
      var mark = ReferenceMark(
        tool: MarkTool.note,
        points: [position],
        color: color,
        width: width,
        text: value,
      );
      final box = mark.bounds(canvasSize);
      mark = mark.copy(
        points: [
          Offset(box.left / canvasSize.width, box.top / canvasSize.height),
        ],
      );
      commit([...marks, mark]);
    }
  }

  void changeColor(Color value) {
    color = value;
    if (tool == MarkTool.select && selected != null) {
      final next = List.of(marks);
      next[selected!] = next[selected!].copy(color: value);
      commit(next, selection: selected);
    } else {
      setState(() {});
    }
  }

  Future<Uint8List> renderMarkup() async {
    final codec = await ui.instantiateImageCodec(widget.bytes);
    ui.Image? image, rendered;
    ui.Picture? picture;
    try {
      image = (await codec.getNextFrame()).image;
      final size = Size(image.width.toDouble(), image.height.toDouble());
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..drawImage(image, Offset.zero, Paint());
      canvas.clipRect(Offset.zero & size);
      for (final mark in marks) {
        mark.paint(canvas, size);
      }
      picture = recorder.endRecording();
      rendered = await picture.toImage(image.width, image.height);
      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Image encoding failed');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      rendered?.dispose();
      picture?.dispose();
      image?.dispose();
      codec.dispose();
    }
  }

  Future<void> save() async {
    if (processing || loading || loadError != null) return;
    if ((!widget.sketch && crop == null) || (widget.sketch && marks.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.sketch
                ? 'Add a mark or note first.'
                : 'Drag a crop selection first.',
          ),
        ),
      );
      return;
    }
    setState(() => processing = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    try {
      final bytes = widget.sketch
          ? await renderMarkup()
          : await compute(cropReference, (widget.bytes, crop!));
      if (mounted) Navigator.pop(context, bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The reference could not be saved. Your original is unchanged; try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  void undoMark() => setState(() {
    redo.add(List.of(marks));
    marks = undo.removeLast();
    selected = null;
  });
  void redoMark() => setState(() {
    undo.add(List.of(marks));
    marks = redo.removeLast();
    selected = null;
  });
  void resetSelection() {
    if (widget.sketch) {
      if (marks.isNotEmpty) commit([]);
    } else {
      setState(() => crop = null);
    }
  }

  Widget editorTools() => ScreenToolbar(
    tools: [
      ScreenTool(
        ScreenAction.save,
        label: 'Save as new version',
        onPressed: processing || loading || loadError != null ? null : save,
      ),
      if (widget.sketch) ...[
        ScreenTool(
          ScreenAction.undo,
          label: 'Undo',
          onPressed: processing || undo.isEmpty ? null : undoMark,
        ),
        ScreenTool(
          ScreenAction.redo,
          label: 'Redo',
          onPressed: processing || redo.isEmpty ? null : redoMark,
        ),
      ],
      ScreenTool(
        ScreenAction.reset,
        label: widget.sketch ? 'Clear marks' : 'Reset selection',
        onPressed: processing || loading || loadError != null
            ? null
            : resetSelection,
      ),
      ScreenTool.help(
        context,
        title: widget.sketch ? 'Markup tools' : 'Crop tools',
        message: widget.sketch
            ? 'Draw multiple coloured marks, shapes and text notes. Select / move lets you reposition or remove marks and edit notes. Undo and Redo also work from the top toolbar. Save creates a new flattened reference; the original remains unchanged.'
            : 'Drag to draw a crop. Drag its corners or edges to resize, or drag inside to move it. Reset clears the box. Save creates a separate cropped reference without changing the original.',
      ),
    ],
  );

  Widget toolbar() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final entry in tools.entries)
            ChoiceChip(
              label: Text(entry.value),
              selected: tool == entry.key,
              onSelected: processing
                  ? null
                  : (_) => setState(() {
                      tool = entry.key;
                      selected = null;
                    }),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final entry in colors.entries)
            Tooltip(
              message: '${entry.key} ink',
              child: ChoiceChip(
                label: Text(entry.key),
                avatar: CircleAvatar(backgroundColor: entry.value, radius: 7),
                selected: color == entry.value,
                onSelected: processing ? null : (_) => changeColor(entry.value),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Line width:'),
          for (final entry in {
            .004: 'Fine',
            .009: 'Medium',
            .016: 'Bold',
          }.entries)
            ChoiceChip(
              label: Text(entry.value),
              selected: width == entry.key,
              onSelected: processing
                  ? null
                  : (_) {
                      setState(() => width = entry.key);
                      if (tool == MarkTool.select && selected != null) {
                        final next = List.of(marks);
                        next[selected!] = next[selected!].copy(width: width);
                        commit(next, selection: selected);
                      }
                    },
            ),
        ],
      ),
      const Text(
        'Text note: tap its position. Select / move: drag an existing mark; select a note to edit it.',
      ),
      if (selected != null)
        Wrap(
          spacing: 8,
          children: [
            if (marks[selected!].tool == MarkTool.note)
              TextButton(
                onPressed: processing
                    ? null
                    : () =>
                          note(marks[selected!].points.first, index: selected),
                child: const Text('Edit note'),
              ),
            TextButton.icon(
              onPressed: processing
                  ? null
                  : () {
                      final next = List.of(marks)..removeAt(selected!);
                      commit(next);
                    },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove selected'),
            ),
          ],
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (loading || loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.sketch ? 'Sketch / mark up' : 'Crop / focus'),
          actions: [editorTools()],
        ),
        body: Center(
          child: loading
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Preparing image preview…'),
                  ],
                )
              : Text(loadError!),
        ),
      );
    }
    return PopScope(
      canPop: !processing,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.sketch ? 'Sketch / mark up' : 'Crop / focus',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [editorTools()],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                if (processing)
                  const Column(
                    children: [
                      LinearProgressIndicator(),
                      Text('Saving a new reference at original resolution…'),
                    ],
                  ),
                Text(
                  widget.sketch
                      ? 'Add coloured marks, shapes and comments. Save creates a new annotated reference.'
                      : 'Drag to draw a crop. Drag corners or edges to resize it; drag inside to move it. Drag outside to start another crop.',
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) => Center(
                    child: SizedBox(
                      width: math.min(720, constraints.maxWidth),
                      child: AspectRatio(
                        aspectRatio: ratio,
                        child: LayoutBuilder(
                          builder: (context, bounds) {
                            final size = bounds.biggest;
                            canvasSize = size;
                            return ClipRect(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(
                                    widget.bytes,
                                    fit: BoxFit.fill,
                                    cacheWidth: previewWidth,
                                  ),
                                  IgnorePointer(
                                    child: CustomPaint(
                                      key: const ValueKey('reference-overlay'),
                                      painter: ReferenceOverlay(
                                        crop: widget.sketch ? null : crop,
                                        marks: marks,
                                        live: live,
                                        selected: selected,
                                      ),
                                    ),
                                  ),
                                  MediaQuery(
                                    // Short, deliberate drags should resize handles and move marks.
                                    data: MediaQuery.of(context).copyWith(
                                      gestureSettings:
                                          const DeviceGestureSettings(
                                            touchSlop: 6,
                                          ),
                                    ),
                                    child: GestureDetector(
                                      key: const ValueKey('reference-canvas'),
                                      behavior: HitTestBehavior.opaque,
                                      dragStartBehavior: DragStartBehavior.down,
                                      onPanStart: processing
                                          ? null
                                          : (d) => begin(
                                              normalise(d.localPosition, size),
                                              size,
                                            ),
                                      onPanUpdate: processing
                                          ? null
                                          : (d) => update(
                                              normalise(d.localPosition, size),
                                            ),
                                      onPanEnd: processing
                                          ? null
                                          : (_) => end(),
                                      onPanCancel: processing
                                          ? null
                                          : () => end(cancel: true),
                                      onTapUp: processing || !widget.sketch
                                          ? null
                                          : (d) {
                                              final point = normalise(
                                                d.localPosition,
                                                size,
                                              );
                                              if (tool == MarkTool.note) {
                                                note(point);
                                              } else if (tool ==
                                                  MarkTool.select) {
                                                setState(
                                                  () => selected = hit(
                                                    point,
                                                    size,
                                                  ),
                                                );
                                              } else if (tool == MarkTool.pen) {
                                                commit([
                                                  ...marks,
                                                  ReferenceMark(
                                                    tool: tool,
                                                    points: [point],
                                                    color: color,
                                                    width: width,
                                                  ),
                                                ]);
                                              }
                                            },
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
                const SizedBox(height: 14),
                if (widget.sketch) ...[
                  toolbar(),
                  const SizedBox(height: 12),
                  Text('${marks.length} marks / notes'),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.sketch) ...[
                      OutlinedButton.icon(
                        onPressed: processing || undo.isEmpty ? null : undoMark,
                        icon: const Icon(Icons.undo),
                        label: const Text('Undo'),
                      ),
                      OutlinedButton.icon(
                        onPressed: processing || redo.isEmpty ? null : redoMark,
                        icon: const Icon(Icons.redo),
                        label: const Text('Redo'),
                      ),
                    ],
                    OutlinedButton.icon(
                      onPressed: processing ? null : resetSelection,
                      icon: const Icon(Icons.restart_alt),
                      label: Text(
                        widget.sketch ? 'Clear marks' : 'Reset selection',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: processing ? null : save,
                      icon: const Icon(Icons.save_alt),
                      label: Text(
                        processing ? 'Processing…' : 'Save as new version',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.sketch
                      ? 'Colours and shapes are visual guidance, not an enforced AI mask. Saving flattens marks and notes into a new image; the original stays untouched.'
                      : 'The crop is saved separately. It does not replace the full-room image or automatically blend an AI edit back into it.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
