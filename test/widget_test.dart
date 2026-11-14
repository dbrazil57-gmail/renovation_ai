import 'package:flutter_test/flutter_test.dart';
import 'package:renovision_ai/models.dart';

void main() {
  test('Claylands narrow edit stays explicit in the generated prompt', () {
    final prompt = buildRenovationPrompt(
      roomName: 'home office',
      instructions:
          'Remove only the brick fireplace and add a closed cupboard.',
      protectedFeatures:
          'Keep rear windows, walls, camera angle and joinery unchanged.',
      preciseEdit: true,
    );
    expect(prompt, contains('PRECISION EDIT'));
    expect(prompt, contains('Remove only the brick fireplace'));
    expect(prompt, contains('Keep rear windows'));
    expect(prompt, contains('Do not silently remove items outside'));
  });
}
