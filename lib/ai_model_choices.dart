/// Preference order, restricted at connection time to models the account lists.
const preferredRoomImageModels = [
  'gpt-image-2.6-sunburst',
  'gpt-image-2.6-flare',
  'gpt-image-2.5-sunburst',
  'gpt-image-2.5-flare',
];

String imageModelLabel(String id) => switch (id) {
  'gpt-image-2.6-sunburst' => 'GPT Image 2.6 Sunburst',
  'gpt-image-2.6-flare' => 'GPT Image 2.6 Flare',
  'gpt-image-2.5-sunburst' => 'GPT Image 2.5 Sunburst',
  'gpt-image-2.5-flare' => 'GPT Image 2.5 Flare',
  _ => id,
};

String imageModelPurpose(String? id) => switch (id) {
  'gpt-image-2.6-sunburst' =>
    'Recommended for room detail, layout adherence and precise edits.',
  'gpt-image-2.6-flare' => 'For quicker concept exploration and iteration.',
  'gpt-image-2.5-sunburst' => 'Earlier detailed-editing model; retained for comparison and account compatibility.',
  'gpt-image-2.5-flare' => 'Earlier fast image model; retained for comparison and account compatibility.',
  _ => 'Model supplied by this connection. Compare its results with the same room and brief.',
};

String recommendedImageModel(List<String> available, {bool fast = false}) {
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
