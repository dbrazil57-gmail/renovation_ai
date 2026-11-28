/// Optional user-supplied visual context, not GPS data or a planting schedule.
const australianClimates = <String, String>{
  'general': 'Australia – climate not specified',
  'tropical': 'Tropical / hot and humid',
  'subtropical': 'Subtropical / warm and humid',
  'temperate': 'Temperate',
  'cool': 'Cool / frost-prone',
  'dry': 'Hot and dry / inland',
  'mediterranean': 'Dry summer / Mediterranean climate',
};

const _climateDirections = <String, String>{
  'general': 'The local climate is unknown. Do not assume all Australian plants suit this site; use restrained region-neutral planting forms and leave local species selection unresolved.',
  'tropical': 'Respond visually to heat, humidity and seasonal rain with shaded outdoor living and region-appropriate tropical planting where changes are authorised.',
  'subtropical': 'Use a warm-climate indoor/outdoor character, shade and layered region-appropriate planting where changes are authorised.',
  'temperate': 'Balance summer shade and seasonal light with layered planting appropriate to a temperate Australian setting.',
  'cool': 'Use a sheltered, tactile design character and planting suited to cool conditions and possible frost; avoid default tropical planting.',
  'dry': 'Use a dry-climate material character, restrained water-wise planting forms and shade where permitted; avoid default lush tropical planting.',
  'mediterranean': 'Respond to dry summers and cooler wetter winters with a restrained water-wise planting character and shade where permitted.',
};

class AustralianDesignSettings {
  final String climateId;
  final bool preferNativePlants;
  final String siteNotes;
  const AustralianDesignSettings({
    this.climateId = '',
    this.preferNativePlants = true,
    this.siteNotes = '',
  });

  bool get enabled => australianClimates.containsKey(climateId);
  String get label => australianClimates[climateId] ?? 'Not selected';
  AustralianDesignSettings copyWith({
    String? climateId,
    bool? preferNativePlants,
    String? siteNotes,
  }) => AustralianDesignSettings(
    climateId: climateId ?? this.climateId,
    preferNativePlants: preferNativePlants ?? this.preferNativePlants,
    siteNotes: siteNotes ?? this.siteNotes,
  );

  Map<String, dynamic> toMap() => {
    'climateId': climateId,
    'preferNativePlants': preferNativePlants,
    'siteNotes': siteNotes,
  };

  factory AustralianDesignSettings.fromMap(Map? value) {
    if (value == null) return const AustralianDesignSettings();
    final climate = value['climateId'];
    final native = value['preferNativePlants'];
    final notes = value['siteNotes'];
    if ((climate != null && climate is! String) ||
        (native != null && native is! bool) ||
        (notes != null && (notes is! String || notes.length > 600))) {
      throw const FormatException('Invalid Australian design settings');
    }
    return AustralianDesignSettings(
      climateId: australianClimates.containsKey(climate)
          ? climate as String
          : '',
      preferNativePlants: native != false,
      siteNotes: notes as String? ?? '',
    );
  }

  String get prompt {
    if (!enabled) return '';
    return 'AUSTRALIAN SETTING: $label. ${_climateDirections[climateId]} '
        'Use the selected style and palette with a practical Australian material character; do not assume a coastal or tropical theme. '
        '${preferNativePlants ? 'PLANTING: Where new or replacement planting is within scope, favour Australian native plants appropriate to the stated locality, climate, sun, soil and available space. Prefer locally indigenous species when known. Australian native does not automatically mean locally suitable, drought-tolerant or suitable indoors. Avoid generic overseas or tropical planting when inconsistent with the setting.' : 'PLANTING: No native-only preference is selected. Keep any requested planting appropriate to the stated locality and conditions.'} '
        '${siteNotes.trim().isEmpty ? '' : 'User-supplied area / site conditions (not verified): ${siteNotes.trim()}. '}'
        'Keep protected trees, existing views and all unselected areas; obey the selected layout restrictions. Indoor styling is not permission to replace vegetation seen through a window. '
        'For balconies and courtyards, depict appropriately sized planting and containers; do not invent large trees or structural changes. '
        'Apply this context only to authorised changes. Do not claim verified species identification, exact mature size, irrigation needs, ecological suitability or building performance from an image.';
  }
}
