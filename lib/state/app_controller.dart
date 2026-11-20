import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/step_sensor.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../data/vault_service.dart';
import 'watch_controller.dart';
import 'wear_os_controller.dart';

/// Single source of truth for the UI. Reads and writes REAL records through
/// [HealthRepository]; every change is persisted (debounced) into the
/// encrypted vault and pushed to listeners + ValueNotifiers.
class AppController extends ChangeNotifier {
  AppController(this._vault) : repo = HealthRepository(_vault);

  final VaultService _vault;
  final HealthRepository repo;

  /// Smart-watch link state (BLE GATT heart-rate buddy).
  final WatchController watch = WatchController();

  /// Wear OS companion state (Data Layer mirror + wrist commands).
  final WearOsController wearos = WearOsController();

  final ValueNotifier<int> stepsN = ValueNotifier<int>(0);
  final ValueNotifier<int> waterN = ValueNotifier<int>(0);

  List<double> weekSteps = List<double>.filled(7, 0);
  List<double> weekSleep = List<double>.filled(7, 0);
  List<int> weekSleepMinutes = List<int>.filled(7, 0);
  List<double> hourly = List<double>.filled(24, 0);
  int streakDays = 0;
  int avgSteps7 = 0;
  int todaySleepMin = 0;
  List<HopEntry> recentHops = const <HopEntry>[];

  StreamSubscription<int>? _sensorSub;
  int _lastSensorTotal = -1;
  Timer? _saveTimer;

  VaultSettings get settings => repo.settings;

  bool get hasData =>
      stepsN.value > 0 || waterN.value > 0 || todaySleepMin > 0;

  Future<void> load() async {
    await repo.load();
    refresh();
  }

  void refresh() {
    final today = repo.today(create: false);
    stepsN.value = (today['steps'] as num?)?.toInt() ?? 0;
    waterN.value = (today['water'] as num?)?.toInt() ?? 0;
    todaySleepMin = (today['sleepMin'] as num?)?.toInt() ?? 0;

    final week = repo.lastDays(7);
    weekSteps = [
      for (final d in week)
        (d.steps / settings.stepsGoal).clamp(0.0, 1.0).toDouble(),
    ];
    weekSleepMinutes = [for (final d in week) d.sleepMin];
    weekSleep = [
      for (final d in week)
        (d.sleepMin / settings.sleepGoalMin).clamp(0.0, 1.0).toDouble(),
    ];
    avgSteps7 = (week.fold<int>(0, (a, d) => a + d.steps) / 7).round();

    // Hourly rhythm from today's real step samples, normalised to the
    // busiest hour so the sketch chart shows the shape of the day.
    final key = HealthRepository.dayKey(DateTime.now());
    final samples = repo.samplesForDay(key);
    final perHour = List<int>.filled(24, 0);
    for (final s in samples) {
      final hour =
          DateTime.fromMillisecondsSinceEpoch((s['ts'] as num).toInt()).hour;
      perHour[hour] += (s['delta'] as num? ?? 0).toInt();
    }
    var maxHour = 0;
    for (final v in perHour) {
      if (v > maxHour) maxHour = v;
    }
    hourly = [for (final v in perHour) maxHour > 0 ? v / maxHour : 0.0];

    streakDays = _computeStreak();
    recentHops = repo.recentEntries(6);

    _mirrorToWrist();

    notifyListeners();
  }

