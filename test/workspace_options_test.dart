import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/design_style_widgets.dart';
import 'package:renovision_ai/focus_workspace.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
import 'package:renovision_ai/renovation_scope_widgets.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/room_prompt.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void main() {
  late RenovisionStore store;
  late RenovationRoom room;
  late Uint8List image;
  late int paidRequests;
  setUp(() async {
    paidRequests = 0;
    final ai = AiService(
      clientFactory: () => MockClient((request) async {
        if (request.url.path == '/health') {
          return http.Response(
            jsonEncode({
              'provider': 'OpenAI',
              'model': 'test-image',
              'quality': 'low',
              'analysisModel': 'test-vision',
              'maxInputImages': 7,
            }),
            200,
          );
        }
        paidRequests++;
        throw StateError('No paid request authorized in this test');
      }),
    );
    await ai.connect(url: 'http://127.0.0.1:8787', pairingCode: 'fixture');
    store = RenovisionStore(records: MemoryBox(), photos: MemoryBox(), ai: ai);
    image = img.encodePng(img.Image(width: 40, height: 30));
    final project = await store.createProject('Fixture home');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Ensuite',
      roomTypeId: 'ensuite',
      originalImage: image,
    );
  });
  tearDown(() => store.dispose());

  test('full room includes ordinary updates and visible fittings but honours Keep; partial stays scoped', () async {
    final draft = RoomDraft(store, room);
    draft.setItemChoice('bathroom_vanity', 'keep');
    draft.flooringNotes.text = 'Large warm greige tiles';
    final full = roomTemplatePrompt(room, draft);
    expect(full, contains('WHOLE-ROOM DESIGN DIRECTION'));
    expect(full, contains('REPLACE Shower / screen'));
    expect(full, contains('KEEP EXISTING Vanity / basin'));
    expect(full, contains('Large warm greige tiles'));
    expect(full, contains('Keep the existing walls'));
    draft.setFullRenovation(false);
    draft.setScope('lighting', true);
    final partial = roomTemplatePrompt(room, draft);
    expect(partial, contains('PARTIAL RENOVATION'));
    expect(partial, isNot(contains('WHOLE-ROOM DESIGN DIRECTION')));
    expect(partial, isNot(contains('REPLACE Shower / screen')));
    expect(partial, contains('KEEP EXISTING Vanity / basin'));
    expect(partial, contains('Update visible light fittings'));
    await draft.save();
    draft.dispose();
    expect(paidRequests, 0);
  });

  test('renovation extent survives autosave, portable restore and saved-recipe reuse without changing legacy records', () async {
    final draft = RoomDraft(store, room);
    draft.setFullRenovation(false);
    draft.setItemChoice('bathroom_shower', 'replace');
    await draft.save();
    final recipe = draft.captureRecipe();
    expect(store.roomById(room.id)!.fullRenovation, false);
    draft.setFullRenovation(true);
    expect(await draft.applyRecipe(recipe), true);
    expect(draft.fullRenovation, false);
    final restored = await store.restoreBackup(
      ProjectBackup.decode(store.backupFor(room.projectId).encode()),
    );
    expect(store.roomsFor(restored.id).single.fullRenovation, false);
    final legacy = room.toMap()..remove('fullRenovation');
    expect(RenovationRoom.fromMap(legacy).fullRenovation, true);
    expect(store.imageFor(room.originalId), orderedEquals(image));
    draft.dispose();
  });

  testWidgets(
    'full room permits Keep exceptions and its switch opens individual changes',
    (tester) async {
      final draft = RoomDraft(store, room);
      draft.setItemChoice('bathroom_vanity', 'keep');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RenovationScopeControls(draft: draft),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Included items & saved exceptions'));
      await tester.pumpAndSettle();
      final vanity = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<String> &&
            w.decoration.labelText == 'Vanity / basin',
      );
      expect(
        tester.widget<DropdownButtonFormField<String>>(vanity).onChanged,
        isNotNull,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('renovation-extent')),
      );
      await tester.tap(find.byKey(const ValueKey('renovation-extent')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<DropdownButtonFormField<String>>(vanity).onChanged,
        isNotNull,
      );
      expect(draft.roomItemChoices['bathroom_vanity'], 'keep');
      await draft.save();
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );

  testWidgets(
    'style pages keep a cross-page selection and show at most ten choices',
    (tester) async {
      final draft = RoomDraft(store, room);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListenableBuilder(
                listenable: draft,
                builder: (_, _) => DesignStyleControls(draft: draft),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(FilterChip), findsNWidgets(10));
      await tester.tap(
        find.widgetWithText(FilterChip, 'Modern / Contemporary'),
      );
      for (var i = 0; i < 2; i++) {
        await tester.ensureVisible(
          find.byKey(const ValueKey('more-design-styles')),
        );
        await tester.tap(find.byKey(const ValueKey('more-design-styles')));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Italian'));
      await tester.tap(find.widgetWithText(FilterChip, 'Italian'));
      await tester.ensureVisible(
        find.byKey(const ValueKey('more-design-styles')),
      );
      await tester.tap(find.byKey(const ValueKey('more-design-styles')));
      await tester.pumpAndSettle();
      expect(draft.styleIds, containsAll(['modern', 'italian']));
      expect(find.byType(FilterChip), findsNWidgets(10));
      expect(
        find.textContaining('Selected: Modern / Contemporary + Italian'),
        findsOneWidget,
      );
      await draft.save();
      await tester.pumpWidget(const SizedBox());
      draft.dispose();
    },
  );

  testWidgets(
    'pinned Generate opens the same confirmation from every tab; cancel sends no requests',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      for (final section in FocusSection.values) {
        await tester.tap(find.byKey(ValueKey('focus-section-${section.name}')));
        await tester.pumpAndSettle();
        final action = find.byKey(const ValueKey('workspace-generate'));
        expect(action.hitTestable(), findsOneWidget);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.text('Send to OpenAI'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
      expect(paidRequests, 0);
      expect(store.designsFor(room.id), isEmpty);
      expect(store.imageFor(room.originalId), orderedEquals(image));
      expect(tester.takeException(), isNull);
    },
  );
}
