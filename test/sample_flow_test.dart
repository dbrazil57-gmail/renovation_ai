import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/sample_flow.dart';
import 'package:renovision_ai/main.dart';
import 'package:renovision_ai/store.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/app_store_scope.dart';

import 'support/memory_box.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> ready(WidgetTester tester) async {
    for (var i = 0; i < 120; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      if (find.textContaining('1/4').evaluate().isNotEmpty) {
        await tester.pumpAndSettle();
        return;
      }
    }
    fail('Sample assets did not load');
  }

  test('authorised sample has actual historical brief, three images and portable practice references without invented AI metadata', () async {
    final flow = await SampleFlow.load(),
        backup = await SampleFlow.load().then((v) => v.practiceBackup());
    expect(flow.images.length, 3);
    expect(
      flow.notes['historicalPrompt'],
      contains('Need to update and modernise'),
    );
    expect(flow.notes['ideaPromptStatus'], contains('Illustrative'));
    expect(
      backup.designs.every(
        (v) => v.aiModel == null && v.providerRequestId == null,
      ),
      true,
    );
    final copy = jsonDecode(utf8.decode(backup.encode())) as Map;
    expect(copy['photos'].length, 3);
    expect(copy['designs'].length, 2);
  });
  testWidgets(
    'sample replay stays offline and practice import preserves customer work and is reused',
    (tester) async {
      var requests = 0, opened = 0;
      final store = RenovisionStore(
        records: MemoryBox(),
        photos: MemoryBox(),
        ai: AiService(
          clientFactory: () {
            requests++;
            throw StateError('Offline sample');
          },
        ),
      );
      addTearDown(store.dispose);
      final customer = await store.createProject('Existing private project');
      await tester.pumpWidget(
        AppStoreScope(
          store: store,
          openRoom: (_, _, _) => opened++,
          child: MaterialApp(
            theme: buildRenovisionTheme(),
            home: const SampleFlowScreen(),
          ),
        ),
      );
      await ready(tester);
      expect(store.projects.length, 1);
      await tester.tap(find.byTooltip('Next sample stage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View saved brief'));
      await tester.pumpAndSettle();
      expect(find.textContaining('EXPLORATION:'), findsOneWidget);
      await tester.ensureVisible(find.text('Try a separate practice project'));
      await tester.tap(find.text('Try a separate practice project'));
      await tester.pumpAndSettle();
      expect(store.projects.length, 2);
      expect(opened, 1);
      expect(
        store.projects.any(
          (v) => v.id == customer.id && v.name == 'Existing private project',
        ),
        true,
      );
      await tester.tap(find.text('Try a separate practice project'));
      await tester.pumpAndSettle();
      expect(store.projects.length, 2);
      expect(opened, 2);
      expect(requests, 0);
    },
  );
  testWidgets(
    'sample stages fit small phone and landscape with enlarged text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final size in [const Size(320, 568), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildRenovisionTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: SampleFlowScreen(key: ValueKey(size)),
          ),
        );
        await ready(tester);
        for (var i = 0; i < 3; i++) {
          await tester.ensureVisible(find.byTooltip('Next sample stage'));
          await tester.tap(find.byTooltip('Next sample stage'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}
