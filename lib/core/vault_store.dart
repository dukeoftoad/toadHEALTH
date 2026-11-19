export 'vault_store_io.dart' if (dart.library.html) 'vault_store_web.dart';

/// Where the encrypted vault lives.
///
/// - Native (Android): private files dir, atomic tmp+rename writes.
/// - Web (GitHub Pages demo): browser localStorage. Everything written is
///   already AES-256-GCM ciphertext, so the browser only ever holds sealed
///   blobs (see SECURITY.md for the honest limitations of browser mode).
abstract class VaultStore {
  Future<String?> readText(String name);
  Future<void> writeText(String name, String content);
  Future<void> delete(String name);
}
