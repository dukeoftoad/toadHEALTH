import 'package:flutter/material.dart';

import 'charts.dart';
import 'data.dart';
import 'icon_painter.dart';
import 'screens/log_sheets.dart';
import 'state/app_services.dart';
import 'theme.dart';
import 'toad_painter.dart';
import 'widgets.dart';

/// Sleep: the night pond. Real logged nights, a real weekly chart and real
/// statistics - no invented deep/light breakdowns. The toad sleeps only
/// when you tell it how long you slept.
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
            child: AnimatedBuilder(
              animation: AppServices.controller,
              builder: (context, _) {
                return ListView(
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
                      child: Text('rest in the pond, dream of flies',
                          style: ToadText.label),
                    ),
                    const SizedBox(height: 16),
                    _buildNightCard(),
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
                    const SectionHeader(title: 'Last 7 nights', accent: ToadColors.moss),
                    const SizedBox(height: 10),
                    _buildStats(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNightCard() {
    final logged = HealthData.todaySleepMin > 0;
    return SketchCard(
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
              Text(
                logged ? fmtDuration(HealthData.todaySleepMin) : 'not logged yet',
                style: const TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: ToadColors.cream,
                ),
              ),
              Text(
                logged ? '  of ${fmtDuration(HealthData.sleepGoalMin)} goal' : '',
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 13,
                  color: ToadColors.cream.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: SketchButton(
              onTap: () => showLogSleepSheet(context),
              background: ToadColors.cream,
              borderColor: ToadColors.lilypad,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                logged ? 'Edit last night' : 'Log last night',
                style: const TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 15,
                  color: ToadColors.moss,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final minutes = HealthData.weekSleepMinutes;
    final loggedNights = minutes.where((m) => m > 0).length;
    final totalMin = minutes.fold<int>(0, (a, b) => a + b);
    final avg = loggedNights > 0 ? totalMin ~/ loggedNights : 0;
    var best = 0;
    for (final m in minutes) {
      if (m > best) best = m;
    }
    return SketchCard(
      seed: 6.2,
      child: Column(
        children: [
          _statRow('Average night', loggedNights > 0 ? fmtDuration(avg) : '-'),
          const Divider(height: 18, color: ToadColors.inkSoft),
          _statRow('Best night', best > 0 ? fmtDuration(best) : '-'),
          const Divider(height: 18, color: ToadColors.inkSoft),
          _statRow('Nights logged', '$loggedNights of 7'),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label, style: ToadText.body)),
        Text(value, style: ToadText.h2),
      ],
    );
  }
}
