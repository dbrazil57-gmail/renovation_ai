import 'package:material_ui/material_ui.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'screens.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final records = await Hive.openBox<dynamic>('renovision_records_v1');
  final photos = await Hive.openBox<dynamic>('renovision_photo_bytes_v1');
  runApp(
    RenovisionApp(
      store: RenovisionStore(records: records, photos: photos),
    ),
  );
}

class RenovisionApp extends StatelessWidget {
  final RenovisionStore store;
  const RenovisionApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Renovision AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF297A72),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F6),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF6F7F6)),
      ),
      home: AppShell(store: store),
    );
  }
}
