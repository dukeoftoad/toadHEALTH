import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'activity_screen.dart';
import 'app.dart';
import 'charts.dart';
import 'data.dart';
import 'icon_painter.dart';
import 'profile_screen.dart';
import 'screens/log_sheets.dart';
import 'screens/watch_screen.dart';
import 'sleep_screen.dart';
import 'state/app_services.dart';
import 'theme.dart';
import 'toad_painter.dart';
import 'water_screen.dart';
import 'widgets.dart';

/// Home: the toad's pond dashboard. Every number on this screen is REAL -
/// recorded in the encrypted on-device vault and fed by the hardware step
/// sensor where the device has one.
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
    AppServices.controller.addSteps(50, manual: true);
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
            child: AnimatedBuilder(
              animation: AppServices.controller,
              builder: (context, _) {
                return ListView(
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
                      child: Text(
                        HealthData.demoData
                            ? 'demo pond - erase it anytime in You'
                            : 'your pond, your data - sealed on this device',
                        style: ToadText.label,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!HealthData.firstRunDone) _buildWelcomeCard(),
                    if (!HealthData.firstRunDone) const SizedBox(height: 16),
                    _buildHeroCard(),
                    const SizedBox(height: 16),
                    _buildWatchCard(),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return SketchCard(
      seed: 1.1,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SketchIcon(
                icon: ToadIcon.sparkle,
                size: 22,
                color: ToadColors.sun,
                seed: 2,
              ),
              const SizedBox(width: 8),
              Text('Welcome to your pond', style: ToadText.h2),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Everything you log stays on this device, sealed with AES-256 '
            'encryption. No account, no cloud, no tracking. Start with a '
            'walk or a glass of water - or set an app password under You.',
            style: ToadText.body,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SketchButton(
                onTap: () => AppServices.controller.markFirstRunDone(),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontFamily: 'PatrickHand', fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              SketchButton(
                onTap: () => showLogStepsSheet(context),
                background: ToadColors.toadLight,
                borderColor: ToadColors.toadDeep,
                child: const Text(
                  'Log a walk',
                  style: TextStyle(fontFamily: 'PatrickHand', fontSize: 15),
                ),
              ),
            ],
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
                text: steps == 0
                    ? 'The pond is quiet... log your first hops!'
                    : 'Ribbit! ${fmtNumber(steps)} hops so far. Tap me to add more!',
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
                              offset: Offset(0, -36 * math.sin(hopT * math.pi)),
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

  /// The watch-link strip: live buddy status on the pond dashboard.
  /// Tap it to drift over to the Pond Watch screen (FlowRoute).
  Widget _buildWatchCard() {
    return SketchCard(
      seed: 2.6,
      padding: const EdgeInsets.all(14),
      child: AnimatedBuilder(
        animation: AppServices.watch,
        builder: (context, _) {
          final w = AppServices.watch;
          final linked = w.connected;
          final subtitle = linked
              ? (w.demoMode
                  ? 'demo buddy pacing your heartbeat'
                  : w.bpm > 0
                      ? '${w.bpm} bpm - the toad is pacing it'
                      : 'waiting for the first heartbeat')
              : 'wire a smart watch over bluetooth';
          return Row(
            children: [
              const SketchIcon(
                icon: ToadIcon.watch,
                size: 26,
                color: ToadColors.pondDeep,
                seed: 6,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      linked
                          ? (w.device?.name ?? 'Pond buddy')
                          : 'Pond Watch',
                      style: ToadText.body,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(subtitle, style: ToadText.label),
                  ],
                ),
              ),
              if (linked && w.bpm > 0)
                Text(
                  '${w.bpm}',
                  style: ToadText.h2.copyWith(color: ToadColors.coral),
                ),
              const SizedBox(width: 8),
              SketchButton(
                onTap: () => _open(const WatchScreen()),
                padding: const EdgeInsets.all(8),
                radius: 24,
                seed: 5.5,
                child: const SketchIcon(
                  icon: ToadIcon.chevron,
                  size: 20,
                  color: ToadColors.toadDeep,
                  seed: 13,
                ),
              ),
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
        return ValueListenableBuilder<int>(
          valueListenable: HealthData.steps,
          builder: (context, steps, _) {
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.30,
              children: [
                StatTile(
                  icon: ToadIcon.walk,
                  label: 'hops today',
                  value: fmtNumber(steps),
                  accent: ToadColors.toad,
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
                  value: HealthData.todaySleepMin > 0
                      ? fmtDuration(HealthData.todaySleepMin)
                      : 'not set',
                  accent: ToadColors.moss,
                  seed: 3.6,
                  onTap: () => _open(const SleepScreen()),
                ),
                StatTile(
                  icon: ToadIcon.chart,
                  label: '7-day average',
                  value: '${fmtNumber(HealthData.avgSteps7)}/day',
                  accent: ToadColors.sun,
                  seed: 4.8,
                  onTap: () => _open(const ActivityScreen()),
                ),
              ],
            );
          },
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
                activeIndex: 6,
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
