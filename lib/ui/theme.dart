import 'package:flutter/material.dart';

/// Colours from the prototype: a soft lilac sky, burnt-orange buttons and purple accents.
abstract final class SpotColors {
  static const sky1 = Color(0xFFE6D8F6);
  static const sky2 = Color(0xFFF6EFFC);
  static const ink = Color(0xFF2B2540);
  static const inkSoft = Color(0xFF6F6787);
  static const card = Colors.white;
  static const line = Color(0xFFEEE6F6);
  static const primary = Color(0xFFB9481D);
  static const primary2 = Color(0xFFDE6A32);
  static const accent = Color(0xFF8D62DC);
  static const accentSoft = Color(0xFFEFE6FC);
  static const gold = Color(0xFFF3A73B);
  static const grass = Color(0xFF79C158);
  static const water = Color(0xFF5AB8EC);
  static const green = Color(0xFF2F9E55);
  static const locked = Color(0xFF9AA3B5);
  static const bronze = Color(0xFFCF8A4C);
  static const silver = Color(0xFFA8B4C8);
  static const goldMedal = Color(0xFFF2B01E);

  /// Card tint for each points tier.
  static Color tier(int points) => switch (points) {
        >= 50 => const Color(0xFFFFF1CF),
        >= 25 => const Color(0xFFF1E8FF),
        >= 10 => const Color(0xFFE6F6E4),
        _ => const Color(0xFFE6F1FF),
      };

  /// Text colour for each points tier's label.
  static Color tierText(int points) => switch (points) {
        >= 50 => const Color(0xFFA86A00),
        >= 25 => const Color(0xFF7446C8),
        >= 10 => const Color(0xFF2F8A3E),
        _ => const Color(0xFF2B6CC4),
      };
}

abstract final class SpotFonts {
  static const display = 'Outfit';
  static const body = 'Nunito';
}

const spotShadow = [
  BoxShadow(color: Color(0x1F4B3278), blurRadius: 30, offset: Offset(0, 10)),
  BoxShadow(color: Color(0x144B3278), blurRadius: 6, offset: Offset(0, 2)),
];

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: SpotColors.accent, primary: SpotColors.primary, secondary: SpotColors.accent, surface: SpotColors.sky2),
    scaffoldBackgroundColor: SpotColors.sky2,
    fontFamily: SpotFonts.body,
  );
  TextStyle display(double size) => TextStyle(fontFamily: SpotFonts.display, fontWeight: FontWeight.w800, fontSize: size, color: SpotColors.ink, height: 1.1);
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineLarge: display(32),
      headlineMedium: display(26),
      titleLarge: display(21),
      titleMedium: display(17),
      bodyLarge: const TextStyle(fontFamily: SpotFonts.body, fontWeight: FontWeight.w700, fontSize: 17, color: SpotColors.ink),
      bodyMedium: const TextStyle(fontFamily: SpotFonts.body, fontWeight: FontWeight.w600, fontSize: 15, color: SpotColors.inkSoft),
      labelLarge: const TextStyle(fontFamily: SpotFonts.display, fontWeight: FontWeight.w700, fontSize: 17),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SpotColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 56),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontFamily: SpotFonts.display, fontWeight: FontWeight.w700, fontSize: 18),
        elevation: 4,
        shadowColor: SpotColors.primary.withValues(alpha: .4),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SpotColors.primary,
        minimumSize: const Size(64, 52),
        shape: const StadiumBorder(),
        side: const BorderSide(color: SpotColors.primary, width: 2),
        textStyle: const TextStyle(fontFamily: SpotFonts.display, fontWeight: FontWeight.w700, fontSize: 17),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SpotColors.inkSoft,
        textStyle: const TextStyle(fontFamily: SpotFonts.display, fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
  );
}
