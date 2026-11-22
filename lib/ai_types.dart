import 'dart:typed_data';

import 'ai_usage.dart';

class AiFailure implements Exception {
  final String message;
  const AiFailure(this.message);
  @override
  String toString() => message;
}

class AiResult {
  final Uint8List image;
  final String provider, model;
  final String? requestId, quality;
  final AiUsage? usage;
  const AiResult({
    required this.image,
    required this.provider,
    required this.model,
    this.requestId,
    this.quality,
    this.usage,
  });
}
