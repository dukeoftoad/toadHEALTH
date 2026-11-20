import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hardware step counter (Sensor.TYPE_STEP_COUNTER).
///
/// Implemented directly on the AOSP sensor stack in MainActivity.kt - NOT
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
