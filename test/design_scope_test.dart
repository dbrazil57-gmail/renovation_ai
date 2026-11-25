import 'support/focus_navigation.dart';

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/design_style_widgets.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void main() {
  late RenovisionStore store;
  late RenovationRoom room;
  late Uint8List image;
  late int edits;
  late Map<String, dynamic>? sent;
  setUp(() async {
    edits = 0;
    sent = null;
    image = img.encodePng(img.Image(width: 40, height: 30));
    final ai = AiService(
      clientFactory: () => MockClient((request) async {
        if (request.url.path == '/health') {
          return http.Response(
            jsonEncode({
              'provider': 'OpenAI',
              'model': 'test-image',
              'analysisModel': 'test-vision',
              'quality': 'low',
              'maxInputImages': 7,
            }),
            200,
          );
        }
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        if (request.url.path == '/analyse') {
          return http.Response(
            jsonEncode({
              'provider': 'OpenAI',
              'model': 'test-vision',
              'observations': 'A kitchen with a peninsula.',
              'questions': [],
              'prompt': 'Refresh this kitchen and keep its layout.',
            }),
            200,
          );
        }
        edits++;
        return http.Response(
          jsonEncode({
            'provider': 'OpenAI',
            'model': 'test-image',
            'image': base64Encode(image),
          }),
          200,
        );
      }),
    );
    await ai.connect(url: 'http://127.0.0.1:8787', pairingCode: 'test-code');
    store = RenovisionStore(records: MemoryBox(), photos: MemoryBox(), ai: ai);
    final project = await store.createProject('Claylands');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: image,
    );
  });
  tearDown(() => store.dispose());

  Future<void> showRoom(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WorkspaceScreen(
          store: store,
          roomId: room.id,
          startInPrecision: store.roomById(room.id)!.preciseEdit,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reach(
    WidgetTester tester,
    Finder target, {
    bool up = false,
  }) async {
    await revealFocusControl(
      tester,
      target,
      up ? -300 : 300,
      scrollable: find.byType(Scrollable).first,
    );
    await ensureFocusVisible(tester, target);
    await tester.pumpAndSettle();
  }

  Future<void> openAdvanced(WidgetTester tester, {bool up = false}) async {
    final control = find.byKey(const ValueKey('renovation-extent'));
    await reach(tester, control, up: up);
    if (tester.widget<SwitchListTile>(control).value) await tester.tap(control);
    await tester.pumpAndSettle();
    await reach(tester, find.text('Choose individual changes'));
    await tester.tap(find.text('Choose individual changes'));
    await tester.pumpAndSettle();
  }

  test('combined style is deduplicated and selected changes explicitly replace the floor and remove the telephone', () {
    final prompt = buildRenovationPrompt(
      roomName: 'Kitchen',
      instructions: '',
      protectedFeatures: 'Keep windows and doors',
      preciseEdit: true,
      designStyleIds: ['contemporary', 'modern'],
      renovationScopeIds: ['flooring', 'dated_fixtures'],
      flooringNotes: 'Large-format warm greige tiles',
      removeItems: 'Old blind',
    );
    expect(RegExp('Modern / Contemporary').allMatches(prompt), hasLength(1));
    expect(
      prompt,
      contains('Replace the existing flooring across the visible room'),
    );
    expect(prompt, contains('Do not retain the old floor pattern'));
    expect(prompt, contains('Large-format warm greige tiles'));
    expect(prompt, contains('telephones or handsets and their visible cords'));
    expect(prompt, contains('Patch and finish the exposed wall'));
    expect(
      prompt,
      contains('Other items explicitly requested for removal: Old blind'),
    );
    expect(
      prompt,
      contains('Protected features take priority over these selections'),
    );
    expect(
      prompt,
      contains('Retain power points, light switches, safety devices'),
    );
    expect(prompt, isNot(contains('No specific edit was provided')));
    final unselected = buildRenovationPrompt(
      roomName: 'Kitchen',
      instructions: 'Change oven',
      protectedFeatures: '',
      preciseEdit: true,
      flooringNotes: 'Unused floor note',
    );
    expect(unselected, isNot(contains('Unused floor note')));
    expect(unselected, isNot(contains('Remove obsolete wall-mounted')));
  });

  testWidgets(
    'legacy Contemporary selection shows one selected combined chip and can be cleared',
    (tester) async {
      await store.updateRoom(room.copyWith(designStyleIds: ['contemporary']));
      final draft = RoomDraft(store, store.roomById(room.id)!);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: draft,
              builder: (context, _) => SingleChildScrollView(
                child: DesignStyleControls(draft: draft),
              ),
            ),
          ),
        ),
      );
      final chip = find.widgetWithText(FilterChip, 'Modern / Contemporary');
      expect(tester.widget<FilterChip>(chip).selected, true);
      expect(find.widgetWithText(FilterChip, 'Contemporary'), findsNothing);
      expect(store.roomById(room.id)!.designStyleIds, ['contemporary']);
      await tester.tap(chip);
      await tester.pump(const Duration(milliseconds: 700));
      expect(store.roomById(room.id)!.designStyleIds, isEmpty);
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );

  testWidgets(
    'phone-width checklist autosaves, feeds copied prompt and survives backup restoration',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
      await showRoom(tester);
      await openAdvanced(tester);
      final floor = find.text('Replace flooring');
      await reach(tester, floor);
      await tester.tap(floor);
      final floorNotes = find.widgetWithText(
        TextField,
        'New flooring / finish (optional)',
      );
      await reach(tester, floorNotes);
      await tester.enterText(floorNotes, 'Large-format greige tiles');
      final phone = find.text('Remove dated wall fixtures / old telephone');
      await reach(tester, phone, up: true);
      await tester.tap(phone);
      final remove = find.widgetWithText(
        TextField,
        'Other items to remove (optional)',
      );
      await reach(tester, remove);
      await tester.enterText(remove, 'Old roller blind');
      await tester.pump(const Duration(milliseconds: 700));
      final saved = store.roomById(room.id)!;
      expect(saved.renovationScopeIds, ['flooring', 'dated_fixtures']);
      expect(saved.flooringNotes, 'Large-format greige tiles');
      expect(saved.removeItems, 'Old roller blind');
      await reach(tester, find.text('Copy AI prompt'));
      await tester.tap(find.text('Copy AI prompt'));
      await tester.pumpAndSettle();
      expect(copied, contains('Large-format greige tiles'));
      expect(copied, contains('telephones or handsets'));
      expect(copied, contains('Old roller blind'));
      expect(edits, 0);
      final copy = await store.restoreBackup(
        ProjectBackup.decode(store.backupFor(room.projectId).encode()),
      );
      final restored = store.roomsFor(copy.id).single;
      expect(restored.renovationScopeIds, saved.renovationScopeIds);
      expect(restored.flooringNotes, saved.flooringNotes);
      expect(restored.removeItems, saved.removeItems);
      expect(store.imageFor(room.originalId), orderedEquals(image));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'conflicting All precision request shows a dialog for copy and generation without calling AI',
    (tester) async {
      await store.updateRoom(
        room.copyWith(
          preciseEdit: true,
          instructions: 'All',
          correctionInstructions: 'All',
        ),
      );
      await showRoom(tester);
      for (final label in ['Copy AI prompt', 'Generate AI design']) {
        final action = label == 'Generate AI design'
            ? aiGenerateAction()
            : find.text(label);
        await reach(tester, action, up: label == 'Generate AI design');
        await tester.tap(action);
        await tester.pumpAndSettle();
        if (label == 'Generate AI design') {
          expect(
            tester
                .widget<FilledButton>(
                  find.byKey(const ValueKey('workspace-generate')),
                )
                .onPressed,
            isNull,
          );
          expect(find.byType(AlertDialog), findsNothing);
          continue;
        }
        expect(find.text('Check the design request'), findsOneWidget);
        expect(find.textContaining('is a whole-room request'), findsOneWidget);
        expect(edits, 0);
        expect(sent, isNull);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }
      await reach(tester, find.text('Analyse photos with AI'), up: true);
      await tester.tap(find.text('Analyse photos with AI'));
      await tester.pumpAndSettle();
      expect(find.textContaining('is a whole-room request'), findsOneWidget);
      expect(sent, isNull);
    },
  );

  testWidgets(
    'precision correction excludes saved whole-room replacements and preserves both briefs in backup',
    (tester) async {
      await store.updateRoom(
        room.copyWith(
          preciseEdit: true,
          instructions: 'Modernise the whole kitchen',
          correctionInstructions: 'Remove only cupboard handles',
          renovationScopeIds: ['flooring', 'tidy_stage', 'cabinetry'],
          roomItemChoices: {
            'kitchen_oven': 'replace',
            'kitchen_microwave': 'keep',
          },
          designStyleIds: ['modern'],
          colourPaletteId: 'charcoal_walnut',
        ),
      );
      await showRoom(tester);
      expect(find.text('Advanced Keep / Replace controls'), findsNothing);
      final correction = find.widgetWithText(TextField, 'Specific correction');
      await reach(tester, correction);
      await tester.enterText(correction, 'Remove only the cupboard handles');
      await tester.pump(const Duration(milliseconds: 700));
      await reach(tester, aiGenerateAction());
      await tester.tap(aiGenerateAction());
      await tester.pumpAndSettle();
      expect(find.text('Send this edit to OpenAI?'), findsOneWidget);
      await tester.tap(find.text('Send to OpenAI'));
      await tester.pumpAndSettle();
      expect(edits, 1);
      expect(sent!['prompt'], contains('Remove only the cupboard handles'));
      expect(sent!['prompt'], contains('PRECISION EDIT:'));
      expect(sent!['prompt'], isNot(contains('REPLACE Oven')));
      expect(sent!['prompt'], contains('KEEP EXISTING Microwave:'));
      expect(sent!['prompt'], isNot(contains('Modernise the whole kitchen')));
      expect(sent!['prompt'], isNot(contains('DESIGN STYLE:')));
      expect(sent!['prompt'], isNot(contains('COLOUR PALETTE:')));
      expect(sent!['prompt'], isNot(contains('WHOLE-ROOM DESIGN DIRECTION')));
      expect(sent!['prompt'], isNot(contains('Remove obsolete wall-mounted')));
      expect(sent!['prompt'], isNot(contains('Replace the existing flooring')));
      expect(store.designsFor(room.id).single.prompt, sent!['prompt']);
      expect(store.roomById(room.id)!.approvedDesignId, isNull);
      final restoredProject = await store.restoreBackup(
        ProjectBackup.decode(store.backupFor(room.projectId).encode()),
      );
      final restored = store.roomsFor(restoredProject.id).single;
      expect(restored.instructions, 'Modernise the whole kitchen');
      expect(
        restored.correctionInstructions,
        'Remove only the cupboard handles',
      );
      expect(restored.renovationScopeIds, [
        'flooring',
        'tidy_stage',
        'cabinetry',
      ]);
      expect(restored.roomItemChoices, {
        'kitchen_oven': 'replace',
        'kitchen_microwave': 'keep',
      });
      await reach(tester, find.text('New design'), up: true);
      await tester.tap(find.text('New design'));
      await tester.pumpAndSettle();
      final wholeRoomField = find.widgetWithText(
        TextField,
        'What should change?',
      );
      await reach(tester, wholeRoomField);
      expect(
        tester.widget<TextField>(wholeRoomField).controller!.text,
        'Modernise the whole kitchen',
      );
    },
  );

  testWidgets(
    'changing renovation scope excludes the earlier proposal without blocking a confirmed generation',
    (tester) async {
      await store.updateRoom(
        store.roomById(room.id)!.copyWith(fullRenovation: false),
      );
      await showRoom(tester);
      await reach(tester, find.text('Analyse photos with AI'));
      await tester.tap(find.text('Analyse photos with AI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send photos for analysis'));
      await tester.pumpAndSettle();
      expect(store.roomById(room.id)!.useAiPrompt, true);
      await openAdvanced(tester);
      await reach(tester, find.text('Replace flooring'));
      await tester.tap(find.text('Replace flooring'));
      await reach(tester, aiGenerateAction());
      await tester.tap(aiGenerateAction());
      await tester.pumpAndSettle();
      expect(find.text('Send this edit to OpenAI?'), findsOneWidget);
      await tester.tap(find.text('Send to OpenAI'));
      await tester.pumpAndSettle();
      expect(edits, 1);
      expect(
        store.designsFor(room.id).single.prompt,
        contains('Replace the existing flooring'),
      );
      expect(
        store.designsFor(room.id).single.prompt,
        isNot(contains('AI DESIGN PROPOSAL')),
      );
      expect(store.roomById(room.id)!.analysis, isNotNull);
    },
  );
}
