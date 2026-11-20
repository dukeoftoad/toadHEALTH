import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/wear_os.dart';

enum WearOsStatus { unknown, unsupported, idle, wristReady }

/// Owns the Wear OS companion state: whether this phone can speak the Data
/// Layer, how many wrists wear the toad, and the throttled mirroring of
/// pond snapshots. Wrist commands are decoded here and handed to the app
/// through [onCommand] (the controller stays storage-agnostic).
class WearOsController extends ChangeNotifier {
  WearOsStatus status = WearOsStatus.unknown;
  int wrists = 0;
  String? lastCommand;
  DateTime? lastCommandAt;

  /// Wrist commands: "log_water" applies the glass, "ping" refreshes.
  void Function(String action, Map<String, Object?> args)? onCommand;

  StreamSubscription<Map<Object?, Object?>>? _sub;
  bool _listening = false;

  // Mirroring bookkeeping: snapshots are coalesced so a burst of sensor
  // events (each step!) still lands on the wrist at a calm cadence.
  Map<String, Object?>? _pending;
  Timer? _flush;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  static const _minInterval = Duration(milliseconds: 900);

  bool get wristLinked => status == WearOsStatus.wristReady && wrists > 0;

  /// Starts the event pipe once; harmless before unlock and on web/desktop.
  void ensureListener() {
    if (_listening || !WearOs.isSupported) return;
    final stream = WearOs.listen();
    if (stream == null) return;
    _listening = true;
    _sub = stream.listen(_onEvent, onError: (_) {});
    WearOs.playServicesAvailable().then((ok) {
      if (!ok) status = WearOsStatus.unsupported;
      notifyListeners();
    });
  }

  void _onEvent(Map<Object?, Object?> event) {
    switch (event['ev']) {
      case 'nodes':
        wrists = (event['count'] as num?)?.toInt() ?? wrists;
        _bumpStatus();
        break;
      case 'wrist':
        wrists = (event['count'] as num?)?.toInt() ?? 0;
        _bumpStatus();
        break;
      case 'command':
        _handleCommand(event['json'] as String?);
        break;
    }
    notifyListeners();
  }

  void _bumpStatus() {
    if (status == WearOsStatus.unsupported) return;
    status = wrists > 0 ? WearOsStatus.wristReady : WearOsStatus.idle;
  }

  void _handleCommand(String? raw) {
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final action = (decoded['action'] as String?) ?? '';
      if (action.isEmpty) return;
      lastCommand = action;
      lastCommandAt = DateTime.now();
      onCommand?.call(
        action,
        Map<String, Object?>.from(decoded as Map<Object?, Object?>),
      );
    } catch (_) {
      // Malformed wrist payload - ignore, the pond stays calm.
    }
  }

  /// Queues a pond snapshot for the wrist; coalesced and throttled.
  void mirror(Map<String, Object?> snapshot) {
    if (status == WearOsStatus.unsupported || !WearOs.isSupported) return;
    _pending = snapshot;
    final elapsed = DateTime.now().difference(_lastSent);
    if (elapsed >= _minInterval) {
      _send();
    } else {
      _flush ??= Timer(_minInterval - elapsed, _send);
    }
  }

  void _send() {
    _flush?.cancel();
    _flush = null;
    final payload = _pending;
    _pending = null;
    if (payload == null) return;
    _lastSent = DateTime.now();
    WearOs.sendState(payload);
  }

  /// One-shot immediate push (used after unlocking / toggling the mirror).
  void mirrorNow(Map<String, Object?> snapshot) {
    _pending = snapshot;
    _send();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _flush?.cancel();
    super.dispose();
  }
}
