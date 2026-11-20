import 'dart:io';

import 'package:flutter/services.dart';

import 'feedback_launch_types.dart';

FeedbackLauncher createFeedbackLauncher() => Platform.isAndroid
    ? AndroidFeedbackLauncher()
    : UnsupportedFeedbackLauncher();

class AndroidFeedbackLauncher implements FeedbackLauncher {
  static const channel = MethodChannel('renovision/feedback');
  @override
  bool get supported => true;
  @override
  Future<bool> open(Uri uri) async {
    if (uri.scheme != 'https' && uri.scheme != 'mailto') return false;
    return await channel.invokeMethod<bool>('open', {'url': uri.toString()}) ==
        true;
  }
}
