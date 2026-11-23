import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/app_session.dart';
import 'package:renovision_ai/context_help.dart';
import 'package:renovision_ai/main.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';
import 'package:renovision_ai/walkthrough_content.dart';
import 'package:renovision_ai/walkthrough_screen.dart';

import 'support/memory_box.dart';

void size(WidgetTester tester, Size value) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = value;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  testWidgets(
    'app Help returns to the existing project without project writes or AI',
    (tester) async {
      size(tester, const Size(390, 844));
      var requests = 0;
      final records = MemoryBox(), photos = MemoryBox();
      final store = RenovisionStore(
        records: records,
        photos: photos,
        ai: AiService(
          clientFactory: () {
            requests++;
            throw StateError('Guide must stay offline');
          },
        ),
      );
      addTearDown(store.dispose);
      final project = await store.createProject('Existing home');
      await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: img.encodePng(img.Image(width: 30, height: 20)),
      );
      final recordsBefore = jsonEncode(records.entries);
      final photosBefore = jsonEncode(photos.entries);
      await tester.pumpWidget(RenovisionApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate((w) => w is HelpIcon && w.title == 'Projects'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sample walkthroughs'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(AppWalkthroughsScreen), findsOneWidget);
      expect(find.text('Camera & photos'), findsOneWidget);
      await tester.ensureVisible(find.text('Live view'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Live view'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Recorded app screens'), findsOneWidget);
      await tester.tap(find.text('Read steps'));
      await tester.pumpAndSettle();
      expect(find.text('Open Live design'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(AppWalkthroughsScreen), findsNothing);
      expect(find.byType(ProjectsTab), findsOneWidget);
      expect(store.projectById(project.id)!.name, 'Existing home');
      final after = Map.of(records.entries)..remove(AppPageSession.recordKey);
      expect(jsonEncode(after), recordsBefore);
      expect(records.get(AppPageSession.recordKey), [
        {'page': 'home', 'tab': 0},
      ]);
      expect(jsonEncode(photos.entries), photosBefore);
      expect(requests, 0);
      expect(store.ai.connected, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all sample paths can be followed, reversed and completed on a phone',
    (tester) async {
      size(tester, const Size(390, 844));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildRenovisionTheme(),
          home: const AppWalkthroughsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      for (final guide in appWalkthroughs) {
        await tester.ensureVisible(find.text(guide.title));
        await tester.pumpAndSettle();
        await tester.tap(find.text(guide.title));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Read steps'));
        await tester.pumpAndSettle();
        expect(find.text('Step 1 of ${guide.steps.length}'), findsOneWidget);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Previous'));
        await tester.pumpAndSettle();
        expect(find.text(guide.steps.first.title), findsOneWidget);
        for (var step = 1; step < guide.steps.length; step++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
          expect(find.text(guide.steps[step].title), findsOneWidget);
          expect(
            find.text('Step ${step + 1} of ${guide.steps.length}'),
            findsOneWidget,
          );
        }
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(find.byType(WalkthroughScreen), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  for (final dimensions in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('guides stay readable with large text at $dimensions', (
      tester,
    ) async {
      size(tester, dimensions);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildRenovisionTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: const AppWalkthroughsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Live view'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Live view'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read steps'));
      await tester.pumpAndSettle();
      for (var i = 1; i < liveWalkthrough.steps.length; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text(liveWalkthrough.steps.last.note!));
      expect(
        find.textContaining('Changing an option does not trigger'),
        findsOneWidget,
      );
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
