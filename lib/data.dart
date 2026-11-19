import 'package:flutter/material.dart';

import 'icon_painter.dart';

/// Thousands separator for hand-written numbers.
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

/// Mock health data store. [steps] and [water] are live notifiers so screens
/// stay in sync (tap the toad on Home, watch the Water tile update).
class HealthData {
  static final ValueNotifier<int> steps = ValueNotifier<int>(4382);
  static final ValueNotifier<int> water = ValueNotifier<int>(5);

  static const int stepsGoal = 8000;
  static const int waterGoal = 8;
  static const int heartRate = 72;
  static const int energy = 1650;
  static const int streakDays = 12;

  static const List<double> weekSteps = [0.52, 0.74, 0.60, 0.90, 0.68, 0.86, 0.55];
  static const List<double> weekSleep = [0.90, 0.81, 0.98, 0.76, 1.00, 0.93, 0.92];
  static const List<String> weekLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const List<double> hourly = [
    0.05, 0.02, 0.00, 0.00, 0.02, 0.08, 0.18, 0.35, 0.50, 0.62, 0.55, 0.48,
    0.40, 0.45, 0.58, 0.66, 0.72, 0.60, 0.50, 0.42, 0.30, 0.22, 0.12, 0.06,
  ];

  static const List<String> tips = [
    'Drink a glass of water before every meal. Ribbit.',
    'Stretch like a lily pad in the sun - five minutes counts.',
    'Hop outside! Ten minutes of green time lifts the whole pond.',
    'Sleep is the pond where tomorrow grows. Aim for eight hours.',
    'Small hops beat giant leaps. Start with five minutes.',
    'Breathe in for four counts, out for six. Stay floaty.',
  ];
}

class HopEntry {
  final String time;
  final String label;
  final ToadIcon icon;

  const HopEntry(this.time, this.label, this.icon);
}

const List<HopEntry> recentHops = [
  HopEntry('07:15', 'Morning stretch walk', ToadIcon.walk),
  HopEntry('12:30', 'Pond-side stroll', ToadIcon.paws),
  HopEntry('18:05', 'Evening sprint', ToadIcon.run),
  HopEntry('20:40', 'Lily pad cooldown', ToadIcon.leaf),
];
