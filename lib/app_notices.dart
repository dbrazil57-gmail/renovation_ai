import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Notices occupy the banner slot and push content; they never cover Generate
/// or navigation at the bottom. Replace stale messages instead of queueing them.
ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
showAppNotice(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  messenger.removeCurrentMaterialBanner();
  late ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
  handle;
  handle = messenger.showMaterialBanner(
    MaterialBanner(
      content: _TimedNotice(message: message, expire: () => handle.close()),
      actions: [
        TextButton(
          onPressed: () => handle.close(),
          child: const Text('Dismiss'),
        ),
      ],
    ),
  );
  return handle;
}

class _TimedNotice extends StatefulWidget {
  final String message;
  final VoidCallback expire;
  const _TimedNotice({required this.message, required this.expire});
  @override
  State<_TimedNotice> createState() => _TimedNoticeState();
}

class _TimedNoticeState extends State<_TimedNotice> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(seconds: 6), widget.expire);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text(widget.message, maxLines: 3, overflow: TextOverflow.ellipsis);
}
