import 'package:flutter/foundation.dart';

import 'data/models.dart';
import 'state/app_controller.dart';

/// Compatibility facade over the live [AppController].
///
/// Before v1.1 this file held simulated data; now every value is REAL,
/// persisted in the AES-256-GCM encrypted on-device vault and fed by the
/// hardware step sensor where available. Screens keep their existing
/// `HealthData.x` call sites; the plumbing below simply delegates.

String fmtNumber(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final rem = s.length - i;
    b.write(s[i]);
    if (rem > 1 && rem % 3 == 1) {
      b.write(',');
    }
  }
  return b.toString();
}

String fmtDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

class HealthData {
  static AppController? _c;

  static void attach(AppController c) => _c = c;

  static AppController get controller {
    assert(_c != null, 'AppController not attached yet');
    return _c!;
  }

  static bool get ready => _c != null;

  static ValueNotifier<int> get steps => controller.stepsN;
  static ValueNotifier<int> get water => controller.waterN;

  static int get stepsGoal => controller.settings.stepsGoal;
  static int get waterGoal => controller.settings.waterGoal;
  static int get sleepGoalMin => controller.settings.sleepGoalMin;

  static List<double> get weekSteps => controller.weekSteps;
  static List<double> get weekSleep => controller.weekSleep;
  static List<int> get weekSleepMinutes => controller.weekSleepMinutes;
  static List<double> get hourly => controller.hourly;
  static List<String> get weekLabels => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static int get streakDays => controller.streakDays;
  static int get avgSteps7 => controller.avgSteps7;
  static int get todaySleepMin => controller.todaySleepMin;
  static List<HopEntry> get recentHops => controller.recentHops;

  static bool get firstRunDone => controller.settings.firstRunDone;
  static bool get demoData => controller.settings.demoData;

  static const List<String> tips = [
    'Drink a glass of water before every meal. Ribbit.',
    'Stretch like a lily pad in the sun - five minutes counts.',
    'Hop outside! Ten minutes of green time lifts the whole pond.',
    'Sleep is the pond where tomorrow grows. Aim for eight hours.',
    'Small hops beat giant leaps. Start with five minutes.',
    'Breathe in for four counts, out for six. Stay floaty.',
  ];
}
