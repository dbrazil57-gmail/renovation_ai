import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:image/image.dart' as img;
import 'package:renovision_ai/focus_workspace.dart';
import 'package:renovision_ai/screens.dart';
import 'package:renovision_ai/main.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

class RememberedControl extends StatefulWidget {
  const RememberedControl({super.key});
  @override
  State<RememberedControl> createState() => _RememberedControlState();
}

class _RememberedControlState extends State<RememberedControl> {
  int count = 0;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => count++),
    child: Text('Remembered state $count'),
  );
}

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(1100, 800),
    const Size(390, 420),
  ]) {
    testWidgets('Focus Canvas fits $size and retains inactive controls', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final input = TextEditingController();
      addTearDown(input.dispose);
      var section = FocusSection.refine;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, change) => FocusWorkspace(
                selected: section,
                onSelected: (value) => change(() => section = value),
                imageBuilder: (height) => SizedBox(
                  height: height,
                  child: const ColoredBox(color: Colors.black),
                ),
                imageTools: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.crop)),
                ],
                thumbnails: [
                  FocusVersionThumbnail(
                    image: null,
                    title: 'Original',
                    selected: true,
                    onTap: () {},
                  ),
                ],
                footer: const Text('Saved locally'),
                sections: {
                  FocusSection.room: [const Text('Room controls')],
                  FocusSection.style: [const RememberedControl()],
                  FocusSection.refine: [
                    TextField(
                      controller: input,
                      decoration: const InputDecoration(
                        labelText: 'New instruction',
                      ),
                    ),
                  ],
                  FocusSection.ideas: [const Text('Saved versions')],
                },
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Keep the windows');
      await tester.tap(find.byKey(const ValueKey('focus-section-style')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remembered state 0'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('focus-section-room')));
      await tester.pumpAndSettle();
      expect(find.text('Room controls'), findsOneWidget);
      expect(find.text('Saved versions'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('focus-section-style')));
      await tester.pumpAndSettle();
      expect(find.text('Remembered state 1'), findsOneWidget);
      await tester.binding.setSurfaceSize(
        size.width < 900 ? const Size(1100, 800) : const Size(390, 844),
      );
      await tester.pumpAndSettle();
      expect(find.text('Remembered state 1'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('focus-section-refine')));
      await tester.pumpAndSettle();
      expect(input.text, 'Keep the windows');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'large text fits the real workspace with a short keyboard viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 560));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
      addTearDown(store.dispose);
      final project = await store.createProject('Home');
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen',
        originalImage: img.encodePng(img.Image(width: 40, height: 30)),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.7)),
            child: child!,
          ),
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('focus-section-refine')));
      await tester.pumpAndSettle();
      expect(find.byType(FocusWorkspace), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home room shortcut preselects type without creating sample data',
    (tester) async {
      final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
      addTearDown(store.dispose);
      final project = await store.createProject('Home');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProjectsTab(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      final bedroom = find.text('Bedroom');
      await tester.ensureVisible(bedroom);
      await tester.pumpAndSettle();
      await tester.tap(bedroom);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Bedroom'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.roomsFor(project.id), isEmpty);
      expect(store.projects, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact app typography reduces real workspace scrolling across Room Style Refine and Ideas',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = RenovisionStore(records: MemoryBox(), photos: MemoryBox());
      addTearDown(store.dispose);
      final project = await store.createProject('Home');
      final bytes = img.encodePng(img.Image(width: 40, height: 30));
      final room = await store.createRoom(
        projectId: project.id,
        name: 'Kitchen with dining area',
        roomTypeId: 'kitchen',
        originalImage: bytes,
      );
      await store.createDesign(
        roomId: room.id,
        image: bytes,
        title: 'Warm charcoal and walnut kitchen with dining-facing storage',
        prompt: 'Keep the layout and window.',
      );
      Future<Map<FocusSection, double>> measure(ThemeData theme) async {
        // Compare fresh screens, without animating between unrelated themes.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: WorkspaceScreen(store: store, roomId: room.id),
          ),
        );
        await tester.pumpAndSettle();
        final extents = <FocusSection, double>{};
        for (final section in FocusSection.values) {
          await tester.tap(
            find.byKey(ValueKey('focus-section-${section.name}')),
          );
          await tester.pumpAndSettle();
          final scrollable = find
              .descendant(
                of: find.byKey(const ValueKey('focus-controls-scroll')),
                matching: find.byType(Scrollable),
              )
              .first;
          extents[section] = tester
              .state<ScrollableState>(scrollable)
              .position
              .maxScrollExtent;
          expect(tester.takeException(), isNull);
        }
        return extents;
      }

      final before = await measure(ThemeData(useMaterial3: true));
      final after = await measure(buildRenovisionTheme());
      for (final section in FocusSection.values) {
        expect(
          after[section],
          lessThan(before[section]!),
          reason: '${section.name} should need less scrolling',
        );
      }
      expect(store.roomById(room.id)!.photoIds, [room.originalId]);
      expect(store.imageFor(room.originalId), bytes);
      expect(store.designsFor(room.id), hasLength(1));
    },
  );

  for (final scale in [1.0, 1.8]) {
    testWidgets(
      'shared compact theme fits all main tabs at 320px and text scale $scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final store = RenovisionStore(
          records: MemoryBox(),
          photos: MemoryBox(),
        );
        addTearDown(store.dispose);
        final project = await store.createProject('Home');
        final room = await store.createRoom(
          projectId: project.id,
          name: 'Kitchen',
          roomTypeId: 'kitchen',
          originalImage: img.encodePng(img.Image(width: 40, height: 30)),
        );
        final design = await store.createDesign(
          roomId: room.id,
          image: store.imageFor(room.originalId)!,
          title: 'Warm charcoal kitchen with walnut and pale stone benchtops',
          prompt: 'Keep layout',
        );
        await store.setFavourite(design, favourite: true);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildRenovisionTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: AppShell(store: store),
          ),
        );
        await tester.pumpAndSettle();
        for (final tab in ['Projects', 'Explore', 'Library']) {
          final target = find.text(tab);
          expect(tester.getRect(target).height, greaterThan(0));
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          2,
        );
        expect(store.designsFor(room.id).single.favourite, isTrue);
        expect(store.roomsFor(project.id), hasLength(1));
      },
    );
  }
}
