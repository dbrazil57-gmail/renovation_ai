import 'exit_guard.dart';

class _NoPageExitGuard implements PageExitGuard {
  @override
  void setPending(bool pending) {}
  @override
  void dispose() {}
}

PageExitGuard createPageExitGuard(void Function() onExit) => _NoPageExitGuard();
