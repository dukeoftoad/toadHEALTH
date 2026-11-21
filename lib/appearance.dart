import 'dart:convert';

import 'package:flutter/material.dart';

import 'core/vault_store.dart';
import 'theme.dart';

/// The theme styles on offer, matching the toad app family: the native
/// ink-on-paper Sketchbook, toadPLAYER's crafted Toad and Toadmark
/// palettes, and the system's Material You.
enum ToadThemeStyle { sketchbook, toad, toadmark, material }

/// Which brightness the paper is drawn at.
enum ToadMode { system, light, dark }

/// The appearance settings: the picked [ToadThemeStyle] and [ToadMode],
/// persisted to a tiny plain JSON file in the app's private store (the
/// theme choice is not health data - it lives outside the sealed vault so
/// the very first frame can already wear it) and applied live.
class Appearance extends ChangeNotifier {
  Appearance._();

  static final Appearance instance = Appearance._();

  static const _fileName = 'appearance.json';

  ToadThemeStyle _style = ToadThemeStyle.sketchbook;
  ToadMode _mode = ToadMode.system;
  VaultStore? _store;

  /// The picked style; sketchbook paper until told otherwise.
  ToadThemeStyle get style => _style;

  /// The picked mode; follows the system until told otherwise.
  ToadMode get mode => _mode;

  /// True once [load] has read (or initialized) the persisted choice.
  bool get loaded => _store != null;

  /// Loads the persisted appearance. [store] overrides the private store
  /// (tests inject an in-memory one); production leaves it out.
  Future<void> load({VaultStore? store}) async {
    _store = store ?? await createDefaultStore();
    // Start from the paper default so a torn or unreadable file lands
    // deterministically there, whatever this process had in memory.
    _style = ToadThemeStyle.sketchbook;
    _mode = ToadMode.system;
    try {
      final raw = await _store!.readText(_fileName);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final savedStyle = decoded['style'];
          if (savedStyle is String) {
            _style = ToadThemeStyle.values
                .where((s) => s.name == savedStyle)
                .firstOrNull ?? ToadThemeStyle.sketchbook;
          }
          final savedMode = decoded['mode'];
          if (savedMode is String) {
            _mode = ToadMode.values
                .where((m) => m.name == savedMode)
                .firstOrNull ?? ToadMode.system;
          }
        }
      }
    } catch (_) {
      // A torn write or an unreadable file falls back to the paper default.
    }
    notifyListeners();
  }

  /// Picks the style, persists it, and re-inks the app.
  void setStyle(ToadThemeStyle style) {
    if (style == _style) return;
    _style = style;
    _persist();
    notifyListeners();
  }

  /// Picks the mode, persists it, and re-inks the app.
  void setMode(ToadMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final store = _store;
    if (store == null) return;
    try {
      await store.writeText(
        _fileName,
        jsonEncode({'version': 1, 'style': _style.name, 'mode': _mode.name}),
      );
    } catch (_) {
      // Persistence is best-effort; the in-memory pick still applies.
    }
  }

  /// The brightness the current mode resolves to, given the platform's.
  Brightness resolveBrightness(Brightness platformBrightness) {
    return switch (_mode) {
      ToadMode.light => Brightness.light,
      ToadMode.dark => Brightness.dark,
      ToadMode.system => platformBrightness,
    };
  }

  /// The palette the resolved brightness of this style paints with.
  InkPalette paletteFor(Brightness brightness) {
    final light = brightness == Brightness.light;
    return switch (_style) {
      ToadThemeStyle.sketchbook =>
        light ? inkPaper : inkNightPond,
      ToadThemeStyle.toad =>
        light ? inkToadDay : inkToadNight,
      ToadThemeStyle.toadmark =>
        light ? inkToadmarkDay : inkToadmarkNight,
      ToadThemeStyle.material =>
        light ? inkMaterialDay : inkMaterialNight,
    };
  }

  /// Builds the active style's [ThemeData] for [brightness]. [dynamicScheme]
  /// carries Android 12+ wallpaper colors for the material style.
  ThemeData themeFor(
    Brightness brightness, {
    ColorScheme? dynamicScheme,
  }) {
    return switch (_style) {
      ToadThemeStyle.sketchbook => buildSketchbookTheme(brightness),
      ToadThemeStyle.toad => _materialTheme(
          brightness,
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF557B2F),
            brightness: brightness,
          ).copyWith(
            surface: ToadColors.cream,
            secondary: brightness == Brightness.light
                ? const Color(0xFF56624A)
                : const Color(0xFFBDC2AE),
            tertiary: brightness == Brightness.light
                ? const Color(0xFF38656A)
                : const Color(0xFFA2CFD4),
          ),
        ),
      ToadThemeStyle.toadmark => _materialTheme(
          brightness,
          ColorScheme.fromSeed(
            seedColor: brightness == Brightness.light
                ? const Color(0xFF446E17)
                : const Color(0xFF84CC16),
            brightness: brightness,
          ).copyWith(
            primary: brightness == Brightness.light
                ? const Color(0xFF446E17)
                : const Color(0xFFA3E635),
            onPrimary: brightness == Brightness.light
                ? Colors.white
                : const Color(0xFF14210A),
            primaryContainer: brightness == Brightness.light
                ? const Color(0xFFD3EFB4)
                : const Color(0xFF2E5312),
            onPrimaryContainer: brightness == Brightness.light
                ? const Color(0xFF102000)
                : const Color(0xFFD9F99D),
            secondary: brightness == Brightness.light
                ? const Color(0xFF0F766E)
                : const Color(0xFF34D399),
            surface: ToadColors.cream,
          ),
        ),
      ToadThemeStyle.material => _materialTheme(
          brightness,
          dynamicScheme ??
              ColorScheme.fromSeed(
                seedColor: const Color(0xFF5F9C3F),
                brightness: brightness,
              ),
        ),
    };
  }

  /// The family's Material shell for the crafted styles: the handwriting
  /// stays (this is still a toad app), the palette follows the scheme.
  ThemeData _materialTheme(Brightness brightness, ColorScheme scheme) {
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
}