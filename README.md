# toadHEALTH

<p align="center">
  <img src="assets/images/banner.png" alt="toadHEALTH banner" width="820" />
</p>

<p align="center">
  <a href="https://github.com/dukeoftoad/toadHEALTH/actions/workflows/flutter-ci.yml"><img src="https://github.com/dukeoftoad/toadHEALTH/actions/workflows/flutter-ci.yml/badge.svg" alt="Flutter CI" /></a>
  <a href="https://github.com/dukeoftoad/toadHEALTH/actions/workflows/release-apk.yml"><img src="https://github.com/dukeoftoad/toadHEALTH/actions/workflows/release-apk.yml/badge.svg" alt="Release APK" /></a>
  <a href="https://github.com/dukeoftoad/toadHEALTH/actions/workflows/gh-pages.yml"><img src="https://github.com/dukeoftoad/toadHEALTH/actions/workflows/gh-pages.yml/badge.svg" alt="Web demo" /></a>
</p>

**toadHEALTH** is a hand-drawn, **local-first, end-to-end encrypted** health
companion built with Flutter - and the toad is not just a mascot, it is the
body of the app. The toad walks your dashboard, runs when you push yourself,
physically hops between navigation tabs, floats on its lily pad as you drink
water, and sleeps when you should be sleeping.

Every stroke in the UI is drawn at runtime by a wobbly-ink "sketchy" engine
built on `CustomPainter` - no static icon fonts, no stock vectors.

## Real encrypted backend (v1.1)

All simulated data is gone. The app now runs on a real, layered on-device
backend - see [ARCHITECTURE.md](ARCHITECTURE.md):

- **Real data** - steps come from the hardware step counter (AOSP
  `TYPE_STEP_COUNTER`, via our own ~150-line Kotlin channel - not Google Fit,
  not Health Connect, no Play Services). Water, sleep and goals are honest
  manual logs. Weekly charts, streaks, averages and the hourly rhythm are all
  computed from stored records.
- **Strong encryption** - every record lives in a single AES-256-GCM envelope.
  The master key is sealed by the **Android hardware Keystore** (non-exportable).
  Optional app password: PBKDF2-HMAC-SHA256, 250k iterations, per-credential salt.
- **Password restore** - a 120-bit recovery code (shown once at password
  creation) unwraps the master key and re-keys the password credential. No
  account, no email, no server.
- **Portable encrypted backups** - `TOAD1:` backup codes are pure ciphertext
  under your own passphrase. Store them anywhere.
- **Zero network** - the Android manifest declares **no INTERNET permission**;
  `allowBackup="false"` keeps the vault out of Google Drive backups.
  See [PRIVACY.md](PRIVACY.md) for the full de-Googling checklist and
  [SECURITY.md](SECURITY.md) for the threat model.

## The toad is the body of the app

- **Hand-drawn everything** - a deterministic ink-wobble engine powers every
  line, circle, blob, chart and icon.
- **The toad mascot** - five live-animated poses: idle, walk, run, sleep, cheer.
- **The launcher icon is the toad too** - a hand-inked *running toad* (mid
  gallop, speed lines, a little heart) stamped into every Android launcher
  density: legacy icons plus an adaptive foreground/background pair.
  Regenerate after artwork changes with `dart run flutter_launcher_icons`.
- **Toad navigation** - the bottom nav is a pond the toad hops across.
- **Pond Watch** - wire an Android smart watch (or any BLE heart-rate strap)
  straight onto the pond over the standard Bluetooth Heart Rate Profile -
  no Play Services, no Wear Data Layer, no network. The toad literally
  paces its run to your live heartbeat, beats becoming hops per minute.
- **Flowing transitions** - screens drift in like lily pads.
- **Handwritten typography** - Caveat and Gochi Hand bundled locally.

## Screens

Splash (toad hops in) -> Lock screen (if app password is set) -> Home pond ->
Motion / Water / Sleep / You (security, backups, data). Tap the Pond Watch
strip on Home to drift into the watch screen: scan the pond, pick your
buddy, and watch the toad jog to your heartbeats (a clearly-labelled demo
buddy is one tap away on emulators and web).

