import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'store.dart';

bool get supportsRoomCamera =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<bool?> chooseRoomPhotoSource(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (dialogContext) => SimpleDialog(
    title: const Text('Add room photos'),
    children: [
      if (supportsRoomCamera)
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const ListTile(
            leading: Icon(Icons.camera_alt_outlined),
            title: Text('Take photo'),
            subtitle: Text('Use your phone camera'),
          ),
        ),
      SimpleDialogOption(
        onPressed: () => Navigator.pop(dialogContext, false),
        child: const ListTile(
          leading: Icon(Icons.photo_library_outlined),
          title: Text('Choose photos'),
          subtitle: Text('Select existing photos from your device'),
        ),
      ),
      SimpleDialogOption(
        onPressed: () => Navigator.pop(dialogContext),
        child: const Text('Cancel'),
      ),
    ],
  ),
);

Future<List<Uint8List>?> selectRoomPhotos({
  required int remaining,
  bool camera = false,
}) async {
  if (remaining <= 0) {
    throw ArgumentError('This room already has 6 photos.');
  }
  final picker = ImagePicker();
  final captured = camera
      ? await picker.pickImage(source: ImageSource.camera)
      : null;
  final files = camera
      ? (captured == null ? <XFile>[] : [captured])
      : await picker.pickMultiImage();
  if (files.isEmpty) return null;
  if (files.length > remaining) {
    throw ArgumentError(
      'You can add $remaining more photos to this room (6 total).',
    );
  }
  final images = <Uint8List>[];
  for (final file in files) {
    if (await file.length() > 18 * 1024 * 1024) {
      throw ArgumentError('Choose photos smaller than 18 MB each.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 18 * 1024 * 1024) {
      throw ArgumentError('Choose photos smaller than 18 MB each.');
    }
    images.add(bytes);
  }
  return images;
}

class RoomPhotosCard extends StatefulWidget {
  final RenovisionStore store;
  final RenovationRoom room;
  final String? selectedPhotoId;
  final ValueChanged<String> onView;
  final bool includeContext;
  final ValueChanged<bool>? onContextChanged;
  final Future<List<Uint8List>?> Function(int remaining)? pickPhotos;
  final Future<List<Uint8List>?> Function(int remaining)? takePhoto;
  const RoomPhotosCard({
    super.key,
    required this.store,
    required this.room,
    required this.selectedPhotoId,
    required this.onView,
    required this.includeContext,
    required this.onContextChanged,
    this.pickPhotos,
    this.takePhoto,
  });
  @override
  State<RoomPhotosCard> createState() => _RoomPhotosCardState();
}

class _RoomPhotosCardState extends State<RoomPhotosCard> {
  bool busy = false;
  String? message;
  Future<void> _add({bool camera = false}) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final remaining =
          RenovisionStore.maxRoomPhotos - widget.room.photoIds.length;
      final images =
          await ((camera ? widget.takePhoto : widget.pickPhotos)?.call(
                remaining,
              ) ??
              selectRoomPhotos(remaining: remaining, camera: camera));
      if (images == null) return;
      await widget.store.addRoomPhotos(widget.room.id, images);
      if (mounted) {
        setState(
          () => message =
              '${images.length} photos added. Originals and approval are unchanged.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => message = error is ArgumentError
              ? '${error.message}'
              : 'Photos could not be added. Existing photos are unchanged.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _primary(String id) async {
    setState(() => busy = true);
    try {
      await widget.store.setPrimaryPhoto(widget.room.id, id);
      if (mounted) widget.onView(id);
    } catch (_) {
      if (mounted) setState(() => message = 'Could not save the primary view.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room photos (${widget.room.photoIds.length}/6)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Add different angles of this same room. The working image sets the output viewpoint; other photos provide context. This does not build a measured 3D room.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              for (final (index, id) in widget.room.photoIds.indexed)
                SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: busy ? null : () => widget.onView(id),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: widget.selectedPhotoId == id
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Image.memory(
                            widget.store.imageFor(id)!,
                            width: 134,
                            height: 85,
                            cacheWidth: 400,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Text(
                        'View ${index + 1}${id == widget.room.originalId ? ' · original' : ''}',
                      ),
                      TextButton(
                        onPressed: busy || id == widget.room.primaryId
                            ? null
                            : () => _primary(id),
                        child: Text(
                          id == widget.room.primaryId
                              ? 'Primary view'
                              : 'Use as primary',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (supportsRoomCamera)
                OutlinedButton.icon(
                  onPressed:
                      busy ||
                          widget.room.photoIds.length >=
                              RenovisionStore.maxRoomPhotos
                      ? null
                      : () => _add(camera: true),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Take photo'),
                ),
              OutlinedButton.icon(
                onPressed:
                    busy ||
                        widget.room.photoIds.length >=
                            RenovisionStore.maxRoomPhotos
                    ? null
                    : () => _add(),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(busy ? 'Saving photos…' : 'Choose photos'),
              ),
            ],
          ),
          if (widget.room.photoIds.length > 1 &&
              widget.onContextChanged != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use other views as AI context'),
              value: widget.includeContext,
              onChanged: widget.onContextChanged,
            ),
          if (message != null) Text(message!),
        ],
      ),
    ),
  );
}
