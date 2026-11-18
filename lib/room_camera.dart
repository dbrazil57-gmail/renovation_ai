import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

bool get supportsLiveRoomCamera =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

enum RoomCameraPhase { opening, ready, paused, unavailable }

abstract class RoomCameraFeed extends ChangeNotifier {
  RoomCameraPhase get phase;
  String? get error;
  Widget preview();
  Future<void> start();
  Future<void> stop();
  Future<Uint8List> capture();
}

/// Preview/capture only: never starts an image stream or sends camera frames.
class DeviceRoomCamera extends RoomCameraFeed {
  final Future<List<CameraDescription>> Function() cameras;
  final CameraController Function(CameraDescription) controllerFactory;
  DeviceRoomCamera({
    Future<List<CameraDescription>> Function()? cameras,
    CameraController Function(CameraDescription)? controllerFactory,
  }) : cameras = cameras ?? availableCameras,
       controllerFactory =
           controllerFactory ??
           ((description) => CameraController(
             description,
             ResolutionPreset.high,
             enableAudio: false,
           ));

  CameraController? _controller;
  Future<void> _tail = Future.value();
  RoomCameraPhase _phase = RoomCameraPhase.paused;
  String? _error;
  bool _wanted = false, _closed = false;
  int _generation = 0;
  @override
  RoomCameraPhase get phase => _phase;
  @override
  String? get error => _error;
  void _notify() {
    if (!_closed) notifyListeners();
  }

  Future<T> _serial<T>(Future<T> Function() task) {
    final operation = _tail.then((_) => task());
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  void _cameraChanged() {
    if (_controller?.value.hasError ?? false) {
      _phase = RoomCameraPhase.unavailable;
      _error = 'Camera connection was interrupted. Retry the camera.';
    }
    _notify();
  }

  @override
  Future<void> start() {
    if (_closed) return Future.value();
    if (_wanted &&
        (_phase == RoomCameraPhase.ready ||
            _phase == RoomCameraPhase.opening)) {
      return _tail;
    }
    _wanted = true;
    _phase = RoomCameraPhase.opening;
    _error = null;
    final ticket = ++_generation;
    _notify();
    return _serial(() async {
      if (!_wanted || _closed || ticket != _generation) return;
      CameraController? candidate;
      try {
        await _release();
        final descriptions = await cameras();
        if (descriptions.isEmpty) {
          throw CameraException('NoCamera', 'No camera available');
        }
        if (!_wanted || _closed || ticket != _generation) return;
        final rear = descriptions.where(
          (camera) => camera.lensDirection == CameraLensDirection.back,
        );
        candidate = controllerFactory(
          rear.isEmpty ? descriptions.first : rear.first,
        );
        await candidate.initialize();
        if (!_wanted || _closed || ticket != _generation) {
          await candidate.dispose();
          return;
        }
        _controller = candidate;
        candidate.addListener(_cameraChanged);
        _phase = RoomCameraPhase.ready;
      } catch (failure) {
        if (candidate != null && candidate != _controller) {
          try {
            await candidate.dispose();
          } catch (_) {}
        }
        if (ticket != _generation || _closed) return;
        _phase = RoomCameraPhase.unavailable;
        final denied =
            failure is CameraException &&
            (failure.code.contains('Denied') ||
                failure.code.contains('Restricted'));
        _error = denied
            ? 'Camera access is blocked. Allow camera access in your device or browser settings, then retry. You can still choose existing photos.'
            : 'Camera is unavailable. Close other camera apps and retry, or choose existing photos.';
      }
      _notify();
    });
  }

  Future<void> _release() async {
    final previous = _controller;
    _controller = null;
    if (previous != null) {
      previous.removeListener(_cameraChanged);
      await previous.dispose();
    }
  }

  @override
  Future<void> stop() {
    _wanted = false;
    _generation++;
    _phase = RoomCameraPhase.paused;
    _notify();
    return _serial(_release);
  }

  @override
  Future<Uint8List> capture() => _serial(() async {
    if (_closed ||
        !_wanted ||
        _phase != RoomCameraPhase.ready ||
        _controller == null) {
      throw StateError('Wait for the camera to be ready.');
    }
    final file = await _controller!.takePicture();
    final bytes = await file.readAsBytes();
    validateRoomCapture(bytes);
    return bytes;
  });

  @override
  Widget preview() => _controller == null || _phase != RoomCameraPhase.ready
      ? const SizedBox.shrink()
      : Center(child: CameraPreview(_controller!));

  @override
  void dispose() {
    _closed = true;
    _wanted = false;
    _generation++;
    unawaited(_serial(_release).catchError((Object _) {}));
    super.dispose();
  }
}

void validateRoomCapture(Uint8List bytes) {
  if (bytes.isEmpty || bytes.lengthInBytes > 18 * 1024 * 1024) {
    throw ArgumentError('Choose a photo smaller than 18 MB.');
  }
}

class RoomCameraSurface extends StatelessWidget {
  final RoomCameraFeed feed;
  const RoomCameraSurface({super.key, required this.feed});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: feed,
    builder: (context, _) => ColoredBox(
      color: const Color(0xFF26251F),
      child: feed.phase == RoomCameraPhase.ready
          ? feed.preview()
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      feed.error ??
                          (feed.phase == RoomCameraPhase.opening
                              ? 'Opening camera…'
                              : 'Camera paused'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (feed.phase != RoomCameraPhase.opening)
                      TextButton(
                        onPressed: feed.start,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry camera'),
                      ),
                  ],
                ),
              ),
            ),
    ),
  );
}

