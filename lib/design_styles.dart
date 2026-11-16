const designStyles = <String, String>{
  'modern': 'Modern / Contemporary',
  'classic': 'Classic',
  'minimalist': 'Minimalist',
  'scandinavian': 'Scandinavian',
  'coastal': 'Coastal',
  'hamptons': 'Hamptons',
  'industrial': 'Industrial',
  'rustic': 'Rustic',
  'japandi': 'Japandi',
  'mid_century': 'Mid-century modern',
  'art_deco': 'Art Deco',
  'mediterranean': 'Mediterranean',
  'farmhouse': 'Farmhouse',
  'cottage': 'Country cottage',
  'french_provincial': 'French provincial',
  'bohemian': 'Bohemian',
  'eclectic': 'Eclectic',
  'transitional': 'Transitional',
  'hotel': 'Boutique hotel',
};

// Read legacy selections without rewriting existing room records or history.
String canonicalStyleId(String id) => id == 'contemporary' ? 'modern' : id;
List<String> canonicalStyleIds(Iterable<String> ids) =>
    ids.map(canonicalStyleId).toSet().toList();

bool hasNoProtectedFinishes(String text) =>
    const {
      'nothing',
      'none',
      'nothing to retain',
      'nothing to keep',
      'nothing all to change',
      'all to change',
    }.contains(
      text
          .toLowerCase()
          .replaceAll(RegExp(r'[.,!;:]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    );

bool isWholeRoomRequest(String text) => const {
  'all',
  'everything',
  'whole room',
  'all of it',
  'change everything',
}.contains(text.toLowerCase().trim().replaceAll(RegExp(r'[.!]'), ''));

bool looksLikeBroadRenovation(String text) {
  final lower = text.toLowerCase();
  if (isWholeRoomRequest(text)) return true;
  if (RegExp(r'whole room|full renovation|everything|all to change')
      .hasMatch(lower)) {
    return true;
  }
  final groups = [
    r'cupboard|cabinet|joinery',
    r'benchtop|worktop|countertop',
    r'floor|tile',
    r'appliance|oven|cooktop|extractor|rangehood',
  ];
  return groups.where((pattern) => RegExp(pattern).hasMatch(lower)).length >= 2;
}
