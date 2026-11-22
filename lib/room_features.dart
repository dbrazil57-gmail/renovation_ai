const regionalRenovationTerms =
    'REGIONAL TERMINOLOGY: Interpret the user\'s words using the room context and photographs. Benchtop/worktop/countertop, taps/faucets, rangehood/extractor hood and light fitting/light fixture are regional equivalents. In a bathroom, basin/washbasin/bathroom sink means the bowl; vanity means the supporting cabinet/counter unit and may include the basin. A kitchen sink is not a bathroom vanity. Do not expand a basin-only request to the whole vanity or silently replace the user\'s instructions through word substitution. These definitions clarify meaning, not permission to change additional items.';

const roomTypes = <String, String>{
  'kitchen': 'Kitchen',
  'bathroom': 'Bathroom',
  'bedroom': 'Bedroom',
  'living': 'Living / dining room',
  'office': 'Office',
  'laundry': 'Laundry',
  'exterior': 'Exterior',
  'other': 'Other room',
  'main_bedroom': 'Main bedroom',
  'guest_bedroom': 'Guest bedroom',
  'kids_bedroom': "Children's bedroom",
  'nursery': 'Nursery',
  'ensuite': 'Ensuite',
  'powder_room': 'Powder room',
  'toilet': 'Separate toilet',
  'dining': 'Dining room',
  'family': 'Family / lounge room',
  'media': 'Media / home theatre',
  'games': 'Games / rumpus room',
  'study': 'Study / library',
  'gym': 'Home gym',
  'sunroom': 'Sunroom / conservatory',
  'pantry': 'Pantry',
  'butlers_pantry': "Butler's pantry",
  'utility': 'Utility / mudroom',
  'wardrobe': 'Walk-in wardrobe / dressing room',
  'entry': 'Entry / foyer',
  'hallway': 'Hallway / passage',
  'stairs': 'Staircase / landing',
  'storage': 'Storage room',
  'attic': 'Attic / loft',
  'basement': 'Basement / cellar',
  'garage': 'Garage / carport',
  'workshop': 'Workshop',
  'front_garden': 'Front garden',
  'back_garden': 'Back garden',
  'courtyard': 'Courtyard',
  'patio': 'Patio / alfresco',
  'deck': 'Deck',
  'balcony': 'Balcony',
  'verandah': 'Verandah / porch',
  'pool': 'Pool / outdoor entertaining',
};

const roomCategories = <String, List<String>>{
  'Kitchen & utility': [
    'kitchen',
    'pantry',
    'butlers_pantry',
    'laundry',
    'utility',
  ],
  'Living & work': [
    'living',
    'dining',
    'family',
    'media',
    'games',
    'office',
    'study',
    'gym',
    'sunroom',
  ],
  'Bedrooms & bathrooms': [
    'bedroom',
    'main_bedroom',
    'guest_bedroom',
    'kids_bedroom',
    'nursery',
    'bathroom',
    'ensuite',
    'powder_room',
    'toilet',
    'wardrobe',
  ],
  'Entry & storage': [
    'entry',
    'hallway',
    'stairs',
    'storage',
    'attic',
    'basement',
  ],
  'Garage & workshop': ['garage', 'workshop'],
  'Outdoor spaces': [
    'exterior',
    'front_garden',
    'back_garden',
    'courtyard',
    'patio',
    'deck',
    'balcony',
    'verandah',
    'pool',
  ],
  'Other': ['other'],
};

String roomFeatureProfile(String type) => switch (type) {
  'main_bedroom' || 'guest_bedroom' || 'kids_bedroom' => 'bedroom',
  'ensuite' || 'powder_room' || 'toilet' => 'bathroom',
  'dining' || 'family' || 'media' || 'games' || 'sunroom' => 'living',
  'study' => 'office',
  'butlers_pantry' => 'pantry',
  'utility' => 'laundry',
  'wardrobe' => 'storage',
  'workshop' => 'garage',
  'front_garden' ||
  'back_garden' ||
  'courtyard' ||
  'patio' ||
  'deck' ||
  'balcony' ||
  'verandah' ||
  'pool' => 'outdoor',
  'entry' || 'hallway' || 'stairs' || 'attic' || 'basement' || 'gym' => 'other',
  _ => type,
};

