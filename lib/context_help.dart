import 'package:material_ui/material_ui.dart';

import 'walkthrough_screen.dart';

Future<void> showContextHelp(
  BuildContext context, {
  required String title,
  required String message,
}) {
  Tooltip.dismissAllToolTips();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      scrollable: true,
      content: SelectableText(message),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.pop(dialogContext);
            showAppWalkthroughs(context);
          },
          icon: const Icon(Icons.play_circle_outline),
          label: const Text('Sample walkthroughs'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

/// Hover on desktop; tap, keyboard-activate or use a screen reader for details.
class HelpIcon extends StatelessWidget {
  final String title;
  final String message;
  const HelpIcon({super.key, required this.title, required this.message});
  @override
  Widget build(BuildContext context) => Tooltip(
    message: message,
    excludeFromSemantics: true,
    triggerMode: TooltipTriggerMode.manual,
    waitDuration: const Duration(milliseconds: 400),
    showDuration: const Duration(seconds: 20),
    constraints: const BoxConstraints(maxWidth: 320),
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: Semantics(
      label: '$title information',
      child: IconButton(
        icon: const Icon(Icons.info_outline, size: 21),
        onPressed: () =>
            showContextHelp(context, title: title, message: message),
      ),
    ),
  );
}

class HelpHeading extends StatelessWidget {
  final String title;
  final String message;
  final TextStyle? style;
  const HelpHeading({
    super.key,
    required this.title,
    required this.message,
    this.style,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: style ?? Theme.of(context).textTheme.titleLarge,
        ),
      ),
      HelpIcon(title: title, message: message),
    ],
  );
}