/// Standalone embedded still capture used by the existing room/photo workflow.
class RoomCaptureScreen extends StatefulWidget {
  final RoomCameraFeed? feed;
  const RoomCaptureScreen({super.key, this.feed});
  @override
  State<RoomCaptureScreen> createState() => _RoomCaptureScreenState();
}

class _RoomCaptureScreenState extends State<RoomCaptureScreen>
    with WidgetsBindingObserver {
  late final RoomCameraFeed feed = widget.feed ?? DeviceRoomCamera();
  Uint8List? photo;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(feed.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && photo == null) {
      unawaited(feed.start());
    } else if (state != AppLifecycleState.resumed &&
        !(state == AppLifecycleState.inactive &&
            feed.phase == RoomCameraPhase.opening)) {
      unawaited(feed.stop().catchError((Object _) {}));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    feed.dispose();
    super.dispose();
  }

  Future<void> take() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final image = await feed.capture();
      validateRoomCapture(image);
      if (!mounted) return;
      setState(() => photo = image);
      await feed.stop();
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Could not capture this photo. Retry or go back to choose photos.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Capture your room')),
      body: Column(
        children: [
          Expanded(
            child: photo == null
                ? RoomCameraSurface(feed: feed)
                : Image.memory(photo!, fit: BoxFit.contain),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error != null) Text(error!),
                  const Text(
                    'Camera preview stays on this device. Capturing does not call AI.',
                  ),
                  const SizedBox(height: 8),
                  if (photo == null)
                    ListenableBuilder(
                      listenable: feed,
                      builder: (context, _) => FilledButton.icon(
                        onPressed: busy || feed.phase != RoomCameraPhase.ready
                            ? null
                            : take,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(busy ? 'Capturing…' : 'Capture photo'),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () {
                                  setState(() => photo = null);
                                  unawaited(feed.start());
                                },
                          child: const Text('Retake'),
                        ),
                        FilledButton(
                          onPressed: busy
                              ? null
                              : () => Navigator.pop(context, photo),
                          child: const Text('Use photo'),
                        ),
                      ],
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

Future<Uint8List?> captureRoomPhoto(BuildContext context) =>
    Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const RoomCaptureScreen()),
    );
