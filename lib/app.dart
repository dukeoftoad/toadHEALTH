import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

import 'appearance.dart';
import 'splash.dart';
import 'theme.dart';

/// The app root: wears the picked appearance style and mode, re-inking the
/// whole paper when it changes. Wallpaper (Material You) colors feed the
/// material style on Android 12+.
class ToadHealthApp extends StatefulWidget {
  const ToadHealthApp({super.key});

  @override
  State<ToadHealthApp> createState() => _ToadHealthAppState();
}

class _ToadHealthAppState extends State<ToadHealthApp> {
  @override
  void initState() {
    super.initState();
    // The platform brightness can flip while the app runs (system mode);
    // appearance picks themselves flow through the ListenableBuilder below.
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        _onPlatformBrightnessChanged;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        null;
    super.dispose();
  }

  void _onPlatformBrightnessChanged() {
    if (Appearance.instance.mode == ToadMode.system) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return ListenableBuilder(
          listenable: Appearance.instance,
          builder: (_, __) {
            final appearance = Appearance.instance;
            final platform =
                WidgetsBinding.instance.platformDispatcher.platformBrightness;
            final brightness = appearance.resolveBrightness(platform);

            // Install the palette for the active style + brightness before
            // the tree builds, so every ToadColors read sketches with it.
            ToadColors.applyPalette(appearance.paletteFor(brightness));

            return MaterialApp(
              title: 'toadHEALTH',
              debugShowCheckedModeBanner: false,
              theme: appearance.themeFor(
                Brightness.light,
                dynamicScheme: _toFlutterColorScheme(
                  lightDynamic?.harmonized(),
                ),
              ),
              darkTheme: appearance.themeFor(
                Brightness.dark,
                dynamicScheme: _toFlutterColorScheme(
                  darkDynamic?.harmonized(),
                ),
              ),
              themeMode: switch (appearance.mode) {
                ToadMode.system => ThemeMode.system,
                ToadMode.light => ThemeMode.light,
                ToadMode.dark => ThemeMode.dark,
              },
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}

/// dynamic_color hands out its own ColorScheme type (from the material_ui
/// package); the app's themes speak Flutter's. Copy the palette across,
/// field by field, so the wallpaper colors survive the crossing.
ColorScheme? _toFlutterColorScheme(material_ui.ColorScheme? scheme) {
  if (scheme == null) return null;
  return ColorScheme.fromSeed(
    seedColor: scheme.primary,
    brightness: scheme.brightness,
  ).copyWith(
    primary: scheme.primary,
    onPrimary: scheme.onPrimary,
    primaryContainer: scheme.primaryContainer,
    onPrimaryContainer: scheme.onPrimaryContainer,
    secondary: scheme.secondary,
    onSecondary: scheme.onSecondary,
    secondaryContainer: scheme.secondaryContainer,
    onSecondaryContainer: scheme.onSecondaryContainer,
    tertiary: scheme.tertiary,
    onTertiary: scheme.onTertiary,
    tertiaryContainer: scheme.tertiaryContainer,
    onTertiaryContainer: scheme.onTertiaryContainer,
    error: scheme.error,
    onError: scheme.onError,
    errorContainer: scheme.errorContainer,
    onErrorContainer: scheme.onErrorContainer,
    outline: scheme.outline,
    outlineVariant: scheme.outlineVariant,
    surface: scheme.surface,
    onSurface: scheme.onSurface,
    surfaceContainerLowest: scheme.surfaceContainerLowest,
    surfaceContainerLow: scheme.surfaceContainerLow,
    surfaceContainer: scheme.surfaceContainer,
    surfaceContainerHigh: scheme.surfaceContainerHigh,
    surfaceContainerHighest: scheme.surfaceContainerHighest,
    onSurfaceVariant: scheme.onSurfaceVariant,
    inverseSurface: scheme.inverseSurface,
    onInverseSurface: scheme.onInverseSurface,
    inversePrimary: scheme.inversePrimary,
    shadow: scheme.shadow,
    surfaceTint: scheme.surfaceTint,
    scrim: scheme.scrim,
  );
}

/// Flowing page transition: a gentle rise and fade, like a lily pad drifting.
class FlowRoute<T> extends PageRouteBuilder<T> {
  FlowRoute({required Widget page})
      : super(
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
