import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to the native hardware key vault (Android Keystore) and the app's
/// private storage directory.
///
class VaultChannel {
  static const MethodChannel _channel = MethodChannel('toadhealth/vault');

  static bool get isSupported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  /// App-private files directory (outside any cloud backup).
  static Future<String?> storageDir() async {
    if (!isSupported) return null;
    try {
      return await _channel.invokeMethod<String>('storageDir');
    } catch (_) {
      return null;
    }
  }

  /// Seal bytes with the hardware-backed AES-256-GCM key.
  /// Format: [version:1][iv:12][ciphertext+tag].
  static Future<Uint8List?> seal(Uint8List plain) async {
    if (!isSupported) return null;
    try {
      return await _channel.invokeMethod<Uint8List>('encrypt', {'plain': plain});
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> unseal(Uint8List sealed) async {
    if (!isSupported) return null;
    try {
      return await _channel.invokeMethod<Uint8List>('decrypt', {'sealed': sealed});
    } catch (_) {
      return null;
    }
  }
}
