import 'package:material_ui/material_ui.dart';

import 'context_help.dart';

/// Shared left-to-right order. Screens supply only their applicable tools.
enum ScreenAction {
  projectsHome,
  save,
  autosave,
  setup,
  undo,
  redo,
  reset,
  zoomOut,
  zoomIn,
  fit,
  settings,
  projectRooms,
  rename,
  finishLater,
  help,
}

class ScreenTool {
  final ScreenAction action;
  final String label;
  final VoidCallback? onPressed;
  final String? helpTitle, helpMessage;
  final bool menuOnly;
  final bool? checked;
  const ScreenTool(
    this.action, {
    required this.label,
    required this.onPressed,
    this.helpTitle,
    this.helpMessage,
    this.menuOnly = false,
    this.checked,
  });
  factory ScreenTool.help(
    BuildContext context, {
    required String title,
    required String message,
  }) => ScreenTool(
    ScreenAction.help,
    label: 'Help',
    helpTitle: title,
    helpMessage: message,
    onPressed: () => showContextHelp(context, title: title, message: message),
  );
  IconData get icon => switch (action) {
    ScreenAction.save => Icons.save_outlined,
    ScreenAction.autosave => Icons.sync,
    ScreenAction.setup => Icons.format_list_numbered,
    ScreenAction.undo => Icons.undo,
    ScreenAction.redo => Icons.redo,
    ScreenAction.reset => Icons.restart_alt,
    ScreenAction.zoomOut => Icons.zoom_out,
    ScreenAction.zoomIn => Icons.zoom_in,
    ScreenAction.fit => Icons.fit_screen,
    ScreenAction.settings => Icons.settings_outlined,
    ScreenAction.projectRooms => Icons.folder_open_outlined,
    ScreenAction.projectsHome => Icons.home_outlined,
    ScreenAction.rename => Icons.edit_outlined,
    ScreenAction.finishLater => Icons.more_time,
    ScreenAction.help => Icons.info_outline,
  };
}

class ScreenToolbar extends StatelessWidget {
  final List<ScreenTool> tools;
  const ScreenToolbar({super.key, required this.tools});
  @override
  Widget build(BuildContext context) {
    final ordered = [...tools]
      ..sort((a, b) => a.action.index.compareTo(b.action.index));
    // Home gets its own slot, keeping Save/setup/Settings visible on phones.
    final hasHome = ordered.any(
      (tool) => tool.action == ScreenAction.projectsHome && !tool.menuOnly,
    );
    final limit =
        (MediaQuery.sizeOf(context).width < 600 ? 3 : 6) + (hasHome ? 1 : 0);
    final visible = ordered
        .where((tool) => !tool.menuOnly)
        .take(limit)
        .toList();
    final overflow = ordered.where((tool) => !visible.contains(tool)).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final tool in visible)
          if (tool.helpMessage != null && tool.onPressed != null)
            HelpIcon(title: tool.helpTitle!, message: tool.helpMessage!)
          else
            IconButton(
              tooltip: tool.label,
              icon: Icon(tool.icon),
              disabledColor: IconTheme.of(context).color
                  ?.withValues(alpha: .38),
              onPressed: tool.onPressed,
            ),
        if (overflow.isNotEmpty)
          PopupMenuButton<ScreenAction>(
            tooltip: 'More tools',
            onSelected: (action) => overflow
                .firstWhere((tool) => tool.action == action)
                .onPressed
                ?.call(),
            itemBuilder: (_) => [
              for (final tool in overflow)
                if (tool.checked != null)
                  CheckedPopupMenuItem(
                    value: tool.action,
                    checked: tool.checked!,
                    enabled: tool.onPressed != null,
                    child: Text(tool.label),
                  )
                else
                  PopupMenuItem(
                    value: tool.action,
                    enabled: tool.onPressed != null,
                    child: Row(
                      children: [
                        Icon(
                          tool.icon,
                          color: tool.onPressed == null
                              ? Theme.of(context).disabledColor
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(tool.label)),
                      ],
                    ),
                  ),
            ],
          ),
      ],
    );
  }
}