Map<String, RoomFeature> roomFeaturesFor(String type) {
  final features =
      roomFeatures[roomFeatureProfile(type)] ?? const <String, RoomFeature>{};
  return Map.fromEntries(
    features.entries.where((entry) {
      if (const ['powder_room', 'toilet'].contains(type) &&
          const ['bathroom_bath', 'bathroom_shower'].contains(entry.key)) {
        return false;
      }
      if (type == 'dining' && entry.key == 'living_seating') return false;
      if (const ['family', 'media', 'games', 'sunroom'].contains(type) &&
          entry.key == 'living_dining') {
        return false;
      }
      return true;
    }),
  );
}

String resolveRoomType(String selected, String name) {
  if (roomTypes.containsKey(selected)) return selected;
  final lower = name.toLowerCase();
  for (final (pattern, type) in [
    (r'kitchen', 'kitchen'),
    (r'bath|ensuite|toilet|powder', 'bathroom'),
    (r'bedroom|bed room', 'bedroom'),
    (r'laundry|utility', 'laundry'),
    (r'office|study', 'office'),
    (r'living|dining|lounge|family|games', 'living'),
    (r'exterior|outside|garden|patio|deck|facade', 'exterior'),
  ]) {
    if (RegExp(pattern).hasMatch(lower)) return type;
  }
  return 'other';
}

