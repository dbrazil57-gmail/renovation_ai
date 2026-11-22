import 'dart:convert';

import 'room_analysis.dart';

/// A detached, allow-listed snapshot. Connection settings/keys are never accepted.
class DesignRecipe {
  static const textFields = [
    'instructions',
    'correctionInstructions',
    'protectedFeatures',
    'colourPaletteId',
    'otherStyle',
    'aiPrompt',
    'flooringNotes',
    'removeItems',
    'roomTypeId',
    'provider',
    'imageModel',
    'imageQuality',
    'conceptDirection',
  ];
  static const boolFields = [
    'preciseEdit',
    'keepLayout',
    'fullRenovation',
    'compareStyles',
    'useAiPrompt',
    'fixedBrief',
  ];
  static const listFields = ['designStyleIds', 'renovationScopeIds'];
  final String _json;
  DesignRecipe(Map value) : _json = jsonEncode(_checked(value));
  Map<String, dynamic> toMap() => jsonDecode(_json) as Map<String, dynamic>;
  RoomAnalysis? get analysis {
    final value = toMap()['analysis'];
    return value is Map ? RoomAnalysis.fromMap(value) : null;
  }

  DesignRecipe withValues(Map<String, dynamic> values) =>
      DesignRecipe({...toMap(), ...values});

  static Map<String, dynamic> _checked(Map value) {
    final result = <String, dynamic>{'version': 1};
    if (value['version'] != null && value['version'] != 1) {
      throw const FormatException('Unsupported design settings');
    }
    for (final key in textFields) {
      final item = value[key];
      if (item == null) continue;
      if (item is! String || item.length > 16000) {
        throw const FormatException('Invalid design settings');
      }
      result[key] = item;
    }
    for (final key in boolFields) {
      final item = value[key];
      if (item == null) continue;
      if (item is! bool) throw const FormatException('Invalid design settings');
      result[key] = item;
    }
    for (final key in listFields) {
      final item = value[key];
      if (item == null) continue;
      if (item is! List ||
          item.length > 40 ||
          item.any((id) => id is! String || id.length > 100)) {
        throw const FormatException('Invalid design choices');
      }
      result[key] = List<String>.from(item);
    }
    for (final key in ['conceptCount', 'precisionConceptCount']) {
      final item = value[key];
      if (item == null) continue;
      if (item is! int || item < 1 || item > 3) {
        throw const FormatException('Invalid design count');
      }
      result[key] = item;
    }
    final choices = value['roomItemChoices'];
    if (choices != null) {
      if (choices is! Map ||
          choices.length > 100 ||
          choices.entries.any(
            (e) =>
                e.key is! String ||
                (e.key as String).length > 100 ||
                !['keep', 'replace'].contains(e.value),
          )) {
        throw const FormatException('Invalid room choices');
      }
      result['roomItemChoices'] = Map<String, String>.from(choices);
    }
    final analysis = value['analysis'];
    if (analysis != null) {
      if (analysis is! Map) {
        throw const FormatException('Invalid saved analysis');
      }
      result['analysis'] = RoomAnalysis.fromMap(analysis).toMap();
    }
    if (jsonEncode(result).length > 128000) {
      throw const FormatException('Saved settings too large');
    }
    return result;
  }
}
