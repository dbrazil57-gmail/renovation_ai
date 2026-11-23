import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/room_start_widgets.dart';
import 'package:renovision_ai/room_starters.dart';
import 'package:renovision_ai/room_features.dart';
import 'package:renovision_ai/design_styles.dart';
import 'package:renovision_ai/design_palettes.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void main() {
  testWidgets(
    'typing a space name suggests types without changing its custom name or selecting automatically',
    (tester) async {
      RoomStartChoice? choice;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  choice = await showDialog<RoomStartChoice>(
                    context: context,
                    builder: (_) => const RoomStartDialog(),
                  );
                },
                child: const Text('Start'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('room-name')),
        'Upstairs bathr',
      );
      await tester.pumpAndSettle();
      final suggested = find.byKey(
        const ValueKey('suggest-room-type-bathroom'),
      );
      expect(tester.widget<ChoiceChip>(suggested).selected, isFalse);
      await tester.ensureVisible(suggested);
      await tester.tap(suggested);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('room-name')))
            .controller!
            .text,
        'Upstairs bathr',
      );
      await tester.tap(find.text('Continue to photos'));
      await tester.pumpAndSettle();
      expect(choice!.name, 'Upstairs bathr');
      expect(choice!.roomTypeId, 'bathroom');
      expect(tester.takeException(), isNull);
    },
  );

  test('home catalogue is reachable by category and subtype controls avoid unrelated items', () {
    final grouped = roomCategories.values.expand((ids) => ids).toList();
    expect(grouped.toSet(), roomTypes.keys.toSet());
    expect(grouped.length, grouped.toSet().length);
    expect(
      roomTypes.keys,
      containsAll([
        'ensuite',
        'powder_room',
        'pantry',
        'wardrobe',
        'garage',
        'stairs',
        'deck',
        'pool',
      ]),
    );
    expect(roomFeaturesFor('ensuite').keys, contains('bathroom_shower'));
    expect(
      roomFeaturesFor('powder_room').keys,
      isNot(contains('bathroom_shower')),
    );
    expect(
      roomFeaturesFor('powder_room').keys,
      isNot(contains('bathroom_bath')),
    );
    expect(roomFeaturesFor('nursery').keys, isNot(contains('bedroom_bed')));
    expect(roomFeaturesFor('dining').keys, isNot(contains('living_seating')));
    expect(roomFeaturesFor('media').keys, isNot(contains('living_dining')));
    final prompt = buildRoomItemsPrompt('butlers_pantry', {
      'pantry_storage': 'replace',
      'kitchen_oven': 'replace',
    }, []);
    expect(prompt, contains("Butler's pantry"));
    expect(prompt, contains('Pantry shelving'));
    expect(prompt, isNot(contains('REPLACE Oven')));
    expect(scopeAppliesToRoom('benchtops', 'butlers_pantry'), true);
    expect(scopeAppliesToRoom('splashback', 'hallway'), false);
    expect(scopeAppliesToRoom('flooring', 'pool'), false);
  });

  testWidgets(
    'room search selects a specific home space and retains a general style direction',
    (tester) async {
      RoomStartChoice? selected;
      const direction = RoomStarter(
        id: 'test',
        title: 'Art Deco',
        roomTypeId: 'kitchen',
        styleId: 'art_deco',
        paletteId: 'forest_cream',
        asset: '',
        description: '',
        anyRoom: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await showDialog<RoomStartChoice>(
                    context: context,
                    builder: (_) => const RoomStartDialog(starter: direction),
                  );
                },
                child: const Text('Start'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('room-search')),
        'ensuite',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('room-type-kitchen')), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('room-type-ensuite')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('room-type-ensuite')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to photos'));
      await tester.pumpAndSettle();
      expect(selected!.roomTypeId, 'ensuite');
      expect(selected!.name, 'Ensuite');
      expect(selected!.starter!.styleId, 'art_deco');
    },
  );

  testWidgets(
    'full style and palette browser is independent of six illustrated examples',
    (tester) async {
      RoomStarter? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DesignDirectionPicker(onUse: (s) => selected = s),
            ),
          ),
        ),
      );
      expect(find.byType(ChoiceChip), findsNWidgets(designStyles.length));
      await tester.tap(find.text('Art Deco'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Forest & cream'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forest & cream'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Use these choices with my room'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use these choices with my room'));
      await tester.pumpAndSettle();
      expect(selected!.styleId, 'art_deco');
      expect(selected!.paletteId, 'forest_cream');
      expect(selected!.anyRoom, true);
      expect(
        designPalettes.map((p) => p.id).toSet(),
        hasLength(designPalettes.length),
      );
      expect(tester.takeException(), isNull);
    },
  );
  test('starter preferences and original photos round-trip without sample image records', () async {
    final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    addTearDown(store.dispose);
    final original = img.encodePng(img.Image(width: 40, height: 30));
    final project = await store.createProject('Existing home');
    final sample = roomStarters.first;
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Dining-side project',
      originalImage: original,
      roomTypeId: sample.roomTypeId,
      colourPaletteId: sample.paletteId,
      designStyleIds: [sample.styleId],
    );
    final backup = ProjectBackup.decode(store.backupFor(project.id).encode());
    expect(backup.rooms.single.name, 'Dining-side project');
    expect(backup.rooms.single.roomTypeId, 'kitchen');
    expect(backup.rooms.single.designStyleIds, ['modern']);
    expect(backup.rooms.single.colourPaletteId, 'charcoal_walnut');
    expect(backup.photos, hasLength(1));
    expect(backup.photos[room.originalId], orderedEquals(original));
    expect(store.allDesigns, isEmpty);
    final before = store.photos.keys.length;
    await expectLater(
      store.createRoom(
        projectId: project.id,
        name: 'Invalid',
        originalImage: original,
        roomTypeId: 'unrecognised',
      ),
      throwsArgumentError,
    );
    await expectLater(
      store.createRoom(
        projectId: project.id,
        name: 'Invalid',
        originalImage: original,
        designStyleIds: ['unrecognised'],
      ),
      throwsArgumentError,
    );
    expect(store.photos.keys.length, before);
    expect(store.roomsFor(project.id), hasLength(1));
  });

  test(
    'all bundled examples load as assets and have valid image bytes',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final sample in roomStarters) {
        final bytes = await rootBundle.load(sample.asset);
        expect(img.decodeImage(bytes.buffer.asUint8List()), isNotNull);
      }
    },
  );

  testWidgets(
    'room cards fit a phone, preserve custom names and clear a mismatched sample',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      RoomStartChoice? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  chosen = await showDialog<RoomStartChoice>(
                    context: context,
                    builder: (_) =>
                        RoomStartDialog(starter: roomStarters.first),
                  );
                },
                child: const Text('Start'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('room-name')),
        'Guest retreat',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('room-type-bathroom')),
      );
      await tester.tap(find.byKey(const ValueKey('room-type-bathroom')));
      await tester.pumpAndSettle();
      expect(find.text('Guest retreat'), findsOneWidget);
      await tester.tap(find.text('Continue to photos'));
      await tester.pumpAndSettle();
      expect(chosen!.name, 'Guest retreat');
      expect(chosen!.roomTypeId, 'bathroom');
      expect(chosen!.starter, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 1.8]) {
    testWidgets(
      'compact room tiles fit long labels on a 320px phone at text scale $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 700);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        RoomStartChoice? chosen;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    chosen = await showDialog<RoomStartChoice>(
                      context: context,
                      builder: (_) => const RoomStartDialog(),
                    );
                  },
                  child: const Text('Start'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();
        final kitchen = find.byKey(const ValueKey('room-type-kitchen'));
        final bathroom = find.byKey(const ValueKey('room-type-bathroom'));
        final kitchenBounds = tester.getRect(kitchen);
        final bathroomBounds = tester.getRect(bathroom);
        if (scale == 1) {
          expect(kitchenBounds.height, lessThan(95));
          expect(bathroomBounds.top, kitchenBounds.top);
          expect(bathroomBounds.left, greaterThan(kitchenBounds.right));
        } else {
          expect(bathroomBounds.top, greaterThan(kitchenBounds.bottom));
        }
        final ink = tester.widgetList<Ink>(
          find.descendant(of: kitchen, matching: find.byType(Ink)),
        );
        expect(
          ink
              .map((widget) => widget.decoration)
              .whereType<BoxDecoration>()
              .any((decoration) => decoration.image?.image is ResizeImage),
          isTrue,
        );
        for (final type in ['living', 'wardrobe', 'sunroom', 'pool']) {
          final tile = find.byKey(ValueKey('room-type-$type'));
          await tester.ensureVisible(tile);
          await tester.pumpAndSettle();
          final label = find.descendant(
            of: tile,
            matching: find.text(roomTypes[type]!),
          );
          final tileBounds = tester.getRect(tile),
              labelBounds = tester.getRect(label);
          expect(labelBounds.left, greaterThanOrEqualTo(tileBounds.left));
          expect(labelBounds.right, lessThanOrEqualTo(tileBounds.right));
          expect(labelBounds.bottom, lessThanOrEqualTo(tileBounds.bottom));
          expect(tester.takeException(), isNull);
        }
        final search = find.byKey(const ValueKey('room-search'));
        await tester.ensureVisible(search);
        await tester.enterText(search, 'wardrobe');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        final wardrobe = find.byKey(const ValueKey('room-type-wardrobe'));
        await tester.ensureVisible(wardrobe);
        await tester.tap(wardrobe);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue to photos'));
        await tester.pumpAndSettle();
        expect(chosen!.roomTypeId, 'wardrobe');
        expect(chosen!.name, roomTypes['wardrobe']);
        expect(chosen!.starter, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'sample gallery filters, shows empty combinations and passes the selected preset',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      RoomStarter? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: InspirationGallery(onUse: (sample) => selected = sample),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('All rooms'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bathroom').last);
      await tester.pumpAndSettle();
      expect(find.text('Calm sage bathroom'), findsOneWidget);
      expect(find.text('Charcoal & walnut kitchen'), findsNothing);
      await tester.tap(find.text('All styles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coastal').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('No samples match'), findsOneWidget);
      await tester.tap(find.text('Clear sample filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Charcoal & walnut kitchen'));
      await tester.pumpAndSettle();
      expect(find.text('AI-created inspiration sample'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Use this style with my room'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Use this style with my room'));
      await tester.pumpAndSettle();
      expect(selected!.id, 'charcoal_kitchen');
      expect(tester.takeException(), isNull);
    },
  );
}
