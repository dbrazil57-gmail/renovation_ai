import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'screens.dart';
import 'store.dart';
import 'app_appearance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final records = await Hive.openBox<dynamic>('renovision_records_v1');
  final photos = await Hive.openBox<dynamic>('renovision_photo_bytes_v1');
  final store = RenovisionStore(records: records, photos: photos);
  runApp(RenovisionApp(store: store));
  unawaited(store.restoreAiConnection());
}

class RenovisionApp extends StatelessWidget {
  final RenovisionStore store;
  const RenovisionApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeChoice>(
      valueListenable: store.appearance,
      builder: (context, choice, _) => MaterialApp(
        title: 'RenoVision',
        debugShowCheckedModeBanner: false,
        theme: buildRenovisionTheme(choice: choice),
        home: AppShell(store: store),
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
