import 'package:flutter/material.dart';

/// One resolvable ink-and-paper palette. The app's screens sketch with
/// [ToadColors] everywhere; a palette is the set of values those names hold
/// for the active theme style and brightness.
class InkPalette {
  const InkPalette({
    required this.cream,
    required this.paper,
    required this.ink,
    required this.inkSoft,
    required this.toad,
    required this.toadDeep,
    required this.toadLight,
    required this.lilypad,
    required this.coral,
    required this.sun,
    required this.pond,
    required this.pondDeep,
    required this.moss,
  });

  /// The page behind everything.
  final Color cream;

  /// A card or sheet of paper.
  final Color paper;

  /// The pen.
  final Color ink;

  /// Faded pencil.
  final Color inkSoft;

  /// The toad's back: primary action green.
  final Color toad;

  /// Forest-depth green for pressed states and headings.
  final Color toadDeep;

  /// Young toad green for gentle fills.
  final Color toadLight;

  /// The lilypad resting green.
  final Color lilypad;

  /// Warm coral for hearts and warnings.
  final Color coral;

  /// Sunlight for streaks and highlights.
  final Color sun;

  /// Pond teal for water and calm data.
  final Color pond;

  /// Deep pond for chart strokes.
  final Color pondDeep;

  /// Mossy night green.
  final Color moss;
}

/// Sketchbook daylight: warm cream paper and swamp greens - the classic
/// toadHEALTH look since the first hop.
const inkPaper = InkPalette(
  cream: Color(0xFFF6F1E0),
  paper: Color(0xFFFEFAEC),
  ink: Color(0xFF2B2B20),
  inkSoft: Color(0xFF7A7561),
  toad: Color(0xFF5F9C3F),
  toadDeep: Color(0xFF3B6B2B),
  toadLight: Color(0xFFBFDC85),
  lilypad: Color(0xFF9CC46A),
  coral: Color(0xFFE2694E),
  sun: Color(0xFFEFB03F),
  pond: Color(0xFF6FB7C4),
  pondDeep: Color(0xFF4E93A3),
  moss: Color(0xFF31402B),
);

/// Sketchbook night: the night pond - deep moss surfaces, cream ink, the
/// same handwriting. The toad family's shared dark paper (toadPLAYER's
/// Sketchbook theme carries the same values).
const inkNightPond = InkPalette(
  cream: Color(0xFF12140E),
  paper: Color(0xFF1A1D16),
  ink: Color(0xFFE7E3D0),
  inkSoft: Color(0xFFA9A48C),
  toad: Color(0xFFA5C77E),
  toadDeep: Color(0xFFBFDC85),
  toadLight: Color(0xFF31402B),
  lilypad: Color(0xFF6E8A56),
  coral: Color(0xFFE89A85),
  sun: Color(0xFFF2C879),
  pond: Color(0xFF8FB9C4),
  pondDeep: Color(0xFFA9D2DD),
  moss: Color(0xFF262B22),
);

/// The Toad style's daylight: toadPLAYER's crafted moss palette.
const inkToadDay = InkPalette(
  cream: Color(0xFFF9FAF1),
  paper: Color(0xFFFEFDF6),
  ink: Color(0xFF1E2416),
  inkSoft: Color(0xFF5D6650),
  toad: Color(0xFF557B2F),
  toadDeep: Color(0xFF3B5B1E),
  toadLight: Color(0xFFBFDC85),
  lilypad: Color(0xFF8DB360),
  coral: Color(0xFFB05E42),
  sun: Color(0xFFD99C2B),
  pond: Color(0xFF5D90A0),
  pondDeep: Color(0xFF3E6E7E),
  moss: Color(0xFF2C3620),
);

/// The Toad style at night.
const inkToadNight = InkPalette(
  cream: Color(0xFF12140E),
  paper: Color(0xFF1A1D16),
  ink: Color(0xFFE7E3D0),
  inkSoft: Color(0xFFA9A48C),
  toad: Color(0xFF9CCC65),
  toadDeep: Color(0xFFBDC2AE),
  toadLight: Color(0xFF2C4218),
  lilypad: Color(0xFF6E8A56),
  coral: Color(0xFFE89A85),
  sun: Color(0xFFF2C879),
  pond: Color(0xFF8FB9C4),
  pondDeep: Color(0xFFA9D2DD),
  moss: Color(0xFF262B22),
);

