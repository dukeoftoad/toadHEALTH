import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'activity_screen.dart';
import 'app.dart';
import 'charts.dart';
import 'data.dart';
import 'icon_painter.dart';
import 'profile_screen.dart';
import 'sleep_screen.dart';
import 'theme.dart';
import 'toad_painter.dart';
import 'water_screen.dart';
import 'widgets.dart';

/// Home: the toad's pond dashboard. The mascot walks (or runs) inside a
/// sketchy progress ring - tap it and it hops while your hop count grows.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _walk = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  )..repeat();
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  );

  int _tipIndex = 0;

  @override
  void dispose() {
    _walk.dispose();
    _hop.dispose();
    super.dispose();
  }

  void _tapToad() {
    HapticFeedback.selectionClick();
    _hop.forward(from: 0);
    HealthData.steps.value = HealthData.steps.value + 50;
  }

  void _open(Widget page) {
    Navigator.of(context).push(FlowRoute(page: page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(
                color: ToadColors.toadLight.withOpacity(0.32),
                base: 0.10,
                amp: 12,
                phase: 0.8,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(
                color: ToadColors.lilypad.withOpacity(0.22),
                base: 0.18,
                amp: 14,
                phase: 2.4,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 130),
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
                    Text('toadHEALTH', style: ToadText.h2),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _open(const ProfileScreen()),
                      child: const SketchIcon(
                        icon: ToadIcon.gear,
                        size: 24,
                        color: ToadColors.inkSoft,
                        seed: 5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Good day, friend!', style: ToadText.h1),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Let us hop toward a healthier you', style: ToadText.label),
                ),
                const SizedBox(height: 16),
                _buildHeroCard(),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Vitals', accent: ToadColors.toad),
                const SizedBox(height: 10),
                _buildVitals(),
                const SizedBox(height: 20),
                const SectionHeader(title: 'This week', accent: ToadColors.toad),
                const SizedBox(height: 10),
                _buildWeekCard(),
                const SizedBox(height: 20),
                const SectionHeader(title: "Toad's wisdom", accent: ToadColors.toad),
                const SizedBox(height: 10),
                _buildTipCard(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return SketchCard(
      seed: 3.3,
      padding: const EdgeInsets.all(18),
      child: ValueListenableBuilder<int>(
        valueListenable: HealthData.steps,
        builder: (context, steps, _) {
          final r = (steps / HealthData.stepsGoal).clamp(0.0, 1.0).toDouble();
          return Column(
            children: [
              SpeechBubble(
                text: 'Ribbit! ${fmtNumber(steps)} hops so far. Tap me to add more!',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 232,
                height: 232,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: SketchRingPainter(
                          progress: r,
                          progressColor: ToadColors.toad,
                          trackColor: ToadColors.ink,
                          strokeWidth: 7,
                          seed: 4.4,
                        ),
                      ),
                    ),
                    Center(
                      child: GestureDetector(
                        onTap: _tapToad,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_walk, _hop]),
                          builder: (context, _) {
                            final hopT = _hop.value;
                            return Transform.translate(
                              offset:
                                  Offset(0, -36 * math.sin(hopT * math.pi)),
                              child: SizedBox(
                                width: 150,
                                height: 150,
                                child: CustomPaint(
                                  painter: ToadPainter(
                                    pose: _hop.isAnimating
                                        ? ToadPose.cheer
                                        : (r > 0.72 ? ToadPose.run : ToadPose.walk),
                                    phase: _walk.value,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedNumber(value: steps, style: ToadText.number),
                  Text(' / ${fmtNumber(HealthData.stepsGoal)}', style: ToadText.label),
                ],
              ),
              const SizedBox(height: 2),
              const Text("today's hops", style: ToadText.label),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVitals() {
    return ValueListenableBuilder<int>(
      valueListenable: HealthData.water,
      builder: (context, water, _) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.30,
          children: [
            StatTile(
              icon: ToadIcon.heart,
              label: 'heart rate',
              value: '${HealthData.heartRate} bpm',
              accent: ToadColors.coral,
              seed: 1.2,
              onTap: () => _open(const ActivityScreen()),
            ),
            StatTile(
              icon: ToadIcon.drop,
              label: 'water',
              value: '$water / ${HealthData.waterGoal} glasses',
              accent: ToadColors.pond,
              seed: 2.4,
              onTap: () => _open(const WaterScreen()),
            ),
            StatTile(
              icon: ToadIcon.moon,
              label: 'sleep',
              value: '7h 20m',
              accent: ToadColors.moss,
              seed: 3.6,
              onTap: () => _open(const SleepScreen()),
            ),
            StatTile(
              icon: ToadIcon.flame,
              label: 'energy',
              value: '${fmtNumber(HealthData.energy)} kcal',
              accent: ToadColors.sun,
              seed: 4.8,
              onTap: () => _open(const ActivityScreen()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeekCard() {
    return SketchCard(
      seed: 5.1,
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
              Text('week of hops', style: ToadText.body),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: SketchBarsPainter(
                values: HealthData.weekSteps,
                labels: HealthData.weekLabels,
                activeIndex: 5,
                barFill: ToadColors.toadLight,
                activeFill: ToadColors.toad,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SketchIcon(
                icon: ToadIcon.flame,
                size: 18,
                color: ToadColors.sun,
                seed: 9,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${HealthData.streakDays}-day hop streak. Toadally consistent!',
                  style: ToadText.body,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    return SketchCard(
      seed: 7.9,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SketchIcon(
            icon: ToadIcon.leaf,
            size: 26,
            color: ToadColors.toad,
            seed: 11,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(HealthData.tips[_tipIndex], style: ToadText.body),
          ),
          const SizedBox(width: 8),
          SketchButton(
            onTap: () {
              setState(() {
                _tipIndex = (_tipIndex + 1) % HealthData.tips.length;
              });
            },
            padding: const EdgeInsets.all(8),
            radius: 24,
            seed: 9.1,
            child: const SketchIcon(
              icon: ToadIcon.chevron,
              size: 20,
              color: ToadColors.toadDeep,
              seed: 13,
            ),
          ),
        ],
      ),
    );
  }
}
