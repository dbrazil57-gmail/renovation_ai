import 'exit_guard_stub.dart'
    if (dart.library.js_interop) 'exit_guard_web.dart'
    as platform;

abstract class PageExitGuard {
  void setPending(bool pending);
  void dispose();
}

PageExitGuard createPageExitGuard(void Function() onExit) =>
    platform.createPageExitGuard(onExit);
