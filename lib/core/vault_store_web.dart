// Web adapter for the GitHub Pages demo.
// The browser's localStorage only ever holds AES-256-GCM ciphertext
// (vault metadata holds wrapped keys, never raw key material, unless no
// hardware vault exists - see SECURITY.md "web demo mode").
import 'dart:html' as html;

import 'vault_store.dart';

class WebVaultStore implements VaultStore {
  static const String _prefix = 'toadhealth.';

  String _key(String name) => '$_prefix$name';

  static Future<VaultStore> createDefaultStore() async {
    return WebVaultStore();
  }

  @override
  Future<String?> readText(String name) async {
    return html.window.localStorage[_key(name)];
  }

  @override
  Future<void> writeText(String name, String content) async {
    html.window.localStorage[_key(name)] = content;
  }

  @override
  Future<void> delete(String name) async {
    html.window.localStorage.remove(_key(name));
  }
}
