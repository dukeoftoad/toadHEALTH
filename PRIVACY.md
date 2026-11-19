# Privacy

toadHEALTH is built privacy-first. This is the full checklist - not marketing,
but verifiable properties of the code in this repository.

## What this app does NOT do

| Claim | How it is enforced |
| --- | --- |
| No data sent to Google | No Firebase, no Google Play Services, no Health Connect, no Google Fit, no reCAPTCHA, no Crashlytics. The only runtime dependency is the pure-Dart `cryptography` package. |
| No data sent anywhere | The Android manifest declares **no `INTERNET` permission** - the OS prevents the app from opening network sockets at all. |
| No analytics / telemetry | None present. Nothing to opt out of. |
| No Android cloud backup of your records | `android:allowBackup="false"` - the vault is excluded from Google Drive device backup and device-transfer. |
| No third-party plugins with hidden network calls | Step counter and Keystore are **our own ~150-line Kotlin channels** in `MainActivity.kt` (AOSP sensor API + Android Keystore). The dependency audit is one file long. |
| No font CDNs | Caveat and Gochi Hand are bundled as local assets. |
| No external CDNs on web | The Pages demo builds with the HTML renderer (`--web-renderer html`), avoiding external WASM/font fetches. |
| No identifiers | No advertising ID, no device fingerprinting, no account system. |

## What this app DOES do

- Reads the hardware step counter sensor (AOSP `Sensor.TYPE_STEP_COUNTER`) -
  a local OS API that involves no company.
- Stores every record only on the device, encrypted with AES-256-GCM.
- Lets you export an encrypted backup that only your passphrase can open.
- Lets you erase everything and re-key the vault in one tap.

## Permissions (Android)

- Runtime permissions: **none**.
- `INTERNET`: **not declared** - network access is impossible.
- Step counter sensor: normal-protection-level sensor, no permission prompt,
  no Play Services involvement.

## Data location

| Platform | Location |
| --- | --- |
| Android | App-private `filesDir` (encrypted, no cloud backup) |
| Web demo | Browser localStorage (encrypted blobs; degraded mode, see SECURITY.md) |

## Third-party list

1. `cryptography` (pub.dev, pure Dart) - AES-GCM and PBKDF2 implementations.
   No network, no telemetry.
2. Flutter SDK / build tooling - compiles the app; ships no runtime telemetry
   of ours (Flutter's own analytics are a CLI-side, opt-out tool concern and
   are not part of the built app).

That is the entire external surface.
