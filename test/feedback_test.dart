import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/feedback.dart';
import 'package:renovision_ai/feedback_launch.dart';
import 'package:renovision_ai/feedback_launch_native.dart';
import 'package:renovision_ai/feedback_storage.dart';
import 'package:renovision_ai/feedback_widgets.dart';
import 'package:renovision_ai/context_help.dart';
import 'package:renovision_ai/main.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

class FeedbackTestDrafts implements FeedbackDrafts {
  FeedbackDraft value = const FeedbackDraft();
  bool fail = false;
  @override
  FeedbackDraft read() => value;
  @override
  Future<void> save(FeedbackDraft draft) async {
    if (fail) throw StateError('No space');
    value = draft;
  }
}

class FeedbackTestLauncher implements FeedbackLauncher {
  final calls = <Uri>[];
  bool result = true;
  @override
  bool get supported => true;
  @override
  Future<bool> open(Uri uri) async {
    calls.add(uri);
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> enter(
    WidgetTester tester,
    FeedbackDrafts drafts, {
    FeedbackDestination? destination,
    FeedbackLauncher? launcher,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => FeedbackScreen(
                    drafts: drafts,
                    destination: destination,
                    launcher: launcher,
                  ),
                ),
              ),
              child: const Text('Open feedback'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open feedback'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextField).at(0),
      'Crop issue + suggestion',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      'Steps: open a photo, then crop.\nExpected: draggable corners.',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  test(
    'report allowlists fields, toggles diagnostics and safely encodes mail',
    () {
      final draft = FeedbackDraft.fromMap({
        'title': 'A + B & C?',
        'details': 'Line one\nLine two',
        'kind': 'feature',
        'apiKey': 'private-provider-marker',
        'photos': ['private-photo-marker'],
        'providerUrl': 'private-endpoint-marker',
      });
      final report = draft.report(build: 'build-123', platform: 'android');
      expect(report, contains('Feature request'));
      expect(report, contains('App build: build-123'));
      expect(report, isNot(contains('private-')));
      expect(draft.toMap().keys.toSet(), {
        'title',
        'details',
        'kind',
        'includeDiagnostics',
      });
      final target = FeedbackDestination.parse(email: 'support@example.test')!;
      final uri = target.forReport(draft, report);
      expect(uri.scheme, 'mailto');
      expect(uri.queryParameters['body'], report);
      expect(uri.queryParameters['subject'], 'RenoVision feature: A + B & C?');
      final minimal = FeedbackDraft(
        title: draft.title,
        details: draft.details,
        includeDiagnostics: false,
      );
      expect(
        minimal.report(build: 'hidden-build', platform: 'hidden-platform'),
        isNot(contains('hidden-')),
      );
      for (final invalid in [
        'http://example.test',
        'javascript:alert(1)',
        'https://user:secret@example.test',
      ]) {
        expect(FeedbackDestination.parse(formUrl: invalid), isNull);
      }
      expect(
        FeedbackDestination.parse(
          email: 'x@example.test\nBcc:secret@example.test',
        ),
        isNull,
      );
      final form = FeedbackDestination.parse(
        formUrl: 'https://example.test/feedback?form=abc',
      )!;
      expect(
        form.forReport(draft, report).toString(),
        'https://example.test/feedback?form=abc',
      );
    },
  );

  test(
    'feedback draft persists separately from portable projects and AI settings',
    () async {
      final records = MemoryBox(), photos = MemoryBox();
      final store = RenovisionStore(records: records, photos: photos);
      addTearDown(store.dispose);
      final project = await store.createProject('Private project');
      await store.createRoom(
        projectId: project.id,
        name: 'Private room',
        originalImage: img.encodePng(img.Image(width: 4, height: 4)),
      );
      final backupBefore = store.backupFor(project.id).contentSignature;
      await records.put('settings:ai_connection', {
        'apiKey': 'private-settings-marker',
      });
      await LocalFeedbackDrafts(records)
          .save(const FeedbackDraft(title: 'Feedback', details: 'Local draft'));
      expect(LocalFeedbackDrafts(records).read().details, 'Local draft');
      expect(store.backupFor(project.id).contentSignature, backupBefore);
      final export = utf8.decode(store.backupFor(project.id).encode());
      expect(export, isNot(contains('Local draft')));
      expect(export, isNot(contains('private-settings-marker')));
      expect(records.get('settings:ai_connection'), {
        'apiKey': 'private-settings-marker',
      });
    },
  );

  testWidgets(
    'unconfigured form autosaves and reopens, validates copy, and never claims delivery',
    (tester) async {
      final drafts = FeedbackTestDrafts(), launcher = FeedbackTestLauncher();
      await enter(tester, drafts, launcher: launcher);
      expect(find.textContaining('Saved on this device only'), findsOneWidget);
      await tester.ensureVisible(find.text('Copy report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy report'));
      await tester.pumpAndSettle();
      expect(
        find.text('Add a short title and some details first.'),
        findsOneWidget,
      );
      await fill(tester);
      expect(drafts.value.title, 'Crop issue + suggestion');
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open feedback'));
      await tester.pumpAndSettle();
      expect(find.text('Crop issue + suggestion'), findsOneWidget);
      expect(launcher.calls, isEmpty);
      expect(find.textContaining('successfully sent'), findsNothing);
    },
  );

  testWidgets(
    'email opening retains draft, shows handoff status and handles missing client',
    (tester) async {
      final drafts = FeedbackTestDrafts(), launcher = FeedbackTestLauncher();
      await enter(
        tester,
        drafts,
        launcher: launcher,
        destination: FeedbackDestination.parse(email: 'support@example.test'),
      );
      await fill(tester);
      await tester.ensureVisible(find.text('Open email'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open email'));
      await tester.pumpAndSettle();
      expect(
        launcher.calls.single.queryParameters['body'],
        contains('Expected: draggable corners.'),
      );
      expect(find.textContaining('Email composer requested.'), findsOneWidget);
      expect(drafts.value.details, contains('Expected:'));
      launcher.result = false;
      await tester.tap(find.text('Open email'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not open the destination.'),
        findsOneWidget,
      );
      expect(find.text('Crop issue + suggestion'), findsOneWidget);
    },
  );

  testWidgets('failed draft write blocks Back until retry succeeds', (
    tester,
  ) async {
    final drafts = FeedbackTestDrafts()..fail = true;
    await enter(tester, drafts);
    await fill(tester);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Draft could not be saved.'),
      160,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Draft could not be saved.'), findsWidgets);
    drafts.fail = false;
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackScreen), findsNothing);
    expect(drafts.value.title, 'Crop issue + suggestion');
  });

  testWidgets('app Help and Settings both open the same feedback draft', (
    tester,
  ) async {
    final records = MemoryBox(), photos = MemoryBox();
    final store = RenovisionStore(records: records, photos: photos);
    addTearDown(store.dispose);
    await tester.pumpWidget(RenovisionApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is HelpIcon && widget.title == 'Projects',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();
    await fill(tester);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Feedback and ideas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Feedback and ideas'));
    await tester.pumpAndSettle();
    expect(find.text('Crop issue + suggestion'), findsOneWidget);
    expect(store.projects, isEmpty);
    expect(photos.keys, isEmpty);
  });

  testWidgets(
    'feature suggestions copy the report and clear only after confirmation',
    (tester) async {
      final drafts = FeedbackTestDrafts();
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
      await enter(tester, drafts);
      await tester.tap(find.text('Report an issue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suggest a feature').last);
      await tester.pumpAndSettle();
      await fill(tester);
      await tester.ensureVisible(find.text('Copy report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy report'));
      await tester.pumpAndSettle();
      expect(copied, contains('Type: Feature request'));
      expect(copied, contains('Expected: draggable corners.'));
      expect(drafts.value.kind, FeedbackKind.feature);
      await tester.tap(find.byTooltip('Clear feedback draft'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep draft'));
      await tester.pumpAndSettle();
      expect(drafts.value.title, 'Crop issue + suggestion');
      await tester.tap(find.byTooltip('Clear feedback draft'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear draft'));
      await tester.pumpAndSettle();
      expect(drafts.value.title, isEmpty);
      expect(drafts.value.details, isEmpty);
    },
  );

  testWidgets('feedback layout supports a small phone with enlarged text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: FeedbackScreen(drafts: FeedbackTestDrafts()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save draft'),
      160,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test(
    'Android handoff handles unavailable apps and rejects unsupported schemes',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AndroidFeedbackLauncher.channel, (
            call,
          ) async {
            calls.add(call);
            return false;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(AndroidFeedbackLauncher.channel, null),
      );
      final launcher = AndroidFeedbackLauncher();
      expect(
        await launcher.open(Uri.parse('mailto:support@example.test')),
        isFalse,
      );
      expect(await launcher.open(Uri.parse('javascript:alert(1)')), isFalse);
      expect(calls, hasLength(1));
    },
  );
}
