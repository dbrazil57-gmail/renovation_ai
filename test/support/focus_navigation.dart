import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/focus_workspace.dart';

/// Workspace has the pinned send action; standalone generation cards keep
/// their existing label. Both lead to the provider/photo confirmation.
Finder aiGenerateAction() => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data == 'Send to AI' || widget.data == 'Generate AI design'),
);

Future<void> _openAnalysisDetails(WidgetTester tester, Finder target) async {
  if (target.evaluate().isNotEmpty) return;
  final details = find.widgetWithText(
    ExpansionTile,
    'Room observations and design plan',
  );
  if (details.evaluate().isNotEmpty) {
    final heading = find.text('Room observations and design plan');
    await tester.ensureVisible(heading);
    await tester.pumpAndSettle();
    await tester.tap(heading);
    await tester.pumpAndSettle();
  }
}

/// Follow the same section navigation as a user before locating a control.
Future<bool> _focusTarget(WidgetTester tester, Finder target) async {
  if (find.byType(FocusWorkspace).evaluate().isEmpty) return false;
  if (target.evaluate().isEmpty) {
    for (final section in FocusSection.values) {
      await tester.tap(find.byKey(ValueKey('focus-section-${section.name}')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      if (section == FocusSection.room) {
        await _openAnalysisDetails(tester, target);
      }
      if (section == FocusSection.style && target.evaluate().isEmpty) {
        final partial = find.byKey(const ValueKey('partial-renovation-items'));
        if (partial.evaluate().isNotEmpty) {
          await tester.ensureVisible(partial);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Choose individual changes'));
          await tester.pumpAndSettle();
        }
      }
      if (target.evaluate().isEmpty && section == FocusSection.refine) {
        final editOptions = find.byKey(const ValueKey('focus-edit-options'));
        if (editOptions.evaluate().isNotEmpty) {
          await tester.ensureVisible(editOptions);
          await tester.pump();
          await tester.tap(editOptions);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
        }
      }
      if (target.evaluate().isEmpty && section == FocusSection.refine) {
        final manual = find.byKey(const ValueKey('manual-ai-tools'));
        if (manual.evaluate().isNotEmpty) {
          await tester.ensureVisible(manual);
          await tester.tap(manual);
          await tester.pumpAndSettle();
        }
      }
      if (target.evaluate().isNotEmpty) break;
    }
  }
  if (target.evaluate().isEmpty) {
    throw StateError(
      'Control unavailable in all Focus Canvas sections: $target',
    );
  }
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return true;
}

Future<void> ensureFocusVisible(WidgetTester tester, Finder target) async {
  if (await _focusTarget(tester, target)) return;
  await _openAnalysisDetails(tester, target);
  await tester.ensureVisible(target);
}

Future<void> revealFocusControl(
  WidgetTester tester,
  Finder target,
  double delta, {
  Finder? scrollable,
  int maxScrolls = 50,
  Duration duration = const Duration(milliseconds: 50),
  bool continuous = false,
}) async {
  if (await _focusTarget(tester, target)) return;
  await _openAnalysisDetails(tester, target);
  final vertical = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable &&
        (widget.axisDirection == AxisDirection.down ||
            widget.axisDirection == AxisDirection.up),
  );
  await tester.scrollUntilVisible(
    target,
    delta,
    scrollable: vertical.evaluate().isNotEmpty ? vertical.first : scrollable,
    maxScrolls: maxScrolls,
    duration: duration,
    continuous: continuous,
  );
}
