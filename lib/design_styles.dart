const designStyles = <String, String>{
  'modern': 'Modern',
  'contemporary': 'Contemporary',
  'classic': 'Classic',
  'minimalist': 'Minimalist',
  'scandinavian': 'Scandinavian',
  'coastal': 'Coastal',
  'hamptons': 'Hamptons',
  'industrial': 'Industrial',
  'rustic': 'Rustic',
  'japandi': 'Japandi',
};

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

bool looksLikeBroadRenovation(String text) {
  final lower = text.toLowerCase();
  if (RegExp(r'whole room|full renovation|everything|all to change')
      .hasMatch(lower))
    return true;
  final groups = [
    r'cupboard|cabinet|joinery',
    r'benchtop|worktop|countertop',
    r'floor|tile',
    r'appliance|oven|cooktop|extractor|rangehood',
  ];
  return groups.where((pattern) => RegExp(pattern).hasMatch(lower)).length >= 2;
}
