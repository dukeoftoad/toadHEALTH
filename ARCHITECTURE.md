# Architecture

toadHEALTH is a **local-first** health companion. There is no backend server,
no account system, and the Android build requests **no INTERNET permission at
all** - records physically cannot leave the device. "Real backend" here means
a real, layered, encrypted on-device backend, architected like a production
app rather than a demo.

## Principles

1. **Local-first** - the device is the source of truth. Nothing syncs, nothing phones home.
2. **Zero third-party trust** - no Firebase, no Google Play Services, no analytics, no ad SDKs. The only runtime dependency beyond Flutter is the pure-Dart `cryptography` package.
3. **Honest data** - every number on screen is measured (hardware step counter) or explicitly logged by the user. The only fake data is an opt-in, clearly-labelled, one-tap-erasable "demo pond".
4. **Hand-drawn everything** - all UI is painted at runtime by the sketchy ink engine; no icon fonts, no stock vectors.

## Layers

```
lib/
  main.dart                  entry point; starts the async boot
  app.dart                   MaterialApp + flowing page transitions
  splash.dart                boot screen; routes to LockScreen or HomeShell

  core/                      platform + crypto primitives
    vault_channel.dart       our own MethodChannel to Android Keystore
                             (seal / unseal / storageDir) - no plugins
    step_sensor.dart         our own EventChannel to Sensor.TYPE_STEP_COUNTER
                             (raw AOSP sensor - not Google Fit / Health Connect)
    watch_link.dart          our own channel to plain BLE GATT - the smart-watch
                             link (standard Heart Rate Profile 0x180D/0x2A37 +
                             Battery 0x180F/0x2A19; native side in WatchLink.kt)
    vault_crypto.dart        AES-256-GCM envelopes ("TAEG" framing),
                             PBKDF2-HMAC-SHA256 derivation, recovery codes
    vault_store.dart         storage abstraction + conditional export
    vault_store_io.dart      file store (app-private dir, atomic tmp+rename)
    vault_store_web.dart     localStorage store for the Pages demo

  data/                      the "backend"
    models.dart              VaultSettings, DayStat, HopEntry
    repository.dart          HealthRepository: days, samples, entries,
                             settings - JSON document, schema-versioned
    vault_service.dart       VaultService: DEK lifecycle, credentials,
                             lock/unlock/restore, encrypted backups

  state/
    app_controller.dart      AppController (ChangeNotifier): aggregates,
                             streaks, hourly buckets, debounced persistence,
                             plus the WatchController (watch link state machine)
    watch_controller.dart    watch connection states (off / scanning /
                             connecting / connected), BPM + battery buffers,
                             and the clearly-labelled demo buddy
    app_services.dart        boot orchestration + tiny service locator

  ui (lib root)              sketchy.dart, toad_painter.dart, icon_painter.dart,
                             charts.dart, widgets.dart, theme.dart,
                             nav_shell.dart, *_screen.dart
```

## Data flow

```
 hardware step counter (AOSP sensor)          user logging (sheets / taps)
              |                                          |
              +----------------> AppController <---------+
                                   |  debounced (2 s)
                                   v
                         HealthRepository
                          (JSON document: days / samples / entries / settings)
                                   | AES-256-GCM seal (TAEG envelope)
                                   v
                             VaultService
                          DEK unwrapped from a credential
                                   v
                       VaultStore (file / localStorage)
```

Reads flow the same way: boot -> vault.init -> (unlock) -> repo.load ->
AppController.refresh -> ValueNotifiers + notifyListeners -> screens.

## Encryption envelope

```
plaintext JSON
   |
   v
AES-256-GCM(key = DEK, nonce = 12 random bytes)
   |
   v
[ 'T' 'A' 'E' 'G' ][ ver:1 ][ nonce:12 ][ ciphertext ][ tag:16 ]
```

The DEK is never stored raw on Android: it is wrapped (sealed) by a key that
lives inside the hardware Keystore (`toadhealth_master`, AES-256-GCM, key
material non-exportable). Optional password and recovery credentials wrap the
same DEK under PBKDF2-derived keys, stored in `vault_meta.json` (which itself
contains no plaintext secrets - only salts, iteration counts and wrapped
blobs).

## Architecture decision records (short form)

- **ADR-1: no backend server.** The user asked for privacy and no Google; the
  strongest possible version of that is an app that cannot make network calls
  at all. Portability is provided by user-owned encrypted backups instead of
  a cloud account.
- **ADR-2: envelope encryption with hardware backing.** DEK sealed by the
  Android Keystore. On platforms without a hardware vault (web demo) the mode
  is *documented degraded*, never silently pretended secure.
- **ADR-3: PBKDF2-HMAC-SHA256, 250k iterations, per-credential salt.**
  Parameters are stored with each credential so they can be strengthened in
  later versions without breaking existing vaults. (Pure-Dart budget chosen
  to stay under ~1 s unlock on mid-range phones.)
- **ADR-4: recovery code instead of "forgot password" email.** A 120-bit
  base32 code shown once at password creation; it unwraps the same DEK and
  re-keys the password credential. No server, no email, no identity.
- **ADR-5: hand-written platform channels, not plugins.** Step counter and
  Keystore live in one Kotlin file (~150 lines) inside MainActivity. This
  keeps the dependency surface at exactly one pure-Dart package and makes the
  privacy audit trivial.
- **ADR-6: JSON vault document with schema version.** A health tracker's data
  volume (KBs per year) does not justify SQLCipher's native footprint for
  v1.1; the repository interface is the seam where SQL/remote backends can
  slot in later without touching the UI.
- **ADR-7: debounced atomic persistence.** Writes are batched (2 s) and
  land via tmp+rename so a crash mid-write can never corrupt the vault.
- **ADR-8: honest degradation.** No sensor -> manual logging with an empty
  state that says so. No web hardware vault -> demo banner says what is
  weaker. The app never fakes data to look alive.
- **ADR-9: watch link over plain BLE GATT, not Google's Wear Data Layer.**
  Wiring an Android smart watch without surrendering the zero-Play-Services
  promise means speaking the standard Bluetooth Heart Rate Profile
  (service 0x180D / measurement 0x2A37, battery 0x180F/0x2A19) from our own
  Kotlin GATT client (WatchLink.kt, ~300 lines). Wear OS watches and ordinary
  BLE heart-rate straps both expose these characteristics. Readings flow as
  EventChannel events into the WatchController state machine; a one-tap,
  clearly-labelled demo buddy covers emulators and the web build. Heartbeat
  samples are session-only and are never persisted into the vault.

## Extending

- Swap the storage backend: implement `VaultStore` (e.g. SQLCipher) - nothing above the seam changes.
- Add metrics: extend the day record + repository helpers; charts/controllers pick it up.
- Raise KDF strength: bump `kdfIterations`; old credentials keep their stored parameters and new ones use the new value.
