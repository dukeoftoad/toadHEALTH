import 'package:flutter/material.dart';

import 'charts.dart';
import 'data.dart';
import 'icon_painter.dart';
import 'theme.dart';
import 'toad_painter.dart';
import 'widgets.dart';

/// Sleep: the night pond. The toad curls up asleep while hand-drawn Zzz's
/// float upward, above a weekly sleep chart and a cozy breakdown.
class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _zzz = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _zzz.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(
                color: ToadColors.moss.withOpacity(0.10),
                base: 0.06,
                amp: 10,
                phase: 0.4,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 130),
              children: [
                Row(
                  children: [
                    const SketchIcon(
                      icon: ToadIcon.moon,
                      size: 26,
                      color: ToadColors.moss,
                      seed: 3,
                    ),
                    const SizedBox(width: 8),
                    Text('Sleep', style: ToadText.h1),
                  ],
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('rest in the pond, dream of flies', style: ToadText.label),
                ),
                const SizedBox(height: 16),
                SketchCard(
                  seed: 2.6,
                  background: ToadColors.moss,
                  borderColor: ToadColors.lilypad,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Night pond',
                        style: TextStyle(
                          fontFamily: 'Caveat',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: ToadColors.cream,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        height: 170,
                        child: Stack(
                          children: [
                            Positioned(
                              right: 8,
                              top: 4,
                              child: SizedBox(
                                width: 100,
                                height: 100,
                                child: AnimatedBuilder(
                                  animation: _zzz,
                                  builder: (context, _) => CustomPaint(
                                    painter: ZzzPainter(
                                      phase: _zzz.value,
                                      color: ToadColors.cream,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: SizedBox(
                                width: 140,
                                height: 140,
                                child: CustomPaint(
                                  painter: ToadPainter(
                                    pose: ToadPose.sleep,
                                    phase: 0.3,
                                    palette: ToadPalette.night,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            '7h 20m',
                            style: TextStyle(
                              fontFamily: 'Caveat',
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: ToadColors.cream,
                            ),
                          ),
                          Text(
                            '  of 8h goal',
                            style: TextStyle(
                              fontFamily: 'PatrickHand',
                              fontSize: 13,
                              color: ToadColors.cream.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'This week', accent: ToadColors.moss),
                const SizedBox(height: 10),
                SketchCard(
                  seed: 4.4,
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: SketchBarsPainter(
                        values: HealthData.weekSleep,
                        labels: HealthData.weekLabels,
                        activeIndex: 6,
                        barFill: ToadColors.lilypad.withOpacity(0.55),
                        activeFill: ToadColors.pond,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Breakdown', accent: ToadColors.moss),
                const SizedBox(height: 10),
                SketchCard(
                  seed: 6.2,
                  child: Column(
                    children: [
                      _breakdownRow('Deep sleep', 0.64, '3h 05m', ToadColors.moss),
                      const SizedBox(height: 12),
                      _breakdownRow('Light sleep', 0.46, '3h 40m', ToadColors.lilypad),
                      const SizedBox(height: 12),
                      _breakdownRow('Peaceful awake', 0.07, '35m', ToadColors.sun),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, double ratio, String value, Color color) {
    return Row(
      children: [
        SizedBox(width: 110, child: Text(label, style: ToadText.body)),
        Expanded(
          child: SizedBox(
            height: 18,
            child: CustomPaint(painter: MiniBarPainter(ratio: ratio, color: color)),
          ),
        ),
        const SizedBox(width: 10),
        Text(value, style: ToadText.label),
      ],
    );
  }
}
