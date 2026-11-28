import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'app_access.dart';
import 'samsung_access.dart';

class AppAccessSettingsCard extends StatefulWidget {
  final AppAccess access;
  final SamsungBilling? billing;
  const AppAccessSettingsCard({super.key, required this.access, this.billing});
  @override
  State<AppAccessSettingsCard> createState() => _AppAccessSettingsCardState();
}

class _AppAccessSettingsCardState extends State<AppAccessSettingsCard> {
  bool checkoutAvailable = false, working = false;
  String? message;
  late SamsungAppAccess samsung;
  @override
  void initState() {
    super.initState();
    samsung = SamsungAppAccess(
      access: widget.access,
      billing: widget.billing ?? SamsungMethodChannel(),
    );
    unawaited(_load());
  }

  Future<void> _load() async {
    await widget.access.load();
    final available = await samsung.available();
    if (mounted) setState(() => checkoutAvailable = available);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      working = true;
      message = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(
          () => message = error is AccessFailure
              ? error.message
              : 'App access could not be updated. Try again later.',
        );
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.access,
    builder: (context, _) {
      final access = widget.access;
      final disabled = working || access.busy;
      return ExpansionTile(
        leading: const Icon(Icons.verified_user_outlined),
        title: const Text('App access'),
        subtitle: Text(access.status),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  access.privateBuild
                      ? 'This private test build has no software expiry. AI provider charges are separate.'
                      : 'Trial and Standard use the same app. Saved projects remain available to view and export when access ends. Your own AI key and provider charges are separate.',
                ),
                if (access.grant case final grant?) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Access ends: ${grant.expires.toLocal().toString().split(".").first}',
                  ),
                  Text(
                    'Offline access until: ${grant.refreshBy.toLocal().toString().split(".").first}',
                  ),
                  const Text(
                    'One active installation. Changing phones requires verified recovery or transfer.',
                  ),
                ],
                if (!access.privateBuild) ...[
                  const SizedBox(height: 8),
                  if (!access.configuration.configured)
                    const Text(
                      'Activation service setup is pending. Checkout is unavailable in this build.',
                    ),
                  if (access.configuration.configured && !checkoutAvailable)
                    const Text(
                      'Samsung checkout setup is pending. No purchase can be made from this build.',
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (access.grant == null)
                        OutlinedButton(
                          onPressed:
                              disabled || !access.configuration.configured
                              ? null
                              : () => _run(access.startTrial),
                          child: const Text('Request trial'),
                        ),
                      if (access.grant != null)
                        OutlinedButton(
                          onPressed:
                              disabled || !access.configuration.configured
                              ? null
                              : () => _run(access.refresh),
                          child: const Text('Refresh access'),
                        ),
                      OutlinedButton(
                        onPressed: disabled || !checkoutAvailable
                            ? null
                            : () => _run(samsung.restore),
                        child: const Text('Restore Samsung purchase'),
                      ),
                    ],
                  ),
                  // Checkout stays out of the UI until the SDK, server and live
                  // product/price/renewal disclosure have passed store acceptance.
                ],
                if (disabled) const LinearProgressIndicator(),
                if (message ?? access.notice case final String notice) ...[
                  const SizedBox(height: 8),
                  Text(notice),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}
