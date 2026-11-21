import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app_revision.dart';
import 'feedback.dart';
import 'feedback_launch.dart';
import 'feedback_storage.dart';

class FeedbackScope extends InheritedWidget {
  final FeedbackDrafts drafts;
  const FeedbackScope({super.key, required this.drafts, required super.child});
  static FeedbackScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FeedbackScope>();
  @override
  bool updateShouldNotify(FeedbackScope oldWidget) =>
      drafts != oldWidget.drafts;
}

Future<void> openFeedback(BuildContext context, FeedbackDrafts drafts) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => FeedbackScreen(drafts: drafts)),
    );

class FeedbackCard extends StatelessWidget {
  final FeedbackDrafts drafts;
  const FeedbackCard({super.key, required this.drafts});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.feedback_outlined),
      title: const Text('Feedback and ideas'),
      subtitle: const Text('Report an issue or suggest a feature'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => openFeedback(context, drafts),
    ),
  );
}

class FeedbackScreen extends StatefulWidget {
  final FeedbackDrafts drafts;
  final FeedbackDestination? destination;
  final FeedbackLauncher? launcher;
  const FeedbackScreen({
    super.key,
    required this.drafts,
    this.destination,
    this.launcher,
  });
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with WidgetsBindingObserver {
  late final TextEditingController title, details;
  late String previousTitle, previousDetails;
  late FeedbackKind kind;
  late bool diagnostics;
  late final destination =
      widget.destination ?? FeedbackDestination.fromEnvironment();
  late final launcher = widget.launcher ?? createFeedbackLauncher();
  Timer? timer;
  Future<void> saves = Future.value();
  int revision = 0, savedRevision = 0;
  bool saving = false, opening = false;
  String? message;
  static const saveFailure =
      'Draft could not be saved. Keep this page open and try Save draft again.';
  bool get dirty => revision != savedRevision;
  FeedbackDraft get draft => FeedbackDraft(
    kind: kind,
    title: title.text,
    details: details.text,
    includeDiagnostics: diagnostics,
  );
  String get report => draft.report(
    build: appBuildId,
    platform: '${kIsWeb ? 'Web / ' : ''}${defaultTargetPlatform.name}',
  );

  @override
  void initState() {
    super.initState();
    final saved = widget.drafts.read();
    kind = saved.kind;
    diagnostics = saved.includeDiagnostics;
    previousTitle = saved.title;
    previousDetails = saved.details;
    title = TextEditingController(text: saved.title)..addListener(textChanged);
    details = TextEditingController(text: saved.details)
      ..addListener(textChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  void textChanged() {
    if (title.text == previousTitle && details.text == previousDetails) return;
    previousTitle = title.text;
    previousDetails = details.text;
    changed();
  }

  void changed() {
    setState(() {
      revision++;
      message = null;
    });
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 400), save);
  }

  Future<bool> save() async {
    timer?.cancel();
    if (!dirty && !saving) return true;
    final value = draft, version = revision;
    if (mounted) setState(() => saving = true);
    final write = saves
        .catchError((_) {})
        .then((_) => widget.drafts.save(value));
    saves = write.catchError((_) {});
    try {
      await write;
      if (mounted) {
        if (message == saveFailure) {
          message = null;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
        setState(() {
          savedRevision = version;
          saving = false;
        });
      }
      return true;
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          message = saveFailure;
        });
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text(saveFailure)));
      }
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(save());
    }
  }

  bool validate() {
    if (draft.ready) return true;
    setState(() => message = 'Add a short title and some details first.');
    return false;
  }

  Future<void> copyReport() async {
    if (!validate()) return;
    try {
      await Clipboard.setData(ClipboardData(text: report));
      if (mounted) {
        setState(
          () => message =
              'Report copied. Paste it into your email or feedback form.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Copy was unavailable. Open Review report to select and copy the text.',
        );
      }
    }
  }

  Future<void> openOnline() async {
    if (opening || destination == null || !validate()) return;
    setState(() => opening = true);
    try {
      // Open immediately from the user's tap; do not consume browser activation
      // waiting for local storage. No report data is placed in a form URL.
      final opened = await launcher.open(destination!.forReport(draft, report));
      if (mounted) {
        setState(
          () => message = !opened
              ? 'Could not open the destination. Copy the report and use your browser or email app.'
              : destination!.email
              ? 'Email composer requested. Review and send it in your email app. Your draft is kept here.'
              : 'Feedback form requested. Copy your report, paste it there and submit. Your draft is kept here.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'Could not open the destination. Copy the report and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  Future<void> clearDraft() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear feedback draft?'),
        content: const Text(
          'This clears only this feedback draft. Your projects and images stay saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep draft'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear draft'),
          ),
        ],
      ),
    );
    if (clear != true || !mounted) return;
    title.clear();
    details.clear();
    changed();
    await save();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    title.dispose();
    details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && !saving,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      if (await save() && context.mounted && !dirty) Navigator.pop(context);
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Feedback and ideas'),
        actions: [
          IconButton(
            tooltip: 'Clear feedback draft',
            onPressed: opening ? null : clearDraft,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<FeedbackKind>(
                initialValue: kind,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Feedback type'),
                items: [
                  for (final value in FeedbackKind.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(
                        value == FeedbackKind.issue
                            ? 'Report an issue'
                            : 'Suggest a feature',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    kind = value;
                    changed();
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Short title'),
              ),
              TextField(
                controller: details,
                maxLength: 4000,
                minLines: 4,
                maxLines: 9,
                decoration: InputDecoration(
                  labelText: 'Details',
                  hintText: kind == FeedbackKind.issue
                      ? 'What happened? What did you expect? Include the steps to reproduce it.'
                      : 'What would you like to do, and how would it help?',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: diagnostics,
                title: const Text('Include app build and platform'),
                onChanged: (value) {
                  diagnostics = value ?? true;
                  changed();
                },
              ),
              const Text(
                'Photos, projects and AI connection settings are not attached. Avoid pasting API keys or private information.',
              ),
              ExpansionTile(
                title: const Text('Review report'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(report),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (destination == null)
                const Text(
                  'Saved on this device only. Not sent—no feedback address is set.',
                )
              else
                Text(
                  'Destination: ${destination!.email ? destination!.uri.path : destination!.uri.host}',
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed:
                        destination == null || !launcher.supported || opening
                        ? null
                        : openOnline,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(
                      destination?.email == true
                          ? 'Open email'
                          : 'Open feedback form',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: copyReport,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy report'),
                  ),
                  TextButton(
                    onPressed: saving ? null : save,
                    child: const Text('Save draft'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message ??
                    (saving
                        ? 'Saving draft…'
                        : dirty
                        ? 'Draft changes waiting to save'
                        : 'Draft saved on this device'),
                semanticsLabel: message,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
