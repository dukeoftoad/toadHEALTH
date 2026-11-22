# Privacy

toadHEALTH is built privacy-first. This is the full checklist - not marketing,
but verifiable properties of the code in this repository.

## What this app does NOT do

| Claim | How it is enforced |
| --- | --- |
| No first-party telemetry or health backend | No Firebase, no Health Connect, no Google Fit, no reCAPTCHA, no Crashlytics, and no toadHEALTH-operated server. The opt-in Wear OS companion does use Google Play services' Wear Data Layer, including its Google Cloud relay fallback described below. |
| No app-owned Internet client beyond the update check | The update flow is the app's one and only network path: a plain GET to `api.github.com/repos/dukeoftoad/toadHEALTH/releases/latest`, run on your "Check for updates" tap or once silently on app open. It sends nothing about the device, the vault or the health records, and nothing is ever uploaded. The Wear Data Layer relay below remains the only other network involvement, and it belongs to Google Play services, not toadHEALTH. |
| No analytics / telemetry | None present. Nothing to opt out of. |
| No Android cloud backup of your records | `android:allowBackup="false"` - the vault is excluded from Google Drive device backup and device-transfer. |
| No third-party plugins with hidden network calls | Step counter and Keystore are **our own ~150-line Kotlin channels** in `MainActivity.kt` (AOSP sensor API + Android Keystore). The dependency audit is one file long. |
| No font CDNs | Caveat and Gochi Hand are bundled as local assets. |
| No external CDNs on web | The Pages demo builds with the HTML renderer (`--web-renderer html`), avoiding external WASM/font fetches. |
| No identifiers | No advertising ID, no device fingerprinting, no account system. |

## What this app DOES do

- Checks GitHub for a newer release (v1.4): one plain GET to the repo's
  `releases/latest`, on your tap or once silently on app open - never
  periodically. Downloads the update APK only after you tap
  "Download & install". Nothing about the device is sent, stored or logged.
- Reads the hardware step counter sensor (AOSP `Sensor.TYPE_STEP_COUNTER`) -
  a local OS API that involves no company.
- Stores every record only on the device, encrypted with AES-256-GCM.
- Lets you export an encrypted backup that only your passphrase can open.
- Lets you erase everything and re-key the vault in one tap.
- Optionally (off by default, one toggle) mirrors steps / water / sleep /
  heart-rate snapshots to a paired Wear OS watch running the companion APK,
  and accepts explicit quick-log/ping commands back from the wrist. Watch
  snapshots are encrypted at rest with a watch-local Android Keystore AES-GCM
  key. Turning mirroring off sends a cache-clear command; an offline watch
  can only erase its local cache after it reconnects. The Wear Data Layer uses
  encrypted Bluetooth when available. If Bluetooth is unavailable, Google
  Play services can relay the payload through a Google-owned cloud node;
  Google documents that cloud path as end-to-end encrypted. The payload can
  therefore transit Google infrastructure even though toadHEALTH operates
  no backend server.

## The Wear OS companion (opt-in)

- Off by default: the mirror toggle lives in the Pond Watch screen and is
  persisted in the encrypted vault (`wearMirror`).
- Google-operated transport: the Wear Data Layer carries messages between
  your phone and watch. It uses encrypted Bluetooth when available. If
  Bluetooth is unavailable, Google Play services can relay the payload
  through Google-owned servers; Google documents this fallback as
  end-to-end encrypted. toadHEALTH does not operate that relay or its own
  backend, but the data may transit Google infrastructure.
- No-Googled-ROMs stay first-class: without Play Services the bridge reports
  "unsupported", the toggle is inert, and every other feature is untouched.
- The wear APK declares no `INTERNET` permission either.
- The last watch snapshot is stored as AES-GCM ciphertext using a watch-local
  Android Keystore key, not as plaintext preferences. Turning mirroring off
  writes an urgent, timestamp-only clear marker to the Wear Data Layer. Google
  buffers data items while devices are disconnected and syncs them on
  reconnection; the watch's timestamp watermark also rejects delayed
  pre-opt-out snapshot messages.

## Permissions (Android)

- Runtime permissions: **none**.
- `INTERNET`: not requested by the phone or Wear app source manifests.
  Google Play services may still use its own network permission and connection
  for the Wear Data Layer cloud relay described above.
- Step counter sensor: normal-protection-level sensor, no permission prompt,
  no Play Services involvement.
- Wear companion module: `WAKE_LOCK` (ambient display dimming only).

## Data location

| Platform | Location |
| --- | --- |
| Android | App-private `filesDir` (encrypted, no cloud backup) |
| Web demo | Browser localStorage (encrypted blobs; degraded mode, see SECURITY.md) |

## Third-party list

1. `cryptography` (pub.dev, pure Dart) - AES-GCM and PBKDF2 implementations.
   No network, no telemetry.
2. `play-services-wearable` (Google Maven, Android only) - the Wear Data
   Layer client for the opt-in wrist mirror. Google Play services transports
   messages over encrypted Bluetooth when available and may use an
   end-to-end-encrypted Google Cloud relay when it is not. No ads, analytics,
   or toadHEALTH-operated upload service are included; the mirror is off by
   default.
3. Flutter SDK / build tooling - compiles the app; ships no runtime telemetry
   of ours (Flutter's own analytics are a CLI-side, opt-out tool concern and
   are not part of the built app).

That is the entire external surface.
