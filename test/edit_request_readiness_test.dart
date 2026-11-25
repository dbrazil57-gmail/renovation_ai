import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/ai_widgets.dart';
import 'package:renovision_ai/brief_readiness.dart';
import 'package:renovision_ai/brief_readiness_widgets.dart';
import 'package:renovision_ai/focus_workspace.dart';
import 'package:renovision_ai/main.dart' show buildRenovisionTheme;
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';

import 'support/focus_navigation.dart';
import 'support/memory_box.dart';

void main() {
  for (final (mode, generated) in [
    (RoomDesignMode.partial, false),
    (RoomDesignMode.partial, true),
    (RoomDesignMode.precise, false),
    (RoomDesignMode.precise, true),
  ]) {
    testWidgets(
      '$mode on ${generated ? 'generated' : 'original'} image cannot proceed without its own change',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var paid = 0;
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
            paid++;
            throw StateError('No paid request expected');
          }),
        );
        await ai.connect(url: 'http://127.0.0.1:8787', pairingCode: 'fixture');
        final store = RenovisionStore(
          records: MemoryBox(),
          photos: MemoryBox(),
          ai: ai,
        );
        addTearDown(store.dispose);
        final project = await store.createProject('Edit readiness fixture');
        final photo = img.encodePng(img.Image(width: 60, height: 40));
        final room = await store.createRoom(
          projectId: project.id,
          name: 'Kitchen',
          originalImage: photo,
        );
        await store.updateRoom(
          room.copyWith(
            instructions: mode == RoomDesignMode.partial && !generated
                ? ''
                : 'Original whole-room renovation goal',
            designStyleIds: ['modern'],
            colourPaletteId: 'sage_oak',
            renovationScopeIds: generated ? ['flooring'] : [],
          ),
        );
        final design = await store.createDesign(
          roomId: room.id,
          image: photo,
          title: 'Chosen concept',
          prompt: 'Historical brief',
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: buildRenovisionTheme(),
            home: WorkspaceScreen(
              store: store,
              roomId: room.id,
              initialDesignId: generated ? design.id : null,
              initialSection: FocusSection.refine,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final modeLabel = mode == RoomDesignMode.partial
            ? 'Partial'
            : 'Precise correction';
        await ensureFocusVisible(tester, find.text(modeLabel));
        await tester.tap(find.text(modeLabel));
        await tester.pumpAndSettle();
        final send = find.byKey(const ValueKey('workspace-generate'));
        final review = find.byKey(const ValueKey('brief-readiness-indicator'));
        bool enabled(Finder target) =>
            tester.widget<FilledButton>(target).onPressed != null;
        expect(enabled(send), false);
        expect(
          find.descendant(of: review, matching: find.textContaining('%')),
          findsNothing,
        );
        await tester.tap(review);
        await tester.pumpAndSettle();
        expect(
          find.text(
            mode == RoomDesignMode.partial
                ? 'Review changes'
                : 'Review correction',
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('brief-proceed-checkbox')),
          findsNothing,
        );
        final primary = find.byKey(const ValueKey('brief-review-primary'));
        expect(enabled(primary), false);
        await tester.tap(primary);
        await tester.pumpAndSettle();
        expect(find.text('Send to OpenAI'), findsNothing);
        expect(paid, 0);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        if (!generated && mode == RoomDesignMode.partial) {
          final draft = tester
              .widget<AiEditCard>(find.byType(AiEditCard, skipOffstage: false))
              .draft!;
          draft.setScope('flooring', true);
          await tester.pumpAndSettle();
          expect(
            enabled(send),
            true,
            reason: 'Selected partial items can supply the request.',
          );
          draft.setScope('flooring', false);
          await tester.pumpAndSettle();
          expect(enabled(send), false);
        }
        final input = generated
            ? find.byKey(const ValueKey('selected-design-update'))
            : find.widgetWithText(
                TextField,
                mode == RoomDesignMode.precise
                    ? 'Specific correction'
                    : 'What should change?',
              );
        await ensureFocusVisible(tester, input);
        await tester.enterText(input, '   ');
        await tester.pump();
        expect(enabled(send), false);
        if (mode == RoomDesignMode.precise) {
          await tester.enterText(input, 'All');
          await tester.pump();
          expect(
            enabled(send),
            false,
            reason: 'A whole-room request is not a precise correction.',
          );
        }
        await tester.enterText(
          input,
          'Replace only the tap with a brushed brass mixer',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(enabled(send), true);
        await tester.tap(review);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('brief-proceed-checkbox')),
          findsNothing,
        );
        expect(enabled(primary), true);
        await tester.tap(primary);
        await tester.pumpAndSettle();
        expect(find.text('Send to OpenAI'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('brief-readiness-guidance')),
          findsNothing,
        );
        expect(paid, 0);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await ensureFocusVisible(tester, input);
        await tester.enterText(input, '');
        await tester.pump();
        expect(enabled(send), false);
        expect(store.designsFor(room.id), hasLength(1));
        expect(store.imageFor(room.originalId), orderedEquals(photo));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'a missing photo cannot be bypassed by a new-design brief checkbox',
    (tester) async {
      final readiness = BriefReadiness.assess(
        imageAvailable: false,
        precise: false,
        instruction: '',
        fullRoom: true,
        selectedChanges: false,
        roomTypeKnown: true,
        styleDefined: false,
        paletteDefined: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => reviewBrief(context, readiness),
                child: const Text('Review'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      final checkbox = find.byKey(const ValueKey('brief-proceed-checkbox'));
      expect(tester.widget<CheckboxListTile>(checkbox).onChanged, isNull);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(checkbox).value, false);
      expect(find.text('Proceed'), findsNothing);
      expect(find.text('Refine brief'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    },
  );

  test(
    'new design allows optional details; partial and precise need a target',
    () {
      BriefReadiness assess({
        bool full = true,
        bool precise = false,
        bool selected = false,
        String text = '',
      }) => BriefReadiness.assess(
        imageAvailable: true,
        precise: precise,
        instruction: text,
        fullRoom: full,
        selectedChanges: selected,
        roomTypeKnown: true,
        styleDefined: true,
        paletteDefined: true,
      );
      expect(assess().canProceed, true);
      expect(assess(full: false).canProceed, false);
      expect(assess(full: false, selected: true).canProceed, true);
      expect(assess(precise: true, selected: true).canProceed, false);
      expect(assess(precise: true, text: 'All').canProceed, false);
      expect(
        assess(precise: true, text: 'Change only the tap').canProceed,
        true,
      );
      expect(
        assess(
          full: false,
          text: 'Change the cabinets',
        ).needsReminder(previouslyReviewed: false),
        false,
      );
    },
  );
}
