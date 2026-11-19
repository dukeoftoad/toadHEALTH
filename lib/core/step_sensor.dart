import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hardware step counter (Sensor.TYPE_STEP_COUNTER).
///
/// Implemented directly on the AOSP sensor stack in MainActivity.kt - NOT
/// Google Fit, NOT Health Connect, no Play Services, no network. The stream
/// emits the raw cumulative step count since device boot; the app derives
/// per-event deltas so reboot baselines are handled safely.
///
/// Returns null on platforms without the channel (web demo, desktop) - the
/// app then relies on honest manual logging instead of pretending.
class StepSensor {
  static const EventChannel _channel = EventChannel('toadhealth/steps');

  static Stream<int>? listen() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return _channel
          .receiveBroadcastStream()
          .map<int>((event) => (event as num).toInt());
    } catch (_) {
      return null;
    }
  }
}
