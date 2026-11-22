/// Only numeric usage is retained, never an arbitrary provider response/key.
class AiUsage {
  final int inputTokens, textTokens, imageTokens, outputTokens;
  final double? estimatedUsd;
  final String ratesDate;
  const AiUsage({
    required this.inputTokens,
    required this.textTokens,
    required this.imageTokens,
    required this.outputTokens,
    this.estimatedUsd,
    this.ratesDate = '2026-11-23',
  });
  factory AiUsage.openAi(Map raw, String model) {
    int n(Object? value) =>
        value is num && value.isFinite && value >= 0 ? value.toInt() : 0;
    final details = raw['input_tokens_details'];
    final text = details is Map ? n(details['text_tokens']) : 0;
    final image = details is Map ? n(details['image_tokens']) : 0;
    final input = n(raw['input_tokens']), output = n(raw['output_tokens']);
    // Standard USD rates verified against the provider pricing table. No
    // estimates for unknown models or incomplete modality splits.
    final known = [
      'gpt-image-2.6-sunburst',
      'gpt-image-2.6-flare',
    ].contains(model);
    bool valid(Object? v) => v is int && v >= 0 && v <= 1000000000;
    final complete =
        valid(raw['input_tokens']) &&
        valid(raw['output_tokens']) &&
        details is Map &&
        valid(details['text_tokens']) &&
        valid(details['image_tokens']) &&
        text + image == input &&
        (details['cached_tokens'] == null || details['cached_tokens'] == 0);
    return AiUsage(
      inputTokens: input,
      textTokens: text,
      imageTokens: image,
      outputTokens: output,
      estimatedUsd: known && complete
          ? (text * 5 + image * 8 + output * 30) / 1000000
          : null,
    );
  }
  factory AiUsage.gemini(Map raw) {
    int n(Object? v) => v is num && v.isFinite && v >= 0 ? v.toInt() : 0;
    return AiUsage(
      inputTokens: n(raw['total_input_tokens']),
      textTokens: 0,
      imageTokens: 0,
      outputTokens: n(raw['total_output_tokens']),
    );
  }
  factory AiUsage.fromMap(Map map) {
    for (final key in [
      'inputTokens',
      'textTokens',
      'imageTokens',
      'outputTokens',
    ]) {
      if (map[key] is! int ||
          (map[key] as int) < 0 ||
          (map[key] as int) > 1000000000) {
        throw const FormatException('Invalid usage');
      }
    }
    final cost = map['estimatedUsd'];
    if (cost != null && (cost is! num || !cost.isFinite || cost < 0)) {
      throw const FormatException('Invalid cost');
    }
    return AiUsage(
      inputTokens: map['inputTokens'],
      textTokens: map['textTokens'],
      imageTokens: map['imageTokens'],
      outputTokens: map['outputTokens'],
      estimatedUsd: cost == null ? null : (cost as num).toDouble(),
      ratesDate: (map['ratesDate'] ?? '').toString(),
    );
  }
  Map<String, dynamic> toMap() => {
    'inputTokens': inputTokens,
    'textTokens': textTokens,
    'imageTokens': imageTokens,
    'outputTokens': outputTokens,
    'estimatedUsd': estimatedUsd,
    'ratesDate': ratesDate,
  };
  String get label => estimatedUsd == null
      ? 'Cost unavailable · $inputTokens input / $outputTokens output tokens'
      : 'Estimated US\$${estimatedUsd!.toStringAsFixed(4)}';
}
