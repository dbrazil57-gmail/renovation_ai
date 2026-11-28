// Curated common starting points; not a measured popularity ranking.
const commonStyleIds = [
  'modern',
  'classic',
  'minimalist',
  'scandinavian',
  'coastal',
  'australian',
  'industrial',
  'rustic',
  'japandi',
  'mid_century',
];

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
  'japanese': 'Japanese',
  'italian': 'Italian',
  'moroccan': 'Moroccan',
  'indian': 'Indian',
  'australian': 'Australian',
  // Historical IDs remain readable in saved rooms/recipes, not new pickers.
  'australian_contemporary': 'Australian contemporary',
  'australian_coastal': 'Australian coastal',
  'australian_bushland': 'Bushland retreat',
  'australian_heritage': 'Australian heritage',
  'australian_tropical': 'Tropical Australian',
};

const legacyAustralianStyleIds = {
  'australian_contemporary',
  'australian_coastal',
  'australian_bushland',
  'australian_heritage',
  'australian_tropical',
};

const australianStyleIds = {'australian', ...legacyAustralianStyleIds};

Iterable<MapEntry<String, String>> selectableDesignStyles({
  Iterable<String> existing = const [],
}) => designStyles.entries.where(
  (entry) =>
      !legacyAustralianStyleIds.contains(entry.key) ||
      existing.contains(entry.key),
);

const regionalStyleIds = {
  'scandinavian',
  'japandi',
  'mediterranean',
  'french_provincial',
  'japanese',
  'italian',
  'moroccan',
  'indian',
  ...australianStyleIds,
};

const styleDesignCues = <String, String>{
  'australian': 'Australian-inspired relaxed indoor/outdoor character, natural timber and stone, eucalyptus greens and earthy neutrals where the palette allows, tactile fabrics and understated practical detailing within the existing geometry. Adapt to the actual property location and climate; this style does not imply the home is in Australia. Where planting is authorised, use locally appropriate plants rather than assuming Australian natives suit every country or site',
  'australian_contemporary': 'Australian contemporary character with tactile timber, warm stone, restrained joinery and practical indoor/outdoor details within the existing geometry; no new openings',
  'australian_coastal': 'relaxed Australian coastal character with sun-washed neutrals, timber, woven textures and understated finishes; avoid nautical props and retain the real outlook',
  'australian_bushland': 'bushland-inspired gum-leaf, earthy and stone tones within the selected palette, textured timber and restrained natural materials; native planting only where authorised, never replace the outside view',
  'australian_heritage': 'a contemporary renovation respecting visible Australian heritage details, verandah character and crafted timber where present; do not invent period features or alter protected facade details',
  'australian_tropical': 'Australian tropical-inspired light materials, woven texture and shaded alfresco character within the existing structure; locally appropriate planting only where authorised, not generic resort palms',
  'modern': 'clean contemporary lines, streamlined cabinetry and fittings, restrained detailing and integrated lighting',
  'classic': 'balanced proportions, refined framed or panelled detailing where appropriate, timeless fittings and elegant layered finishes',
  'minimalist':
      'simple forms, visually quiet surfaces and discreet usable storage',
  'scandinavian': 'pale natural timber, light neutral finishes and practical understated forms',
  'coastal': 'light airy finishes, relaxed natural textures and gentle seaside-inspired tones',
  'hamptons': 'light panelled cabinetry, tailored traditional details and relaxed coastal finishes',
  'industrial': 'metal accents, robust tactile materials and purposeful utilitarian detailing',
  'rustic': 'warm timber, tactile natural surfaces and restrained handcrafted character',
  'japandi': 'warm minimalism, natural timber and quiet balanced detailing',
  'mid_century':
      'warm timber, simple geometric detailing and restrained retro accents',
  'art_deco':
      'refined geometric accents, rich contrast and elegant metal detailing',
  'mediterranean':
      'warm earthy finishes, natural texture and relaxed sunlit character',
  'farmhouse': 'practical panelled joinery, warm natural materials and relaxed traditional detailing',
  'cottage': 'comfortable small-scale traditional details and gently textured finishes',
  'french_provincial': 'refined traditional joinery and muted natural finishes',
  'bohemian': 'layered natural textures, personal decorative accents and relaxed coordination',
  'eclectic': 'a deliberate balance of contrasting periods, textures and personal accents',
  'transitional':
      'clean contemporary forms balanced with restrained classic detailing',
  'hotel': 'coordinated polished finishes, considered lighting and restrained luxurious accents',
  'japanese': 'Japanese-inspired calm proportions, natural timber, tactile restrained finishes and considered uncluttered detailing; retain the real room geometry',
  'italian': 'Italian-inspired material coordination, refined stone and timber, elegant crafted joinery and balanced contemporary or traditional detailing as selected',
  'moroccan': 'Moroccan-inspired restrained geometric pattern, tactile plaster and crafted accents within the chosen palette; do not introduce arches or change openings without permission',
  'indian': 'Indian-inspired crafted timber, considered textile or geometric accents and layered materials within the selected palette; preserve the existing room and requested modern or classic direction',
};

String styleDirection(Iterable<String> ids, {String other = ''}) {
  final styles = canonicalStyleIds(ids)
      .where(designStyles.containsKey)
      .toList();
  final names = [
    for (final id in styles) designStyles[id]!,
    if (other.trim().isNotEmpty) other.trim(),
  ];
  if (names.isEmpty) return '';
  return 'DESIGN STYLE: ${names.join(' + ')}. ${styles.length > 1 ? 'Blend these influences into one coherent design, rather than treating each as a separate output.' : 'Make this style visible in the unprotected finishes and details.'} Protected features and explicit Keep choices take priority.\nSTYLE DETAILS: ${styles.map((id) => styleDesignCues[id]).join('; ')}. Apply these cues only within the requested scope and palette; do not retain an outdated look simply because it appears in the working image.';
}

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
