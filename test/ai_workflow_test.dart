import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/ai_widgets.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/store.dart';
import 'package:renovision_ai/screens.dart';

import 'support/memory_box.dart';

class FailingRecords extends MemoryBox {
  bool failDesignWrites = false;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    if (failDesignWrites && key.toString().startsWith('design:')) {
      throw StateError('Synthetic disk failure');
    }
    return super.put(key, value);
  }
}

void main() {
  late RenovisionStore store;
  late FailingRecords records;
  late AiService ai;
  late int edits;
  late int status;
  late Map<String, dynamic>? submitted;
  late Uint8List original;
  late Uint8List output;
  late RenovationRoom room;
  DesignVersion? saved;
  Completer<void>? editGate;

  setUp(() async {
    edits = 0;
    status = 200;
    submitted = null;
    saved = null;
    editGate = null;
    original = img.encodePng(img.Image(width: 60, height: 40));
    output = img.encodePng(img.Image(width: 80, height: 50));
    ai = AiService(
      clientFactory: () => MockClient((request) async {
        if (request.url.path == '/health') {
          return http.Response(
            jsonEncode({
              'provider': 'OpenAI',
              'model': 'test-image-model',
              'quality': 'low',
              'maxInputImages': 7,
              'imageModels': ['test-image-model', 'test-alternate-model'],
              'imageQualities': ['low', 'medium'],
            }),
            200,
          );
        }
        edits++;
        submitted = jsonDecode(request.body) as Map<String, dynamic>;
        if (editGate != null) await editGate!.future;
        return http.Response(
          jsonEncode({
            'image': base64Encode(output),
            'provider': 'OpenAI',
            'model': submitted!['model'] ?? 'test-image-model',
            'quality': submitted!['quality'],
            'requestId': 'test-request',
          }),
          status,
        );
      }),
    );
    await ai.connect(url: 'http://127.0.0.1:8787', pairingCode: 'test-code');
    records = FailingRecords();
    store = RenovisionStore(records: records, photos: MemoryBox(), ai: ai);
    final project = await store.createProject('Claylands');
    room = await store.createRoom(
      projectId: project.id,
      name: 'Office',
      originalImage: original,
    );
  });
  tearDown(() => store.dispose());

  Future<void> showCard(
    WidgetTester tester, {
    String instructions = 'Fix only the skirting',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AiEditCard(
              store: store,
              buildRequest: () => AiEditRequest(
                roomId: room.id,
                parentId: null,
                sourceImageId: room.originalId,
                image: original,
                prompt: 'Fix only the skirting; keep the wide windows',
                title: 'AI office',
                instructions: instructions,
                precise: true,
              ),
              onSaved: (design) => saved = design,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Generate AI design'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate AI design'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to OpenAI'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'All cannot generate a precision edit until the user chooses whole-room mode',
    (tester) async {
      await store.updateRoom(
        room.copyWith(
          instructions: 'All',
          correctionInstructions: 'All',
          preciseEdit: true,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Generate AI design'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Generate AI design'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generate AI design'));
      await tester.pumpAndSettle();
      expect(edits, 0);
      expect(
        find.textContaining('“All” is a whole-room request'),
        findsOneWidget,
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Use whole-room renovation'),
        -350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Use whole-room renovation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use whole-room renovation'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.scrollUntilVisible(
        find.text('Generate AI design'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await confirm(tester);
      expect(edits, 1);
      expect(
        submitted!['prompt'],
        contains('coordinated whole-room renovation'),
      );
      expect(submitted!['prompt'], isNot(contains('PRECISION EDIT:')));
    },
  );

  testWidgets(
    'model selection sends nothing until confirmation and the reviewed settings are frozen',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AiConnectionCard(ai: ai)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('test-image-model').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('test-alternate-model').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('low').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('medium').last);
      await tester.pumpAndSettle();
      expect(ai.model, 'test-alternate-model');
      expect(edits, 0);
      await showCard(tester);
      await tester.tap(find.text('Generate AI design'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining(
            'test-alternate-model · medium quality',
          ),
        ),
        findsOneWidget,
      );
      ai.selectImageSettings(
        imageModel: 'test-image-model',
        imageQuality: 'low',
      );
      await tester.tap(find.text('Send to OpenAI'));
      await tester.pumpAndSettle();
      expect(submitted!['model'], 'test-alternate-model');
      expect(submitted!['quality'], 'medium');
      expect(edits, 1);
      expect(saved!.aiModel, 'test-alternate-model');
      expect(saved!.title, contains('test-alternate-model / medium'));
      expect(
        () => ai.selectImageSettings(
          imageModel: 'arbitrary',
          imageQuality: 'low',
        ),
        throwsA(isA<AiFailure>()),
      );
      expect(edits, 1);
    },
  );

  testWidgets(
    'running image generation blocks Back and survives scrolling away before local saving',
    (tester) async {
      editGate = Completer<void>();
      addTearDown(() {
        if (!editGate!.isCompleted) editGate!.complete();
      });
      await store.updateRoom(
        room.copyWith(instructions: 'Fix the skirting only'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        WorkspaceScreen(store: store, roomId: room.id),
                  ),
                ),
                child: const Text('Open room'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open room'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Generate AI design'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Generate AI design'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generate AI design'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send to OpenAI'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(edits, 1);
      await tester.pageBack();
      await tester.pump();
      expect(find.byType(WorkspaceScreen), findsOneWidget);
      expect(store.designsFor(room.id), isEmpty);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 1800));
      await tester.pump(const Duration(milliseconds: 400));
      editGate!.complete();
      await tester.pumpAndSettle();
      expect(store.designsFor(room.id), hasLength(1));
      expect(store.imageFor(room.originalId), orderedEquals(original));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'precision correction uses the approved version and keeps its parent without whole-room scope',
    (tester) async {
      final baseline = await store.createDesign(
        roomId: room.id,
        image: output,
        title: 'Approved office',
        prompt: 'Prior edit',
      );
      await store.approveBaseline(room.id, designId: baseline.id);
      await store.setRoomPalette(room.id, 'charcoal_walnut');
      await store.updateRoom(
        store
            .roomById(room.id)!
            .copyWith(
              instructions: 'Modernise the whole room',
              correctionInstructions: 'Fix the skirting only',
              preciseEdit: true,
            ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Generate AI design'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await confirm(tester);
      expect(edits, 1);
      expect(
        base64Decode(submitted!['image'] as String),
        orderedEquals(output),
      );
      final generated = store
          .designsFor(room.id)
          .firstWhere((d) => d.aiModel != null);
      expect(generated.parentId, baseline.id);
      expect(generated.sourceImageId, baseline.imageId);
      expect(generated.prompt, contains('Fix the skirting only'));
      expect(generated.prompt, contains('PRECISION EDIT:'));
      expect(generated.prompt, isNot(contains('EXPLORATION:')));
      expect(
        generated.prompt,
        isNot(contains('Replace the existing flooring')),
      );
      expect(generated.prompt, isNot(contains('REPLACE Oven')));
      expect(generated.prompt, isNot(contains('COLOUR PALETTE:')));
      expect(generated.prompt, isNot(contains('Modernise the whole room')));
      expect(store.roomById(room.id)!.approvedDesignId, baseline.id);
      expect(store.imageFor(room.originalId), orderedEquals(original));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'multi-view generation sends primary first and records supporting views',
    (tester) async {
      await store.addRoomPhotos(room.id, [output, original]);
      final views = store.roomById(room.id)!.photoIds;
      await store.setPrimaryPhoto(room.id, views[1]);
      await store.updateRoom(
        store
            .roomById(room.id)!
            .copyWith(instructions: 'Unify the design using every angle'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(store: store, roomId: room.id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Generate AI design'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await confirm(tester);
      expect(edits, 1);
      expect(
        base64Decode(submitted!['image'] as String),
        orderedEquals(output),
      );
      expect(submitted!['supportingImages'], hasLength(2));
      expect(submitted!['prompt'], contains('MULTIPLE VIEWS OF THE SAME ROOM'));
      final generated = store.designsFor(room.id).single;
      expect(generated.sourceImageId, views[1]);
      expect(generated.supportingImageIds, [views[0], views[2]]);
      expect(store.imageFor(room.originalId), orderedEquals(original));
      expect(tester.takeException(), isNull);
    },
  );

  test('client rejects remote relay destinations before sending a request', () {
    expect(
      () => AiService.localRelay('https://untrusted.example'),
      throwsA(isA<AiFailure>()),
    );
    expect(
      () => AiService.localRelay('http://localhost:8787/other'),
      throwsA(isA<AiFailure>()),
    );
    expect(AiService.localRelay('http://10.0.2.2:8787').host, '10.0.2.2');
  });

  testWidgets(
    'cancel or empty precision instruction makes no generation call',
    (tester) async {
      await showCard(tester);
      await tester.tap(find.text('Generate AI design'));
      await tester.pumpAndSettle();
      expect(edits, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(edits, 0);
      await tester.pumpWidget(const SizedBox());
      await showCard(tester, instructions: '');
      await tester.tap(find.text('Generate AI design'));
      await tester.pumpAndSettle();
      expect(edits, 0);
      expect(
        find.textContaining('Describe the specific change'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'in-app generation saves a new version and leaves baseline intact',
    (tester) async {
      await showCard(tester);
      await confirm(tester);
      expect(edits, 1);
      expect(submitted!['confirmed'], isTrue);
      expect(
        base64Decode(submitted!['image'] as String),
        orderedEquals(original),
      );
      final version = store.designsFor(room.id).single;
      expect(saved!.id, version.id);
      expect(version.sourceImageId, room.originalId);
      expect(version.aiProvider, 'OpenAI');
      expect(version.aiModel, 'test-image-model');
      expect(version.providerRequestId, 'test-request');
      expect(store.imageFor(version.imageId), orderedEquals(output));
      expect(store.imageFor(room.originalId), orderedEquals(original));
      expect(store.roomById(room.id)!.approvedDesignId, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('provider error leaves project untouched and does not retry', (
    tester,
  ) async {
    status = 402;
    await showCard(tester);
    await confirm(tester);
    expect(edits, 1);
    expect(store.designsFor(room.id), isEmpty);
    expect(store.imageFor(room.originalId), orderedEquals(original));
    expect(find.textContaining('AI key was rejected'), findsOneWidget);
  });

  testWidgets('failed local save can be retried without another paid request', (
    tester,
  ) async {
    await showCard(tester);
    records.failDesignWrites = true;
    await confirm(tester);
    expect(edits, 1);
    expect(store.designsFor(room.id), isEmpty);
    expect(find.text('Retry saving result'), findsOneWidget);
    records.failDesignWrites = false;
    await tester.ensureVisible(find.text('Retry saving result'));
    await tester.tap(find.text('Retry saving result'));
    await tester.pumpAndSettle();
    expect(edits, 1);
    expect(store.designsFor(room.id), hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
