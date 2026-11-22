import 'package:material_ui/material_ui.dart';

import 'ai_service.dart';

class TesterAccessCard extends StatefulWidget {
  final AiService ai;
  const TesterAccessCard({super.key, required this.ai});
  @override
  State<TesterAccessCard> createState() => _TesterAccessCardState();
}

class _TesterAccessCardState extends State<TesterAccessCard> {
  final address = TextEditingController(), invitation = TextEditingController();
  bool busy = false;
  String? message;
  @override
  void dispose() {
    address.dispose();
    invitation.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
      invitation.clear();
    } catch (e) {
      if (mounted) {
        setState(
          () => message = e is AiFailure
              ? e.message
              : 'Test access could not update. Try again in Settings.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const Text('Tester credits · invitation access'),
    subtitle: Text(
      widget.ai.isTester
          ? widget.ai.testerAllowance?.summary ?? 'Check remaining credits'
          : 'Optional owner-funded trial; no personal AI account',
    ),
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A private invitation and an activated HTTPS test service are required. No credits are supplied by this APK alone. Offline sample replay in Help needs neither.',
            ),
            if (widget.ai.isTester) ...[
              Text(
                'Expires: ${widget.ai.testerAllowance?.expires.toLocal().toString().split('.').first ?? 'Unknown'}',
              ),
              const Text(
                'One allowance per confirmed analysis or design image. Multiple ideas use one per image. Owner-funded limits are enforced by the service; interrupted attempts can consume an allowance.',
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: busy || widget.ai.activity.active
                        ? null
                        : () => run(widget.ai.refreshTesterAllowance),
                    child: const Text('Refresh credits'),
                  ),
                  TextButton(
                    onPressed: busy || widget.ai.activity.active
                        ? null
                        : () => run(widget.ai.disconnect),
                    child: const Text('Remove test invitation'),
                  ),
                ],
              ),
            ] else ...[
              TextField(
                controller: address,
                keyboardType: TextInputType.url,
                maxLength: 256,
                decoration: const InputDecoration(
                  labelText: 'Test service HTTPS address',
                  counterText: '',
                ),
              ),
              TextField(
                controller: invitation,
                obscureText: true,
                maxLength: 512,
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                decoration: const InputDecoration(
                  labelText: 'Private tester invitation',
                  counterText: '',
                ),
              ),
              FilledButton(
                onPressed: busy || widget.ai.activity.active
                    ? null
                    : () => run(
                        () => widget.ai.connectTester(
                          url: address.text,
                          invitation: invitation.text,
                        ),
                      ),
                child: Text(
                  busy ? 'Checking invitation…' : 'Activate test access',
                ),
              ),
              const Text(
                'Android encrypts the invitation on this device; it is excluded from project files and backups. Chrome keeps it for this session. Activation checks access only; no photo is sent.',
              ),
            ],
            if (message != null) Text(message!),
          ],
        ),
      ),
    ],
  );
}
