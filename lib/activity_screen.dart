import 'package:flutter/material.dart';

import 'charts.dart';
import 'data.dart';
import 'icon_painter.dart';
import 'theme.dart';
import 'toad_painter.dart';
import 'widgets.dart';

/// Motion: the walking toad and the running toad take centre stage.
/// Toggle between them and watch the stride speed (and speed lines) change.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _walk = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  bool _run = false;

  @override
  void dispose() {
    _walk.dispose();
    super.dispose();
  }

  void _toggle(bool run) {
    setState(() {
      _run = run;
      _walk.duration = Duration(milliseconds: run ? 480 : 900);
      _walk.value = 0;
      _walk.repeat();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(
                color: ToadColors.toadLight.withOpacity(0.25),
                base: 0.08,
                amp: 10,
                phase: 1.4,
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
                      icon: ToadIcon.run,
                      size: 26,
                      color: ToadColors.toadDeep,
                      seed: 3,
                    ),
                    const SizedBox(width: 8),
                    Text('Motion', style: ToadText.h1),
                  ],
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('every hop counts', style: ToadText.label),
                ),
                const SizedBox(height: 16),
                SketchCard(
                  seed: 2.2,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 210,
                        height: 195,
                        child: AnimatedBuilder(
                          animation: _walk,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: ToadPainter(
                                pose: _run ? ToadPose.run : ToadPose.walk,
                                phase: _walk.value,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _modeButton(
                              ToadIcon.walk, 'Walk', !_run, () => _toggle(false)),
                          const SizedBox(width: 10),
                          _modeButton(
                              ToadIcon.run, 'Run', _run, () => _toggle(true)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _miniStat(fmtNumber(HealthData.steps.value), 'steps', 1.1),
                    const SizedBox(width: 10),
                    _miniStat('3.1 km', 'distance', 2.3),
                    const SizedBox(width: 10),
                    _miniStat('48 min', 'active', 3.5),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionHeader(
                    title: "Today's rhythm", accent: ToadColors.toad),
                const SizedBox(height: 10),
                SketchCard(
                  seed: 4.4,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SketchIcon(
                            icon: ToadIcon.chart,
                            size: 20,
                            color: ToadColors.toadDeep,
                            seed: 7,
                          ),
                          const SizedBox(width: 8),
                          Text('hourly hops', style: ToadText.body),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: SketchLinePainter(
                            points: HealthData.hourly,
                            ink: ToadColors.ink,
                            accent: ToadColors.toad,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Recent hops', accent: ToadColors.toad),
                const SizedBox(height: 10),
                for (var i = 0; i < recentHops.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SketchCard(
                      seed: 6.0 + i,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          SketchIcon(
                            icon: recentHops[i].icon,
                            size: 22,
                            color: ToadColors.toadDeep,
                            seed: 8.0 + i,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(recentHops[i].label, style: ToadText.body),
                          ),
                          Text(recentHops[i].time, style: ToadText.label),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, double seed) {
    return Expanded(
      child: SketchCard(
        seed: seed,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: ToadText.h2),
            ),
            const SizedBox(height: 2),
            Text(label, style: ToadText.label),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(ToadIcon icon, String label, bool active, VoidCallback onTap) {
    return SketchButton(
      onTap: onTap,
      seed: label.length * 1.7,
      radius: 22,
      background: active ? ToadColors.toadLight : ToadColors.paper,
      borderColor: active ? ToadColors.toadDeep : ToadColors.ink,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SketchIcon(
            icon: icon,
            size: 20,
            color: active ? ToadColors.toadDeep : ToadColors.inkSoft,
            seed: label.length * 2.1,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'PatrickHand',
              fontSize: 15,
              color: active ? ToadColors.toadDeep : ToadColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
