import 'package:material_ui/material_ui.dart';

import 'app_brand.dart';

enum AppThemeChoice {
  brandGreen(
    'Eucalyptus & stone',
    brandActionArgb,
    brandForestArgb,
    brandPaperArgb,
    brandPanelArgb,
    brandInkArgb,
  ),
  warmOlive(
    'Warm olive',
    0xFF706B3E,
    0xFF26251F,
    0xFFF1ECE3,
    0xFFFCF9F3,
    0xFF292A24,
  ),
  oceanBlue(
    'Ocean blue',
    0xFF1C608A,
    0xFF162C41,
    0xFFEEF4FA,
    0xFFFCFDFF,
    0xFF1F2F3D,
  ),
  forestGreen(
    'Forest green',
    0xFF2B6B52,
    0xFF193D34,
    0xFFEFF6F0,
    0xFFFCFFFC,
    0xFF21372C,
  ),
  terracotta(
    'Terracotta',
    0xFFA64D36,
    0xFF482C27,
    0xFFFBF1EB,
    0xFFFFFCF8,
    0xFF402C26,
  ),
  slate('Slate', 0xFF53627B, 0xFF242934, 0xFFF1F3F7, 0xFFFCFDFF, 0xFF252C38);

  final String label;
  final int accent, canvas, paper, panel, ink;

  static AppThemeChoice fromSaved(Object? value) {
    final saved = value is Map ? value : const {};
    final selected = values
        .where((choice) => choice.name == saved['theme'])
        .firstOrNull;
    // Adopt the approved brand in place of the legacy default. An explicit
    // choice made in the new picker, including olive, remains the user's choice.
    if (selected == warmOlive && saved['brandThemeVersion'] != 1) {
      return brandGreen;
    }
    return selected ?? brandGreen;
  }

  const AppThemeChoice(
    this.label,
    this.accent,
    this.canvas,
    this.paper,
    this.panel,
    this.ink,
  );

  AppAppearance get colours => AppAppearance(
    accent: Color(accent),
    canvas: Color(canvas),
    paper: Color(paper),
    panel: Color(panel),
    ink: Color(ink),
  );
}

class AppAppearance extends ThemeExtension<AppAppearance> {
  final Color accent, canvas, paper, panel, ink;
  const AppAppearance({
    required this.accent,
    required this.canvas,
    required this.paper,
    required this.panel,
    required this.ink,
  });

  static AppAppearance of(BuildContext context) =>
      Theme.of(context).extension<AppAppearance>() ??
      AppThemeChoice.brandGreen.colours;

  @override
  AppAppearance copyWith({
    Color? accent,
    Color? canvas,
    Color? paper,
    Color? panel,
    Color? ink,
  }) => AppAppearance(
    accent: accent ?? this.accent,
    canvas: canvas ?? this.canvas,
    paper: paper ?? this.paper,
    panel: panel ?? this.panel,
    ink: ink ?? this.ink,
  );

  @override
  AppAppearance lerp(covariant AppAppearance? other, double t) => other == null
      ? this
      : AppAppearance(
          accent: Color.lerp(accent, other.accent, t)!,
          canvas: Color.lerp(canvas, other.canvas, t)!,
          paper: Color.lerp(paper, other.paper, t)!,
          panel: Color.lerp(panel, other.panel, t)!,
          ink: Color.lerp(ink, other.ink, t)!,
        );
}
