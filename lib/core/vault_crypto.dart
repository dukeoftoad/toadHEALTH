import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// The toadHEALTH ink-and-iron crypto core.
///
/// - Data at rest: AES-256-GCM (authenticated encryption) envelopes.

const List<int> _magic = [0x54, 0x41, 0x45, 0x47]; // "TAEG"
const int _version = 1;
const int _nonceLength = 12;
const int _tagLength = 16;

final AesGcm _aes = AesGcm.with256bits();

Uint8List randomBytes(int length) {
  final rng = Random.secure();
  return Uint8List.fromList(
    List<int>.generate(length, (_) => rng.nextInt(256)),
  );
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

Uint8List utf8Bytes(String s) => Uint8List.fromList(utf8.encode(s));

/// PBKDF2-HMAC-SHA256 -> 256-bit key.
Future<Uint8List> deriveKey(String secret, Uint8List salt, int iterations) async {
  final kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  );
  final key = await kdf.deriveKeyFromPassword(password: secret, nonce: salt);
  return Uint8List.fromList(await key.extractBytes());
}

/// Encrypt + frame into the TAEG envelope.
Future<Uint8List> sealBytes(List<int> plain, Uint8List key) async {
  final nonce = randomBytes(_nonceLength);
  final box = await _aes.encrypt(
    plain,
    secretKey: SecretKey(key),
    nonce: nonce,
  );
  return _concat([
    _magic,
    [_version],
    nonce,
    box.cipherText,
    box.mac.bytes,
  ]);
}

/// Open a TAEG envelope. Returns null on any failure (wrong key, tampering,
/// bad frame) - callers treat null as "no / wrong data".
Future<Uint8List?> openBytes(Uint8List sealed, Uint8List key) async {
  try {
    final headerLength = _magic.length + 1 + _nonceLength;
    if (sealed.length < headerLength + _tagLength) return null;
    for (var i = 0; i < _magic.length; i++) {
      if (sealed[i] != _magic[i]) return null;
    }
    if (sealed[_magic.length] != _version) return null;
    final nonce = Uint8List.sublistView(
      sealed,
      _magic.length + 1,
      _magic.length + 1 + _nonceLength,
    );
    final rest = Uint8List.sublistView(sealed, headerLength);
    final cipherText = Uint8List.sublistView(rest, 0, rest.length - _tagLength);
    final mac = Mac(Uint8List.sublistView(rest, rest.length - _tagLength));
    final plain = await _aes.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: SecretKey(key),
    );
    return Uint8List.fromList(plain);
  } catch (_) {
    return null;
  }
}

String encodeB64(List<int> bytes) => base64Encode(bytes);

Uint8List decodeB64(String s) => Uint8List.fromList(base64Decode(s));

const String _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

/// 120-bit recovery code, rendered as 24 base32 characters in 4 groups.
/// Example: K7MQP2-VX4RGN-9TBJHD-3WYFZ6
String newRecoveryCode() {
  final bytes = randomBytes(15);
  var bits = 0;
  var value = 0;
  final out = StringBuffer();
  for (final b in bytes) {
    value = (value << 8) | b;
    bits += 8;
    while (bits >= 5) {
      out.write(_base32Alphabet[(value >> (bits - 5)) & 31]);
      bits -= 5;
    }
  }
  final raw = out.toString();
  return '${raw.substring(0, 6)}-${raw.substring(6, 12)}-'
      '${raw.substring(12, 18)}-${raw.substring(18, 24)}';
}

/// Uppercase and strip everything that is not part of the base32 alphabet,
/// so users can paste codes with or without dashes / spaces / lowercase.
String normalizeRecoveryCode(String input) {
  return input.toUpperCase().replaceAll(RegExp('[^A-Z2-7]'), '');
}
