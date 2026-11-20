abstract class FeedbackLauncher {
  bool get supported;

  /// Requests a browser/email composer. This never means feedback was submitted.
  Future<bool> open(Uri uri);
}

class UnsupportedFeedbackLauncher implements FeedbackLauncher {
  @override
  bool get supported => false;
  @override
  Future<bool> open(Uri uri) async => false;
}
