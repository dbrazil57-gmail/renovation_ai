import 'support/focus_navigation.dart';

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
import 'package:renovision_ai/app_session.dart';
import 'package:renovision_ai/main.dart' show RenovisionApp;
import 'package:renovision_ai/local_paint.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';
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
    final workspace = find.byKey(const ValueKey('workspace-generate'));
    final button = workspace.evaluate().isNotEmpty
        ? workspace
        : find.text('Generate AI design');
    await ensureFocusVisible(tester, button);
    await tester.pumpAndSettle();
    await tester.tap(button);
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
          home: WorkspaceScreen(
            store: store,
            roomId: room.id,
            startInPrecision: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await revealFocusControl(
        tester,
        find.text('Generate AI design'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await ensureFocusVisible(tester, find.text('Generate AI design'));
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
      await revealFocusControl(
        tester,
        find.text('Use New design'),
        -350,
        scrollable: find.byType(Scrollable).first,
      );
      await ensureFocusVisible(tester, find.text('Use New design'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use New design'));
      await tester.pump(const Duration(milliseconds: 700));
      await revealFocusControl(
        tester,
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
    'selected design update sends only the focused request and preserves broad brief and approval',
    (tester) async {
      final baseline = await store.createDesign(
        roomId: room.id,
        image: output,
        title: 'Chosen design',
        prompt: 'Historical brief',
      );
      await store.approveBaseline(room.id, designId: baseline.id);
      await store.addRoomPhotos(room.id, [original]);
      await store.updateRoom(
        store
            .roomById(room.id)!
            .copyWith(
              instructions: 'Replace every cabinet and the entire floor',
              designStyleIds: ['classic'],
            ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(
            store: store,
            roomId: room.id,
            initialDesignId: baseline.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final update = find.byKey(const ValueKey('selected-design-update'));
      await ensureFocusVisible(tester, update);
      await tester.enterText(update, 'Change only the tap to brushed brass');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final apply = find.text('Review & generate change').first;
      await Scrollable.ensureVisible(tester.element(apply), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(edits, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await ensureFocusVisible(tester, apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send to OpenAI'));
      await tester.pumpAndSettle();
      expect(edits, 1);
      expect(
        submitted!['prompt'],
        contains('Change only the tap to brushed brass'),
      );
      expect(submitted!['prompt'], isNot(contains('Replace every cabinet')));
      expect(submitted!['supportingImages'], anyOf(isNull, isEmpty));
      expect(
        store.roomById(room.id)!.instructions,
        'Replace every cabinet and the entire floor',
      );
      expect(store.roomById(room.id)!.approvedDesignId, baseline.id);
      expect(
        store.designsFor(room.id).firstWhere((d) => d.aiModel != null).parentId,
        baseline.id,
      );
      expect(tester.takeException(), isNull);
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
      expect(saved!.recipe!.toMap()['imageModel'], 'test-alternate-model');
      expect(saved!.recipe!.toMap()['imageQuality'], 'medium');
      expect(saved!.recipe!.toMap()['preciseEdit'], isTrue);
      expect(
        saved!.recipe!.toMap()['correctionInstructions'],
        'Fix only the skirting',
      );
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
      await revealFocusControl(
        tester,
        find.text('Generate AI design'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await ensureFocusVisible(tester, find.text('Generate AI design'));
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
          home: WorkspaceScreen(
            store: store,
            roomId: room.id,
            startInPrecision: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await revealFocusControl(
        tester,
        find.byKey(const ValueKey('workspace-generate')),
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
    'finish polish resumes with clean source first, guide second and no request before confirmation',
    (tester) async {
      final clean = await store.createDesign(
        roomId: room.id,
        image: output,
        title: 'Approved kitchen design',
        prompt: 'Earlier approved concept',
      );
      await store.approveBaseline(room.id, designId: clean.id);
      await store.addRoomPhotos(room.id, [original]);
      final finish = LocalPaintRecipe(
        width: 80,
        height: 50,
        surfaces: [
          PaintSurface(
            name: 'Splashback 1',
            kind: LocalSurfaceKind.splashback,
            finish: LocalFinish.rectangleTiles,
            rgb: 0x7D6247,
            groutRgb: 0x555550,
            marks: [
              PaintMark(PaintMarkKind.polygon, const [
                PaintPoint(.1, .2),
                PaintPoint(.9, .2),
                PaintPoint(.9, .6),
                PaintPoint(.1, .6),
              ]),
            ],
          ),
        ],
      );
      final guideBytes = renderLocalPaint(PaintRenderInput(output, finish))
          .bytes;
      final guide = await store.createDesign(
        roomId: room.id,
        image: guideBytes,
        title: 'Local finishes',
        prompt: 'Local finish preview; no AI request.',
        parentId: clean.id,
        sourceImageId: clean.imageId,
        paintRecipe: finish,
      );
      await store.updateRoom(
        store
            .roomById(room.id)!
            .copyWith(
              instructions: 'Replace every cabinet and the entire floor',
              correctionInstructions: '',
            ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(
            store: store,
            roomId: room.id,
            initialDesignId: guide.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final resume = find.byKey(const ValueKey('resume-finish-polish'));
      await ensureFocusVisible(tester, resume);
      await tester.tap(resume);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(edits, 0);
      final review = find.text('Review & send AI polish').first;
      await ensureFocusVisible(tester, review);
      await tester.tap(review);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('polish-prompt-before-send')),
        findsOneWidget,
      );
      expect(find.text('Clean design · image 1'), findsOneWidget);
      expect(find.text('Rough finish guide · image 2'), findsOneWidget);
      expect(
        find.textContaining('This is a broad renovation request'),
        findsNothing,
      );
      expect(edits, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(edits, 0);
      expect(store.designsFor(room.id), hasLength(2));
      expect(
        store.roomById(room.id)!.correctionInstructions,
        startsWith('FINISH POLISH:'),
      );

      // Reopening a previous-release draft must also recover roles from its
      // local recipe/source provenance, without going back through the editor.
      await tester.pumpWidget(const SizedBox());
      await store.updateRoom(
        store
            .roomById(room.id)!
            .copyWith(
              correctionInstructions:
                  'The selected image is a rough local finish preview with paint/tile choices. '
                  'Use bronze tiles with dark grout. Keep the tile joints especially fine.',
              precisionConceptCount: 3,
            ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(
            store: store,
            roomId: room.id,
            initialDesignId: guide.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await confirm(tester);
      expect(edits, 1);
      expect(
        base64Decode(submitted!['image'] as String),
        orderedEquals(output),
      );
      final supporting = submitted!['supportingImages'] as List;
      expect(supporting, hasLength(1));
      expect(
        base64Decode(supporting.single as String),
        orderedEquals(guideBytes),
      );
      final prompt = submitted!['prompt'] as String;
      expect(prompt, contains('Edit image 1'));
      expect(prompt, contains('Image 2 is a rough local'));
      expect(prompt, contains('actual splashback wall'));
      expect(prompt, contains('window glass, frame and outdoor view'));
      expect(prompt, contains('even where the rough guide covers them'));
      expect(prompt, contains('Keep the tile joints especially fine'));
      expect(prompt, isNot(contains('Replace every cabinet')));
      expect(prompt, isNot(contains('MULTIPLE VIEWS OF THE SAME ROOM')));
      expect(prompt, isNot(contains('Image 1 is the rough')));
      final polished = store
          .designsFor(room.id)
          .singleWhere((version) => version.providerRequestId != null);
      expect(polished.title, startsWith('AI finish polish'));
      expect(polished.parentId, guide.id);
      expect(polished.sourceImageId, clean.imageId);
      expect(polished.supportingImageIds, [guide.imageId]);
      expect(polished.paintRecipe, isNull);
      expect(store.roomById(room.id)!.approvedDesignId, clean.id);
      expect(store.imageFor(room.originalId), orderedEquals(original));
      expect(store.imageFor(guide.imageId), orderedEquals(guideBytes));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(store.roomById(room.id)!.correctionInstructions, isEmpty);
      final portable = ProjectBackup.decode(
        store.backupFor(room.projectId).encode(),
      );
      final restored = await store.restoreBackup(portable);
      final restoredRoom = store.roomsFor(restored.id).single;
      final restoredVersions = store.designsFor(restoredRoom.id);
      final restoredPolish = restoredVersions.singleWhere(
        (v) => v.aiModel != null,
      );
      final restoredGuide = restoredVersions.singleWhere(
        (v) => v.paintRecipe != null,
      );
      expect(restoredPolish.parentId, restoredGuide.id);
      expect(restoredPolish.supportingImageIds, [restoredGuide.imageId]);
      expect(restoredPolish.sourceImageId, restoredGuide.sourceImageId);
      expect(
        store.imageFor(restoredPolish.sourceImageId!),
        orderedEquals(output),
      );
      expect(store.imageFor(restoredGuide.imageId), orderedEquals(guideBytes));
      expect(edits, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'finish polish refuses an unavailable clean source instead of sending only the rough guide',
    (tester) async {
      final finish = LocalPaintRecipe(
        width: 60,
        height: 40,
        surfaces: [
          PaintSurface(
            name: 'Wall',
            marks: [
              PaintMark(PaintMarkKind.polygon, const [
                PaintPoint(.1, .1),
                PaintPoint(.8, .1),
                PaintPoint(.8, .8),
              ]),
            ],
          ),
        ],
      );
      final guide = await store.createDesign(
        roomId: room.id,
        image: output,
        title: 'Clean design',
        prompt: '',
      );
      final preview = await store.createDesign(
        roomId: room.id,
        image: output,
        title: 'Local paint',
        prompt: '',
        sourceImageId: guide.imageId,
        paintRecipe: finish,
      );
      await store.updateRoom(
        room.copyWith(correctionInstructions: paintRefinementPrompt(finish)),
      );
      await store.photos.delete(guide.imageId);
      await tester.pumpWidget(
        MaterialApp(
          home: WorkspaceScreen(
            store: store,
            roomId: room.id,
            initialDesignId: preview.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-generate')));
      await tester.pumpAndSettle();
      expect(edits, 0);
      expect(
        find.textContaining(
          'clean source for this finish preview is unavailable',
        ),
        findsOneWidget,
      );
      expect(store.designsFor(room.id), hasLength(2));
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
      await revealFocusControl(
        tester,
        find.byKey(const ValueKey('workspace-generate')),
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

  testWidgets(
    'refresh while reviewing AI confirmation restores workspace without replaying the dialog or request',
    (tester) async {
      await store.updateRoom(room.copyWith(instructions: 'Update the floor'));
      await store.records.put(AppPageSession.recordKey, [
        {'page': 'home', 'tab': 0},
        {
          'page': 'workspace',
          'projectId': room.projectId,
          'roomId': room.id,
          'photoId': room.originalId,
          'section': 'refine',
          'mode': 'newDesign',
        },
      ]);
      await tester.pumpWidget(RenovisionApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workspace-generate')));
      await tester.pumpAndSettle();
      expect(find.text('Send to OpenAI'), findsOneWidget);
      expect(edits, 0);
      final session = tester
          .widget<AppPageSessionScope>(find.byType(AppPageSessionScope))
          .session;
      await session.flush();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(RenovisionApp(store: store));
      await tester.pumpAndSettle();
      expect(find.byType(WorkspaceScreen), findsOneWidget);
      expect(find.text('Send to OpenAI'), findsNothing);
      expect(edits, 0);
      expect(store.designsFor(room.id), isEmpty);
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
    await ensureFocusVisible(tester, find.text('Retry saving result'));
    await tester.tap(find.text('Retry saving result'));
    await tester.pumpAndSettle();
    expect(edits, 1);
    expect(store.designsFor(room.id), hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
