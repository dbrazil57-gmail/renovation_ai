import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:renovision_ai/app_access.dart';
import 'package:renovision_ai/app_access_widgets.dart';
import 'package:renovision_ai/ai_service.dart';
import 'package:renovision_ai/store.dart';

import 'support/access_fixture.dart';
import 'support/memory_box.dart';

void main() {
  test('expired work stays readable/exportable and AI is blocked before any provider call', () async {
    final records = MemoryBox(), photos = MemoryBox();
    final original = RenovisionStore(records: records, photos: photos);
    final project = await original.createProject('Retained project');
    final room = await original.createRoom(
      projectId: project.id,
      name: 'Kitchen',
      originalImage: Uint8List.fromList([1, 2, 3]),
    );
    original.dispose();
    final fixture = AccessFixture();
    await fixture.initialise();
    final access = fixture.create();
    await access.startTrial();
    fixture.now = fixture.now.add(const Duration(days: 31));
    int providerCalls = 0;
    final ai = AiService(
      clientFactory: () {
        providerCalls++;
        throw StateError('Must not contact provider');
      },
    );
    final store = RenovisionStore(
      records: records,
      photos: photos,
      access: access,
      ai: ai,
    );
    expect(store.roomById(room.id)!.name, 'Kitchen');
    expect(store.imageFor(room.originalId), [1, 2, 3]);
    final backup = utf8.decode(store.backupFor(project.id).encode());
    expect(backup, contains('Retained project'));
    expect(backup, isNot(contains('synthetic-licence')));
    expect(backup, isNot(contains(access.deviceId!)));
    expect(backup, isNot(contains('seed')));
    await expectLater(
      store.createProject('Denied'),
      throwsA(isA<AccessFailure>()),
    );
    await expectLater(
      store.createRoom(
        projectId: project.id,
        name: 'Denied',
        originalImage: Uint8List.fromList([4]),
      ),
      throwsA(isA<AccessFailure>()),
    );
    await expectLater(
      ai.edit(image: Uint8List.fromList([1]), prompt: 'New kitchen'),
      throwsA(isA<AiFailure>()),
    );
    await expectLater(
      ai.analyse(image: Uint8List.fromList([1]), context: 'Kitchen'),
      throwsA(isA<AiFailure>()),
    );
    await expectLater(
      ai.researchReferences('Kitchen'),
      throwsA(isA<AiFailure>()),
    );
    expect(providerCalls, 0);
    expect(ai.diagnostics.entries, isEmpty);
    expect(store.roomsFor(project.id), hasLength(1));
    store.dispose();
  });

  testWidgets(
    'private access stays compact and has no checkout/trial actions',
    (tester) async {
      final access = AppAccess();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppAccessSettingsCard(access: access)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Private test build'), findsOneWidget);
      await tester.tap(find.text('App access'));
      await tester.pumpAndSettle();
      expect(find.text('Request trial'), findsNothing);
      expect(find.text('Restore Samsung purchase'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      access.dispose();
    },
  );
  testWidgets('unconfigured store build cannot request a trial or buy', (
    tester,
  ) async {
    final access = AppAccess(
      configuration: const AccessConfiguration(mode: 'licensed'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppAccessSettingsCard(access: access),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('App access'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Request trial'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Restore Samsung purchase'),
          )
          .onPressed,
      isNull,
    );
    expect(find.textContaining('Checkout is unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    access.dispose();
  });
}
