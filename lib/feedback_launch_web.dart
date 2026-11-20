import 'package:web/web.dart' as web;

import 'feedback_launch_types.dart';

FeedbackLauncher createFeedbackLauncher() => _WebFeedbackLauncher();

class _WebFeedbackLauncher implements FeedbackLauncher {
  @override
  bool get supported => true;
  @override
  Future<bool> open(Uri uri) async {
    if (uri.scheme != 'https' && uri.scheme != 'mailto') return false;
    final link = web.HTMLAnchorElement()
      ..href = uri.toString()
      ..target = '_blank'
      ..rel = 'noopener noreferrer';
    web.document.body?.appendChild(link);
    try {
      link.click();
    } finally {
      link.remove();
    }
    // Browsers cannot confirm that an email app opened or that a form was sent.
    return true;
  }
}
