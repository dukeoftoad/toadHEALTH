import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to the Wear OS companion app (android/wear) over the Wear Data
/// Layer. Like [WatchLink], this is toadHEALTH's own channel - but unlike
/// the BLE heart-rate buddy, this one is a real companion app running on
/// the wrist: it mirrors pond snapshots and sends quick logs back.
///
/// Privacy: the Data Layer uses encrypted Bluetooth when available.
/// Google Play services can relay end-to-end-encrypted payloads through
/// Google-owned cloud servers when Bluetooth is unavailable. toadHEALTH
/// operates no backend of its own. Without Play Services the channel is
/// unsupported and every other part of the pond keeps hopping.
class WearOs {
  static const MethodChannel _channel = MethodChannel('toadhealth/wear_os');
  static const EventChannel _events = EventChannel('toadhealth/wear_os_events');

  static bool get isSupported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  /// True when Google Play Services carry the Data Layer on this phone.
  static Future<bool> playServicesAvailable() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mirrors a pond snapshot to every connected wrist. The payload is the
  /// map below; native side JSON-encodes it into the /toad/state message.
  static Future<bool> sendState(Map<String, Object?> state) async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'sendState',
            {'json': jsonEncode(state)},
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Clears the persisted snapshot on every watch running the companion.
  static Future<bool> clearState() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('clearState') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Wear events as maps:
  ///   {ev: nodes,   count}   - connected Data Layer nodes
  ///   {ev: wrist,   count}   - nodes wearing the toadHEALTH companion
  ///   {ev: command, json}    - a wrist command payload, e.g.
  ///                            {"action": "log_water", "glasses": 1}
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