  /// Mirrors the pond snapshot to paired Wear OS wrists (feature/wear-os).
  /// Only while the user's mirror toggle is on; coalesced inside the
  /// controller so step bursts stay calm on the wrist.
  void _mirrorToWrist() {
    if (!repo.settings.wearMirror) return;
    wearos.mirror({
      'steps': stepsN.value,
      'stepsGoal': repo.settings.stepsGoal,
      'water': waterN.value,
      'waterGoal': repo.settings.waterGoal,
      'sleepMin': todaySleepMin,
      'sleepGoalMin': repo.settings.sleepGoalMin,
      'hr': watch.bpm,
      'hrOn': watch.connected,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Wrist commands land here (wired by AppServices.boot).
  Future<void> handleWristCommand(
    String action,
    Map<String, Object?> args,
  ) async {
    // A delayed/in-flight Data Layer message must not mutate data after the
    // user has disabled the wrist mirror.
    if (!settings.wearMirror) return;
    switch (action) {
      case 'log_water':
        final glasses = ((args['glasses'] as num?)?.toInt() ?? 1).clamp(1, 5);
        await addWater(glasses);
        break;
      case 'ping':
        // The wrist wants a fresh snapshot: refresh re-mirrors.
        refresh();
        break;
    }
  }

  /// Toggles the wrist mirror (persisted with the rest of the vault).
  /// refresh() below queues the first snapshot for the wrist.
  Future<void> setWearMirror(bool on) async {
    if (!on) wearos.clearMirror();
    final s = settings..wearMirror = on;
    repo.settings = s;
    repo.addEntry('security', on ? 'wrist mirror on' : 'wrist mirror off');
    _touch();
    refresh();
  }

  /// A day counts toward the hop streak if any real activity was logged.
  int _computeStreak() {
    final now = DateTime.now();
    var streak = 0;
    for (var i = 0; i < 3650; i++) {
      final d = DateTime(now.year, now.month, now.day - i);
      final key = HealthRepository.dayKey(d);
      final active = repo.daySteps(key) >= 1000 ||
          repo.dayWater(key) >= 1 ||
          repo.daySleep(key) >= 300;
      if (active) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  void _touch() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      repo.save();
    });
  }

  // ---------- mutations (all persisted) ----------

  Future<void> addSteps(int delta, {bool manual = false}) async {
    if (delta <= 0) return;
    repo.addSteps(delta);
    repo.addSample(DateTime.now().millisecondsSinceEpoch, delta);
    if (manual) {
      repo.addEntry('steps', '+$delta hops (logged)');
    }
    _touch();
    refresh();
  }

  Future<void> addWater(int delta) async {
    final key = HealthRepository.dayKey(DateTime.now());
    final current = repo.dayWater(key);
    final next = current + delta;
    repo.setWater(next < 0 ? 0 : next);
    if (delta > 0) {
      repo.addEntry('water', '${next < 0 ? 0 : next} / ${settings.waterGoal} glasses');
    }
    _touch();
    refresh();
  }

  Future<void> logSleep(int minutes) async {
    repo.logSleep(minutes);
    final h = minutes ~/ 60;
    final m = minutes % 60;
    repo.addEntry('sleep', '${h}h ${m.toString().padLeft(2, '0')}m');
    _touch();
    refresh();
  }

  Future<void> updateGoals({
    int? stepsGoal,
    int? waterGoal,
    int? sleepGoalMin,
  }) async {
    final s = settings;
    s.stepsGoal = stepsGoal ?? s.stepsGoal;
    s.waterGoal = waterGoal ?? s.waterGoal;
    s.sleepGoalMin = sleepGoalMin ?? s.sleepGoalMin;
    repo.settings = s;
    repo.addEntry(
      'goal',
      '${s.stepsGoal} hops / ${s.waterGoal} glasses / '
      '${(s.sleepGoalMin / 60).toStringAsFixed(1)} h sleep',
    );
    _touch();
    refresh();
  }

  Future<void> markFirstRunDone() async {
    final s = settings..firstRunDone = true;
    repo.settings = s;
    await repo.save();
    refresh();
  }

  /// Fill 30 days of clearly-labelled pretend data so reviewers can explore
  /// the app without owning a pond. One tap to erase.
  Future<void> seedDemo() async {
    final now = DateTime.now();
    final rnd = Random(11);
    for (var i = 29; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day - i);
      final key = HealthRepository.dayKey(d);
      repo.upsertDay(
        key,
        steps: 2600 + rnd.nextInt(5600),
        water: 3 + rnd.nextInt(6),
        sleepMin: 360 + rnd.nextInt(160),
      );
    }
    repo.upsertDay(
      HealthRepository.dayKey(now),
      steps: 4382,
      water: 5,
      sleepMin: 440,
    );
    for (var h = 6; h <= 20; h += 2) {
      repo.addSample(
        DateTime(now.year, now.month, now.day, h).millisecondsSinceEpoch,
        200 + rnd.nextInt(600),
      );
    }
    final s = settings..demoData = true..firstRunDone = true;
    repo.settings = s;
    repo.addEntry('security', 'demo pond filled');
    await repo.save();
    refresh();
  }

  Future<bool> importBackup(String code, String passphrase) async {
    final json = await _vault.importBackup(code, passphrase);
    if (json == null) return false;
    try {
      repo.importJson(json);
    } on FormatException {
      return false;
    }
    await repo.save();
    refresh();
    return true;
  }

  Future<String> exportBackup(String passphrase) async {
    await repo.save();
    return await _vault.exportBackup(passphrase, repo.exportJson());
  }

  Future<void> wipeData() async {
    repo.reset();
    await _vault.wipeEverything();
    await repo.save();
    refresh();
  }

  // ---------- hardware sensor ----------

  Future<void> startSensor() async {
    final stream = StepSensor.listen();
    if (stream == null || _sensorSub != null) return;
    _sensorSub = stream.listen((total) {
      if (_lastSensorTotal < 0) {
        _lastSensorTotal = total;
        return;
      }
      final delta = total - _lastSensorTotal;
      _lastSensorTotal = total;
      if (delta > 0) {
        addSteps(delta);
      }
    }, onError: (_) {});
  }

  /// Keep the watch event pipe warm so a previously linked buddy's events
  /// (battery, disconnects) are seen even before the Pond Watch screen is
  /// opened. Harmless on platforms without the channel.
  void startWatchListener() {
    watch.ensureListener();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _sensorSub?.cancel();
    watch.dispose();
    wearos.dispose();
    stepsN.dispose();
    waterN.dispose();
    super.dispose();
  }
}
