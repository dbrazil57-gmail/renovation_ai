import 'dart:math';

import 'ai_types.dart';

/// Server-authoritative request allowances, not money or purchased entitlements.
class TesterAllowance {
  final int analyses, designs;
  final DateTime expires;
  const TesterAllowance(this.analyses, this.designs, this.expires);
  factory TesterAllowance.fromMap(dynamic value) {
    if (value is! Map) throw const AiFailure('Invalid test allowance.');
    final a = value['analyses'], d = value['designs'];
    final expiry = DateTime.tryParse(value['expires']?.toString() ?? '');
    if (a is! int ||
        d is! int ||
        a < 0 ||
        d < 0 ||
        a > 100000 ||
        d > 100000 ||
        expiry == null) {
      throw const AiFailure('Invalid test allowance.');
    }
    return TesterAllowance(a, d, expiry);
  }
  Map<String, dynamic> toMap() => {
    'analyses': analyses,
    'designs': designs,
    'expires': expires.toUtc().toIso8601String(),
  };
  String get summary => '$analyses analyses · $designs designs left';
}

Uri testerServiceUri(String text) {
  final uri = Uri.tryParse(text.trim());
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      uri.hasQuery ||
      (uri.path.isNotEmpty && uri.path != '/') ||
      uri.host == 'localhost' ||
      uri.host == '::1' ||
      RegExp(
        r'^(127\.|10\.|192\.168\.|169\.254\.|172\.(1[6-9]|2[0-9]|3[01])\.)',
      ).hasMatch(uri.host)) {
    throw const AiFailure(
      'Enter the public HTTPS test-service address supplied with your invitation.',
    );
  }
  return uri.replace(path: '');
}

String testerRequestId() {
  final random = Random.secure();
  return List.generate(
    24,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
