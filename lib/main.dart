import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'brand_mark.dart';
import 'app_brand.dart';
import 'screens.dart';
import 'store.dart';
import 'app_appearance.dart';
import 'feedback_widgets.dart';
import 'feedback_storage.dart';
import 'app_store_scope.dart';
import 'app_session.dart';
import 'focus_workspace.dart';
import 'room_draft.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RenovisionStartup(loadStore: openLocalStore));
}

Future<RenovisionStore> openLocalStore() async {
  await Hive.initFlutter();
  final records = await Hive.openBox<dynamic>('renovision_records_v1');
  final photos = await Hive.openBox<dynamic>('renovision_photo_bytes_v1');
  return RenovisionStore(records: records, photos: photos);
}

/// Paints before eager storage opens, with a retry path that never clears data.
class RenovisionStartup extends StatefulWidget {
  final Future<RenovisionStore> Function() loadStore;
  const RenovisionStartup({super.key, required this.loadStore});
  @override
  State<RenovisionStartup> createState() => _RenovisionStartupState();
}

class _RenovisionStartupState extends State<RenovisionStartup> {
  RenovisionStore? store;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => failed = false);
    try {
      await Future<void>.delayed(Duration.zero);
      final loaded = await widget.loadStore();
      if (!mounted) {
        loaded.dispose();
        return;
      }
      setState(() => store = loaded);
      unawaited(loaded.access.load());
      unawaited(
        loaded.restoreAiConnection().catchError((_) {
          loaded.ai.connectionNotice =
              'Projects loaded. Reconnect AI in Settings if needed.';
        }),
      );
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  void dispose() {
    store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (store != null) return RenovisionApp(store: store!);
    return MaterialApp(
      title: appName,
      theme: buildRenovisionTheme(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppBrandMark(size: 48),
                    const SizedBox(height: 16),
                    Text(
                      failed
                          ? 'Saved projects could not be opened'
                          : 'Opening your projects…',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (failed) ...[
                      const Text(
                        'Your data has not been cleared. Check device storage and close other app tabs, then retry.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Retry opening projects'),
                      ),
                    ] else
                      const CircularProgressIndicator(
                        semanticsLabel: 'Opening saved project storage',
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RenovisionApp extends StatefulWidget {
  final RenovisionStore store;
  const RenovisionApp({super.key, required this.store});

  @override
  State<RenovisionApp> createState() => _RenovisionAppState();
}

class _RenovisionAppState extends State<RenovisionApp> {
  RenovisionStore get store => widget.store;
  late final session = AppPageSession(store.records);

  List<Route<dynamic>> restorePages(String _) {
    final saved = session.initialPages;
    final tab = saved.firstOrNull?['tab'];
    final pages = <Widget>[
      AppShell(store: store, initialTab: tab is int ? tab.clamp(0, 2) : 0),
    ];
    for (var index = 0; index < saved.length; index++) {
      final page = saved[index], kind = page['page'];
      if (kind == 'home') continue;
      if (kind == 'settings') {
        pages.add(settingsPage(store));
        continue;
      }
      final project = store.projectById(page['projectId']?.toString() ?? '');
      if (project == null || project.archived || project.deleted) break;
      if (kind == 'project') {
        pages.add(ProjectScreen(store: store, project: project));
        continue;
      }
      final room = store.roomById(page['roomId']?.toString() ?? '');
      if (room == null || room.projectId != project.id || room.deleted) break;
      if (kind == 'setup') {
        pages.add(
          roomEntry(
            store,
            room,
            forceSetup: true,
            returnToWorkspace: page['returnToWorkspace'] == true,
          ),
        );
        continue;
      }
      if (kind != 'workspace') break;
      final selected = store
          .designsFor(room.id)
          .where((design) => design.id == page['designId'])
          .firstOrNull;
      final photoId = room.photoIds.contains(page['photoId'])
          ? page['photoId'] as String
          : room.primaryId;
      final next = index + 1 < saved.length ? saved[index + 1] : null;
      final finishPanel = next != null && next['page'] == 'finishes'
          ? next['panel']
          : null;
      final tool =
          next != null &&
              next['page'] == 'tool' &&
              const [
                'crop',
                'sketch',
                'compare',
                'viewer',
              ].contains(next['tool'])
          ? next['tool'] as String
          : null;
      pages.add(
        WorkspaceScreen(
          store: store,
          roomId: room.id,
          initialDesignId: selected?.id,
          initialPhotoId: selected == null ? photoId : null,
          initialSection: FocusSection.values
              .where((v) => v.name == page['section'])
              .firstOrNull,
          initialMode: RoomDesignMode.values
              .where((v) => v.name == page['mode'])
              .firstOrNull,
          initialFinishPanel: finishPanel is int
              ? finishPanel.clamp(0, 1)
              : null,
          initialTool: tool,
        ),
      );
      // Reopen the finish editor through its workspace callbacks so Save/Back
      // keep their existing source/version semantics, never replaying AI.
      if (next?['page'] == 'finishes' || tool != null) index++;
    }
    return [
      for (final page in pages) MaterialPageRoute<void>(builder: (_) => page),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppStoreScope(
      store: store,
      openRoom: (context, roomId, designId) => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => WorkspaceScreen(
            store: store,
            roomId: roomId,
            initialDesignId: designId,
          ),
        ),
      ),
      child: AppPageSessionScope(
        session: session,
        child: FeedbackScope(
          drafts: LocalFeedbackDrafts(store.records),
          child: ValueListenableBuilder<AppThemeChoice>(
            valueListenable: store.appearance,
            builder: (context, choice, _) => MaterialApp(
              title: appName,
              debugShowCheckedModeBanner: false,
              theme: buildRenovisionTheme(choice: choice),
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => AppShell(store: store),
              ),
              navigatorObservers: [session],
              onGenerateInitialRoutes: restorePages,
            ),
          ),
        ),
      ),
    );
  }
}

ThemeData buildRenovisionTheme({
  AppThemeChoice choice = AppThemeChoice.warmOlive,
}) {
  final colours = choice.colours;
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colours.accent,
      brightness: Brightness.light,
    ),
    extensions: [colours],
    scaffoldBackgroundColor: colours.paper,
    snackBarTheme: const SnackBarThemeData(showCloseIcon: true),
    cardTheme: CardThemeData(
      color: colours.panel,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colours.canvas,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 52,
    ),
  );
  final text = base.textTheme.copyWith(
    headlineSmall: base.textTheme.headlineSmall!.copyWith(
      fontSize: 20,
      height: 1.2,
    ),
    titleLarge: base.textTheme.titleLarge!.copyWith(fontSize: 18, height: 1.25),
    titleMedium: base.textTheme.titleMedium!.copyWith(
      fontSize: 15,
      height: 1.3,
    ),
    titleSmall: base.textTheme.titleSmall!.copyWith(fontSize: 14, height: 1.3),
    bodyLarge: base.textTheme.bodyLarge!.copyWith(fontSize: 14, height: 1.35),
    bodyMedium: base.textTheme.bodyMedium!.copyWith(fontSize: 13, height: 1.4),
    bodySmall: base.textTheme.bodySmall!.copyWith(fontSize: 12, height: 1.3),
    labelLarge: base.textTheme.labelLarge!.copyWith(fontSize: 13, height: 1.25),
    labelMedium: base.textTheme.labelMedium!.copyWith(
      fontSize: 12,
      height: 1.3,
    ),
    labelSmall: base.textTheme.labelSmall!.copyWith(fontSize: 11, height: 1.3),
  );
  return base.copyWith(
    textTheme: text,
    iconTheme: base.iconTheme.copyWith(size: 22),
    inputDecorationTheme: const InputDecorationTheme(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(48, 40),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(48, 40),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(48, 40),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: text.labelLarge,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    listTileTheme: ListTileThemeData(
      titleTextStyle: text.bodyLarge,
      subtitleTextStyle: text.bodySmall,
    ),
    navigationBarTheme: NavigationBarThemeData(
      labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
    ),
  );
}
