# toadHEALTH

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
- **No first-party backend** - toadHEALTH does not run a health-data
  server, and its phone/watch source manifests do not request
  **`INTERNET` permission**. The opt-in Wear OS Data Layer is provided by
  Google Play services: it uses encrypted Bluetooth when available and may
  relay end-to-end-encrypted payloads through Google-owned cloud servers when
  Bluetooth is unavailable. `allowBackup="false"` keeps the local vault out
  of Android backup. See [PRIVACY.md](PRIVACY.md) and [SECURITY.md](SECURITY.md).

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

## Appearance (v1.4)

The paper the toad is drawn on is a choice, in the You tab's new
Appearance page:

- **Sketchbook** - the native ink-on-paper: warm cream, swamp greens,
  the toadHEALTH original.
- **Toad** - toadPLAYER's crafted palette: deep moss green with warm
  earth accents, never follows the wallpaper.
- **Toadmark** - the frog-lime family brand: ink on warm paper in
  daylight, a frog-lime glow on deep ink at night.
- **System Material** - Material You: follows the wallpaper's colors on
  Android 12+ (read locally through `dynamic_color`, no network), toad
  green elsewhere.
- **Daylight** - follow the system, keep the paper bright, or sink to
  the night pond: deep moss surfaces with cream ink in every style.

The pick persists to a tiny plain JSON file in the app's private store
(no unlock needed - the theme is not health data), and the whole app -
charts, painters, hand-drawn cards and all - re-inks live because every
color flows through the active palette.

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
- **The BLE heart-rate path stays direct** - it uses no Play Services or
  Wear Data Layer and requests no Internet permission in the app manifest;
  BLE permissions carry `neverForLocation`. This is separate from the
  optional Wear OS companion described below, which uses Google's Data Layer
  and its documented encrypted cloud-relay fallback.
- **Honest states** - scanning radar, hop-over handshake, live BPM ring,
  sparkline, battery, zone copy. Errors tell you what actually went wrong
  (permission, Bluetooth off, no heart-rate service).
- **Demo buddy** - one tap gives a clearly-labelled simulated heartbeat so
  emulators, web and reviewers can explore the full flow without hardware.

Regenerate the launcher toad after artwork changes:
`dart run flutter_launcher_icons`.

## Release signing

Release APKs use one persistent Android keystore for both the phone and Wear
companion. The release workflow requires the repository secrets documented in
[RELEASE_SIGNING.md](RELEASE_SIGNING.md); it fails closed when they are absent.
Local release builds without those values are unsigned. Debug builds are
unaffected.

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
  persisted in the encrypted vault. The Wear Data Layer uses encrypted
  Bluetooth when available; if Bluetooth is unavailable, Google Play services
  can relay the payload through Google-owned cloud servers. Google documents
  that fallback as end-to-end encrypted. toadHEALTH runs no backend of its
  own, but mirrored data may transit Google infrastructure. On de-Googled
  ROMs without Play Services the card reports "unsupported".
- **The BLE heart-rate buddy stays** - Pond Watch's GATT link (below) is
  untouched; the two watch features are independent and complementary.

Install the companion: grab `toadHEALTH-wear.apk` from a Release and
`adb install` it on the watch (Wear OS 3+), then open it once and flip the
mirror toggle on the phone.

## Getting started

Requires Flutter 3.50+ stable. Android phone and Wear modules compile and target API 37 (AGP 9.3.1, Gradle 9.5.0, Java 17).

```bash
flutter pub get
flutter run
```

The Android platform folder is fully checked in. A local release build works
unsigned unless you provide the persistent release-keystore environment
variables in [RELEASE_SIGNING.md](RELEASE_SIGNING.md); never use the debug
certificate for a published APK. For iOS run:

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
