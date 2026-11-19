import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/focus_workspace.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

class CoverRecords extends MemoryBox {
  bool fail = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (fail && key == 'settings:home_cover') {
      throw StateError('Test storage failure');
    }
    await super.put(key, value);
  }
}

void main() {
  late CoverRecords records;
  late MemoryBox photos;
  late RenovisionStore store;
  late RenovationRoom room;
  final photo = img.encodePng(img.Image(width: 32, height: 24));
  setUp(() async {
    records = CoverRecords();
    photos = MemoryBox();
    store = RenovisionStore(records: records, photos: photos);
    final project = await store.createProject('Test home');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Lounge',
      originalImage: photo,
    );
    await store.rememberRoom(room.id);
  });
  tearDown(() => store.dispose());

  test(
    'existing saved rooms no longer become the opening cover automatically',
    () {
      expect(store.resumeRoom!.id, room.id);
      expect(store.homeCoverImageId, isNull);
      expect(store.homeCoverAsset, 'assets/inspiration/coastal-living.png');
      expect(store.imageFor(room.originalId), photo);
    },
  );

  test('app sample selection persists on restart and is independent of the most recent room', () async {
    await store.setHomeCoverSample('sage_bathroom');
    final another = await store.createRoom(
      projectId: room.projectId,
      name: 'Kitchen',
      originalImage: photo,
    );
    await store.rememberRoom(another.id);
    final reopened = RenovisionStore(records: records, photos: photos);
    addTearDown(reopened.dispose);
    expect(reopened.homeCoverSampleId, 'sage_bathroom');
    expect(reopened.homeCoverAsset, 'assets/inspiration/sage-bathroom.png');
    expect(reopened.homeCoverImageId, isNull);
    expect(reopened.resumeRoom!.id, another.id);
  });

  test('chosen photo/design persists separately, preserves room data and falls back if unavailable', () async {
    final design = await store.createDesign(
      roomId: room.id,
      image: photo,
      title: 'Favourite idea',
      prompt: 'Test',
    );
    await store.setHomeCoverImage(room.id, design.imageId);
    final reopened = RenovisionStore(records: records, photos: photos);
    addTearDown(reopened.dispose);
    expect(reopened.homeCoverImageId, design.imageId);
    expect(reopened.roomById(room.id)!.primaryId, room.primaryId);
    expect(reopened.roomById(room.id)!.approvedDesignId, room.approvedDesignId);
    expect(reopened.roomById(room.id)!.photoIds, room.photoIds);
    expect(
      utf8.decode(reopened.backupFor(room.projectId).encode()),
      isNot(contains('settings:home_cover')),
    );
    await store.trashDesign(design.id);
    expect(store.homeCoverImageId, isNull);
    expect(store.homeCoverSampleId, RenovisionStore.defaultHomeCoverSampleId);
    await store.setHomeCoverImage(room.id, room.originalId);
    expect(store.homeCoverImageId, room.originalId);
    await store.setHomeCoverSample(RenovisionStore.defaultHomeCoverSampleId);
    expect(store.homeCoverImageId, isNull);
    expect(store.imageFor(room.originalId), photo);
  });

  test('invalid choice and failed save preserve the previous cover', () async {
    await store.setHomeCoverSample('sage_bathroom');
    await expectLater(
      store.setHomeCoverImage(room.id, 'missing'),
      throwsArgumentError,
    );
    await expectLater(
      store.setHomeCoverSample('../private'),
      throwsArgumentError,
    );
    records.fail = true;
    await expectLater(
      store.setHomeCoverImage(room.id, room.originalId),
      throwsStateError,
    );
    expect(store.homeCoverSampleId, 'sage_bathroom');
    expect(store.homeCoverImageId, isNull);
    expect(store.imageFor(room.originalId), photo);
  });

  testWidgets(
    'home cover picker selects saved photos, samples and restores default without touching Continue',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectsTab(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      FocusHomeHero hero() =>
          tester.widget<FocusHomeHero>(find.byType(FocusHomeHero));
      expect(hero().image, isNull);
      expect(hero().imageAsset, store.homeCoverAsset);
      expect(find.text('Continue Lounge'), findsOneWidget);
      await tester.tap(find.byTooltip('Change home cover'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My projects'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lounge · View 1'));
      await tester.pumpAndSettle();
      expect(hero().image, photo);
      await tester.tap(find.byTooltip('Change home cover'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calm sage bathroom'));
      await tester.pumpAndSettle();
      expect(hero().image, isNull);
      expect(hero().imageAsset, 'assets/inspiration/sage-bathroom.png');
      await tester.tap(find.byTooltip('Change home cover'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use default'));
      await tester.pumpAndSettle();
      expect(hero().imageAsset, 'assets/inspiration/coastal-living.png');
      expect(find.text('Continue Lounge'), findsOneWidget);
      expect(store.imageFor(room.originalId), photo);
    },
  );

  testWidgets(
    'cover dialog fits narrow screens and large text and reports save failure',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(body: ProjectsTab(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Change home cover'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      records.fail = true;
      await tester.ensureVisible(find.text('Calm sage bathroom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calm sage bathroom'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cover could not be saved'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.homeCoverImageId, isNull);
      expect(store.homeCoverSampleId, RenovisionStore.defaultHomeCoverSampleId);
    },
  );
}
