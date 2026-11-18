import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/focus_workspace.dart';

/// Follow the same section navigation as a user before locating a control.
Future<bool> _focusTarget(WidgetTester tester, Finder target) async {
  if (find.byType(FocusWorkspace).evaluate().isEmpty) return false;
  if (target.evaluate().isEmpty) {
    for (final section in FocusSection.values) {
      await tester.tap(find.byKey(ValueKey('focus-section-${section.name}')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
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
