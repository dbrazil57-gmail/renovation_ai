import 'package:flutter_test/flutter_test.dart';
import 'package:renovision_ai/models.dart';

void main() {
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
}
