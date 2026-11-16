import 'room_features.dart';

const renovationScope = <String, ({String label, String instruction})>{
  'tidy_stage': (
    label: 'Tidy and stage / remove everyday clutter',
    instruction: 'Tidy and stage the visible room: remove freestanding rubbish bins, loose packaging, washing-up and incidental clutter. Finish exposed surfaces naturally. Do not remove built-in storage, appliances, useful furniture, personal possessions explicitly marked to keep, safety devices or functional fittings. Preserve architecture, openings, the outside view and the agreed layout. Any explicitly protected item takes priority over this cleanup.',
  ),
  'flooring': (
    label: 'Replace flooring',
    instruction: 'Replace the existing flooring across the visible room with a new finish that suits the selected palette and style. Do not retain the old floor pattern.',
  ),
  'cabinetry': (
    label: 'Update cupboards / cabinetry',
    instruction: 'Update cupboard and cabinet fronts within the agreed layout; retain useful storage unless its removal is requested.',
  ),
  'benchtops': (
    label: 'Replace benchtops',
    instruction: 'Replace benchtop surfaces with a new finish suited to the selected palette and style.',
  ),
  'appliances': (
    label: 'Update appliances',
    instruction: 'Replace visible appliances with modern equivalents in their existing positions unless relocation is requested.',
  ),
  'splashback': (
    label: 'Replace splashback',
    instruction:
        'Replace the existing splashback finish within its current wall area.',
  ),
  'lighting': (
    label: 'Update lighting',
    instruction: 'Update visible light fittings without changing the ceiling shape or inventing new structural openings.',
  ),
  'walls': (
    label: 'Refresh wall finishes',
    instruction: 'Refresh visible wall paint and finishes without moving walls, windows or doors.',
  ),
  'dated_fixtures': (
    label: 'Remove dated wall fixtures / old telephone',
    instruction: 'Remove obsolete wall-mounted telephones or handsets and their visible cords if present. Patch and finish the exposed wall to match its surroundings. Retain power points, light switches, safety devices and any protected or uncertain functional equipment; ask about uncertain items rather than removing them.',
  ),
};

String buildRenovationScopePrompt({
  List<String> scopeIds = const [],
  String flooringNotes = '',
  String removeItems = '',
  String? roomType,
  bool coordinatedDesign = false,
}) {
  final selected = scopeIds
      .toSet()
      .where(renovationScope.containsKey)
      .where((id) => roomType == null || scopeAppliesToRoom(id, roomType))
      .toList();
  final removal = removeItems.trim();
  if (selected.isEmpty && removal.isEmpty) return '';
  return '''${coordinatedDesign ? 'ADVANCED USER OVERRIDES: Apply these explicit choices within the whole-room design direction. They do not require leaving every other surface unchanged.' : 'SELECTED CHANGES: These selections explicitly define the requested edit areas, including when Precision edit is selected. A selected floor or fixture is within scope; do not preserve its old appearance merely because it is in the original photo.'}
${selected.map((id) => '- ${renovationScope[id]!.instruction}').join('\n')}
${selected.contains('flooring') && flooringNotes.trim().isNotEmpty ? '- New flooring direction: ${flooringNotes.trim()}' : ''}
${removal.isNotEmpty ? '- Other items explicitly requested for removal: $removal. Remove only these items and repair the exposed finishes.' : ''}
${coordinatedDesign ? 'Coordinate these choices with the whole-room design direction.' : 'Retain everything outside the requested changes.'} Protected features take priority over these selections; if a selected change conflicts with a protected feature, retain it and ask for clarification.''';
}
