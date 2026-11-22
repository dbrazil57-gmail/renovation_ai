import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'store.dart';

class StoragePrivacyCard extends StatelessWidget {
  final RenovisionStore store;
  const StoragePrivacyCard({super.key, required this.store});

  String get _location => kIsWeb
      ? 'Browser: ${Uri.base.origin}\nProject data and photos: this Chrome/browser profile’s IndexedDB storage.'
      : 'Project data: ${store.records.path ?? 'app-private data folder'}\nPhotos and designs: ${store.photos.path ?? 'app-private photo store'}';

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      key: const ValueKey('storage-privacy-details'),
      leading: const Icon(Icons.folder_outlined),
      title: const Text('Storage and privacy'),
      subtitle: const Text('Locations, backups and protection'),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('On this device', style: Theme.of(context).textTheme.titleSmall),
        SelectableText(_location),
        const SizedBox(height: 8),
        const Text(
          'Portable files',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const Text(
          'Save project and Back up project let you choose a file location. If your browser uses downloads, its Downloads setting controls the folder. App-local saving stays in the app/browser store.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Backup protection',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const Text(
          'Normal .renovision.json files are readable project copies. Password-protected .renovision backups encrypt their contents. Backup passwords and AI keys are not included in project exports.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Local data and AI key',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          'Local photos and project records do not yet have an app-level encryption layer. ${store.ai.keyRememberedOnDevice ? 'On Android, the API key is encrypted with Android Keystore.' : 'In this browser/device mode, the API key stays in session memory.'}',
        ),
        const SizedBox(height: 8),
        const Text('Cloud AI', style: TextStyle(fontWeight: FontWeight.w600)),
        const Text(
          'Analysis and generation send selected images and your brief to the connected AI after confirmation. Live video stays on the device. Manual AI handoff is also available.',
        ),
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _location));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  persist: false,
                  content: Text('Storage location details copied.'),
                ),
              );
            }
          },
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copy storage locations'),
        ),
      ],
    ),
  );
}
