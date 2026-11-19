# toadHEALTH

<p align="center">
  <img src="assets/images/banner.png" alt="toadHEALTH banner" width="820" />
</p>

<p align="center">
  <a href="https://github.com/dukeoftoad/toadHEALTH/actions/workflows/flutter-ci.yml"><img src="https://github.com/dukeoftoad/toadHEALTH/actions/workflows/flutter-ci.yml/badge.svg" alt="Flutter CI" /></a>
  <a href="https://github.com/dukeoftoad/toadHEALTH/actions/workflows/release-apk.yml"><img src="https://github.com/dukeoftoad/toadHEALTH/actions/workflows/release-apk.yml/badge.svg" alt="Release APK" /></a>
  <a href="https://github.com/dukeoftoad/toadHEALTH/actions/workflows/gh-pages.yml"><img src="https://github.com/dukeoftoad/toadHEALTH/actions/workflows/gh-pages.yml/badge.svg" alt="Web demo" /></a>
</p>

**toadHEALTH** is a gentle, hand-drawn health companion built with Flutter - and the toad is not just a mascot, it is the body of the app. The toad walks your dashboard, runs when you push yourself, physically hops between navigation tabs, floats on its lily pad as you drink water, and sleeps when you should be sleeping.

Every stroke in the UI is drawn at runtime by a wobbly-ink "sketchy" engine built on `CustomPainter` - no static icon fonts, no stock vectors. The running toad and walking toad are the app icon and the navigation icons, all sketched by hand.

## Features

- **Hand-drawn everything** - a deterministic ink-wobble engine powers every line, circle, blob, chart and icon, so the whole app looks sketched with a pen.
- **The toad mascot** - five live-animated poses: idle, walk, run, sleep and cheer.
- **Toad navigation** - the bottom nav is a pond the toad hops across; it lands on whichever lily pad (tab) you pick.
- **Home** - hop counter with a sketchy progress ring (tap the toad, it hops and adds hops), vitals tiles, weekly bar chart, rotating toad wisdom.
- **Motion** - walk/run toggle with speed lines, hourly rhythm chart with ink hatching, recent hops list.
- **Water** - a pond that rises glass by glass while the toad bobs on its lily pad, with splash ripples.
- **Sleep** - the night pond with floating Zzz glyphs, weekly sleep chart and a cozy breakdown.
- **Profile** - draggable hand-drawn goal sliders, badges and streaks.
- **Flowing transitions** - screens drift in like lily pads (rise + fade).
- **Handwritten typography** - Caveat and Gochi Hand are bundled in the app.

## Screens

Splash (the toad hops in) -> Home (pond dashboard) -> Motion / Water / Sleep / You.

## Getting started

Requires Flutter 3.22+ (any channel).

```bash
flutter pub get
flutter run
```

The Android platform folder is fully checked in, so `flutter build apk --release` works out of the box. For iOS or desktop run:

```bash
flutter create . --platforms ios
flutter run -d macos
```

### Build an APK

```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

## Workflows

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `flutter-ci.yml` | push / pull request | `flutter analyze` + debug APK build, uploads APK artifact |
| `release-apk.yml` | tag `v*` / manual | release APK build, attached to a GitHub Release |
| `gh-pages.yml` | push to main / manual | Flutter web build deployed to GitHub Pages |

Live web demo: <https://dukeoftoad.github.io/toadHEALTH/>

## Project layout

```
lib/
  main.dart            entry point
  app.dart             MaterialApp + flowing page transitions
  theme.dart           swamp-green palette + handwritten type styles
  sketchy.dart         the hand-drawn ink engine (wobbly lines, ellipses, blobs)
  toad_painter.dart    the toad mascot painter (5 poses, walk-cycle animated)
  icon_painter.dart    hand-drawn icon set incl. running / walking toad
  charts.dart          sketchy rings, bars, lines, pond, waves, Zzz, ripples
  widgets.dart         sketch cards, buttons, speech bubbles, stat tiles
  nav_shell.dart       app shell + the hopping-toad bottom navigation
  *_screen.dart        splash, home, activity, water, sleep, profile
```

## License

MIT - see [LICENSE](LICENSE).
