import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'charts.dart';
import 'data.dart';
import 'icon_painter.dart';
import 'state/app_services.dart';
import 'theme.dart';
import 'toad_painter.dart';
import 'widgets.dart';

/// Water: a hand-drawn pond that rises glass by glass while the toad floats
/// on its lily pad. Splash ripples reward every glass you log.
class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> with TickerProviderStateMixin {
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _flow.dispose();
    _ripple.dispose();
    super.dispose();
  }

  void _add() {
    HapticFeedback.selectionClick();
    AppServices.controller.addWater(1);
    _ripple.forward(from: 0);
  }

  void _remove() {
    AppServices.controller.addWater(-1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(
                color: ToadColors.pond.withOpacity(0.16),
                base: 0.08,
                amp: 10,
                phase: 1.1,
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
                      icon: ToadIcon.drop,
                      size: 26,
                      color: ToadColors.pondDeep,
                      seed: 3,
                    ),
                    const SizedBox(width: 8),
                    Text('Water', style: ToadText.h1),
                  ],
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('keep the pond happy', style: ToadText.label),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<int>(
                  valueListenable: HealthData.water,
                  builder: (context, water, _) {
                    final ratio = water / HealthData.waterGoal;
                    return SketchCard(
                      seed: 2.8,
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        height: 260,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _flow,
                                builder: (context, _) => CustomPaint(
                                  painter:
                                      PondPainter(level: ratio, phase: _flow.value),
                                ),
                              ),
                            ),
                            if (_ripple.isAnimating)
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _ripple,
                                  builder: (context, _) => CustomPaint(
                                    painter: RipplePainter(
                                      phase: _ripple.value,
                                      color: ToadColors.pondDeep,
                                      cx: 0.62,
                                      cy: 0.62,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 20 + ratio * 140,
                              child: Center(
                                child: SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: AnimatedBuilder(
                                    animation: _flow,
                                    builder: (context, _) => CustomPaint(
                                      painter: ToadPainter(
                                        pose: ToadPose.idle,
                                        phase: _flow.value,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                ValueListenableBuilder<int>(
                  valueListenable: HealthData.water,
                  builder: (context, water, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < HealthData.waterGoal; i++)
                          SketchIcon(
                            icon: ToadIcon.drop,
                            size: 26,
                            color:
                                i < water ? ToadColors.pondDeep : ToadColors.inkSoft,
                            filled: i < water,
                            seed: i * 1.3 + 1,
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SketchButton(
                      onTap: _remove,
                      padding: const EdgeInsets.all(12),
                      radius: 22,
                      seed: 4.2,
                      child: const SketchIcon(
                        icon: ToadIcon.minus,
                        size: 20,
                        color: ToadColors.inkSoft,
                        seed: 5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SketchButton(
                        onTap: _add,
                        background: ToadColors.pond.withOpacity(0.18),
                        borderColor: ToadColors.pondDeep,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        radius: 26,
                        seed: 5.6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SketchIcon(
                              icon: ToadIcon.plus,
                              size: 22,
                              color: ToadColors.pondDeep,
                              seed: 6,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'log a glass',
                              style: TextStyle(
                                fontFamily: 'PatrickHand',
                                fontSize: 16,
                                color: ToadColors.pondDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ValueListenableBuilder<int>(
                  valueListenable: HealthData.water,
                  builder: (context, water, _) {
                    final ratio = water / HealthData.waterGoal;
                    final msg = ratio < 0.25
                        ? 'The pond is drying up, ribbit... log some water!'
                        : ratio < 0.75
                            ? 'Nice splashes! Keep the pond flowing.'
                            : 'Full pond! Toadally hydrated today.';
                    return SpeechBubble(text: msg);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
