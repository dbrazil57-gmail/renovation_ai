import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/storage_status_widgets.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

class FailingStorage extends MemoryBox {
  bool fail = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (fail) throw StateError('Simulated full storage');
    await super.put(key, value);
  }
}

void main() {
  testWidgets(
    'storage check reports both boxes and keeps project image and backup unchanged',
    (tester) async {
      final records = MemoryBox(), photos = MemoryBox();
      final store = RenovisionStore(records: records, photos: photos);
      final project = await store.createProject('Claylands');
      final image = img.encodePng(img.Image(width: 30, height: 20));
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: image,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: StorageStatusCard(store: store)),
          ),
        ),
      );
      await tester.tap(find.text('Check local saving'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('writes completed and read back correctly'),
        findsOneWidget,
      );
      expect(find.text('Stored images: 1'), findsOneWidget);
      expect(store.lastStorageCheck, isNotNull);
      expect(store.imageFor(room.originalId), orderedEquals(image));
      expect(store.backupFor(project.id).photos, hasLength(1));
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );

  testWidgets(
    'storage check failure is visible and never clears existing work',
    (tester) async {
      final records = MemoryBox(), photos = FailingStorage();
      final store = RenovisionStore(records: records, photos: photos);
      final project = await store.createProject('Claylands');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: img.encodePng(img.Image(width: 30, height: 20)),
      );
      final original = store.imageFor(room.originalId)!;
      photos.fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: StorageStatusCard(store: store)),
          ),
        ),
      );
      await tester.tap(find.text('Check local saving'));
      await tester.pumpAndSettle();
      expect(find.textContaining('The storage check failed'), findsOneWidget);
      expect(store.lastStorageCheck, isNull);
      expect(store.projects.single.id, project.id);
      expect(store.imageFor(room.originalId), orderedEquals(original));
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
