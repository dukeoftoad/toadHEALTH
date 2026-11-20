# Android release signing

The phone APK and Wear OS companion must be signed with the **same persistent
certificate** so the Wear Data Layer can authenticate the pair. Do not sign
release builds with Gradle's debug key, and never commit the keystore or its
passwords to the repository.

## Create and back up the keystore

Create a long-lived release keystore in a secure location:

```sh
keytool -genkeypair -v \
  -keystore toadhealth-release.jks \
  -alias toadhealth \
  -keyalg RSA -keysize 4096 -validity 10000
```

Back up the keystore and its passwords securely. Losing this key can prevent
updates from being signed as the same app identity.

## Configure GitHub Actions

Add these repository Actions secrets (Settings → Secrets and variables →
Actions → Repository secrets):

- `TOADHEALTH_RELEASE_KEYSTORE_BASE64`: base64 encoding of the complete
  keystore file (on Linux: `base64 -w0 toadhealth-release.jks`).
- `TOADHEALTH_RELEASE_STORE_PASSWORD`: keystore password.
- `TOADHEALTH_RELEASE_KEY_ALIAS`: key alias (for the command above,
  `toadhealth`).
- `TOADHEALTH_RELEASE_KEY_PASSWORD`: private-key password.

The release workflow decodes the keystore into the runner's temporary
directory and configures the same signing identity for both Gradle modules.
The file is not retained as a repository artifact. The workflow stops before
building if any required secret is missing.

Local release builds can use the same four values as environment variables,
plus `TOADHEALTH_RELEASE_STORE_FILE` pointing to the local keystore path.
Without the complete configuration, Gradle produces unsigned release
variants; debug builds continue to work normally.
