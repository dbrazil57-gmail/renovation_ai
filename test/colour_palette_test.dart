import 'support/focus_navigation.dart';

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/colour_palette_widgets.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void main() {
  late RenovisionStore store;
  late RenovationRoom room;
  late Uint8List image;
  setUp(() async {
    store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
    image = img.encodePng(img.Image(width: 40, height: 30));
    final project = await store.createProject('Claylands');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: image,
      additionalImages: [image],
      colourPaletteId: 'sage_oak',
    );
  });
  tearDown(() => store.dispose());

  testWidgets(
    'Style panel exposes palette and quick swatches save immediately',
    (tester) async {
      await store.setRoomPalette(room.id, '');
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('focus-section-style')));
      await tester.pumpAndSettle();
      expect(find.text('Colour palette').hitTestable(), findsOneWidget);
      await ensureFocusVisible(tester, find.byKey(const ValueKey('quick-palette-warm_neutrals')));
      expect(
        find.byKey(const ValueKey('quick-palette-warm_neutrals')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('quick-palette-warm_neutrals')),
      );
      await tester.pumpAndSettle();
      expect(store.roomById(room.id)!.colourPaletteId, 'warm_neutrals');
      expect(store.imageFor(room.originalId), orderedEquals(image));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('quick palette strip fits a phone-width screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: WorkspaceScreen(store: store, roomId: room.id),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('focus-section-style')));
    await tester.pumpAndSettle();
    expect(find.text('Colour palette').hitTestable(), findsOneWidget);
    final quick = find.byKey(const ValueKey('quick-palette-charcoal_walnut'));
    final horizontal = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.right,
    );
    await tester.scrollUntilVisible(quick, 170, scrollable: horizontal.last);
    await tester.pumpAndSettle();
    await ensureFocusVisible(tester, quick);
    await tester.tap(quick);
    await tester.pumpAndSettle();
    expect(store.roomById(room.id)!.colourPaletteId, 'charcoal_walnut');
    expect(tester.takeException(), isNull);
  });

  test('palette prompt records names, hex values and precision scope', () {
    final prompt = buildRenovationPrompt(
      roomName: 'Kitchen',
      instructions: 'Change only the island',
      protectedFeatures: 'Keep the wall cupboards',
      preciseEdit: true,
      colourPaletteId: 'charcoal_walnut',
    );
    expect(prompt, contains('COLOUR PALETTE: Charcoal & walnut'));
    expect(prompt, contains('Cabinetry: Warm charcoal (#383A37)'));
    expect(prompt, contains('Timber / finishes: Walnut brown (#77523B)'));
    expect(prompt, contains('only to the explicitly requested edit areas'));
    expect(prompt, contains('Keep the wall cupboards'));
    expect(
      prompt,
      contains('not permission to replace or repaint a protected item'),
    );
  });

  test('no preference adds no colour direction', () {
    final prompt = buildRenovationPrompt(
      roomName: 'Kitchen',
      instructions: '',
      protectedFeatures: '',
      preciseEdit: false,
    );
    expect(prompt, isNot(contains('COLOUR PALETTE:')));
  });

  test(
    'room creation, changes and restored copies retain palette and room data',
    () async {
      final design = await store.createDesign(
        roomId: room.id,
        image: image,
        title: 'Approved',
        prompt: 'Keep windows',
      );
      await store.approveBaseline(room.id, designId: design.id);
      final primary = store.roomById(room.id)!.photoIds.last;
      await store.setPrimaryPhoto(room.id, primary);
      await store.setRoomPalette(room.id, 'charcoal_walnut');
      final copy = store.roomById(room.id)!;
      expect(copy.colourPaletteId, 'charcoal_walnut');
      expect(copy.approvedDesignId, design.id);
      expect(copy.primaryId, primary);
      expect(copy.photoIds, hasLength(2));
      final restored = await store.restoreBackup(
        ProjectBackup.decode(store.backupFor(room.projectId).encode()),
      );
      expect(
        store.roomsFor(restored.id).single.colourPaletteId,
        'charcoal_walnut',
      );
      expect(store.imageFor(room.originalId), orderedEquals(image));
      await store.setRoomPalette(room.id, '');
      expect(store.roomById(room.id)!.colourPaletteId, '');
    },
  );

  test('legacy backups default to no preference; invalid palette types are rejected', () {
    final data = jsonDecode(
      utf8.decode(store.backupFor(room.projectId).encode()),
    ) as Map<String, dynamic>;
    (data['rooms'] as List).first.remove('colourPaletteId');
    final legacy = ProjectBackup.decode(
      Uint8List.fromList(utf8.encode(jsonEncode(data))),
    );
    expect(legacy.rooms.single.colourPaletteId, '');
    data['rooms'][0]['colourPaletteId'] = 123;
    expect(
      () => ProjectBackup.decode(
        Uint8List.fromList(utf8.encode(jsonEncode(data))),
      ),
      throwsA(isA<BackupFailure>()),
    );
  });

  test('invalid preset cannot change room or create a new room', () async {
    await expectLater(
      store.setRoomPalette(room.id, 'unknown'),
      throwsArgumentError,
    );
    await expectLater(
      store.createRoom(
        projectId: room.projectId,
        name: 'Other',
        originalImage: image,
        colourPaletteId: 'unknown',
      ),
      throwsArgumentError,
    );
    expect(store.roomById(room.id)!.colourPaletteId, 'sage_oak');
    expect(store.roomsFor(room.projectId), hasLength(1));
  });

  testWidgets(
    'upload palette chooser shows photo and permits a choice at phone width',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => selected = await chooseColourPalette(
                  context,
                  photos: [image],
                ),
                child: const Text('Choose'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      await ensureFocusVisible(
        tester,
        find.byKey(const ValueKey('palette-charcoal_walnut')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('palette-charcoal_walnut')));
      await tester.pump();
      await tester.tap(find.text('Use palette'));
      await tester.pumpAndSettle();
      expect(selected, 'charcoal_walnut');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelling palette changes leaves saved preference intact', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomColourPaletteCard(store: store, room: room, preview: image),
        ),
      ),
    );
    await tester.tap(find.text('Change palette'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('palette-')));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.roomById(room.id)!.colourPaletteId, 'sage_oak');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'workspace palette selection preserves draft and enters copied prompt',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      final instructions = find.widgetWithText(
        TextField,
        'What should change?',
      );
      await revealFocusControl(
        tester,
        instructions,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(instructions, 'Change only the island cupboards');
      await revealFocusControl(
        tester,
        find.text('Change palette'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await ensureFocusVisible(tester, find.text('Change palette'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change palette'));
      await tester.pumpAndSettle();
      await ensureFocusVisible(
        tester,
        find.byKey(const ValueKey('palette-charcoal_walnut')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('palette-charcoal_walnut')));
      await tester.tap(find.text('Use palette'));
      await tester.pumpAndSettle();
      expect(store.roomById(room.id)!.colourPaletteId, 'charcoal_walnut');
      await revealFocusControl(
        tester,
        find.text('Copy AI prompt'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await ensureFocusVisible(tester, find.text('Copy AI prompt'));
      await tester.tap(find.text('Copy AI prompt'));
      await tester.pumpAndSettle();
      expect(copied, contains('COLOUR PALETTE: Charcoal & walnut'));
      expect(copied, contains('Change only the island cupboards'));
      expect(store.roomById(room.id)!.photoIds, hasLength(2));
      expect(store.imageFor(room.originalId), orderedEquals(image));
      expect(tester.takeException(), isNull);
    },
  );
}
