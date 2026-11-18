import 'dart:typed_data';

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
  const AiResult({
    required this.image,
    required this.provider,
    required this.model,
    this.requestId,
    this.quality,
  });
}
