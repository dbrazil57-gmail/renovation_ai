import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import 'screen_toolbar.dart';

Future<void> openImageViewer(
  BuildContext context,
  Uint8List bytes, {
  required String title,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => ImageViewerScreen(bytes: bytes, title: title),
  ),
);

/// A lightweight preview; the viewer receives the full original image bytes.
class ExpandableImage extends StatelessWidget {
  final Uint8List bytes;
  final String title;
  final double height;
  final bool inlineZoom;
  const ExpandableImage({
    super.key,
    required this.bytes,
    required this.title,
    this.height = 260,
    this.inlineZoom = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.memory(
      bytes,
      fit: BoxFit.contain,
      cacheWidth: 1200,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
    void open() => openImageViewer(context, bytes, title: title);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Semantics(
                  button: true,
                  label: 'View $title full screen',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: open,
                    child: inlineZoom
                        ? InteractiveViewer(
                            minScale: 1,
                            maxScale: 5,
                            child: image,
                          )
                        : image,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton.filledTonal(
                    tooltip: 'Open image full screen',
                    onPressed: open,
                    icon: const Icon(Icons.fullscreen),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('Tap image to enlarge and zoom'),
        ),
      ],
    );
  }
}

/// Viewing only: no edits, file writes, provider calls or orientation locks.
class ImageViewerScreen extends StatefulWidget {
  final Uint8List bytes;
  final String title;
  const ImageViewerScreen({
    super.key,
    required this.bytes,
    required this.title,
  });
  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  final transform = TransformationController();
  Size viewport = Size.zero;
  Offset doubleTapPosition = Offset.zero;
  static const maxZoom = 8.0;

  void fit() => transform.value = Matrix4.identity();

  void zoom(double factor, {Offset? focalPoint}) {
    final current = transform.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(1.0, maxZoom);
    if (next == 1) {
      fit();
      return;
    }
    final focal = focalPoint ?? viewport.center(Offset.zero);
    final scene = transform.toScene(focal);
    transform.value = Matrix4.diagonal3Values(next, next, 1)
      ..setTranslationRaw(
        focal.dx - scene.dx * next,
        focal.dy - scene.dy * next,
        0,
      );
  }

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      leading: IconButton(
        tooltip: 'Close image viewer',
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        ListenableBuilder(
          listenable: transform,
          builder: (context, _) => ScreenToolbar(
            tools: [
              ScreenTool(
                ScreenAction.zoomOut,
                label: 'Zoom out',
                onPressed: transform.value.getMaxScaleOnAxis() <= 1
                    ? null
                    : () => zoom(1 / 1.5),
              ),
              ScreenTool(
                ScreenAction.zoomIn,
                label: 'Zoom in',
                onPressed: transform.value.getMaxScaleOnAxis() >= maxZoom
                    ? null
                    : () => zoom(1.5),
              ),
              ScreenTool(ScreenAction.fit, label: 'Fit image', onPressed: fit),
              ScreenTool.help(
                context,
                title: 'Image viewer',
                message: 'Pinch or use the zoom buttons, then drag to pan. Fit image resets the view. Double-tap zooms or fits. Enable Android Auto rotate and turn your phone sideways for a wider view. Viewing does not edit or save a new image.',
              ),
            ],
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, bounds) {
          final size = bounds.biggest;
          if (viewport != size) {
            viewport = size;
            // Refit after rotation/resizing rather than leave a zoomed photo off screen.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) fit();
            });
          }
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTapDown: (details) =>
                doubleTapPosition = details.localPosition,
            onDoubleTap: () => transform.value.getMaxScaleOnAxis() > 1
                ? fit()
                : zoom(2.5, focalPoint: doubleTapPosition),
            child: InteractiveViewer(
              key: const ValueKey('full-screen-image'),
              transformationController: transform,
              minScale: 1,
              maxScale: maxZoom,
              child: SizedBox.expand(
                child: Image.memory(
                  widget.bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  semanticLabel: widget.title,
                  frameBuilder: (context, child, frame, synchronous) =>
                      synchronous || frame != null
                      ? child
                      : Stack(
                          children: [
                            child,
                            const Center(
                              child: Text(
                                'Opening image…',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                  errorBuilder: (_, error, stack) => const Center(
                    child: Text(
                      'This image could not be displayed.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
    bottomNavigationBar: MediaQuery.sizeOf(context).height < 480
        ? null
        : const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Pinch to zoom · Drag to pan · Double-tap to zoom or fit\nTurn your phone sideways for a wider view (Auto rotate on).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
  );
}
