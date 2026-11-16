import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'app_revision.dart';
import 'store.dart';

class StorageStatusCard extends StatefulWidget {
  final RenovisionStore store;
  const StorageStatusCard({super.key, required this.store});
  @override
  State<StorageStatusCard> createState() => _StorageStatusCardState();
}

class _StorageStatusCardState extends State<StorageStatusCard> {
  bool busy = false;
  String? message;
  Future<void> _check() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await widget.store.checkLocalStorage();
      if (mounted) {
        setState(
          () => message = kIsWeb
              ? 'Photo and project storage writes completed and read back correctly. Reopen this same address/profile to check that they survive restarting.'
              : 'Photo and project storage writes completed and read back correctly. Close and reopen the app to check that they survive restarting.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'The storage check failed. Keep this session open and back up your projects before restarting. No projects or photos were removed.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App build and saved data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SelectableText('Build: $appBuildId'),
            if (kIsWeb) ...[
              const SizedBox(height: 6),
              SelectableText('Browser address: ${Uri.base.origin}'),
              const Text(
                'Use the same address, port and normal Chrome profile each time. A different address/profile has a separate project store.',
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${widget.store.projects.length} projects · ${widget.store.records.keys.where((key) => key.toString().startsWith('room:')).length} rooms · ${widget.store.allDesigns.length} design versions',
            ),
            Text(
              'Stored images: ${widget.store.photos.keys.where((key) => key.toString().startsWith('photo_')).length}',
            ),
            Text(
              widget.store.lastStorageCheck == null
                  ? 'No successful storage check recorded here yet.'
                  : 'Last successful storage check: ${widget.store.lastStorageCheck!.toLocal()}',
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : _check,
              icon: const Icon(Icons.save_outlined),
              label: Text(busy ? 'Checking storage…' : 'Check local saving'),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message!),
              ),
            const SizedBox(height: 8),
            const Text(
              'Images created in another AI app enter this project only after Import generated AI result. In-app generations save as versions. Use Back up project for a separate portable copy.',
            ),
          ],
        ),
      ),
    ),
  );
}
