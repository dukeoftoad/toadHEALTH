import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toad_health/appearance.dart';
import 'package:toad_health/core/vault_store.dart';
import 'package:toad_health/theme.dart';

/// An in-memory [VaultStore] for appearance persistence tests.
class FakeVaultStore implements VaultStore {
  final Map<String, String> files = {};

  @override
  Future<String?> readText(String name) async => files[name];

  @override
  Future<void> writeText(String name, String content) async {
    files[name] = content;
  }

  @override
  Future<void> delete(String name) async {
    files.remove(name);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Appearance persistence', () {
    test('a fresh install wears the sketchbook paper and follows the system',
        () async {
      final store = FakeVaultStore();
      await Appearance.instance.load(store: store);
      expect(Appearance.instance.style, ToadThemeStyle.sketchbook);
      expect(Appearance.instance.mode, ToadMode.system);
      // Nothing to persist until a pick is made.
      expect(store.files, isEmpty);
    });

    test('style and mode round-trip through the store', () async {
      final store = FakeVaultStore();
      await Appearance.instance.load(store: store);
      Appearance.instance.setStyle(ToadThemeStyle.toadmark);
      Appearance.instance.setMode(ToadMode.dark);

      final saved = store.files['appearance.json'];
      expect(saved, isNotNull);
      expect(saved, contains('"style":"toadmark"'));
      expect(saved, contains('"mode":"dark"'));

      // A later boot reads the same pick back.
      await Appearance.instance.load(store: store);
      expect(Appearance.instance.style, ToadThemeStyle.toadmark);
      expect(Appearance.instance.mode, ToadMode.dark);
    });

    test('a torn write falls back to the paper defaults', () async {
      final store = FakeVaultStore()
        ..files['appearance.json'] = '{not json at all';
      await Appearance.instance.load(store: store);
      expect(Appearance.instance.style, ToadThemeStyle.sketchbook);
      expect(Appearance.instance.mode, ToadMode.system);
    });

    test('an unknown saved style name keeps the sketchbook', () async {
      final store = FakeVaultStore()
        ..files['appearance.json'] = '{"style":"hologram","mode":"dark"}';
      await Appearance.instance.load(store: store);
      expect(Appearance.instance.style, ToadThemeStyle.sketchbook);
      expect(Appearance.instance.mode, ToadMode.dark);
    });

    test('picking the current style again does not rewrite the file',
        () async {
      final store = FakeVaultStore();
      await Appearance.instance.load(store: store);
      Appearance.instance.setStyle(ToadThemeStyle.toad);
      final firstWrite = store.files['appearance.json'];
      Appearance.instance.setStyle(ToadThemeStyle.toad);
      expect(store.files['appearance.json'], firstWrite);
    });
  });

  group('mode resolution', () {
    test('system mode follows the platform brightness', () {
      Appearance.instance.setMode(ToadMode.system);
      expect(
        Appearance.instance.resolveBrightness(Brightness.dark),
        Brightness.dark,
      );
      expect(
        Appearance.instance.resolveBrightness(Brightness.light),
        Brightness.light,
      );
    });

    test('light and dark modes hold their paper whatever the sky', () {
      Appearance.instance.setMode(ToadMode.light);
      expect(
        Appearance.instance.resolveBrightness(Brightness.dark),
        Brightness.light,
      );
      Appearance.instance.setMode(ToadMode.dark);
      expect(
        Appearance.instance.resolveBrightness(Brightness.light),
        Brightness.dark,
      );
    });
  });

  group('palettes', () {
    test('every style has a palette for both brightnesses', () {
      for (final style in ToadThemeStyle.values) {
        Appearance.instance.setStyle(style);
        for (final brightness in Brightness.values) {
          final palette = Appearance.instance.paletteFor(brightness);
          // Distinct light/dark surfaces: the page actually changes.
          expect(palette.cream, isNot(equals(palette.ink)));
        }
      }
    });

    test('the sketchbook daylight is the classic toadHEALTH paper', () {
      Appearance.instance.setStyle(ToadThemeStyle.sketchbook);
      final palette = Appearance.instance.paletteFor(Brightness.light);
      expect(palette.cream, const Color(0xFFF6F1E0));
      expect(palette.paper, const Color(0xFFFEFAEC));
      expect(palette.ink, const Color(0xFF2B2B20));
      expect(palette.toad, const Color(0xFF5F9C3F));
    });

    test('the night pond flips ink and paper', () {
      Appearance.instance.setStyle(ToadThemeStyle.sketchbook);
      final night = Appearance.instance.paletteFor(Brightness.dark);
      expect(night.cream, const Color(0xFF12140E));
      expect(night.ink, const Color(0xFFE7E3D0));
    });

    test('the toadmark style carries the frog-lime brand', () {
      Appearance.instance.setStyle(ToadThemeStyle.toadmark);
      expect(
        Appearance.instance.paletteFor(Brightness.light).toad,
        const Color(0xFF446E17),
      );
      expect(
        Appearance.instance.paletteFor(Brightness.dark).lilypad,
        const Color(0xFF84CC16),
      );
    });

    test('applying a palette re-inks the ToadColors names', () {
      ToadColors.applyPalette(inkNightPond);
      expect(ToadColors.ink, const Color(0xFFE7E3D0));
      expect(ToadColors.cream, const Color(0xFF12140E));
      // Back to daylight for the next reader.
      ToadColors.applyPalette(inkPaper);
      expect(ToadColors.ink, const Color(0xFF2B2B20));
    });
  });

  group('themes', () {
    test('every style builds for both brightnesses', () {
      for (final style in ToadThemeStyle.values) {
        Appearance.instance.setStyle(style);
        for (final brightness in Brightness.values) {
          final theme = Appearance.instance.themeFor(brightness);
          expect(theme.scaffoldBackgroundColor, isNotNull);
        }
      }
    });

    test('the handwriting survives every style switch', () {
      for (final style in ToadThemeStyle.values) {
        Appearance.instance.setStyle(style);
        final theme = Appearance.instance.themeFor(Brightness.light);
        expect(theme.textTheme.bodyLarge?.fontFamily, 'PatrickHand');
        expect(theme.textTheme.headlineMedium?.fontFamily, 'Caveat');
      }
    });

    test('the material style can wear wallpaper colors', () {
      Appearance.instance.setStyle(ToadThemeStyle.material);
      final wallpaper = ColorScheme.fromSeed(
        seedColor: const Color(0xFFB39DDB),
        brightness: Brightness.light,
      );
      final themed = Appearance.instance.themeFor(
        Brightness.light,
        dynamicScheme: wallpaper,
      );
      expect(themed.colorScheme.primary, wallpaper.primary);
    });
  });
}
