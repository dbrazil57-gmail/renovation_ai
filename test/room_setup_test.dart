import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/room_setup.dart';
import 'package:renovision_ai/store.dart';

import 'support/memory_box.dart';

void main() {
  late RenovisionStore store;
  late RenovationRoom room;
  late int analyses, edits;
  setUp(() async {
    analyses = 0;
    edits = 0;
    final image = img.encodePng(img.Image(width: 40, height: 30));
    final ai = AiService(
      clientFactory: () => MockClient((request) async {
        if (request.url.path == '/health') {
          return http.Response(
            jsonEncode({
              'provider': 'OpenAI',
              'model': 'synthetic-image',
              'quality': 'low',
              'analysisModel': 'synthetic-vision',
            }),
            200,
          );
        }
        if (request.url.path == '/analyse') {
          analyses++;
          final body = jsonDecode(request.body) as Map;
          expect(body['prompt'], contains('Modernise while keeping layout'));
          return http.Response(
            jsonEncode({
              'provider': 'OpenAI',
              'model': 'synthetic-vision',
              'observations': 'A visible room with a window.',
              'questions': [],
              'prompt': 'Modernise this room within its existing layout.',
            }),
            200,
          );
        }
        edits++;
        final body = jsonDecode(request.body) as Map;
        expect(body['prompt'], contains('PHOTO ANALYSIS'));
        return http.Response(
          jsonEncode({
            'provider': 'OpenAI',
            'model': 'synthetic-image',
            'image': base64Encode(image),
          }),
          200,
        );
      }),
    );
    store = RenovisionStore(records: MemoryBox(), photos: MemoryBox(), ai: ai);
    final project = await store.createProject('House');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: image,
      guidedSetup: true,
    );
  });
  tearDown(() => store.dispose());

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoomSetupScreen(
                    store: store,
                    roomId: room.id,
                    workspace: (_) =>
                        const Scaffold(body: Text('Finished workspace')),
                  ),
                ),
              ),
              child: const Text('Start setup'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Start setup'));
    await tester.pumpAndSettle();
  }

  Future<void> reach(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'finish later saves the goal and setup stage and reopening resumes it',
    (tester) async {
      await show(tester);
      expect(find.text('Step 1 of 4 · Room photos'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      final goal = find.widgetWithText(
        TextField,
        'Your renovation goal (optional)',
      );
      await tester.enterText(goal, 'Modernise while keeping layout');
      await tester.tap(find.text('Finish later'));
      await tester.pumpAndSettle();
      expect(find.text('Start setup'), findsOneWidget);
      expect(
        store.roomById(room.id)!.instructions,
        'Modernise while keeping layout',
      );
      expect(store.roomById(room.id)!.setupStep, 1);
      expect(store.roomById(room.id)!.setupComplete, isFalse);
      await tester.tap(find.text('Start setup'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 4 · Design direction'), findsOneWidget);
      expect(
        tester.widget<TextField>(goal).controller!.text,
        'Modernise while keeping layout',
      );
      expect(analyses, 0);
      expect(edits, 0);
    },
  );

  testWidgets(
    'guided analysis uses the goal and final generation saves before opening workspace',
    (tester) async {
      await store.ai.connect(
        url: 'http://127.0.0.1:8787',
        pairingCode: 'synthetic',
      );
      await show(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Your renovation goal (optional)'),
        'Modernise while keeping layout',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await reach(tester, find.text('Analyse room photos'));
      await tester.tap(find.text('Analyse room photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send photos for analysis'));
      await tester.pumpAndSettle();
      await reach(tester, find.text('Use this AI prompt for the next design'));
      await tester.tap(find.text('Use this AI prompt for the next design'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review final options'));
      await tester.pumpAndSettle();
      await reach(tester, find.text('Generate AI design'));
      await tester.tap(find.text('Generate AI design'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send to OpenAI'));
      await tester.pumpAndSettle();
      expect(analyses, 1);
      expect(edits, 1);
      expect(store.designsFor(room.id), hasLength(1));
      await tester.tap(find.text('Open design workspace'));
      await tester.pumpAndSettle();
      expect(find.text('Finished workspace'), findsOneWidget);
      expect(store.roomById(room.id)!.setupComplete, isTrue);
      expect(store.imageFor(room.originalId), isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
}
