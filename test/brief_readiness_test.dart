import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/brief_readiness.dart';
import 'package:renovision_ai/focus_workspace.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

class BriefRecords extends MemoryBox {
  bool failReview = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (failReview && key.toString().startsWith('settings:brief_review:')) {
      throw StateError('Simulated reminder preference failure');
    }
    await super.put(key, value);
  }
}

void main() {
  BriefReadiness assess({
    bool image = true,
    bool precise = false,
    bool full = true,
    bool known = true,
    String instruction = '',
    bool changes = false,
    bool style = false,
    bool palette = false,
  }) => BriefReadiness.assess(
    imageAvailable: image,
    precise: precise,
    instruction: instruction,
    fullRoom: full,
    selectedChanges: changes,
    roomTypeKnown: known,
    styleDefined: style,
    paletteDefined: palette,
  );

  test('coverage increases with useful input; defaults allow a basic concept and clear styling can complete it', () {
    expect(assess(full: false, known: false).percentage, 40);
    expect(assess().percentage, 65);
    expect(assess(instruction: 'Replace the ceiling fitting').percentage, 75);
    expect(assess(style: true).percentage, 80);
    expect(assess(style: true, palette: true).percentage, 100);
    expect(assess(changes: true, style: true, palette: true).percentage, 100);
    expect(assess(image: false, style: true, palette: true).percentage, 65);
  });

  test('a precise correction needs an image and instruction, not room/style/palette extras', () {
    final correction = assess(
      precise: true,
      known: false,
      instruction: 'Remove the bin',
    );
    expect(correction.percentage, 100);
    expect(correction.missing, isEmpty);
    expect(assess(precise: true).percentage, 60);
    expect(
      assess(precise: true, image: false, instruction: 'Remove bin').percentage,
      45,
    );
    expect(assess(precise: true).recommendedTarget, BriefTarget.refine);
  });

  test('75 percent needs one review; low coverage always reminds again', () {
    final high = assess(instruction: 'New cupboards');
    expect(high.needsReminder(previouslyReviewed: false), true);
    expect(high.needsReminder(previouslyReviewed: true), false);
    expect(assess().needsReminder(previouslyReviewed: true), true);
    expect(
      assess(
        style: true,
        palette: true,
      ).needsReminder(previouslyReviewed: true),
      false,
    );
  });

  test('review preference survives store reload, is separate per room/mode and does not alter a project', () async {
    final records = MemoryBox(), photos = MemoryBox();
    final store = RenovisionStore(records: records, photos: photos);
    final project = await store.createProject('Sample');
    final image = img.encodePng(img.Image(width: 40, height: 30));
    final room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: image,
    );
    final before = room.toMap();
    await store.rememberBriefReview(room.id, precise: false);
    expect(store.roomById(room.id)!.toMap(), before);
    expect(
      utf8.decode(store.backupFor(project.id).encode()),
      isNot(contains('settings:brief_review')),
    );
    store.dispose();
    final reopened = RenovisionStore(records: records, photos: photos);
    addTearDown(reopened.dispose);
    expect(reopened.briefGuidanceReviewed(room.id, precise: false), true);
    expect(reopened.briefGuidanceReviewed(room.id, precise: true), false);
    expect(reopened.briefGuidanceReviewed('other-room', precise: false), false);
    expect(reopened.imageFor(room.originalId), orderedEquals(image));
  });

  group('workspace guidance', () {
    late RenovisionStore store;
    late BriefRecords records;
    late RenovationRoom room;
    late int imageRequests;
    setUp(() async {
      imageRequests = 0;
      final image = img.encodePng(img.Image(width: 40, height: 30));
      final ai = AiService(
        clientFactory: () => MockClient((request) async {
          if (request.url.path == '/health') {
            return http.Response(
              jsonEncode({
                'provider': 'OpenAI',
                'model': 'fixture',
                'quality': 'low',
              }),
              200,
            );
          }
          imageRequests++;
          return http.Response(
            jsonEncode({
              'provider': 'OpenAI',
              'model': 'fixture',
              'image': base64Encode(image),
            }),
            200,
          );
        }),
      );
      await ai.connect(url: 'http://127.0.0.1:8787', pairingCode: 'fixture');
      records = BriefRecords();
      store = RenovisionStore(records: records, photos: MemoryBox(), ai: ai);
      final project = await store.createProject('Sample');
      room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: image,
      );
    });
    tearDown(() => store.dispose());

    Future<void> show(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> generate(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('workspace-generate')));
      await tester.pumpAndSettle();
    }

    void expectScore(int percent) {
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('brief-readiness-indicator')),
          matching: find.text('Brief $percent% complete'),
        ),
        findsOneWidget,
      );
    }

    testWidgets(
      'low brief stays visible on every tab and Refine returns to visible inputs without an API request',
      (tester) async {
        await show(tester);
        for (final tab in FocusSection.values) {
          await tester.tap(find.byKey(ValueKey('focus-section-${tab.name}')));
          await tester.pumpAndSettle();
          expectScore(65);
        }
        await generate(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.byKey(const ValueKey('brief-readiness-guidance')),
          findsOneWidget,
        );
        await tester.tap(find.text('Refine brief'));
        await tester.pumpAndSettle();
        final input = find.widgetWithText(TextField, 'What should change?');
        expect(input.hitTestable(), findsOneWidget);
        await tester.enterText(input, 'Replace the main ceiling light');
        await tester.pump();
        expectScore(75);
        expect(imageRequests, 0);
        expect(store.briefGuidanceReviewed(room.id, precise: false), false);
        await tester.tap(find.text('Precise correction'));
        await tester.pumpAndSettle();
        expectScore(60);
        await generate(tester);
        expect(find.byType(AlertDialog), findsNothing);
        expect(imageRequests, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'checklist checkbox enables Proceed below 75 without sending until paid confirmation',
      (tester) async {
        await show(tester);
        expectScore(65);
        final indicator = find.byKey(
          const ValueKey('brief-readiness-indicator'),
        );
        final checkbox = find.byKey(const ValueKey('brief-proceed-checkbox'));
        await tester.tap(indicator);
        await tester.pumpAndSettle();
        expect(find.text('Refine brief'), findsOneWidget);
        expect(find.text('Proceed'), findsNothing);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
        expect(find.text('Proceed'), findsOneWidget);
        expect(find.text('Refine brief'), findsNothing);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
        expect(find.text('Refine brief'), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(imageRequests, 0);
        await tester.tap(indicator);
        await tester.pumpAndSettle();
        expect(tester.widget<CheckboxListTile>(checkbox).value, false);
        await tester.tap(checkbox);
        await tester.tap(find.byKey(const ValueKey('brief-review-primary')));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Send to OpenAI'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('brief-readiness-guidance')),
          findsNothing,
        );
        expect(imageRequests, 0);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(store.briefGuidanceReviewed(room.id, precise: false), false);
        await tester.tap(indicator);
        await tester.pumpAndSettle();
        await tester.tap(checkbox);
        await tester.tap(find.byKey(const ValueKey('brief-review-primary')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Send to OpenAI'));
        await tester.pumpAndSettle();
        expect(imageRequests, 1);
        expect(store.designsFor(room.id), hasLength(1));
        expect(store.briefGuidanceReviewed(room.id, precise: false), false);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a failed reminder preference does not duplicate or discard a confirmed image request',
      (tester) async {
        await store.updateRoom(
          room.copyWith(instructions: 'Update the lighting'),
        );
        records.failReview = true;
        await show(tester);
        expectScore(75);
        await generate(tester);
        await tester.tap(find.text('Send to OpenAI'));
        await tester.pumpAndSettle();
        expect(imageRequests, 1);
        expect(store.designsFor(room.id), hasLength(1));
        expect(store.briefGuidanceReviewed(room.id, precise: false), false);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'proceed can send a basic brief; high-score review persists and a later low score reminds again',
      (tester) async {
        await show(tester);
        // Basic 65% coverage is advisory, not a new gate or a paid analysis step.
        await generate(tester);
        await tester.tap(find.text('Send to OpenAI'));
        await tester.pumpAndSettle();
        expect(imageRequests, 1);
        expect(store.briefGuidanceReviewed(room.id, precise: false), false);
        await tester.tap(find.byKey(const ValueKey('focus-section-refine')));
        await tester.pumpAndSettle();
        final input = find.widgetWithText(TextField, 'What should change?');
        await tester.ensureVisible(input);
        await tester.enterText(input, 'Replace the main ceiling light');
        await tester.pump();
        expectScore(75);
        await generate(tester);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(store.briefGuidanceReviewed(room.id, precise: false), false);
        await generate(tester);
        await tester.tap(find.text('Send to OpenAI'));
        await tester.pumpAndSettle();
        expect(imageRequests, 2);
        expect(store.briefGuidanceReviewed(room.id, precise: false), true);
        await generate(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.byKey(const ValueKey('brief-readiness-guidance')),
          findsNothing,
        );
        expect(find.text('Send to OpenAI'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(imageRequests, 2);
        await tester.tap(find.byKey(const ValueKey('focus-section-refine')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(input);
        await tester.enterText(input, '');
        await tester.pump();
        expectScore(65);
        await generate(tester);
        expect(
          find.byKey(const ValueKey('brief-readiness-guidance')),
          findsOneWidget,
        );
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(imageRequests, 2);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
