import 'package:material_ui/material_ui.dart';

import 'room_starters.dart';
import 'store.dart';

Future<void> chooseHomeCover(BuildContext context, RenovisionStore store) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _HomeCoverDialog(store: store),
    );

class HomeCoverSettingsCard extends StatelessWidget {
  final RenovisionStore store;
  const HomeCoverSettingsCard({super.key, required this.store});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.wallpaper_outlined),
      title: const Text('Home cover'),
      subtitle: Text(
        store.homeCoverImageId == null
            ? 'App example'
            : 'Your selected photo or design',
      ),
      trailing: IconButton(
        tooltip: 'Change home cover',
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => chooseHomeCover(context, store),
      ),
    ),
  );
}

class _HomeCoverDialog extends StatefulWidget {
  final RenovisionStore store;
  const _HomeCoverDialog({required this.store});
  @override
  State<_HomeCoverDialog> createState() => _HomeCoverDialogState();
}

class _HomeCoverDialogState extends State<_HomeCoverDialog> {
  bool busy = false;
  String? error;
  Future<void> _save(Future<void> Function() save) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await save();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Cover could not be saved. Retry or cancel.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final selectedImageId = store.homeCoverImageId;
    final selectedSampleId = store.homeCoverSampleId;
    final saved = [
      for (final project in store.projects)
        for (final room in store.roomsFor(project.id)) ...[
          for (var i = 0; i < room.photoIds.length; i++)
            (
              roomId: room.id,
              imageId: room.photoIds[i],
              title: '${room.displayName} · View ${i + 1}',
              detail: project.name,
            ),
          for (final design in store.designsFor(room.id))
            (
              roomId: room.id,
              imageId: design.imageId,
              title: design.title,
              detail: '${project.name} / ${room.displayName}',
            ),
        ],
    ].where((item) => store.imageFor(item.imageId) != null).toList();
    return PopScope(
      canPop: !busy,
      child: DefaultTabController(
        length: 2,
        child: Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 460,
            height:
                (MediaQuery.sizeOf(context).height -
                        MediaQuery.viewInsetsOf(context).bottom -
                        32)
                    .clamp(220.0, 620.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Home cover',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'App examples'),
                            Tab(text: 'My projects'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TabBarView(
                            children: [
                              ListView.builder(
                                itemCount: roomStarters.length,
                                itemBuilder: (context, index) {
                                  final sample = roomStarters[index];
                                  return ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.asset(
                                        sample.asset,
                                        width: 64,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        cacheWidth: 160,
                                      ),
                                    ),
                                    title: Text(sample.title),
                                    trailing:
                                        selectedImageId == null &&
                                            selectedSampleId == sample.id
                                        ? const Icon(Icons.check_circle_outline)
                                        : null,
                                    onTap: busy
                                        ? null
                                        : () => _save(
                                            () => store.setHomeCoverSample(
                                              sample.id,
                                            ),
                                          ),
                                  );
                                },
                              ),
                              saved.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Add room photos or create a design to choose your own cover.',
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: saved.length,
                                      itemBuilder: (context, index) {
                                        final item = saved[index];
                                        return ListTile(
                                          leading: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Image.memory(
                                              store.imageFor(item.imageId)!,
                                              width: 64,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              cacheWidth: 160,
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(
                                                    Icons.broken_image_outlined,
                                                  ),
                                            ),
                                          ),
                                          title: Text(item.title),
                                          subtitle: Text(item.detail),
                                          trailing:
                                              selectedImageId == item.imageId
                                              ? const Icon(
                                                  Icons.check_circle_outline,
                                                )
                                              : null,
                                          onTap: busy
                                              ? null
                                              : () => _save(
                                                  () => store.setHomeCoverImage(
                                                    item.roomId,
                                                    item.imageId,
                                                  ),
                                                ),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                        if (busy) const LinearProgressIndicator(),
                        if (error != null) Text(error!),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => _save(
                                () => store.setHomeCoverSample(
                                  RenovisionStore.defaultHomeCoverSampleId,
                                ),
                              ),
                        child: const Text('Use default'),
                      ),
                      TextButton(
                        onPressed: busy ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
