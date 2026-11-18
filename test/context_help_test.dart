
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/context_help.dart';
import 'package:renovision_ai/file_transfer.dart';
import 'package:renovision_ai/project_transfer_widgets.dart';
import 'package:renovision_ai/room_save_widgets.dart';
import 'package:renovision_ai/room_draft.dart';
import 'package:renovision_ai/room_setup.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

class HelpFiles implements AppFiles {
  int writes = 0;
  @override
  bool get supported => true;
  @override
  Future<Uint8List?> pickBackup() async => null;
  @override
  Future<FileSaveResult> save(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) async {
    writes++;
    return FileSaveResult.saved;
  }
}

void main() {
  const message =
      'A project file includes rooms, photos and designs. Your API key stays separate.';
  testWidgets(
    'desktop hover reveals details; mouse exit hides them; tap opens readable help',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HelpHeading(title: 'Project file', message: message),
          ),
        ),
      );
      expect(find.text(message, findRichText: true), findsNothing);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(HelpIcon)));
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(message, findRichText: true), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await mouse.moveTo(const Offset(0, 500));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(message, findRichText: true), findsNothing);
      await tester.tap(find.byType(HelpIcon));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        message,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      await mouse.removePointer();
    },
  );
  testWidgets(
    'phone tap and keyboard activation open help with large text without overflow',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: const Scaffold(
            body: HelpHeading(title: 'Project file', message: message),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(HelpIcon));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test('compact status shortens known success only; errors and action-needed text remain complete', () {
    expect(
      compactProjectFileStatus(
        'Saved on this device. Save a project file to keep a portable copy.',
      ),
      'Saved on this device.',
    );
    for (final message in [
      'Project file save failed. Local work is retained. Use Save project or Save as to retry.',
      'Unsaved project file changes · use Save project',
      'Download requested. Check Downloads; automatic file updates are unavailable.',
    ]) {
      expect(compactProjectFileStatus(message), message);
    }
  });

  testWidgets(
    'project help is hidden initially and opening it does not save or alter project data',
    (tester) async {
      final files = HelpFiles();
      final store = RenovisionStore(
        records: MemoryBox(),
        photos: MemoryBox(),
        files: files,
      );
      addTearDown(store.dispose);
      final project = await store.createProject('Help test');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectFileControls(store: store, projectId: project.id),
          ),
        ),
      );
      expect(find.text('Save project'), findsOneWidget);
      expect(find.text('Saved on this device.'), findsOneWidget);
      expect(find.textContaining('One file contains'), findsNothing);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is HelpIcon && w.title == 'Project file',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        contains('One file contains'),
      );
      expect(files.writes, 0);
      expect(store.projects.single.id, project.id);
    },
  );
  testWidgets(
    'autosave information tap does not toggle the switch or write a file',
    (tester) async {
      final files = HelpFiles();
      final store = RenovisionStore(
        records: MemoryBox(),
        photos: MemoryBox(),
        files: files,
      );
      final project = await store.createProject('Autosave help');
      final bytes = img.encodePng(img.Image(width: 30, height: 20));
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: bytes,
      );
      final draft = RoomDraft(store, room);
      addTearDown(() {
        draft.dispose();
        store.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomSaveControls(
              store: store,
              draft: draft,
              autosaveOnly: true,
              activeImage: () => bytes,
              saveAndClose: () async {},
              askName: (_, _) async => null,
              onProjectCopy: (_) {},
            ),
          ),
        ),
      );
      final before = draft.autosaveEnabled;
      await tester.tap(
        find.byWidgetPredicate((w) => w is HelpIcon && w.title == 'Autosave'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(draft.autosaveEnabled, before);
      expect(files.writes, 0);
    },
  );
  testWidgets(
    'first room-photo step keeps guidance while project explanation stays behind info',
    (tester) async {
      final store = RenovisionStore(
        records: MemoryBox(),
        photos: MemoryBox(),
        files: HelpFiles(),
      );
      addTearDown(store.dispose);
      final project = await store.createProject('First step');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        guidedSetup: true,
        originalImage: img.encodePng(img.Image(width: 30, height: 20)),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RoomSetupScreen(
            store: store,
            roomId: room.id,
            workspace: (_) => const Scaffold(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your first photos are saved'),
        findsOneWidget,
      );
      expect(find.textContaining('One file contains'), findsNothing);
    },
  );
}
