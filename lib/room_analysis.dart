/// The vision response is kept separate from the user's editable prompt.
class RoomAnalysisResult {
  final String observations;
  final List<String> questions;
  final String prompt;
  final String model;
  final String? requestId;
  const RoomAnalysisResult({
    required this.observations,
    required this.questions,
    required this.prompt,
    required this.model,
    this.requestId,
  });

  static Map<String, dynamic> validateOutput(dynamic value) {
    if (value is! Map) throw const FormatException('Invalid analysis.');
    for (final (key, limit) in [('observations', 4000), ('prompt', 8000)]) {
      final text = value[key];
      if (text is! String || text.trim().isEmpty || text.length > limit) {
        throw const FormatException('Incomplete analysis.');
      }
    }
    final questions = value['questions'];
    if (questions is! List ||
        questions.length > 10 ||
        questions.any(
          (q) => q is! String || q.trim().isEmpty || q.length > 1000,
        )) {
      throw const FormatException('Invalid analysis questions.');
    }
    return Map<String, dynamic>.from(value);
  }

  factory RoomAnalysisResult.fromMap(Map<dynamic, dynamic> value) {
    validateOutput(value);
    if (value['model'] is! String ||
        (value['model'] as String).isEmpty ||
        (value['requestId'] != null && value['requestId'] is! String)) {
      throw const FormatException('Invalid analysis metadata.');
    }
    return RoomAnalysisResult(
      observations: value['observations'] as String,
      questions: List<String>.from(value['questions'] as List),
      prompt: value['prompt'] as String,
      model: value['model'] as String,
      requestId: value['requestId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'observations': observations,
    'questions': questions,
    'prompt': prompt,
    'model': model,
    'requestId': requestId,
  };
}

class RoomAnalysis {
  final RoomAnalysisResult result;
  final String sourceImageId;
  final List<String> supportingImageIds;
  final String context;
  final DateTime created;
  const RoomAnalysis({
    required this.result,
    required this.sourceImageId,
    required this.supportingImageIds,
    required this.context,
    required this.created,
  });

  bool matches(String source, Iterable<String> support, String inputContext) =>
      source == sourceImageId &&
      context == inputContext &&
      support.length == supportingImageIds.length &&
      support.toList().asMap().entries.every(
        (e) => supportingImageIds[e.key] == e.value,
      );

  Map<String, dynamic> toMap() => {
    'result': result.toMap(),
    'sourceImageId': sourceImageId,
    'supportingImageIds': supportingImageIds,
    'context': context,
    'created': created.toIso8601String(),
  };

  factory RoomAnalysis.fromMap(Map<dynamic, dynamic> value) {
    final source = value['sourceImageId'];
    final support = value['supportingImageIds'];
    if (source is! String ||
        source.isEmpty ||
        support is! List ||
        support.length > 6 ||
        support.any((s) => s is! String || s.isEmpty) ||
        support.toSet().length != support.length ||
        support.contains(source) ||
        value['context'] is! String ||
        (value['context'] as String).length > 16000 ||
        value['result'] is! Map) {
      throw const FormatException('Invalid analysis sources.');
    }
    return RoomAnalysis(
      result: RoomAnalysisResult.fromMap(value['result'] as Map),
      sourceImageId: source,
      supportingImageIds: List<String>.from(support),
      context: value['context'] as String,
      created: DateTime.parse(value['created'] as String),
    );
  }
}

const roomAnalysisSchema = {
  'type': 'object',
  'properties': {
    'observations': {'type': 'string'},
    'questions': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'prompt': {'type': 'string'},
  },
  'required': ['observations', 'questions', 'prompt'],
  'additionalProperties': false,
};
