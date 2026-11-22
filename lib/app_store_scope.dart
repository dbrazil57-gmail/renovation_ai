import 'package:material_ui/material_ui.dart';

import 'store.dart';

class AppStoreScope extends InheritedWidget {
  final RenovisionStore store;
  final void Function(BuildContext, String, String?) openRoom;
  const AppStoreScope({
    super.key,
    required this.store,
    required this.openRoom,
    required super.child,
  });
  static AppStoreScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStoreScope>();
  @override
  bool updateShouldNotify(AppStoreScope oldWidget) => oldWidget.store != store;
}
