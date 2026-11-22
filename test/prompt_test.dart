import 'package:flutter_test/flutter_test.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/room_analysis.dart';

void main() {
  test('lighting updates replace main fittings rather than only adding accent lights, while protections win', () {
    for (final fullRoom in [false, true]) {
      final prompt = buildRenovationPrompt(
        roomName: 'Bathroom',
        roomTypeId: 'bathroom',
        instructions: 'Update lighting',
        protectedFeatures: 'Keep the pendant above the bath',
        preciseEdit: false,
        wholeRoomDirection: fullRoom,
        renovationScopeIds: fullRoom ? [] : ['lighting'],
      );
      expect(prompt, contains('old main fitting must not remain unchanged'));
      expect(
        prompt,
        contains('keeping the ceiling structure does not mean keeping'),
      );
      expect(prompt, contains('do not invent unseen fittings'));
      expect(prompt, contains('MUST RETAIN: Keep the pendant above the bath'));
      expect(prompt, contains('task or accent lighting only take priority'));
    }
  });

  test('a precise accent-light-only edit does not inherit whole-room fixture replacement', () {
    const instruction =
        'Add lighting under the vanity only. Keep the main ceiling light.';
    final prompt = buildRenovationPrompt(
      roomName: 'Bathroom',
      instructions: instruction,
      protectedFeatures: 'Main ceiling light',
      preciseEdit: true,
      wholeRoomDirection: true,
    );
    expect(prompt, contains('Requested design changes: $instruction'));
    expect(
      prompt,
      isNot(contains('old main fitting must not remain unchanged')),
    );
    expect(prompt, contains('PRECISION EDIT'));
  });

  test('analysis and generation clarify regional objects without rewriting the user brief', () {
    const instruction =
        'Replace the basin and taps only; retain the vanity cabinet.';
    final prompt = buildRenovationPrompt(
      roomName: 'Ensuite',
      instructions: instruction,
      protectedFeatures: 'Vanity cabinet',
      preciseEdit: true,
    );
    for (final text in [prompt, roomAnalysisInstructions]) {
      expect(text, contains('basin/washbasin/bathroom sink'));
      expect(text, contains('Benchtop/worktop/countertop'));
      expect(
        text,
        contains('Do not expand a basin-only request to the whole vanity'),
      );
    }
    expect(prompt, contains('Requested design changes: $instruction'));
    expect(
      roomAnalysisInstructions,
      contains('main ceiling/wall light fittings'),
    );
    expect(roomAnalysisInstructions, contains('rather than guessing'));
  });

  test('whole-room direction works without checkboxes and explicit protections remain authoritative', () {
    final prompt = buildRenovationPrompt(
      roomName: 'Kitchen',
      instructions: 'Modernise the whole kitchen',
      protectedFeatures: 'Keep the existing floor and oven',
      preciseEdit: false,
      wholeRoomDirection: true,
      roomItemChoices: {'kitchen_oven': 'keep'},
    );
    expect(prompt, contains('WHOLE-ROOM DESIGN DIRECTION:'));
    expect(prompt, contains('layered lighting'));
    expect(prompt, contains('Remove everyday loose clutter'));
    expect(prompt, contains('MUST RETAIN: Keep the existing floor and oven'));
    expect(prompt, contains('KEEP EXISTING Oven:'));
    expect(
      prompt,
      contains('Explicit user instructions and KEEP choices override'),
    );
    final precise = buildRenovationPrompt(
      roomName: 'Kitchen',
      instructions: 'Remove only handles',
      protectedFeatures: '',
      preciseEdit: true,
      wholeRoomDirection: true,
    );
    expect(precise, isNot(contains('WHOLE-ROOM DESIGN DIRECTION:')));
  });
  test(
    'whole-room All uses a coordinated brief and staging remains opt-in',
    () {
      String prompt(List<String> scope) => buildRenovationPrompt(
        roomName: 'Kitchen',
        instructions: 'All',
        protectedFeatures: 'Layout and windows',
        preciseEdit: false,
        renovationScopeIds: scope,
      );
      final ordinary = prompt(['walls']);
      expect(ordinary, contains('coordinated whole-room renovation'));
      expect(ordinary, isNot(contains('remove freestanding rubbish bins')));
      final staged = prompt(['walls', 'tidy_stage']);
      expect(staged, contains('remove freestanding rubbish bins'));
      expect(staged, contains('Any explicitly protected item takes priority'));
      expect(staged, contains('outside view'));
      expect(staged, contains('MUST RETAIN: Layout and windows'));
    },
  );
  test('precision prompt includes protected features and limited scope', () {
    final prompt = buildRenovationPrompt(
      roomName: 'office',
      instructions: 'Remove only the fireplace',
      protectedFeatures: 'Keep the existing wide windows',
      preciseEdit: true,
    );
    expect(prompt, contains('PRECISION EDIT'));
    expect(prompt, contains('Remove only the fireplace'));
    expect(prompt, contains('Keep the existing wide windows'));
    expect(prompt, contains('Do not silently remove'));
  });

  test('exploration prompt has a creative mode', () {
    final prompt = buildRenovationPrompt(
      roomName: 'kitchen',
      instructions: '',
      protectedFeatures: '',
      preciseEdit: false,
    );
    expect(prompt, contains('EXPLORATION'));
    expect(prompt, contains('Suggest a tasteful'));
  });

  test('an empty New design brief authorises a substantial coordinated concept without weakening a correction', () {
    final concept = buildRenovationPrompt(
      roomName: 'Living room',
      instructions: '',
      protectedFeatures: 'Wide windows and fireplace',
      preciseEdit: false,
      wholeRoomDirection: true,
    );
    expect(concept, contains('DESIGN INITIATIVE:'));
    expect(concept, contains('at least three substantial'));
    expect(
      concept,
      contains('Unprotected existing furniture may be replaced in place'),
    );
    expect(concept, contains('MUST RETAIN: Wide windows and fireplace'));
    final correction = buildRenovationPrompt(
      roomName: 'Living room',
      instructions: 'Change only the lamp shade',
      protectedFeatures: 'Wide windows and fireplace',
      preciseEdit: true,
      wholeRoomDirection: true,
    );
    expect(correction, isNot(contains('DESIGN INITIATIVE:')));
    expect(correction, isNot(contains('may be replaced in place')));
    expect(correction, contains('Keep unselected regions consistent'));
  });
}
