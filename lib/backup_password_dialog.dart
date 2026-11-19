import 'package:material_ui/material_ui.dart';

Future<String?> askBackupPassword(
  BuildContext context, {
  required bool creating,
}) => showDialog<String>(
  context: context,
  builder: (_) => _BackupPasswordDialog(creating: creating),
);

class _BackupPasswordDialog extends StatefulWidget {
  final bool creating;
  const _BackupPasswordDialog({required this.creating});
  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final password = TextEditingController(), repeated = TextEditingController();
  String? error;
  @override
  void dispose() {
    password.dispose();
    repeated.dispose();
    super.dispose();
  }

  void _submit() {
    if (password.text.trim().length < 12 || password.text.length > 1024) {
      setState(() => error = 'Use 12 or more characters (up to 1024).');
    } else if (widget.creating && password.text != repeated.text) {
      setState(() => error = 'The passwords do not match.');
    } else {
      Navigator.pop(context, password.text);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.creating ? 'Protect backup' : 'Unlock backup'),
    scrollable: true,
    content: SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.creating
                ? 'Keep this password somewhere safe. It is not saved in the app, and a lost password cannot be recovered.'
                : 'Enter the password used when this backup was created.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('backup-password'),
            controller: password,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Backup password',
              errorText: error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.creating)
            TextField(
              key: const ValueKey('backup-password-repeat'),
              controller: repeated,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'Repeat password'),
              onSubmitted: (_) => _submit(),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(widget.creating ? 'Protect and save' : 'Unlock'),
      ),
    ],
  );
}
