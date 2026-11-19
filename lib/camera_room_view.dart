import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'exit_guard.dart';
import 'models.dart';
import 'room_camera.dart';
import 'store.dart';

/// Resolve a design to its saved camera/photo source, never a different view.
/// Older versions with no recorded source cannot safely be aligned.
String? roomPhotoForDesign(
  RenovationRoom room,
  Iterable<DesignVersion> versions,
  String? designId,
) {
  final available = {
    for (final d in versions.where((d) => d.roomId == room.id && !d.deleted))
      d.id: d,
  };
  final visited = <String>{};
  var current = available[designId];
  while (current != null && visited.add(current.id)) {
    // Crop/markup/import records have no reliable full-frame geometry. Do not
    // treat their descendants as camera renders merely via a parent link.
    if (current.aiProvider == null) return null;
    final source = current.sourceImageId;
    if (source != null) {
      if (room.photoIds.contains(source)) return source;
      final sources = available.values.where((d) => d.imageId == source);
      current = sources.isEmpty ? null : sources.first;
    } else {
      current = available[current.parentId];
    }
  }
  return null;
}

List<DesignVersion> cameraDesignsForPhoto(
  RenovationRoom room,
  List<DesignVersion> versions,
  String photoId,
) => versions
    .where(
      (d) =>
          !d.deleted &&
          d.aiProvider != null &&
          roomPhotoForDesign(room, versions, d.id) == photoId,
    )
    .toList();

/// A captured still is redesigned through the existing, consented AI workflow.
/// The live blend is deliberately manual: there is no pose tracking or video AI.
class CameraRoomView extends StatefulWidget {
  final RenovisionStore store;
  final String roomId;
  final String? initialPhotoId, initialDesignId;
  final RoomCameraFeed? feed;
  final WidgetBuilder? settingsBuilder;
  final Widget Function(String? photoId)? liveDesignBuilder;
  final Widget Function(String photoId, ValueChanged<String?> onSelected)
  workspace;
  const CameraRoomView({
    super.key,
    required this.store,
    required this.roomId,
    required this.workspace,
    this.initialPhotoId,
    this.initialDesignId,
    this.feed,
    this.settingsBuilder,
    this.liveDesignBuilder,
  });
  @override
  State<CameraRoomView> createState() => _CameraRoomViewState();
}

