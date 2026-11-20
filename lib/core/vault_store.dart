export 'vault_store_io.dart' if (dart.library.html) 'vault_store_web.dart';

/// Where the encrypted vault lives.
///
/// - Native (Android): private files dir, atomic tmp+rename writes.
abstract class VaultStore {
  Future<String?> readText(String name);
  Future<void> writeText(String name, String content);
  Future<void> delete(String name);
}