/// The Toadmark style's daylight: the frog-lime brand on warm paper - the
/// family handwriting with brand accents.
const inkToadmarkDay = InkPalette(
  cream: Color(0xFFF6F1E0),
  paper: Color(0xFFFEFAEC),
  ink: Color(0xFF2B2B20),
  inkSoft: Color(0xFF615E4F),
  toad: Color(0xFF446E17),
  toadDeep: Color(0xFF2E5312),
  toadLight: Color(0xFFD3EFB4),
  lilypad: Color(0xFF84CC16),
  coral: Color(0xFF8F5C00),
  sun: Color(0xFFD99C2B),
  pond: Color(0xFF0F766E),
  pondDeep: Color(0xFF00564E),
  moss: Color(0xFF102000),
);

/// The Toadmark style at night: deep ink with the frog-lime glow.
const inkToadmarkNight = InkPalette(
  cream: Color(0xFF0B100F),
  paper: Color(0xFF131A18),
  ink: Color(0xFFF3F4F6),
  inkSoft: Color(0xFFB8C7C0),
  toad: Color(0xFFA3E635),
  toadDeep: Color(0xFF65A30D),
  toadLight: Color(0xFF2E5312),
  lilypad: Color(0xFF84CC16),
  coral: Color(0xFF2DD4BF),
  sun: Color(0xFFFBBF24),
  pond: Color(0xFF34D399),
  pondDeep: Color(0xFF14B8A6),
  moss: Color(0xFF14210A),
);

/// The System Material style: neutral daylight surfaces, the toad green as
/// the seed. With Android 12+ wallpaper colors the scheme is remapped in
/// [Appearance]; this is the fixed fallback.
const inkMaterialDay = InkPalette(
  cream: Color(0xFFF9FAF3),
  paper: Color(0xFFFFFDF4),
  ink: Color(0xFF1C1E17),
  inkSoft: Color(0xFF5C6152),
  toad: Color(0xFF5F9C3F),
  toadDeep: Color(0xFF3B6B2B),
  toadLight: Color(0xFFBFDC85),
  lilypad: Color(0xFF9CC46A),
  coral: Color(0xFFE2694E),
  sun: Color(0xFFEFB03F),
  pond: Color(0xFF6FB7C4),
  pondDeep: Color(0xFF4E93A3),
  moss: Color(0xFF31402B),
);

/// System Material at night.
const inkMaterialNight = InkPalette(
  cream: Color(0xFF131409),
  paper: Color(0xFF1B1C11),
  ink: Color(0xFFE6E8DC),
  inkSoft: Color(0xFFA9AC9B),
  toad: Color(0xFFA5C77E),
  toadDeep: Color(0xFFBFDC85),
  toadLight: Color(0xFF31402B),
  lilypad: Color(0xFF6E8A56),
  coral: Color(0xFFE89A85),
  sun: Color(0xFFF2C879),
  pond: Color(0xFF8FB9C4),
  pondDeep: Color(0xFFA9D2DD),
  moss: Color(0xFF262B22),
);

/// The toadHEALTH palette names, resolved through the active theme palette.
/// Every screen sketches with these names; [Appearance.applyPalette] swaps
/// the values behind them when the theme style or brightness changes, and
/// the whole app re-inks on the next build.
class ToadColors {
  ToadColors._();

  static InkPalette _active = inkPaper;

  /// Installs [palette] as the active one. Called by the app shell whenever
  /// the theme is rebuilt; screens never need to know.
  static void applyPalette(InkPalette palette) => _active = palette;

  /// The palette currently on the page.
  static InkPalette get active => _active;

  static Color get cream => _active.cream;
  static Color get paper => _active.paper;
  static Color get ink => _active.ink;
  static Color get inkSoft => _active.inkSoft;
  static Color get toad => _active.toad;
  static Color get toadDeep => _active.toadDeep;
  static Color get toadLight => _active.toadLight;
  static Color get lilypad => _active.lilypad;
  static Color get coral => _active.coral;
  static Color get sun => _active.sun;
  static Color get pond => _active.pond;
  static Color get pondDeep => _active.pondDeep;
  static Color get moss => _active.moss;
}

/// Hand-written typography: Caveat for big sketchy headings and numbers,
/// Patrick Hand for labels and body copy. The ink colour follows the active
/// palette, so every style keeps the handwriting while switching pens.
class ToadText {
  ToadText._();

  static TextStyle get display => TextStyle(
        fontFamily: 'Caveat',
        fontSize: 46,
        height: 1.05,
        fontWeight: FontWeight.w700,
        color: ToadColors.ink,
      );

