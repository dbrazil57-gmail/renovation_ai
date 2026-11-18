import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:image/image.dart' as img;
import 'package:renovision_ai/focus_workspace.dart';
import 'package:renovision_ai/screens.dart';
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
                saveStatus: const Text('Saved locally'),
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
}
