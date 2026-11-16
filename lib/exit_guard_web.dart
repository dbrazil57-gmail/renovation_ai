import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'exit_guard.dart';

class _WebPageExitGuard implements PageExitGuard {
  final void Function() onExit;
  bool pending = false;
  late final JSFunction listener;
  _WebPageExitGuard(this.onExit) {
    listener = ((web.Event event) {
      if (!pending) return;
      // The browser cannot await this write. Keep its standard leave warning
      // active so the user can stay while Save now completes.
      onExit();
      event.preventDefault();
      (event as web.BeforeUnloadEvent).returnValue = 'Unsaved changes';
    }).toJS;
  }
  @override
  void setPending(bool value) {
    if (value == pending) return;
    pending = value;
    if (pending) {
      web.window.addEventListener('beforeunload', listener);
    } else {
      web.window.removeEventListener('beforeunload', listener);
    }
  }

  @override
  void dispose() => web.window.removeEventListener('beforeunload', listener);
}

PageExitGuard createPageExitGuard(void Function() onExit) =>
    _WebPageExitGuard(onExit);