  static TextStyle get h1 => TextStyle(
        fontFamily: 'Caveat',
        fontSize: 32,
        height: 1.1,
        fontWeight: FontWeight.w700,
        color: ToadColors.ink,
      );

  static TextStyle get h2 => TextStyle(
        fontFamily: 'Caveat',
        fontSize: 24,
        height: 1.15,
        fontWeight: FontWeight.w700,
        color: ToadColors.ink,
      );

  static TextStyle get body => TextStyle(
        fontFamily: 'PatrickHand',
        fontSize: 15.5,
        height: 1.35,
        color: ToadColors.ink,
      );

  static TextStyle get label => TextStyle(
        fontFamily: 'PatrickHand',
        fontSize: 12.5,
        height: 1.2,
        letterSpacing: 0.3,
        color: ToadColors.inkSoft,
      );

  static TextStyle get number => TextStyle(
        fontFamily: 'Caveat',
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: ToadColors.ink,
      );
}

/// The hand-written heading swap shared by every style: Caveat signs each
/// display and headline role (its script weight needs a little extra size
/// to hold its own), PatrickHand carries body copy through the base font
/// family.
TextStyle sketchHeading(TextStyle? style, double bump) {
  final size = style?.fontSize ?? 24.0;
  return (style ?? const TextStyle()).copyWith(
    fontFamily: 'Caveat',
    fontWeight: FontWeight.w700,
    fontSize: size + bump,
    height: 1.05,
  );
}

/// The sketchbook ThemeData for [brightness]: the ink-on-paper world, in
/// daylight cream or the night pond.
ThemeData buildSketchbookTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final scheme = (light
          ? ColorScheme.fromSeed(
              seedColor: const Color(0xFF5F9C3F),
              brightness: Brightness.light,
            )
          : ColorScheme.fromSeed(
              seedColor: const Color(0xFF5F8A46),
              brightness: Brightness.dark,
            ))
      .copyWith(
        primary: light ? const Color(0xFF3B6B2B) : const Color(0xFFA5C77E),
        onPrimary: light ? const Color(0xFFF6F1E0) : const Color(0xFF1F2A16),
        primaryContainer: light
            ? const Color(0xFFBFDC85)
            : const Color(0xFF31402B),
        onPrimaryContainer: light
            ? const Color(0xFF31402B)
            : const Color(0xFFBFDC85),
        secondary: light ? const Color(0xFF4E93A3) : const Color(0xFF8FB9C4),
        onSecondary: light ? const Color(0xFFF6F1E0) : const Color(0xFF16323A),
        tertiary: light ? const Color(0xFFE2694E) : const Color(0xFFE89A85),
        onTertiary: light ? const Color(0xFFF6F1E0) : const Color(0xFF3A160D),
        surface: ToadColors.cream,
        onSurface: ToadColors.ink,
        surfaceContainerLowest: light
            ? const Color(0xFFFEFAEC)
            : const Color(0xFF0D0F0B),
        surfaceContainerLow: light
            ? const Color(0xFFF9F3E1)
            : const Color(0xFF141611),
        surfaceContainer: light
            ? const Color(0xFFF3ECDB)
            : const Color(0xFF1A1D16),
        surfaceContainerHigh: light
            ? const Color(0xFFECE4D0)
            : const Color(0xFF20241C),
        surfaceContainerHighest: light
            ? const Color(0xFFE4DBC4)
            : const Color(0xFF262B22),
        outlineVariant: light
            ? const Color(0xFFD9D2BC)
            : const Color(0xFF3A4032),
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'PatrickHand',
    scaffoldBackgroundColor: ToadColors.cream,
    colorScheme: scheme,
  );

  final textTheme = base.textTheme.copyWith(
    displayLarge: sketchHeading(base.textTheme.displayLarge, 5),
    displayMedium: sketchHeading(base.textTheme.displayMedium, 5),
    displaySmall: sketchHeading(base.textTheme.displaySmall, 4),
    headlineLarge: sketchHeading(base.textTheme.headlineLarge, 4),
    headlineMedium: sketchHeading(base.textTheme.headlineMedium, 3),
    headlineSmall: sketchHeading(base.textTheme.headlineSmall, 2),
  );

  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: TextStyle(
        fontFamily: 'Caveat',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
  );
}

/// Kept for the splash's first frame: the classic daylight paper.
ThemeData buildToadTheme() => buildSketchbookTheme(Brightness.light);
