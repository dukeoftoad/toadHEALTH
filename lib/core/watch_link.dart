import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to a smart watch over plain Android BLE (GATT).
///
/// Like [VaultChannel] and [StepSensor], this is toadHEALTH's OWN channel,
/// implemented in WatchLink.kt / MainActivity.kt: no third-party plugins,
/// no Google Play Services, no Wear Data Layer, no network. The watch only
/// has to speak the standard Bluetooth Heart Rate Profile:
///
///   Heart Rate Service     0x180D   (notify -> 0x2A37, BPM)
///   Battery Service        0x180F   (read   -> 0x2A19, percent)
///
/// Works with Wear OS watches while they expose the heart-rate service and
/// with ordinary BLE heart-rate straps. Returns null / false on platforms
/// without the channel (web demo, desktop) - the UI then offers the
/// clearly-labelled demo buddy instead of pretending.
class WatchLink {
  static const MethodChannel _channel = MethodChannel('toadhealth/watch');
  static const EventChannel _events = EventChannel('toadhealth/watch_events');

  static bool get isSupported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  /// True when a Bluetooth adapter is present and enabled.
  static Future<bool> isAvailable() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Asks for BLE permissions. False means "denied / unavailable".
  static Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('requestPermissions') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Starts a BLE scan. Emits `device` events on [_events] while running.
  static Future<bool> startScan() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('startScan') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> stopScan() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('stopScan');
    } catch (_) {}
  }

  static Future<bool> connect(String address) async {
    if (!isSupported) return false;
    try {
      return await _channel
              .invokeMethod<bool>('connect', {'address': address}) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> disconnect() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('disconnect');
    } catch (_) {}
  }

  /// Watch events as maps:
  ///   {ev: state,    value: scanning|connecting|connected|off}
  ///   {ev: device,   name, address, rssi}
  ///   {ev: hr,       bpm}
  ///   {ev: battery,  level}
  ///   {ev: error,    code: perm|bt_off|scan|connect|no_hr}
  static Stream<Map<Object?, Object?>>? listen() {
    if (!isSupported) return null;
    try {
      return _events.receiveBroadcastStream().map<Map<Object?, Object?>>(
        (event) => Map<Object?, Object?>.from(event as Map),
      );
    } catch (_) {
      return null;
    }
  }
}
