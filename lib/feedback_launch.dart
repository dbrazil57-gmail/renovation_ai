import 'feedback_launch_stub.dart'
    if (dart.library.js_interop) 'feedback_launch_web.dart'
    if (dart.library.io) 'feedback_launch_native.dart'
    as platform;
import 'feedback_launch_types.dart';

export 'feedback_launch_types.dart';

FeedbackLauncher createFeedbackLauncher() => platform.createFeedbackLauncher();
