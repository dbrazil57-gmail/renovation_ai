import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_diagnostics.dart';
import 'package:renovision_ai/ai_diagnostics_widgets.dart';
import 'package:renovision_ai/ai_model_choices.dart';
import 'package:renovision_ai/ai_types.dart';

void main() {
  test(
    'log keeps the latest forty entries and strips arbitrary restored metadata',
    () {
      final log = AiDiagnostics();
      addTearDown(log.dispose);
      for (var i = 0; i < 45; i++) {
        log.record(
          operation: AiOperation.design,
          provider: AiProvider.gemini,
          model: geminiRoomImageModels.first,
          elapsed: Duration(milliseconds: i),
        );
      }
      expect(log.entries, hasLength(40));
      expect(log.entries.first['elapsedMs'], 44);
      expect(log.entries.last['elapsedMs'], 5);
      final restored = AiDiagnostics();
      addTearDown(restored.dispose);
      restored.restore([
        {
          ...log.entries.first,
          'model': 'PRIVATE KEY',
          'quality': 'PRIVATE PROMPT',
          'message': 'PRIVATE PHOTO',
          'headers': {'Authorization': 'SECRET'},
        },
        {'time': 'invalid', 'provider': 'gemini', 'operation': 'design'},
      ]);
      expect(restored.entries, hasLength(1));
      expect(restored.entries.single['model'], 'other');
      for (final value in ['PRIVATE', 'SECRET', 'Authorization']) {
        expect(restored.report, isNot(contains(value)));
      }
    },
  );

  testWidgets(
    'settings diagnostics opens, copies only the safe report, and clears the log',
    (tester) async {
      final log = AiDiagnostics();
      addTearDown(log.dispose);
      log.record(
        operation: AiOperation.design,
        provider: AiProvider.gemini,
        model: geminiRoomImageModels.last,
        elapsed: const Duration(seconds: 1),
        ok: false,
        failure: const AiFailure(
          'PRIVATE upstream detail',
          problem: AiProblem.options,
          statusCode: 400,
        ),
      );
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = call.arguments['text'] as String;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiDiagnosticsCard(diagnostics: log),
            ),
          ),
        ),
      );
      await tester.tap(find.text('AI diagnostics'));
      await tester.pumpAndSettle();
      expect(find.textContaining('HTTP 400'), findsOneWidget);
      await tester.tap(find.text('Copy diagnostics'));
      await tester.pumpAndSettle();
      expect(copied, log.report);
      expect(copied, isNot(contains('PRIVATE')));
      await tester.tap(find.text('Clear log'));
      await tester.pumpAndSettle();
      expect(log.entries, isEmpty);
    },
  );
}
