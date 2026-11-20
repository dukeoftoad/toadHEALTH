import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/watch_link.dart';

enum WatchLinkState { off, scanning, connecting, connected }

/// A buddy discovered during a scan.
class WatchDevice {
  final String name;
  final String address;
  final int rssi;

  const WatchDevice({required this.name, required this.address, required this.rssi});

  @override
  bool operator ==(Object other) =>
      other is WatchDevice && other.address == address;

  @override
  int get hashCode => address.hashCode;
}

/// Owns the smart-watch connection state machine and the live readings the
/// UI draws. All real data arrives over [WatchLink]; a clearly-labelled
/// demo buddy ("Pond Buddy (demo)") keeps the pond lively on emulators,
/// web and desktop where BLE does not exist - same honest-demo approach as
/// the demo pond data.
class WatchController extends ChangeNotifier {
  WatchLinkState state = WatchLinkState.off;
  List<WatchDevice> devices = <WatchDevice>[];
  WatchDevice? device;
  int bpm = 0;
  int battery = -1;
  bool demoMode = false;
  String? error;

  /// Latest heart-rate samples (oldest first), capped for the sparkline.
  final List<int> bpmHistory = <int>[];

  StreamSubscription<Map<Object?, Object?>>? _sub;
  Timer? _demoTimer;
  final math.Random _rnd = math.Random();
  double _demoPhase = 0;

  bool get busy =>
      state == WatchLinkState.scanning || state == WatchLinkState.connecting;

  bool get connected => state == WatchLinkState.connected;

  void ensureListener() {
    if (_sub != null) return;
    final stream = WatchLink.listen();
    if (stream == null) return;
    _sub = stream.listen(_onEvent, onError: (_) {});
  }

  void _onEvent(Map<Object?, Object?> event) {
    switch (event['ev']) {
      case 'state':
        final value = event['value'] as String?;
        switch (value) {
          case 'scanning':
            state = WatchLinkState.scanning;
            break;
          case 'connecting':
            state = WatchLinkState.connecting;
            break;
          case 'connected':
            state = WatchLinkState.connected;
            error = null;
            bpmHistory.clear();
            break;
          default:
            state = WatchLinkState.off;
        }
        break;
      case 'device':
        final address = event['address'] as String?;
        if (address == null) break;
        final found = WatchDevice(
          name: (event['name'] as String?) ?? 'Unnamed buddy',
          address: address,
          rssi: (event['rssi'] as num?)?.toInt() ?? -200,
        );
        final index = devices.indexOf(found);
        if (index >= 0) {
          devices[index] = found;
        } else {
          devices.add(found);
        }
        devices.sort((a, b) => b.rssi.compareTo(a.rssi));
        if (devices.length > 12) devices.removeRange(12, devices.length);
        break;
      case 'hr':
        final value = (event['bpm'] as num?)?.toInt() ?? 0;
        if (value > 0) {
          bpm = value;
          _push(value);
        }
        break;
      case 'battery':
        final level = (event['level'] as num?)?.toInt() ?? -1;
        if (level >= 0) battery = level;
        break;
      case 'error':
        final code = event['code'] as String?;
        if (state == WatchLinkState.scanning || state == WatchLinkState.connecting) {
          state = WatchLinkState.off;
        }
        error = code;
        break;
    }
    notifyListeners();
  }

  // ---------- user actions ----------

  Future<void> startScan() async {
    error = null;
    devices = <WatchDevice>[];
    notifyListeners();
    ensureListener();
    if (!WatchLink.isSupported) {
      // No BLE here (web demo / desktop): hop straight to the demo buddy.
      startDemo();
      return;
    }
    final granted = await WatchLink.requestPermissions();
    if (!granted) {
      error = 'perm';
      state = WatchLinkState.off;
      notifyListeners();
      return;
    }
    final started = await WatchLink.startScan();
    state = started ? WatchLinkState.scanning : WatchLinkState.off;
    if (!started) error = 'scan';
    notifyListeners();
  }

  Future<void> stopScan() async {
    await WatchLink.stopScan();
    if (state == WatchLinkState.scanning) {
      state = WatchLinkState.off;
      notifyListeners();
    }
  }

  Future<void> connect(WatchDevice target) async {
    await stopScan();
    if (target.address == 'demo:pond') {
      startDemo();
      return;
    }
    state = WatchLinkState.connecting;
    device = target;
    error = null;
    notifyListeners();
    ensureListener();
    final ok = await WatchLink.connect(target.address);
    if (!ok) {
      state = WatchLinkState.off;
      error = 'connect';
      notifyListeners();
    }
    // Success arrives through the `state: connected` event.
  }

  Future<void> disconnect() async {
    stopDemo();
    await WatchLink.disconnect();
    state = WatchLinkState.off;
    device = null;
    bpm = 0;
    battery = -1;
    bpmHistory.clear();
    notifyListeners();
  }

  /// Explicit "demo buddy" entry point for the watch screen.
  void startDemo() {
    stopScan();
    stopDemo();
    demoMode = true;
    error = null;
    device = const WatchDevice(
      name: 'Pond Buddy (demo)',
      address: 'demo:pond',
      rssi: -40,
    );
    state = WatchLinkState.connected;
    battery = 87;
    _demoPhase = _rnd.nextDouble() * 6;
    _demoTimer = Timer.periodic(const Duration(seconds: 1), (_) => _demoTick());
    _demoTick();
    notifyListeners();
  }

  void stopDemo() {
    _demoTimer?.cancel();
    _demoTimer = null;
    demoMode = false;
  }

  /// A gentle jog waveform with beat-to-beat variability, so the demo buddy
  /// feels alive instead of flat-lining on a magic constant.
  void _demoTick() {
    _demoPhase += 0.10 + _rnd.nextDouble() * 0.06;
    final wave = math.sin(_demoPhase * math.pi) * 16 +
        math.sin(_demoPhase * math.pi * 2.7) * 6 +
        (_rnd.nextDouble() - 0.5) * 6;
    bpm = (78 + wave).round().clamp(52, 148);
    _push(bpm);
    notifyListeners();
  }

  void _push(int value) {
    bpmHistory.add(value);
    if (bpmHistory.length > 90) bpmHistory.removeRange(0, bpmHistory.length - 90);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _demoTimer?.cancel();
    super.dispose();
  }
}
