import 'dart:io';

import 'vault_channel.dart';
import 'vault_store.dart';

/// File-backed store for native platforms. Uses the app-private directory
/// provided by our own channel (Android filesDir, excluded from cloud
/// backups via android:allowBackup="false"), falling back to a fixed
/// temp location on desktop debug builds.
class IoVaultStore implements VaultStore {
  IoVaultStore(this._dir);

  final Directory _dir;

  static Future<VaultStore> createDefaultStore() async {
    Directory dir;
    final path = await VaultChannel.storageDir();
    if (path != null && path.isNotEmpty) {
      dir = Directory(path);
    } else {
      dir = Directory(
          '${Directory.systemTemp.path}${Platform.pathSeparator}toadhealth_vault');
    }
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return IoVaultStore(dir);
  }

  File _file(String name) =>
      File('${_dir.path}${Platform.pathSeparator}$name');

  @override
  Future<String?> readText(String name) async {
    try {
      final f = _file(name);
      if (!f.existsSync()) return null;
      return f.readAsStringSync();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeText(String name, String content) async {
    try {
      final f = _file(name);
      final tmp = _file('$name.tmp');
      tmp.writeAsStringSync(content, flush: true);
      try {
        tmp.renameSync(f.path);
      } catch (_) {
        // Some filesystems refuse renames across paths; fall back to a
        // direct write (tiny files, risk window is microseconds).
        f.writeAsStringSync(content, flush: true);
        if (tmp.existsSync()) tmp.deleteSync();
      }
    } catch (_) {
      // Storage full or unavailable - keep the app alive; the next save
      // retries. The previous atomic copy on disk remains valid.
    }
  }

  @override
  Future<void> delete(String name) async {
    try {
      final f = _file(name);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {
      // ignore
    }
  }
}