## Watch link (v1.2)

The smart-watch feature keeps the project's promises:

- **Standard profile, not a walled garden** - the native `WatchLink.kt`
  GATT client speaks the Bluetooth Heart Rate Service (`0x180D` ->
  `0x2A37`, BPM notifications) and Battery Service (`0x180F` -> `0x2A19`).
  Wear OS watches expose these while sharing their sensor; most BLE
  heart-rate straps always do.
- **Still de-Googled** - no Play Services dependency, no Wear Data Layer,
  and the manifest still has **no INTERNET permission**; BLE permissions
  carry `neverForLocation`.
- **Honest states** - scanning radar, hop-over handshake, live BPM ring,
  sparkline, battery, zone copy. Errors tell you what actually went wrong
  (permission, Bluetooth off, no heart-rate service).
- **Demo buddy** - one tap gives a clearly-labelled simulated heartbeat so
  emulators, web and reviewers can explore the full flow without hardware.

Regenerate the launcher toad after artwork changes:
`dart run flutter_launcher_icons`.

## Wear OS companion (v1.3)

The toad now hops onto the wrist: `android/wear` is a tiny **native Kotlin
companion app** (no Flutter engine on board) that mirrors your pond and
talks back.

- **Mirror the pond** - flip "Mirror pond to wrist" in the Pond Watch
  screen; steps, water glasses, sleep and the linked heart rate travel to
  the watch as compact snapshots over the Wear Data Layer, coalesced so
  step bursts stay calm.
- **The wrist is alive** - the companion draws the same hand-inked toad at
  runtime (blinking, breathing, hopping on goal quarters), shows big
  handwritten numbers in Caveat, and fits round and square watch faces.
- **Quick logs** - "+1 glass" on the wrist logs water on the phone; a ping
  on wrist wake pulls a fresh snapshot. A background listener keeps the
  last pond state warm so the companion opens instantly.
- **Opt-in and honest** - the mirror is off by default and the toggle is
  persisted in the encrypted vault. The Data Layer is a device-to-device
  transport between your phone and your watch; the phone app still declares
  **no INTERNET permission**. On de-Googled ROMs without Play Services the
  card reports "unsupported" and everything else keeps hopping.
- **The BLE heart-rate buddy stays** - Pond Watch's GATT link (below) is
  untouched; the two watch features are independent and complementary.

Install the companion: grab `toadHEALTH-wear.apk` from a Release and
`adb install` it on the watch (Wear OS 3+), then open it once and flip the
mirror toggle on the phone.

## Getting started

Requires Flutter 3.22+ (any channel).

```bash
flutter pub get
flutter run
```

The Android platform folder is fully checked in, so `flutter build apk
--release` works out of the box. For iOS run:

```bash
flutter create . --platforms ios
flutter run
```

### Build an APK

```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

## Workflows

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `flutter-ci.yml` | push / pull request | `flutter analyze` + debug APK builds (phone and wear), uploads both artifacts |
| `release-apk.yml` | tag `v*` / manual | release APK builds (phone + wear), attached to a GitHub Release |
| `gh-pages.yml` | push to main / manual | Flutter web (HTML renderer) deployed to GitHub Pages |

Live web demo: <https://dukeoftoad.github.io/toadHEALTH/>

## Project layout

```
lib/
  main.dart               entry point; boots the encrypted vault
  app.dart                MaterialApp + flowing page transitions
  splash.dart             boot screen; routes to lock screen or home
  core/                   crypto engine, platform channels, storage adapters
  data/                   models, encrypted repository, vault/key service
  state/                  AppController (source of truth), boot
  screens/                lock screen, manual log sheets
  ...                     sketchy engine, toad painter, icons, charts,
                          widgets, theme, nav shell, five screens
android/wear/            Wear OS companion module (native Kotlin wrist app)
```

## License

MIT - see [LICENSE](LICENSE).
