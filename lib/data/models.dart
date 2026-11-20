import '../icon_painter.dart';

/// User-tunable settings persisted inside the encrypted vault.
class VaultSettings {
  int stepsGoal;
  int waterGoal;
  int sleepGoalMin;
  bool firstRunDone;
  bool demoData;

  /// Mirror the pond onto paired Wear OS wrists (feature/wear-os).
  bool wearMirror;

  VaultSettings({
    this.stepsGoal = 8000,
    this.waterGoal = 8,
    this.sleepGoalMin = 480,
    this.firstRunDone = false,
    this.demoData = false,
    this.wearMirror = false,
  });

  factory VaultSettings.fromMap(Map<String, dynamic> m) => VaultSettings(
        stepsGoal: (m['stepsGoal'] as num?)?.toInt() ?? 8000,
        waterGoal: (m['waterGoal'] as num?)?.toInt() ?? 8,
        sleepGoalMin: (m['sleepGoalMin'] as num?)?.toInt() ?? 480,
        firstRunDone: m['firstRunDone'] as bool? ?? false,
        demoData: m['demoData'] as bool? ?? false,
        wearMirror: m['wearMirror'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'stepsGoal': stepsGoal,
        'waterGoal': waterGoal,
        'sleepGoalMin': sleepGoalMin,
        'firstRunDone': firstRunDone,
        'demoData': demoData,
        'wearMirror': wearMirror,
      };
}

/// One immutable snapshot of a tracked day (used for week aggregates).
class DayStat {
  final String date;
  final int steps;
  final int water;
  final int sleepMin;

  const DayStat(this.date, this.steps, this.water, this.sleepMin);
}

/// A real user action recorded in the vault (activity feed).
class HopEntry {
  final DateTime ts;
  final String type; // steps | water | sleep | goal | security
  final String detail;

  const HopEntry(this.ts, this.type, this.detail);

  String get time =>
      '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

  String get label => detail;

  ToadIcon get icon {
    switch (type) {
      case 'water':
        return ToadIcon.drop;
      case 'sleep':
        return ToadIcon.moon;
      case 'goal':
        return ToadIcon.target;
      case 'security':
        return ToadIcon.sparkle;
      default:
        return ToadIcon.paws;
    }
  }
}