typedef RoomFeature = ({String label, String replacement});
const roomFeatures = <String, Map<String, RoomFeature>>{
  'kitchen': {
    'kitchen_appliances': (label: 'All kitchen appliances', replacement: ''),
    'kitchen_oven': (
      label: 'Oven',
      replacement: 'Replace the existing oven with a visibly new modern built-in oven in the same position.',
    ),
    'kitchen_microwave': (
      label: 'Microwave',
      replacement: 'Replace the existing microwave with a visibly new modern equivalent in the same position.',
    ),
    'kitchen_cooktop': (
      label: 'Cooktop',
      replacement: 'Replace the existing cooktop with a visibly new modern cooktop in the same position.',
    ),
    'kitchen_extractor': (
      label: 'Extractor / rangehood',
      replacement: 'Replace the extractor/rangehood itself with a visibly new modern unit. Keep its position and change surrounding cupboards only if requested.',
    ),
    'kitchen_fridge': (
      label: 'Fridge',
      replacement: 'Replace the existing fridge with a visibly new modern fridge in the same position.',
    ),
    'kitchen_dishwasher': (
      label: 'Dishwasher',
      replacement: 'Replace the existing dishwasher with a visibly new modern dishwasher in the same position.',
    ),
  },
  'bathroom': {
    'bathroom_vanity': (
      label: 'Vanity / basin',
      replacement: 'Replace the vanity and basin with modern equivalents in their current positions.',
    ),
    'bathroom_shower': (
      label: 'Shower / screen',
      replacement: 'Replace the shower fittings and screen within the current shower footprint.',
    ),
    'bathroom_bath': (
      label: 'Bath',
      replacement:
          'Replace the bath with a modern equivalent in its current position.',
    ),
    'bathroom_toilet': (
      label: 'Toilet',
      replacement:
          'Replace the toilet with a modern equivalent in the same position.',
    ),
    'bathroom_taps': (
      label: 'Taps / fittings',
      replacement: 'Replace visible taps and fittings with coordinated modern equivalents.',
    ),
    'bathroom_tiles': (
      label: 'Wall tiles',
      replacement:
          'Replace visible wall tiles without changing walls or openings.',
    ),
  },
  'bedroom': {
    'bedroom_bed': (
      label: 'Bed',
      replacement: 'Replace the bed with a new design suited to the style and agreed circulation.',
    ),
    'bedroom_wardrobe': (
      label: 'Wardrobes',
      replacement: 'Update wardrobe fronts and fittings while retaining storage and footprint.',
    ),
    'bedroom_bedside': (
      label: 'Bedside furniture',
      replacement:
          'Replace visible bedside furniture with coordinated new pieces.',
    ),
    'bedroom_window': (
      label: 'Curtains / blinds',
      replacement:
          'Replace curtains or blinds without changing window sizes or frames.',
    ),
  },
  'living': {
    'living_seating': (
      label: 'Sofa / seating',
      replacement: 'Replace visible seating with new pieces suited to the requested style and circulation.',
    ),
    'living_dining': (
      label: 'Dining table / chairs',
      replacement: 'Replace the visible dining table and chairs with coordinated new pieces.',
    ),
    'living_storage': (
      label: 'Storage / TV unit',
      replacement: 'Update storage and TV furniture while retaining storage and the agreed layout.',
    ),
    'living_window': (
      label: 'Curtains / blinds',
      replacement:
          'Replace curtains or blinds without changing windows or openings.',
    ),
  },
  'office': {
    'office_desk': (
      label: 'Desk',
      replacement:
          'Replace the desk with a new design suited to the agreed layout.',
    ),
    'office_chair': (
      label: 'Office chair',
      replacement: 'Replace the office chair with a new practical chair suited to the style.',
    ),
    'office_storage': (
      label: 'Shelving / storage',
      replacement: 'Update shelving and storage while retaining useful capacity and footprint.',
    ),
    'office_window': (
      label: 'Curtains / blinds',
      replacement: 'Replace curtains or blinds without changing the windows.',
    ),
  },
  'laundry': {
    'laundry_appliances': (label: 'All laundry appliances', replacement: ''),
    'laundry_washer': (
      label: 'Washing machine',
      replacement: 'Replace the washing machine with a visibly new modern equivalent in the same position.',
    ),
    'laundry_dryer': (
      label: 'Dryer',
      replacement: 'Replace the dryer with a visibly new modern equivalent in the same position.',
    ),
    'laundry_tub': (
      label: 'Laundry tub / sink',
      replacement: 'Replace the laundry tub and tap with new fittings in the current position.',
    ),
  },
  'exterior': {
    'exterior_roof': (
      label: 'Roof finish',
      replacement: 'Update the roof finish while retaining its shape, height and structure.',
    ),
    'exterior_cladding': (
      label: 'Wall cladding / finish',
      replacement: 'Update exterior wall finishes without changing the building footprint or openings.',
    ),
    'exterior_door': (
      label: 'Front door finish',
      replacement: 'Update the front door finish while keeping its opening, size and position.',
    ),
    'exterior_paving': (
      label: 'Paving / deck finish',
      replacement: 'Update paving or deck finishes within their footprint, without inventing level or structural changes.',
    ),
    'exterior_fence': (
      label: 'Fence / gate finish',
      replacement: 'Update fence or gate finishes while retaining their height and position.',
    ),
  },
  'nursery': {
    'nursery_cot': (
      label: 'Cot / sleep furniture',
      replacement: 'Update only visible nursery sleep furniture; retain its position and do not invent safety certifications.',
    ),
    'nursery_storage': (
      label: 'Nursery storage',
      replacement:
          'Update visible nursery storage within the agreed footprint.',
    ),
    'nursery_chair': (
      label: 'Nursery chair',
      replacement:
          'Update the existing nursery chair without blocking circulation.',
    ),
  },
  'pantry': {
    'pantry_storage': (
      label: 'Pantry shelving / cupboards',
      replacement: 'Update existing pantry shelves and cupboard fronts while retaining practical storage and footprint.',
    ),
    'pantry_bench': (
      label: 'Pantry work surface',
      replacement: 'Update an existing pantry work surface in place; do not add one if none is visible.',
    ),
  },
  'storage': {
    'storage_joinery': (
      label: 'Shelves / storage joinery',
      replacement: 'Update visible shelves or storage joinery within the existing footprint, retaining usable capacity.',
    ),
    'storage_fronts': (
      label: 'Storage doors / fronts',
      replacement: 'Update existing storage doors or drawer fronts without changing room openings.',
    ),
  },
  'garage': {
    'garage_storage': (
      label: 'Garage / workshop storage',
      replacement: 'Update visible garage or workshop storage without obstructing access or vehicle space.',
    ),
    'garage_bench': (
      label: 'Workbench',
      replacement:
          'Update an existing workbench in place; do not invent one if absent.',
    ),
    'garage_door': (
      label: 'Garage door finish',
      replacement: 'Update the visible garage door finish while preserving its opening, size and position.',
    ),
  },
  'outdoor': {
    'outdoor_seating': (
      label: 'Outdoor seating',
      replacement:
          'Update visible outdoor seating within the existing usable area.',
    ),
    'outdoor_planting': (
      label: 'Planting / planters',
      replacement: 'Update visible planting or planters within existing garden boundaries; retain protected plants.',
    ),
    'outdoor_paving': (
      label: 'Paving / decking finish',
      replacement: 'Update paving or deck finishes in place, preserving levels, edges, pool boundaries and circulation.',
    ),
    'outdoor_fence': (
      label: 'Fence / balustrade finish',
      replacement: 'Update surface finishes only; preserve existing fence and balustrade height, position and openings.',
    ),
  },
  'other': {},
};

