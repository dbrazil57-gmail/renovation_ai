import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/app_appearance.dart';
import 'package:renovision_ai/app_appearance_widgets.dart';
import 'package:renovision_ai/file_transfer.dart';
import 'package:renovision_ai/main.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/storage_privacy_widgets.dart';
import 'package:renovision_ai/store.dart';

import 'support/focus_navigation.dart';
import 'support/memory_box.dart';

class AppearanceRecords extends MemoryBox {
  bool fail = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (fail && key == 'settings:appearance') {
      throw StateError('Synthetic write failure');
    }
    await super.put(key, value);
  }
}

class UnchangedFile implements ReusableSaveDestination {
  @override
  Future<FileSaveResult> write(Uint8List bytes) async => FileSaveResult.saved;
}

class LocatedBox extends MemoryBox {
  final String location;
  LocatedBox(this.location);
  @override
  String get path => location;
}

void main() {
  test('brand default adopts legacy olive while explicit alternatives remain restorable', () async {
    final records = AppearanceRecords(), photos = MemoryBox();
    await records.put('settings:appearance', {'theme': 'warmOlive'});
    final store = RenovisionStore(records: records, photos: photos);
    expect(store.appearance.value, AppThemeChoice.brandGreen);
    await store.setAppTheme(AppThemeChoice.warmOlive);
    store.dispose();
    final reopened = RenovisionStore(records: records, photos: photos);
    expect(reopened.appearance.value, AppThemeChoice.warmOlive);
    reopened.dispose();
    expect(
      AppThemeChoice.fromSaved({'theme': 'forestGreen'}),
      AppThemeChoice.forestGreen,
    );
    expect(AppThemeChoice.fromSaved(null), AppThemeChoice.brandGreen);
  });
  test('appearance persists, falls back safely and never marks project files dirty or changes room choices', () async {
    final records = AppearanceRecords(), photos = MemoryBox();
    await records.put('settings:appearance', {'theme': 'unknown-legacy-theme'});
    final store = RenovisionStore(records: records, photos: photos);
    expect(store.appearance.value, AppThemeChoice.brandGreen);
    final project = await store.createProject('Existing home');
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: Uint8List.fromList([1, 2, 3]),
      colourPaletteId: 'charcoal_walnut',
      designStyleIds: ['modern'],
    );
    store.documents.attach(project.id, UnchangedFile(), alreadySaved: true);
    await store.setAppTheme(AppThemeChoice.oceanBlue);
    expect(store.documents.hasPending(project.id), isFalse);
    expect(store.roomById(room.id)!.colourPaletteId, 'charcoal_walnut');
    expect(store.backupFor(project.id).rooms.single.designStyleIds, ['modern']);
    records.fail = true;
    await expectLater(
      store.setAppTheme(AppThemeChoice.terracotta),
      throwsStateError,
    );
    expect(store.appearance.value, AppThemeChoice.oceanBlue);
    store.dispose();
    final reopened = RenovisionStore(records: records, photos: photos);
    expect(reopened.appearance.value, AppThemeChoice.oceanBlue);
    expect(reopened.imageFor(room.originalId), [1, 2, 3]);
    reopened.dispose();
  });

  testWidgets(
    'all themes preview in Settings without navigating away or losing an unsaved workspace draft',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
      addTearDown(store.dispose);
      final project = await store.createProject('Home');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        roomTypeId: 'kitchen',
        originalImage: img.encodePng(img.Image(width: 40, height: 30)),
      );
      await store.setAutosaveEnabled(false);
      await tester.pumpWidget(RenovisionApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue Kitchen'));
      await tester.pumpAndSettle();
      final input = find.widgetWithText(TextField, 'What should change?');
      await ensureFocusVisible(tester, input);
      await tester.enterText(input, 'Keep this unfinished design brief.');
      await tester.tap(find.byTooltip('Room settings'));
      await tester.pumpAndSettle();
      final appearance = find.byKey(const ValueKey('app-appearance-settings'));
      await revealFocusControl(tester, appearance, 200);
      await Scrollable.ensureVisible(tester.element(appearance), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(find.text('App appearance'));
      await tester.pumpAndSettle();
      for (final choice in AppThemeChoice.values) {
        final target = find.byKey(ValueKey('app-theme-${choice.name}'));
        await revealFocusControl(tester, target, 150);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(store.appearance.value, choice);
        expect(tester.widget<ChoiceChip>(target).selected, isTrue);
        expect(
          Theme.of(tester.element(target)).extension<AppAppearance>()!.canvas,
          choice.colours.canvas,
        );
        expect(find.byType(SettingsTab), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(input).controller!.text,
        'Keep this unfinished design brief.',
      );
      expect(store.roomById(room.id)!.instructions, isEmpty);
      expect(store.autosaveEnabled, isFalse);
      expect(store.roomById(room.id)!.photoIds, [room.originalId]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'theme save failure keeps the previous choice and fits enlarged phone text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final records = AppearanceRecords()..fail = true;
      final store = RenovisionStore(records: records, photos: MemoryBox());
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildRenovisionTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AppAppearanceSettingsCard(store: store),
            ),
          ),
        ),
      );
      final choice = find.byKey(const ValueKey('app-theme-oceanBlue'));
      await tester.tap(find.byKey(const ValueKey('app-appearance-settings')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(store.appearance.value, AppThemeChoice.brandGreen);
      expect(find.textContaining('Theme could not be saved'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'storage details show actual local paths and distinguish backup protection from local-store encryption',
    (tester) async {
      final store = RenovisionStore(
        records: LocatedBox('/private/project-data.hive'),
        photos: LocatedBox('/private/room-photos.hive'),
      );
      addTearDown(store.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StoragePrivacyCard(store: store),
            ),
          ),
        ),
      );
      expect(find.textContaining('app-level encryption'), findsNothing);
      await tester.tap(find.text('Storage and privacy'));
      await tester.pumpAndSettle();
      expect(find.textContaining('app-level encryption'), findsOneWidget);
      expect(
        find.textContaining('protects only the exported .renovision file'),
        findsOneWidget,
      );
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        contains('/private/room-photos.hive'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('all theme accent and text colours retain readable contrast', () {
    for (final choice in AppThemeChoice.values) {
      final colours = choice.colours;
      final textContrast =
          (colours.paper.computeLuminance() + .05) /
          (colours.ink.computeLuminance() + .05);
      final buttonContrast = 1.05 / (colours.accent.computeLuminance() + .05);
      expect(textContrast, greaterThanOrEqualTo(4.5));
      expect(buttonContrast, greaterThanOrEqualTo(4.5));
    }
  });
}
