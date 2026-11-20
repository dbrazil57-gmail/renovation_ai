enum AiProvider {
  openai('OpenAI', 'api.openai.com'),
  gemini('Gemini', 'generativelanguage.googleapis.com');

  final String label;
  final String host;
  const AiProvider(this.label, this.host);

  List<String> get imageModels =>
      this == openai ? preferredRoomImageModels : geminiRoomImageModels;
  List<String> get recommendations => imageModels.take(2).toList();
  static AiProvider fromId(Object? value) =>
      value == 'gemini' ? gemini : openai;
}

const geminiRoomImageModels = ['gemini-nano-banana-2.1', 'gemini-3-pro-image'];
const geminiAnalysisModels = [
  'gemini-3.5-flash-lite',
  'gemini-3.8-flash',
  'gemini-3.1-pro-preview',
];

/// Preference order, restricted at connection time to models the account lists.
const preferredRoomImageModels = [
  'gpt-image-2.6-sunburst',
  'gpt-image-2.6-flare',
  'gpt-image-2.5-sunburst',
  'gpt-image-2.5-flare',
];

String imageModelLabel(String id) => switch (id) {
  'gemini-nano-banana-2.1' => 'Nano Banana 2.1',
  'gemini-3-pro-image' => 'Nano Banana Pro',
  'gpt-image-2.6-sunburst' => 'GPT Image 2.6 Sunburst',
  'gpt-image-2.6-flare' => 'GPT Image 2.6 Flare',
  'gpt-image-2.5-sunburst' => 'GPT Image 2.5 Sunburst',
  'gpt-image-2.5-flare' => 'GPT Image 2.5 Flare',
  _ => id,
};

String imageModelPurpose(String? id) => switch (id) {
  'gemini-nano-banana-2.1' => 'Recommended Gemini option for photo redesign, multiple views and refinement.',
  'gemini-3-pro-image' =>
    'For complex visual briefs and detailed design exploration.',
  'gpt-image-2.6-sunburst' =>
    'Recommended for room detail, layout adherence and precise edits.',
  'gpt-image-2.6-flare' => 'For quicker concept exploration and iteration.',
  'gpt-image-2.5-sunburst' => 'Earlier detailed-editing model; retained for comparison and account compatibility.',
  'gpt-image-2.5-flare' => 'Earlier fast image model; retained for comparison and account compatibility.',
  _ => 'Model supplied by this connection. Compare its results with the same room and brief.',
};

String recommendedImageModel(
  List<String> available, {
  bool fast = false,
  bool detailed = false,
}) {
  if (available.any(geminiRoomImageModels.contains)) {
    final preferred = detailed
        ? geminiRoomImageModels.reversed
        : geminiRoomImageModels;
    return preferred.where(available.contains).first;
  }
  final preferred = fast
      ? const [
          'gpt-image-2.6-flare',
          'gpt-image-2.5-flare',
          ...preferredRoomImageModels,
        ]
      : const [
          'gpt-image-2.6-sunburst',
          'gpt-image-2.5-sunburst',
          ...preferredRoomImageModels,
        ];
  return preferred.where(available.contains).firstOrNull ?? available.first;
}

String imageQualityLabel(AiProvider provider, String quality) =>
    provider == AiProvider.gemini
    ? switch (quality) {
        'low' => '1K',
        'medium' => '2K',
        'high' => '4K',
        _ => quality,
      }
    : quality;
