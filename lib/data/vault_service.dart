import 'dart:convert';
import 'dart:typed_data';

import '../core/vault_channel.dart';
import '../core/vault_crypto.dart';
import '../core/vault_store.dart';

/// Key lifecycle for the toadHEALTH vault.
///
/// Architecture (envelope encryption):
///
///   DEK  - 32 random bytes, encrypts the health database (AES-256-GCM)
///   device credential    - DEK wrapped by the Android Keystore hardware key
///   password credential  - DEK wrapped by PBKDF2-HMAC-SHA256(app password)
///   recovery credential  - DEK wrapped by PBKDF2-HMAC-SHA256(recovery code)
///
/// Losing your password? The recovery code unwraps the same DEK and lets
/// you set a new password - that is password restore, without any server,
/// without any account, without anything leaving the device.
class VaultService {
  VaultStore? _store;
  Map<String, dynamic> _meta = {};
  Uint8List? _dek;

  bool unlocked = false;
  bool needsUnlock = false;

  bool get hasPassword => _meta['password'] != null;
  bool get hasRecovery => _meta['recovery'] != null;
  bool get ready => unlocked && _dek != null;

  /// PBKDF2 iterations. Stored per credential in the vault metadata so it
  /// can be raised in future releases without breaking existing vaults.
  static const int kdfIterations = 250000;

  Future<void> init() async {
    _store = await createDefaultStore();
    final raw = await _store?.readText('vault_meta.json');
    if (raw == null) {
      await _createFresh();
      return;
    }
    try {
      _meta = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      await _createFresh();
      return;
    }
    if (_meta['password'] != null) {
      needsUnlock = true;
      unlocked = false;
    } else {
      unlocked = await unlockWithDevice();
      needsUnlock = !unlocked;
    }
  }

  Future<void> _createFresh() async {
    _dek = randomBytes(32);
    _meta = {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'device': null,
      'password': null,
      'recovery': null,
    };
    await _wrapDeviceCredential();
    await _saveMeta();
    unlocked = true;
    needsUnlock = false;
  }

  Future<void> _wrapDeviceCredential() async {
    final dek = _dek!;
    final sealed = await VaultChannel.seal(dek);
    if (sealed != null) {
      _meta['device'] = {'kind': 'keystore', 'wrapped': encodeB64(sealed)};
    } else {
      // No hardware vault on this platform (web demo / desktop debug).
      // The raw key lives beside the ciphertext it opens - an honest,
      // documented degraded mode. SECURITY.md covers the trade-off.
      _meta['device'] = {'kind': 'raw', 'wrapped': encodeB64(dek)};
    }
  }

  Future<Uint8List?> _unwrapDeviceCredential() async {
    final cred = _meta['device'];
    if (cred == null) return null;
    final c = (cred as Map).cast<String, dynamic>();
    final wrapped = decodeB64(c['wrapped'] as String);
    if (c['kind'] == 'keystore') {
      return await VaultChannel.unseal(wrapped);
    }
    return wrapped;
  }

  Future<Map<String, dynamic>> _wrapWithSecret(String secret) async {
    final salt = randomBytes(16);
    final kek = await deriveKey(secret, salt, kdfIterations);
    final sealed = await sealBytes(_dek!, kek);
    return {
      'salt': encodeB64(salt),
      'iterations': kdfIterations,
      'wrapped': encodeB64(sealed),
    };
  }