bool isApplianceGroup(String id) => id.endsWith('_appliances');
bool isIndividualAppliance(String id) =>
    !isApplianceGroup(id) &&
    (id.startsWith('kitchen_') ||
        id == 'laundry_washer' ||
        id == 'laundry_dryer');

String itemChoice(
  String id,
  Map<String, String> choices,
  List<String> scopeIds,
) =>
    choices[id] ??
    (isApplianceGroup(id) && scopeIds.contains('appliances') ? 'replace' : '');

String effectiveItemChoice(
  String id,
  Map<String, String> choices,
  List<String> scopeIds,
) =>
    choices[id] ??
    (isIndividualAppliance(id)
        ? itemChoice('${id.split('_').first}_appliances', choices, scopeIds)
        : '');

bool scopeAppliesToRoom(String id, String type) {
  if (id == 'tidy_stage') return true;
  final profile = roomFeatureProfile(type);
  if (!const {
    'flooring',
    'cabinetry',
    'benchtops',
    'splashback',
    'lighting',
    'walls',
    'dated_fixtures',
  }.contains(id)) {
    return false;
  }
  if (profile == 'exterior' || profile == 'outdoor') return id == 'lighting';
  if (id == 'benchtops' || id == 'splashback') {
    return const ['kitchen', 'laundry', 'pantry'].contains(profile) ||
        type == 'other';
  }
  return true;
}

String buildRoomItemsPrompt(
  String type,
  Map<String, String> choices,
  List<String> scopeIds,
) {
  final features = roomFeaturesFor(type);
  final lines = <String>[];
  for (final entry in features.entries.where((e) => !isApplianceGroup(e.key))) {
    final choice = effectiveItemChoice(entry.key, choices, scopeIds);
    if (choice == 'keep') {
      lines.add(
        '- KEEP EXISTING ${entry.value.label}: retain the existing item(s), appearance and position. Do not modernise or recolour these items to match a style or palette.',
      );
    } else if (choice == 'replace') {
      lines.add('- REPLACE ${entry.value.label}: ${entry.value.replacement}');
    }
  }
  if (lines.isEmpty) return '';
  final applianceGuidance = features.keys.any(isApplianceGroup)
      ? 'For replacement appliances, show visibly new models, not the dated fronts with a different colour or merely new surrounding cabinets. Individual choices override All appliances; the instructions above already include those overrides.'
      : '';
  return '''ROOM ITEM CHOICES (${roomTypes[type]}):
${lines.join('\n')}
$applianceGuidance
Explicit KEEP choices override broad scope/style requests. Protected features take priority; if other text conflicts with a Keep choice, retain the item and ask for clarification. Apply choices only to items visible in the attached views; do not invent unseen items. Keep the viewpoint and agreed layout.''';
}

bool hasRoomChanges(
  String type,
  Map<String, String> choices,
  List<String> scopeIds,
  String removeItems,
) =>
    removeItems.trim().isNotEmpty ||
    scopeIds.any((id) => scopeAppliesToRoom(id, type)) ||
    (roomFeaturesFor(type).keys
        .where((id) => !isApplianceGroup(id))
        .any((id) => effectiveItemChoice(id, choices, scopeIds) == 'replace'));
