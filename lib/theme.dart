import 'package:flutter/material.dart';

/// The toadHEALTH palette: swamp greens, warm cream paper and pond teals.
class ToadColors {
  static const cream = Color(0xFFF6F1E0);
  static const paper = Color(0xFFFEFAEC);
  static const ink = Color(0xFF2B2B20);
  static const inkSoft = Color(0xFF7A7561);
  static const toad = Color(0xFF5F9C3F);
  static const toadDeep = Color(0xFF3B6B2B);
  static const toadLight = Color(0xFFBFDC85);
  static const lilypad = Color(0xFF9CC46A);
  static const coral = Color(0xFFE2694E);
  static const sun = Color(0xFFEFB03F);
  static const pond = Color(0xFF6FB7C4);
  static const pondDeep = Color(0xFF4E93A3);
  static const moss = Color(0xFF31402B);
}

/// Hand-written typography: Caveat for big sketchy headings and numbers,
/// Patrick Hand for labels and body copy. If the fonts are missing the app
/// gracefully falls back to the platform font.
class ToadText {
  static const display = TextStyle(
    fontFamily: 'Caveat',
    fontSize: 46,
    height: 1.05,
    fontWeight: FontWeight.w700,
    color: ToadColors.ink,
  );

  static const h1 = TextStyle(
    fontFamily: 'Caveat',
    fontSize: 32,
    height: 1.1,
    fontWeight: FontWeight.w700,
    color: ToadColors.ink,
  );

  static const h2 = TextStyle(
    fontFamily: 'Caveat',
    fontSize: 24,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: ToadColors.ink,
  );

  static const body = TextStyle(
    fontFamily: 'PatrickHand',
    fontSize: 15.5,
    height: 1.35,
    color: ToadColors.ink,
  );

  static const label = TextStyle(
    fontFamily: 'PatrickHand',
    fontSize: 12.5,
    height: 1.2,
    letterSpacing: 0.3,
    color: ToadColors.inkSoft,
  );

  static const number = TextStyle(
    fontFamily: 'Caveat',
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: ToadColors.ink,
  );
}

ThemeData buildToadTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'PatrickHand',
    scaffoldBackgroundColor: ToadColors.cream,
    colorScheme: ColorScheme.fromSeed(seedColor: ToadColors.toad),
  );
}
