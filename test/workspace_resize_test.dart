import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/store.dart';
import 'package:renovision_ai/workspace_layout.dart';

import 'support/memory_box.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets(
      'dragging divider at $size resizes both panes, preserves drafts and tabs, and resets',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final store = RenovisionStore(
          records: MemoryBox(),
          photos: MemoryBox(),
        );
        addTearDown(store.dispose);
        final project = await store.createProject('Resize fixture');
        final image = img.encodePng(img.Image(width: 40, height: 30));
        final room = await store.createRoom(
          projectId: project.id,
          name: 'Kitchen',
          originalImage: image,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: WorkspaceScreen(store: store, roomId: room.id),
          ),
        );
        await tester.pumpAndSettle();
        final divider = find.byKey(const ValueKey('workspace-resize-handle'));
        final imagePane = find.byKey(const ValueKey('workspace-image-pane'));
        final controls = find.byKey(const ValueKey('workspace-options-pane'));
        final send = find.byKey(const ValueKey('workspace-generate'));
        final wide = size.width >= 900;
        double extent(Finder target) =>
            wide ? tester.getSize(target).width : tester.getSize(target).height;
        final originalImageExtent = extent(imagePane),
            originalControls = extent(controls);
        final sendPosition = tester.getRect(send);
        await tester.drag(
          divider,
          wide ? const Offset(-130, 0) : const Offset(0, -130),
        );
        await tester.pumpAndSettle();
        expect(extent(imagePane), lessThan(originalImageExtent));
        expect(extent(controls), greaterThan(originalControls));
        expect(tester.getRect(send), sendPosition);
        final saved = store.workspaceLayout;
        expect(
          wide ? saved.wideImageFraction : saved.portraitImageFraction,
          isNotNull,
        );

        await tester.tap(find.byKey(const ValueKey('focus-section-refine')));
        await tester.pumpAndSettle();
        final instructions = find.widgetWithText(
          TextField,
          'What should change?',
        );
        await tester.ensureVisible(instructions);
        await tester.enterText(instructions, 'Replace just the ceiling light');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final beforeEnlarge = extent(imagePane);
        await tester.drag(
          divider,
          wide ? const Offset(180, 0) : const Offset(0, 180),
        );
        await tester.pumpAndSettle();
        expect(extent(imagePane), greaterThan(beforeEnlarge));
        expect(send.hitTestable(), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('focus-section-style')));
        await tester.pumpAndSettle();
        final enlarged = extent(imagePane);
        await tester.tap(find.byKey(const ValueKey('focus-section-refine')));
        await tester.pumpAndSettle();
        expect(extent(imagePane), enlarged);
        expect(
          tester.widget<TextField>(instructions).controller!.text,
          'Replace just the ceiling light',
        );

        await tester.drag(
          divider,
          wide ? const Offset(3000, 0) : const Offset(0, 3000),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('focus-section-style')).hitTestable(),
          findsOneWidget,
        );
        expect(send.hitTestable(), findsOneWidget);
        await tester.drag(
          divider,
          wide ? const Offset(-3000, 0) : const Offset(0, -3000),
        );
        await tester.pumpAndSettle();
        expect(extent(imagePane), greaterThanOrEqualTo(wide ? 240 : 80));
        expect(
          find.byTooltip('Open image full screen').hitTestable(),
          findsOneWidget,
        );
        await tester.tap(divider);
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tap(divider);
        await tester.pumpAndSettle();
        expect(extent(imagePane), closeTo(originalImageExtent, .01));
        expect(store.workspaceLayout.toMap(), isEmpty);
        expect(store.imageFor(room.originalId), image);
        expect(store.designsFor(room.id), isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'device split survives reopening and keyboard/rotation without losing either orientation preference',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
      addTearDown(store.dispose);
      final project = await store.createProject('Fixture');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: img.encodePng(img.Image(width: 40, height: 30)),
      );
      await store.setWorkspaceLayout(
        const WorkspaceLayout(
          portraitImageFraction: .6,
          wideImageFraction: .55,
        ),
      );
      Future<void> open() async {
        await tester.pumpWidget(
          MaterialApp(
            home: WorkspaceScreen(store: store, roomId: room.id),
          ),
        );
        await tester.pumpAndSettle();
      }

      await open();
      final pane = find.byKey(const ValueKey('workspace-image-pane'));
      final initial = tester.getSize(pane).height;
      await tester.binding.setSurfaceSize(const Size(390, 430));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpAndSettle();
      expect(tester.getSize(pane).width, greaterThan(500));
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpAndSettle();
      expect(tester.getSize(pane).height, closeTo(initial, .01));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await open();
      expect(tester.getSize(pane).height, closeTo(initial, .01));
      expect(store.workspaceLayout.toMap(), {'portrait': .6, 'wide': .55});
      expect(
        utf8.decode(store.backupFor(project.id).encode()),
        isNot(contains('workspace_layout')),
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('invalid saved layout falls back to automatic sizing', () {
    expect(
      WorkspaceLayout.fromMap({'portrait': 'bad', 'wide': double.nan}).toMap(),
      isEmpty,
    );
    expect(
      WorkspaceLayout.fromMap({'portrait': -1, 'wide': 3}).toMap(),
      isEmpty,
    );
    expect(WorkspaceLayout.fromMap(null).toMap(), isEmpty);
  });
}
