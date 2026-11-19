# Security

## What is protected

| Asset | Protection |
| --- | --- |
| Health records (days, samples, entries, settings) | AES-256-GCM (authenticated encryption), sealed as a single `vault_data.taeg` envelope |
| Master key (DEK) | 32 random bytes, never written raw on Android - sealed by the hardware Keystore key (`toadhealth_master`, AES-256-GCM, non-exportable) |
| App password | PBKDF2-HMAC-SHA256, 250,000 iterations, random 16-byte salt; only the wrapped DEK is stored |
| Recovery code | 120-bit base32 code; wraps the same DEK under its own PBKDF2 credential |
| Backups | `TOAD1:` payload = PBKDF2(passphrase) -> AES-256-GCM; passphrase never touches disk |
| Network egress | Impossible on Android: the manifest declares **no INTERNET permission**. No third-party SDKs exist in the binary. |

## Threat model (honest scope)

**Protected against:** casual device access, backup extraction (Android cloud
backup is disabled via `allowBackup="false"`), file-level exfiltration of the
app's data without the device key, and any form of network interception (there
is no network).

**Not protected against:** a rooted/compromised OS reading memory while the
vault is unlocked, a screen observer while you type the password, or someone
who has *both* your device and your recovery code. This is the same honest
scope as mainstream encrypted note apps.

## Password restore (no server involved)

1. When you set an app password the app shows a **recovery code** exactly once
   (`XXXXXX-XXXXXX-XXXXXX-XXXXXX`). Store it safely.
2. If you forget the password, the lock screen offers **"Forgot password?
   Restore access"**.
3. Enter the recovery code + a new password. The code unwraps the master key,
   the password credential is re-wrapped under the new password, and the data
   decrypts exactly as before.

Lost the code too? The data is unrecoverable by design - there is no escrow,
because there is no third party.

## Degraded modes (documented, never silent)

- **Web demo (GitHub Pages):** browsers have no hardware keychain we can use
  from pure Dart, so the master key is stored beside the ciphertext in
  localStorage. Everything is still AES-256-GCM encrypted at rest, but treat
  the demo as a convenience sandbox: use a password you do not reuse, or just
  play with the demo pond.
- **Desktop debug builds:** vault falls back to a temp directory with the
  device-credential mode above. Not for production use.

## Design details

- Vault metadata (`vault_meta.json`) stores: version, credential kinds,
  salts, iteration counts, wrapped keys. It contains no plaintext secrets.
- Wrong password / tampered data -> GCM tag mismatch -> open fails -> generic
  error, no oracle beyond "wrong".
- Unlock derives the key with the iteration count stored for *that*
  credential, so parameters can be raised in future releases without
  breaking old vaults.
- Persistence is atomic (tmp + rename); a crash mid-write cannot corrupt the
  vault.
- Erase everything deletes both files and generates a fresh DEK; old
  ciphertext on disk is gone with its key.

## Reporting

Found something? Open a GitHub issue on `dukeoftoad/toadHEALTH` describing the
weakness without proof-of-concept payloads in the title.
