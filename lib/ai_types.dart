import 'dart:typed_data';

import 'ai_usage.dart';

enum AiProblem {
  credentials,
  permission,
  billing,
  quota,
  model,
  options,
  blocked,
  timeout,
  network,
  invalidResponse,
  unknown,
}

class AiFailure implements Exception {
  final String message;
  final AiProblem problem;
  final int? statusCode;
  const AiFailure(
    this.message, {
    this.problem = AiProblem.unknown,
    this.statusCode,
  });
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