  Future<Uint8List?> _unwrapWithSecret(
    Map<String, dynamic> cred,
    String secret,
  ) async {
    try {
      final salt = decodeB64(cred['salt'] as String);
      final iters = (cred['iterations'] as num?)?.toInt() ?? kdfIterations;
      final kek = await deriveKey(secret, salt, iters);
      return await openBytes(decodeB64(cred['wrapped'] as String), kek);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveMeta() async {
    await _store?.writeText('vault_meta.json', jsonEncode(_meta));
  }

  // ---------- unlock paths ----------

  Future<bool> unlockWithDevice() async {
    try {
      final dek = await _unwrapDeviceCredential();
      if (dek == null || dek.length != 32) return false;
      _dek = dek;
      unlocked = true;
      needsUnlock = false;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlockWithPassword(String password) async {
    final cred = _meta['password'];
    if (cred == null) return false;
    final dek = await _unwrapWithSecret(
      (cred as Map).cast<String, dynamic>(),
      password,
    );
    if (dek == null) return false;
    _dek = dek;
    unlocked = true;
    needsUnlock = false;
    return true;
  }

  /// Password restore: recovery code unwraps the DEK, then the password
  /// credential is re-wrapped under the new password.
  Future<bool> restoreWithRecoveryCode(String code, String newPassword) async {
    final cred = _meta['recovery'];
    if (cred == null) return false;
    final normalized = normalizeRecoveryCode(code);
    final dek = await _unwrapWithSecret(
      (cred as Map).cast<String, dynamic>(),
      normalized,
    );
    if (dek == null) return false;
    _dek = dek;
    unlocked = true;
    needsUnlock = false;
    _meta['password'] = await _wrapWithSecret(newPassword);
    await _saveMeta();
    return true;
  }

  // ---------- credential management ----------

  /// Requires an unlocked vault. Returns the recovery code (shown once).
  Future<String> setPassword(String password) async {
    if (!ready) {
      throw StateError('vault is locked');
    }
    final recovery = newRecoveryCode();
    _meta['password'] = await _wrapWithSecret(password);
    _meta['recovery'] = await _wrapWithSecret(normalizeRecoveryCode(recovery));
    await _saveMeta();
    return recovery;
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final cred = _meta['password'];
    if (cred == null) return false;
    final dek = await _unwrapWithSecret(
      (cred as Map).cast<String, dynamic>(),
      oldPassword,
    );
    if (dek == null) return false;
    _meta['password'] = await _wrapWithSecret(newPassword);
    await _saveMeta();
    return true;
  }

  Future<void> clearPassword() async {
    if (!ready) {
      throw StateError('vault is locked');
    }
    _meta['password'] = null;
    _meta['recovery'] = null;
    await _wrapDeviceCredential();
    await _saveMeta();
  }

  // ---------- vault data (sealed with the DEK) ----------

  Future<String?> readData() async {
    if (!ready) return null;
    final b64 = await _store?.readText('vault_data.taeg');
    if (b64 == null) return null;
    final plain = await openBytes(decodeB64(b64), _dek!);
    if (plain == null) return null;
    return utf8.decode(plain);
  }

  Future<void> writeData(String json) async {
    if (!ready) return;
    final sealed = await sealBytes(utf8Bytes(json), _dek!);
    await _store?.writeText('vault_data.taeg', encodeB64(sealed));
  }

  Future<void> wipeEverything() async {
    await _store?.delete('vault_data.taeg');
    await _store?.delete('vault_meta.json');
    _meta = {};
    _dek = null;
    unlocked = false;
    await init();
  }

  // ---------- portable encrypted backups ----------

  /// Format: TOAD1:<base64>[salt:16][TAEG envelope]. The passphrase never
  /// touches disk; the backup is useless without it.
  Future<String> exportBackup(String passphrase, String vaultJson) async {
    final salt = randomBytes(16);
    final kek = await deriveKey(passphrase, salt, kdfIterations);
    final sealed = await sealBytes(utf8Bytes(vaultJson), kek);
    final payload = _concat([salt, sealed]);
    return 'TOAD1:${encodeB64(payload)}';
  }

  Future<String?> importBackup(String backupCode, String passphrase) async {
    final s = backupCode.trim();
    if (!s.startsWith('TOAD1:')) return null;
    try {
      final payload = decodeB64(s.substring(6));
      if (payload.length < 16 + 33) return null;
      final salt = Uint8List.sublistView(payload, 0, 16);
      final sealed = Uint8List.sublistView(payload, 16);
      final kek = await deriveKey(passphrase, salt, kdfIterations);
      final plain = await openBytes(sealed, kek);
      if (plain == null) return null;
      return utf8.decode(plain);
    } catch (_) {
      return null;
    }
  }
}

Uint8List _concat(List<List<int>> parts) {
  var total = 0;
  for (final p in parts) {
    total += p.length;
  }
  final out = Uint8List(total);
  var i = 0;
  for (final p in parts) {
    out.setRange(i, i + p.length, p);
    i += p.length;
  }
  return out;
}
