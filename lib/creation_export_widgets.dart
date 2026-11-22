import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'creation_export.dart';
import 'project_transfer_widgets.dart' show pngExportBytes, exportName;

class CreationExportControls extends StatefulWidget {
  final Uint8List bytes;
  final String title;
  final CreationExports? exports;
  const CreationExportControls({
    super.key,
    required this.bytes,
    required this.title,
    this.exports,
  });
  @override
  State<CreationExportControls> createState() => _CreationExportControlsState();
}

class _CreationExportControlsState extends State<CreationExportControls> {
  late final CreationExports exports =
      widget.exports ?? createCreationExports();
  Uint8List? prepared;
  bool busy = false;
  String? status;

  @override
  void didUpdateWidget(CreationExportControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.bytes, oldWidget.bytes)) prepared = null;
  }

  Future<void> _export(bool sharing) async {
    if (busy) return;
    final source = widget.bytes;
    final name = '${exportName(widget.title)}.png';
    setState(() {
      busy = true;
      status = 'Preparing image…';
    });
    try {
      final Uint8List png =
          prepared ??
          await compute<Uint8List, Uint8List>(pngExportBytes, source);
      if (!mounted) return;
      // Cache this view's sanitized copy, leaving its original bytes untouched.
      if (identical(source, widget.bytes)) prepared = png;
      setState(() => status = sharing ? 'Opening sharing…' : 'Saving image…');
      final result = sharing
          ? await exports.share(png, name: name)
          : await exports.save(png, name: name);
      if (!mounted) return;
      final message = switch (result) {
        CreationExportResult.gallerySaved =>
          'Saved to Gallery · Pictures/RenoVision.',
        CreationExportResult.fileSaved =>
          'Image saved to your chosen location.',
        CreationExportResult.downloadRequested =>
          sharing
              ? 'File sharing is unavailable here. Image download requested; share it from Downloads.'
              : 'Image download requested. Check Downloads.',
        CreationExportResult.shareOpened =>
          'Share sheet opened. Choose where to send your image.',
        CreationExportResult.cancelled =>
          'Cancelled. Your creation is still saved in the app.',
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(persist: false, content: Text(message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              persist: false,
              content: Text(
                sharing
                    ? 'Sharing could not open. Tap Share again, or save the image and share it from your photos/files.'
                    : 'Image could not be saved. Check free space and try again. Your creation is still in the app.',
              ),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          status = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!exports.supported) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          children: [
            FilledButton.tonalIcon(
              onPressed: busy ? null : () => _export(false),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Save image'),
            ),
            FilledButton.tonalIcon(
              onPressed: busy ? null : () => _export(true),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share creation'),
            ),
          ],
        ),
        if (busy) Semantics(liveRegion: true, child: Text(status!)),
      ],
    );
  }
}
