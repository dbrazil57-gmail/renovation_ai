import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/australian_design.dart';
import 'package:renovision_ai/design_recipe.dart';
import 'package:renovision_ai/design_styles.dart';
import 'package:renovision_ai/design_style_widgets.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/room_analysis.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/room_prompt.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void main() {
  late RenovisionStore store;
  late RenovationRoom room;
  setUp(() async {
    store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    final project = await store.createProject('Australian sample');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Courtyard',
      originalImage: img.encodePng(img.Image(width: 32, height: 24)),
    );
  });
  tearDown(() => store.dispose());

  test('legacy records stay global and retain their original data', () {
    final legacy = room.toMap()..remove('australianSetting');
    final read = RenovationRoom.fromMap(legacy);
    expect(read.australianSetting.enabled, isFalse);
    expect(read.australianSetting.prompt, isEmpty);
    expect(read.originalId, room.originalId);
    expect(read.instructions, room.instructions);
  });

  testWidgets(
    'Australian choices survive autosave, backup and settings reuse',
    (tester) async {
      final draft = RoomDraft(store, room);
      addTearDown(draft.dispose);
      draft.setStyle('australian_bushland', true);
      expect(draft.australianSetting.enabled, isFalse);
      draft.setAustralianSetting(
        draft.australianSetting.copyWith(
          climateId: 'mediterranean',
          preferNativePlants: false,
        ),
      );
      draft.australianSiteNotes.text = 'Perth, coastal wind, sandy soil';
      await tester.pump(const Duration(milliseconds: 700));
      expect(draft.state, DraftSaveState.saved);
      final saved = store.roomById(room.id)!;
      expect(saved.australianSetting.climateId, 'mediterranean');
      expect(saved.australianSetting.preferNativePlants, isFalse);
      expect(saved.australianSetting.siteNotes, contains('Perth'));

      final recipe = DesignRecipe(draft.captureRecipe().toMap());
      draft.setAustralianSetting(const AustralianDesignSettings());
      draft.australianSiteNotes.clear();
      expect(await draft.applyRecipe(recipe), isTrue);
      expect(
        draft.currentAustralianSetting.toMap(),
        saved.australianSetting.toMap(),
      );

      final backup = ProjectBackup.decode(
        store.backupFor(room.projectId).encode(),
      );
      final restored = await store.restoreBackup(backup);
      final restoredRoom = store.roomsFor(restored.id).single;
      expect(
        restoredRoom.australianSetting.toMap(),
        saved.australianSetting.toMap(),
      );
      expect(
        store.imageFor(restoredRoom.originalId),
        store.imageFor(room.originalId),
      );
      expect(restoredRoom.designStyleIds, contains('australian_bushland'));
    },
  );

  test(
    'Australian is one global style and never selects a property country',
    () {
      final choices = selectableDesignStyles().map((e) => e.key).toList();
      expect(choices, containsAll(['australian', 'japanese', 'italian']));
      expect(choices.any(legacyAustralianStyleIds.contains), isFalse);
      final draft = RoomDraft(store, room);
      addTearDown(draft.dispose);
      draft.setStyle('australian', true);
      draft.changes.text = 'Refresh this courtyard in California';
      final prompt = roomTemplatePrompt(room, draft);
      expect(prompt, contains('Australian-inspired'));
      expect(prompt, contains('actual property location and climate'));
      expect(prompt, contains('California'));
      expect(prompt, isNot(contains('AUSTRALIAN SETTING')));
      expect(prompt, isNot(contains('favour Australian native plants')));
      expect(draft.australianSetting.enabled, isFalse);
      final legacy = room.copyWith(designStyleIds: ['australian_bushland']);
      expect(RenovationRoom.fromMap(legacy.toMap()).designStyleIds, [
        'australian_bushland',
      ]);
    },
  );

  test(
    'climate and native choices reach analysis context without expanding scope',
    () {
      final draft = RoomDraft(store, room);
      addTearDown(draft.dispose);
      draft.setAustralianSetting(
        const AustralianDesignSettings(climateId: 'cool'),
      );
      draft.australianSiteNotes.text = 'Canberra, frosty, shaded courtyard';
      final prompt = roomTemplatePrompt(room, draft);
      expect(prompt, contains('Cool / frost-prone'));
      expect(prompt, contains('favour Australian native plants'));
      expect(prompt, contains('Canberra'));
      expect(prompt, contains('Indoor styling is not permission'));
      expect(prompt, contains('protected trees'));
      expect(prompt, contains('appropriately sized planting and containers'));

      draft.setAnalysis(
        RoomAnalysis(
          result: RoomAnalysisResult.fromMap({
            'observations': 'A courtyard with a retained tree.',
            'questions': <String>[],
            'prompt': 'A cool-climate courtyard proposal.',
            'model': 'synthetic-vision',
          }),
          sourceImageId: room.originalId,
          supportingImageIds: const [],
          context: prompt,
          created: DateTime.now(),
        ),
        useProposal: true,
      );
      expect(
        usesRoomDesignProposal(prompt, draft, sourceImageId: room.originalId),
        isTrue,
      );
      draft.setAustralianSetting(
        draft.currentAustralianSetting.copyWith(climateId: 'dry'),
      );
      final updated = roomTemplatePrompt(room, draft);
      expect(
        usesRoomDesignProposal(updated, draft, sourceImageId: room.originalId),
        isFalse,
      );
      expect(
        reviewedRoomPrompt(updated, draft, sourceImageId: room.originalId),
        contains('retained tree'),
      );
      expect(updated, contains('water-wise'));

      draft.setAustralianSetting(
        draft.australianSetting.copyWith(preferNativePlants: false),
      );
      expect(
        roomTemplatePrompt(room, draft),
        isNot(contains('favour Australian native plants')),
      );
      draft.setAustralianSetting(
        draft.australianSetting.copyWith(climateId: ''),
      );
      expect(
        roomTemplatePrompt(room, draft),
        isNot(contains('AUSTRALIAN SETTING')),
      );
    },
  );

  test('saved-design updates and precise corrections do not reapply regional styling', () {
    final draft = RoomDraft(store, room);
    addTearDown(draft.dispose);
    draft.setAustralianSetting(
      const AustralianDesignSettings(climateId: 'tropical'),
    );
    draft.correction.text = 'Repaint only the wall';
    draft.updatingSelectedDesign = true;
    draft.setDesignMode(RoomDesignMode.partial);
    expect(
      roomTemplatePrompt(room, draft),
      isNot(contains('AUSTRALIAN SETTING')),
    );
    draft.setDesignMode(RoomDesignMode.precise);
    expect(
      roomTemplatePrompt(room, draft),
      isNot(contains('AUSTRALIAN SETTING')),
    );
    expect(roomTemplatePrompt(room, draft), contains('Repaint only the wall'));
    final direct = buildRenovationPrompt(
      roomName: 'Kitchen',
      instructions: 'Repaint the wall',
      protectedFeatures: '',
      preciseEdit: true,
      australianSetting: draft.currentAustralianSetting,
    );
    expect(direct, isNot(contains('AUSTRALIAN SETTING')));
  });

  test(
    'settings allow-list rejects invalid fields and does not invent a climate',
    () {
      expect(
        AustralianDesignSettings.fromMap({'climateId': 'unknown'}).enabled,
        isFalse,
      );
      for (final invalid in [
        {'climateId': 12},
        {'preferNativePlants': 'true'},
        {'siteNotes': 'a' * 601},
      ]) {
        expect(
          () => DesignRecipe({'australianSetting': invalid}),
          throwsFormatException,
        );
      }
      final checked = DesignRecipe({
        'australianSetting': {
          'climateId': 'general',
          'apiKey': 'must-not-be-copied',
        },
      }).toMap();
      expect(
        (checked['australianSetting'] as Map).containsKey('apiKey'),
        isFalse,
      );
    },
  );

  for (final size in [const Size(320, 640), const Size(780, 390)]) {
    testWidgets('Australian style and optional property settings fit $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final draft = RoomDraft(store, room);
      addTearDown(draft.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListenableBuilder(
                listenable: draft,
                builder: (context, _) => DesignStyleControls(draft: draft),
              ),
            ),
          ),
        ),
      );
      expect(find.widgetWithText(FilterChip, 'Bushland retreat'), findsNothing);
      final style = find.widgetWithText(FilterChip, 'Australian');
      await tester.ensureVisible(style);
      await tester.tap(style);
      await tester.pumpAndSettle();
      expect(draft.styleIds, contains('australian'));
      expect(draft.australianSetting.enabled, isFalse);
      final setting = find.text('Australian property (optional)');
      await tester.ensureVisible(setting);
      await tester.tap(setting);
      await tester.pumpAndSettle();
      final location = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(location);
      await tester.tap(location);
      await tester.pumpAndSettle();
      await tester.tap(find.text(australianClimates['general']!).last);
      await tester.pumpAndSettle();
      final native = find.widgetWithText(
        CheckboxListTile,
        'Prefer suitable Australian native planting',
      );
      await tester.ensureVisible(native);
      await tester.tap(native);
      await tester.pumpAndSettle();
      expect(draft.australianSetting.preferNativePlants, isFalse);
      final notes = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.controller == draft.australianSiteNotes,
      );
      await tester.ensureVisible(notes);
      await tester.enterText(notes, 'Sunny courtyard, sandy soil');
      final climate = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(climate);
      await tester.tap(climate);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hot and dry / inland').last);
      await tester.pumpAndSettle();
      expect(draft.currentAustralianSetting.climateId, 'dry');
      expect(
        draft.currentAustralianSetting.siteNotes,
        'Sunny courtyard, sandy soil',
      );
      expect(draft.australianSetting.preferNativePlants, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await draft.save();
    });
  }
}
