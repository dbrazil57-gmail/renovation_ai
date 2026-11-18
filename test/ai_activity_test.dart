import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_activity.dart';
import 'package:renovision_ai/ai_activity_widget.dart';

void main() {
  test('elapsed time freezes after completion and an active task cannot be dismissed or replaced', () {
    var now = DateTime(2026, 11, 18, 12);
    final activity = AiActivity(now: () => now);
    activity.begin(roomId: 'room', operation: 'Design');
    now = now.add(const Duration(seconds: 65));
    activity.update(AiStage.waiting);
    activity.dismiss();
    expect(activity.active, isTrue);
    expect(
      () => activity.begin(roomId: 'other', operation: 'Analysis'),
      throwsStateError,
    );
    expect(activity.elapsed, const Duration(seconds: 65));
    activity.update(AiStage.saving);
    now = now.add(const Duration(seconds: 3));
    activity.update(AiStage.completed);
    now = now.add(const Duration(minutes: 5));
    expect(activity.elapsed, const Duration(seconds: 68));
    activity.dismiss();
    expect(activity.stage, AiStage.idle);
    activity.dispose();
  });

  testWidgets(
    'phone activity stays visible while content scrolls and never invents a percentage',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var now = DateTime(2026, 11, 18, 12);
      final activity = AiActivity(now: () => now);
      activity.begin(roomId: 'room', operation: 'Design');
      activity.update(AiStage.waiting);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                SizedBox(height: 2000, child: Text('Room settings')),
                Text('Bottom of settings'),
              ],
            ),
            bottomNavigationBar: AiActivityStrip(
              activity: activity,
              roomId: 'room',
            ),
          ),
        ),
      );
      now = now.add(const Duration(seconds: 37));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0:37 elapsed'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        isNull,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -1700));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.text('Design: sending / waiting for AI').hitTestable(),
        findsOneWidget,
      );
      expect(find.byTooltip('Dismiss activity'), findsNothing);
      activity.update(
        AiStage.failed,
        detail: 'Request timed out. No automatic retry was sent.',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Request timed out'), findsOneWidget);
      await tester.tap(find.byTooltip('Dismiss activity'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ai-elapsed')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      activity.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('activity for a different room is hidden', (tester) async {
    final activity = AiActivity()..begin(roomId: 'other', operation: 'Design');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AiActivityStrip(
            activity: activity,
            roomId: 'room',
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('ai-elapsed')), findsNothing);
    activity.update(AiStage.completed);
    await tester.pumpWidget(const SizedBox());
    activity.dispose();
  });
}
