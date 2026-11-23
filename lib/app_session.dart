import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:hive_ce/hive_ce.dart';

/// Device navigation only. Project exports do not contain this session record.
/// Dialogs and pending paid requests are deliberately not replayed at startup.
class AppPageSession extends NavigatorObserver {
  static const recordKey = 'settings:current_pages_v1';
  final Box<dynamic> records;
  final List<Map<String, dynamic>> initialPages;
  final _routes = <Route<dynamic>>[];
  final _pages = <Route<dynamic>, Map<String, dynamic>>{};
  final _onReturn = <Route<dynamic>, void Function(Map<String, dynamic>)>{};
  Future<void> _writes = Future.value();
  String? _last;

  AppPageSession(this.records) : initialPages = _read(records.get(recordKey));

  static List<Map<String, dynamic>> _read(dynamic raw) {
    if (raw is! List || raw.length > 8) return [];
    try {
      return [for (final entry in raw) Map<String, dynamic>.from(entry as Map)];
    } catch (_) {
      return [];
    }
  }

  void register(
    Route<dynamic> route,
    Map<String, dynamic> page, {
    void Function(Map<String, dynamic>)? onReturn,
  }) {
    _pages[route] = Map.unmodifiable(page);
    if (onReturn == null) {
      _onReturn.remove(route);
    } else {
      _onReturn[route] = onReturn;
    }
    _remember();
  }

  void forget(Route<dynamic> route) {
    _pages.remove(route);
    _onReturn.remove(route);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _remember();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final leaving = _pages[route];
    _routes.remove(route);
    forget(route);
    _remember();
    if (leaving != null && previousRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_routes.contains(previousRoute)) {
          _onReturn[previousRoute]?.call(leaving);
        }
      });
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    forget(route);
    _remember();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (oldRoute != null) forget(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    } else if (newRoute != null) {
      _routes.add(newRoute);
    }
    _remember();
  }

  void _remember() {
    final pages = [
      for (final route in _routes)
        if (_pages[route] != null) _pages[route]!,
    ];
    if (pages.isEmpty) return;
    final encoded = jsonEncode(pages);
    if (encoded == _last) return;
    _last = encoded;
    _writes = _writes
        .catchError((_) {})
        .then((_) => records.put(recordKey, pages));
    // Navigation failure must never clear projects or block editing.
    unawaited(
      _writes.catchError((_) {
        _last = null;
      }),
    );
  }

  Future<void> flush() => _writes;

  Route<dynamic>? projectRoute(String projectId) => _routes.reversed
      .where(
        (route) =>
            _pages[route]?['page'] == 'project' &&
            _pages[route]?['projectId'] == projectId,
      )
      .firstOrNull;
}

class AppPageSessionScope extends InheritedWidget {
  final AppPageSession session;
  const AppPageSessionScope({
    super.key,
    required this.session,
    required super.child,
  });
  static AppPageSession? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AppPageSessionScope>()
      ?.session;
  @override
  bool updateShouldNotify(AppPageSessionScope oldWidget) =>
      oldWidget.session != session;
}

/// Associates a mounted page with its durable IDs and current workspace tab.
/// Widgets used outside the app shell (tests/demos) continue to work unchanged.
class SavedAppPage extends StatefulWidget {
  final Map<String, dynamic> page;
  final Widget child;
  final void Function(Map<String, dynamic>)? onReturn;
  const SavedAppPage({
    super.key,
    required this.page,
    required this.child,
    this.onReturn,
  });
  @override
  State<SavedAppPage> createState() => _SavedAppPageState();
}

class _SavedAppPageState extends State<SavedAppPage> {
  AppPageSession? session;
  Route<dynamic>? route;
  bool scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    session = AppPageSessionScope.maybeOf(context);
    route = ModalRoute.of(context);
    update();
  }

  @override
  void didUpdateWidget(SavedAppPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    update();
  }

  void update() {
    if (session == null || route == null || scheduled || widget.page.isEmpty) {
      return;
    }
    scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduled = false;
      if (mounted) {
        session?.register(route!, widget.page, onReturn: widget.onReturn);
      }
    });
  }

  @override
  void dispose() {
    if (route != null) session?.forget(route!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