class _CameraRoomViewState extends State<CameraRoomView>
    with WidgetsBindingObserver {
  late final RoomCameraFeed feed = widget.feed ?? DeviceRoomCamera();
  late final PageExitGuard exitGuard;
  late String photoId;
  String? designId, message;
  Uint8List? pendingCapture;
  bool live = true, busy = false, designing = false, aligned = false;
  bool alignOriginal = true;
  double blend = .5;
  RenovationRoom get room => widget.store.roomById(widget.roomId)!;
  List<DesignVersion> get designs =>
      cameraDesignsForPhoto(room, widget.store.designsFor(room.id), photoId);
  DesignVersion? get design {
    final matches = designs.where((d) => d.id == designId);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  void initState() {
    super.initState();
    photoId = room.photoIds.contains(widget.initialPhotoId)
        ? widget.initialPhotoId!
        : room.primaryId;
    designId = widget.initialDesignId;
    if (design == null) designId = designs.firstOrNull?.id;
    exitGuard = createPageExitGuard(() {});
    widget.store.addListener(_changed);
    widget.store.documents.addListener(_changed);
    feed.addListener(_feedChanged);
    WidgetsBinding.instance.addObserver(this);
    unawaited(feed.start());
  }

  void _changed() {
    _pendingChanged();
    if (mounted) setState(() {});
  }

  void _feedChanged() {
    if (!mounted) return;
    setState(() {
      if (feed.phase != RoomCameraPhase.ready) aligned = false;
    });
  }

  void _pendingChanged() => exitGuard.setPending(
    busy ||
        pendingCapture != null ||
        widget.store.documents.hasPending(room.projectId),
  );
  Future<void> _stop() async {
    try {
      await feed.stop();
    } catch (_) {
      /* Preview can be retried. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (live && !designing && pendingCapture == null && !busy) {
        unawaited(feed.start());
      }
    } else if (!(state == AppLifecycleState.inactive &&
        feed.phase == RoomCameraPhase.opening)) {
      if (mounted) setState(() => aligned = false);
      unawaited(_stop());
    }
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() => aligned = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.store.removeListener(_changed);
    widget.store.documents.removeListener(_changed);
    feed.removeListener(_feedChanged);
    exitGuard.dispose();
    feed.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (busy ||
        designing ||
        room.photoIds.length >= RenovisionStore.maxRoomPhotos) {
      return;
    }
    setState(() {
      busy = true;
      message = 'Capturing photo…';
      aligned = false;
    });
    _pendingChanged();
    try {
      final bytes = await feed.capture();
      validateRoomCapture(bytes);
      if (!mounted) return;
      setState(() {
        pendingCapture = bytes;
        live = false;
        message = 'Saving capture…';
      });
      _pendingChanged();
      await _stop();
      await _saveCapture();
    } catch (_) {
      if (mounted) {
        setState(
          () => message = pendingCapture == null
              ? 'Photo could not be captured. Retry the camera.'
              : 'Capture has not saved. Keep this screen open and retry saving.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        _pendingChanged();
      }
    }
  }

  Future<void> _saveCapture() async {
    final bytes = pendingCapture;
    if (bytes == null) return;
    final ids = await widget.store.addRoomPhotos(room.id, [bytes]);
    if (!mounted) return;
    setState(() {
      photoId = ids.single;
      designId = null;
      pendingCapture = null;
      message = 'Capture saved in this room. Design this view when ready.';
    });
    _pendingChanged();
  }

  Future<void> _retrySave() async {
    if (busy) return;
    setState(() {
      busy = true;
      message = 'Saving capture…';
    });
    _pendingChanged();
    try {
      await _saveCapture();
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Capture has not saved. Retry saving or discard it.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        _pendingChanged();
      }
    }
  }

  Future<bool> _discard() async {
    if (busy) return false;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unsaved capture?'),
        content: const Text(
          'This photo could not be saved. Existing room photos and designs are safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep capture'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard capture'),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) return false;
    setState(() {
      pendingCapture = null;
      message = null;
    });
    _pendingChanged();
    return true;
  }

  Future<void> _changeMode(bool nextLive) async {
    if (busy || designing || pendingCapture != null) return;
    setState(() {
      live = nextLive;
      aligned = false;
      alignOriginal = true;
    });
    if (live) {
      await feed.start();
    } else {
      await _stop();
    }
  }

  Future<void> _designView() async {
    if (busy || designing || pendingCapture != null) return;
    setState(() {
      designing = true;
      aligned = false;
      live = false;
    });
    await _stop();
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => widget.workspace(photoId, (id) {
          if (mounted && designs.any((d) => d.id == id)) {
            setState(() => designId = id);
          }
        }),
      ),
    );
    if (!mounted) return;
    setState(() {
      designing = false;
      if (design == null) designId = designs.firstOrNull?.id;
      message = design == null
          ? 'No design saved for this view yet.'
          : 'Design saved. Compare it here or align a live overlay.';
    });
  }

  Future<void> _settings() async {
    if (busy || designing || pendingCapture != null) return;
    setState(() {
      designing = true;
      aligned = false;
    });
    await _stop();
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: widget.settingsBuilder!),
    );
    if (!mounted) return;
    setState(() => designing = false);
    if (live) await feed.start();
  }

  Future<void> _liveDesign({bool useSavedView = false}) async {
    if (busy ||
        designing ||
        pendingCapture != null ||
        widget.liveDesignBuilder == null) {
      return;
    }
    setState(() {
      designing = true;
      aligned = false;
    });
    try {
      if (widget.store.documents.hasPending(room.projectId)) {
        await widget.store.documents.save(room.projectId);
      }
      await _stop();
      if (mounted) {
        await Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                widget.liveDesignBuilder!(useSavedView ? photoId : null),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'Save the project file successfully before starting Live design.',
        );
        if (live) await feed.start();
      }
    } finally {
      if (mounted) setState(() => designing = false);
    }
  }

  Widget _image(Uint8List bytes) => Image.memory(
    bytes,
    fit: BoxFit.contain,
    gaplessPlayback: true,
    errorBuilder: (_, _, _) => const Center(
      child: Text('Photo unavailable', style: TextStyle(color: Colors.white)),
    ),
  );

  Widget _canvas() {
    final source = pendingCapture ?? widget.store.imageFor(photoId);
    final result = design == null
        ? null
        : widget.store.imageFor(design!.imageId);
    return ColoredBox(
      color: const Color(0xFF191A17),
      child: LayoutBuilder(
        builder: (context, size) => Stack(
          fit: StackFit.expand,
          children: [
            if (live)
              RoomCameraSurface(feed: feed)
            else if (source != null)
              _image(source),
            if (live && aligned && source != null)
              IgnorePointer(
                child: Opacity(
                  opacity: blend,
                  child: _image(
                    alignOriginal || result == null ? source : result,
                  ),
                ),
              ),
            if (!live && result != null && pendingCapture == null)
              ClipRect(clipper: _RevealClipper(blend), child: _image(result)),
            if (!live && result != null && pendingCapture == null)
              Positioned(
                left: (size.maxWidth - 2) * blend,
                top: 0,
                bottom: 0,
                width: 2,
                child: const IgnorePointer(
                  child: ColoredBox(color: Colors.white70),
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: IgnorePointer(
                child: Text(
                  live
                      ? (aligned
                            ? 'Manual overlay · phone must stay still'
                            : 'Live camera · on device')
                      : (pendingCapture != null
                            ? 'Unsaved capture'
                            : result == null
                            ? 'Saved room photo'
                            : 'Captured before / design after'),
                  style: const TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls() => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              label: Text('Live view'),
              icon: Icon(Icons.videocam_outlined),
            ),
            ButtonSegment(
              value: false,
              label: Text('Compare'),
              icon: Icon(Icons.compare),
            ),
          ],
          selected: {live},
          onSelectionChanged: busy || pendingCapture != null
              ? null
              : (values) => _changeMode(values.single),
        ),
        const SizedBox(height: 8),
        if (pendingCapture != null) ...[
          FilledButton(
            onPressed: busy ? null : _retrySave,
            child: const Text('Retry saving capture'),
          ),
          TextButton(
            onPressed: busy ? null : _discard,
            child: const Text('Discard unsaved capture'),
          ),
        ] else ...[
          DropdownButtonFormField<String>(
            key: ValueKey('camera-photo-$photoId'),
            initialValue: photoId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Saved view'),
            items: [
              for (var i = 0; i < room.photoIds.length; i++)
                DropdownMenuItem(
                  value: room.photoIds[i],
                  child: Text(
                    'View ${i + 1}${room.photoIds[i] == room.originalId ? ' · original' : ''}',
                  ),
                ),
            ],
            onChanged: busy
                ? null
                : (id) {
                    if (id != null) {
                      setState(() {
                        photoId = id;
                        designId = designs.firstOrNull?.id;
                        aligned = false;
                        alignOriginal = true;
                        blend = .5;
                      });
                    }
                  },
          ),
          if (designs.isNotEmpty)
            DropdownButtonFormField<String>(
              key: ValueKey('camera-design-$photoId-$designId'),
              initialValue: design?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Design from this view',
              ),
              items: [
                for (final d in designs)
                  DropdownMenuItem(
                    value: d.id,
                    child: Text(
                      d.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (id) => setState(() {
                      designId = id;
                      aligned = false;
                      alignOriginal = true;
                    }),
            ),
          if (live && design != null) ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable manual overlay'),
              subtitle: const Text(
                'Match the saved viewpoint. Moving breaks alignment.',
              ),
              value: aligned,
              onChanged: busy
                  ? null
                  : (value) => setState(() {
                      aligned = value ?? false;
                      alignOriginal = true;
                    }),
            ),
            if (aligned)
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Align original'),
                    selected: alignOriginal,
                    onSelected: (_) => setState(() => alignOriginal = true),
                  ),
                  ChoiceChip(
                    label: const Text('Show design'),
                    selected: !alignOriginal,
                    onSelected: (_) => setState(() => alignOriginal = false),
                  ),
                ],
              ),
          ],
          if ((!live && design != null) || (live && aligned))
            Slider(
              value: blend,
              label: '${(blend * 100).round()}%',
              semanticFormatterCallback: (value) =>
                  '${(value * 100).round()} percent ${live ? 'overlay opacity' : 'design reveal'}',
              onChanged: (value) => setState(() => blend = value),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (live)
                ListenableBuilder(
                  listenable: feed,
                  builder: (context, _) => FilledButton.icon(
                    onPressed:
                        busy ||
                            feed.phase != RoomCameraPhase.ready ||
                            room.photoIds.length >=
                                RenovisionStore.maxRoomPhotos
                        ? null
                        : _capture,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(busy ? 'Saving…' : 'Capture new view'),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : widget.liveDesignBuilder == null
                    ? _designView
                    : () => _liveDesign(useSavedView: !live),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  widget.liveDesignBuilder == null
                      ? 'Design saved view'
                      : 'Design in live camera',
                ),
              ),
            ],
          ),
          if (room.photoIds.length >= RenovisionStore.maxRoomPhotos)
            const Text(
              '6 photos saved · use a saved view or create another room for more captures.',
            ),
        ],
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message!, semanticsLabel: message),
          ),
        const SizedBox(height: 8),
        const Text(
          'AI uses a saved photo after your confirmation. This preview does not send video or track the room.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop:
        !busy &&
        pendingCapture == null &&
        !widget.store.documents.hasPending(room.projectId),
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop || busy) return;
      if (pendingCapture != null && !await _discard()) return;
      if (!context.mounted) return;
      setState(() => busy = true);
      _pendingChanged();
      try {
        if (widget.store.documents.hasPending(room.projectId)) {
          await widget.store.documents.save(room.projectId);
        }
        if (context.mounted) Navigator.pop(context);
      } catch (_) {
        if (mounted) {
          setState(
            () => message = 'Saved locally. Project file could not be updated; retry Back or Save project from Settings.',
          );
        }
      } finally {
        if (mounted) {
          setState(() => busy = false);
          _pendingChanged();
        }
      }
    },
    child: Scaffold(
      appBar: AppBar(
        actions: [
          if (widget.liveDesignBuilder != null)
            IconButton(
              tooltip: 'Live design',
              onPressed: busy || pendingCapture != null ? null : _liveDesign,
              icon: const Icon(Icons.auto_awesome_outlined),
            ),
          if (widget.liveDesignBuilder != null)
            IconButton(
              tooltip: 'Edit saved view in workspace',
              onPressed: busy || pendingCapture != null ? null : _designView,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (widget.settingsBuilder != null)
            IconButton(
              tooltip: 'Settings',
              onPressed: busy || pendingCapture != null ? null : _settings,
              icon: const Icon(Icons.settings_outlined),
            ),
        ],
        title: const Text(
          'Camera renovation',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side =
                constraints.maxWidth >= 700 ||
                (constraints.maxHeight < 420 && constraints.maxWidth >= 550);
            return Flex(
              direction: side ? Axis.horizontal : Axis.vertical,
              children: [
                Expanded(child: _canvas()),
                SizedBox(
                  width: side ? 340 : null,
                  height: side ? null : constraints.maxHeight * .49,
                  child: SingleChildScrollView(child: _controls()),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _RevealClipper extends CustomClipper<Rect> {
  final double fraction;
  _RevealClipper(this.fraction);
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);
  @override
  bool shouldReclip(_RevealClipper oldClipper) =>
      fraction != oldClipper.fraction;
}
