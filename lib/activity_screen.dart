import 'package:flutter/material.dart';

import 'charts.dart';
import 'data.dart';
import 'icon_painter.dart';
import 'screens/log_sheets.dart';
import 'state/app_services.dart';
import 'theme.dart';
import 'toad_painter.dart';
import 'widgets.dart';

/// Motion: real steps from the hardware sensor (or honest manual logs),
/// real distance and energy estimates computed from them, a real hourly
/// rhythm chart, and the real activity feed from the encrypted vault.
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
            child: AnimatedBuilder(
              animation: AppServices.controller,
              builder: (context, _) {
                return ListView(
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
                              _modeButton(ToadIcon.walk, 'Walk', !_run,
                                  () => _toggle(false)),
                              const SizedBox(width: 10),
                              _modeButton(ToadIcon.run, 'Run', _run,
                                  () => _toggle(true)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SketchButton(
                            onTap: () => showLogStepsSheet(context),
                            background: ToadColors.toadLight,
                            borderColor: ToadColors.toadDeep,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SketchIcon(
                                  icon: ToadIcon.paws,
                                  size: 20,
                                  color: ToadColors.toadDeep,
                                  seed: 21,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Log a walk',
                                  style: TextStyle(
                                    fontFamily: 'PatrickHand',
                                    fontSize: 15,
                                    color: ToadColors.toadDeep,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStats(),
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
                              Text('steps per hour', style: ToadText.body),
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
                    const SectionHeader(
                        title: 'Recent hops', accent: ToadColors.toad),
                    const SizedBox(height: 10),
                    _buildRecent(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final steps = HealthData.steps.value;
    final distanceKm = steps * 0.0007; // ~0.7 m stride, honest estimate
    final kcal = steps * 0.04; // ~0.04 kcal per step, honest estimate
    return Row(
      children: [
        _miniStat(fmtNumber(steps), 'hops today', 1.1),
        const SizedBox(width: 10),
        _miniStat('${distanceKm.toStringAsFixed(2)} km', 'distance', 2.3),
        const SizedBox(width: 10),
        _miniStat('${kcal.round()} kcal', 'est. energy', 3.5),
      ],
    );
  }

  Widget _buildRecent() {
    final hops = HealthData.recentHops;
    if (hops.isEmpty) {
      return SketchCard(
        seed: 6.0,
        child: Text(
          'No hops logged yet - take a walk, tap the toad on Home, or log '
          'one by hand. Everything lands here.',
          style: ToadText.body.copyWith(color: ToadColors.inkSoft),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < hops.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SketchCard(
              seed: 6.0 + i,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  SketchIcon(
                    icon: hops[i].icon,
                    size: 22,
                    color: ToadColors.toadDeep,
                    seed: 8.0 + i,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(hops[i].label, style: ToadText.body),
                  ),
                  Text(hops[i].time, style: ToadText.label),
                ],
              ),
            ),
          ),
      ],
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
