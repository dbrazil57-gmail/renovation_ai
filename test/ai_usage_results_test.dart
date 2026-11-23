import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_usage.dart';
import 'package:renovision_ai/ai_usage_widgets.dart';
import 'package:renovision_ai/room_analysis.dart';

void main() {
  test('analysis prices returned input, cached input and complete output separately', () {
    final usage = AiUsage.openAiAnalysis({
      'input_tokens': 1000,
      'output_tokens': 100,
      'input_tokens_details': {'cached_tokens': 200},
      'output_tokens_details': {'reasoning_tokens': 30},
    }, 'gpt-6-luna');
    expect(usage.estimatedInputUsd, closeTo(.000082, 1e-12));
    expect(usage.estimatedOutputUsd, closeTo(.00005, 1e-12));
    expect(usage.estimatedUsd, closeTo(.000132, 1e-12));
    final tiny = AiUsage.openAiAnalysis({
      'input_tokens': 1,
      'output_tokens': 0,
    }, 'gpt-6-luna');
    expect(tiny.label, contains('0.00000010'));
    for (final invalid in [
      {'input_tokens': 100},
      {'input_tokens': -1, 'output_tokens': 1},
      {
        'input_tokens': 10,
        'output_tokens': 1,
        'input_tokens_details': {'cached_tokens': 11},
      },
    ]) {
      expect(
        AiUsage.openAiAnalysis(invalid, 'gpt-6-luna').estimatedUsd,
        isNull,
      );
    }
    expect(
      AiUsage.openAiAnalysis({
        'input_tokens': 10,
        'output_tokens': 1,
      }, 'unknown').estimatedUsd,
      isNull,
    );
    expect(
      AiUsage.openAiAnalysis(
        {'input_tokens': 10, 'output_tokens': 1},
        'gpt-6-luna',
        serviceTier: 'priority',
      ).estimatedUsd,
      isNull,
    );
  });

  test('saved analysis retains costs and old analysis remains readable without usage', () {
    final usage = AiUsage.openAiAnalysis({
      'input_tokens': 1000,
      'output_tokens': 100,
    }, 'gpt-4.1-mini');
    final result = RoomAnalysisResult(
      observations: 'Brick exterior.',
      questions: [],
      prompt: 'Retain brick; modernise trim.',
      model: 'gpt-4.1-mini',
      usage: usage,
    );
    final saved = RoomAnalysis(
      result: result,
      sourceImageId: 'photo',
      supportingImageIds: [],
      context: 'Exterior',
      created: DateTime.utc(2026, 11, 23),
    );
    final restored = RoomAnalysis.fromMap(
      jsonDecode(jsonEncode(saved.toMap())) as Map,
    );
    expect(restored.result.usage!.estimatedUsd, closeTo(.00056, 1e-12));
    final old = result.toMap()..remove('usage');
    expect(RoomAnalysisResult.fromMap(old).usage, isNull);
    expect(
      () => RoomAnalysisResult.fromMap({...old, 'usage': 'invalid'}),
      throwsFormatException,
    );
  });

  testWidgets(
    'result cost opens an input/output breakdown and unavailable cost stays explicit',
    (tester) async {
      final usage = AiUsage.openAiAnalysis({
        'input_tokens': 1000,
        'output_tokens': 100,
      }, 'gpt-6-luna');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiUsageSummary(
              operation: 'Analysis',
              usage: usage,
              model: 'gpt-6-luna',
            ),
          ),
        ),
      );
      await tester.tap(find.textContaining('Analysis · Estimated'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Prompt and photo input: US\$0.0001'),
        findsOneWidget,
      );
      expect(find.textContaining('Result output:'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AiUsageSummary(operation: 'Design')),
        ),
      );
      expect(
        find.text('Design · Cost unavailable for this saved result'),
        findsOneWidget,
      );
      expect(find.textContaining('US\$0.0000'), findsNothing);
    },
  );
}
