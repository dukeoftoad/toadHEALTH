import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'charts.dart';
import 'data.dart';
import 'icon_painter.dart';
import 'sketchy.dart';
import 'theme.dart';
import 'toad_painter.dart';
import 'widgets.dart';

/// Profile: your toad identity. A sketchy avatar ring, hop streak, draggable
/// hand-drawn goal sliders, badges, and a little about card with the app icon.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _goalSteps = 8000;
  double _goalWater = 8;
  double _goalSleep = 480;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BlobPainter(
                color: ToadColors.toadLight.withOpacity(0.20),
                seed: 3.0,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 130),
              children: [
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(painter: _AvatarRingPainter()),
                            ),
                            Center(
                              child: SizedBox(
                                width: 112,
                                height: 112,
                                child: CustomPaint(
                                  painter: ToadPainter(
                                    pose: ToadPose.idle,
                                    phase: 0.35,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Lily Padmore', style: ToadText.h1),
                      const Text('hop member since spring 2024', style: ToadText.label),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SketchCard(
                  seed: 2.4,
                  child: Row(
                    children: [
                      const SketchIcon(
                        icon: ToadIcon.flame,
                        size: 30,
                        color: ToadColors.sun,
                        seed: 4,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${HealthData.streakDays}-day hop streak', style: ToadText.h2),
                          const Text('longest ever: 21 days', style: ToadText.label),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Goals', accent: ToadColors.toad),
                const SizedBox(height: 10),
                SketchCard(
                  seed: 3.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GoalSlider(
                        label: 'Daily hops',
                        value: _goalSteps,
                        min: 2000,
                        max: 12000,
                        display: (v) => '${fmtNumber(v.round())} steps',
                        color: ToadColors.toad,
                        onChanged: (v) => setState(() => _goalSteps = v),
                      ),
                      const SizedBox(height: 16),
                      _GoalSlider(
                        label: 'Glasses of water',
                        value: _goalWater,
                        min: 4,
                        max: 12,
                        display: (v) => '${v.round()} glasses',
                        color: ToadColors.pond,
                        onChanged: (v) => setState(() => _goalWater = v),
                      ),
                      const SizedBox(height: 16),
                      _GoalSlider(
                        label: 'Hours of sleep',
                        value: _goalSleep,
                        min: 360,
                        max: 600,
                        display: (v) => '${(v / 60).toStringAsFixed(1)} hours',
                        color: ToadColors.moss,
                        onChanged: (v) => setState(() => _goalSleep = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Badges', accent: ToadColors.toad),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _badge(ToadIcon.leaf, 'Sprout', ToadColors.toad),
                    _badge(ToadIcon.flame, 'Blaze', ToadColors.sun),
                    _badge(ToadIcon.paws, 'Marathon', ToadColors.coral),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'About', accent: ToadColors.toad),
                const SizedBox(height: 10),
                SketchCard(
                  seed: 5.2,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('toadHEALTH v1.0.0', style: ToadText.body),
                            const SizedBox(height: 2),
                            Text(
                              'A gentle, hand-drawn health companion. Every stroke is '
                              'drawn by a toad holding a very steady pen.',
                              style: ToadText.body.copyWith(
                                color: ToadColors.inkSoft,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text('made with muddy paws and Flutter', style: ToadText.label),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(ToadIcon icon, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Center(
              child: SketchIcon(
                icon: icon,
                size: 26,
                color: color,
                seed: label.length * 1.3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: ToadText.label),
        ],
      ),
    );
  }
}

class _AvatarRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    drawSketchStroke(
      canvas,
      sketchEllipse(c, r, r, seed: 1.5, amp: 1.6),
      color: ToadColors.toad,
      width: 2.4,
    );
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawCircle(
        Offset(c.dx + math.cos(a) * (r - 9), c.dy + math.sin(a) * (r - 9)),
        1.2,
        fillPaint(ToadColors.inkSoft, opacity: 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarRingPainter oldDelegate) => false;
}

class _GoalSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String Function(double) display;
  final Color color;
  final ValueChanged<double> onChanged;

  const _GoalSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: ToadText.body),
            const Spacer(),
            Text(
              display(value),
              style: TextStyle(fontFamily: 'PatrickHand', fontSize: 14, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final ratio = ((value - min) / (max - min)).clamp(0.0, 1.0).toDouble();
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _seek(d.localPosition.dx, w),
              onHorizontalDragUpdate: (d) => _seek(d.localPosition.dx, w),
              child: SizedBox(
                height: 30,
                width: w,
                child: CustomPaint(
                  painter: _SliderPainter(ratio: ratio, color: color),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _seek(double dx, double w) {
    final t = (dx / w).clamp(0.0, 1.0).toDouble();
    onChanged(min + (max - min) * t);
  }
}

class _SliderPainter extends CustomPainter {
  final double ratio;
  final Color color;

  _SliderPainter({required this.ratio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    drawSketchStroke(
      canvas,
      sketchLine(Offset(6, y), Offset(size.width - 6, y), seed: 2, amp: 0.5),
      color: ToadColors.ink,
      width: 2.0,
      opacity: 0.25,
      ghost: false,
    );
    final endX = 6 + (size.width - 12) * ratio;
    drawSketchStroke(
      canvas,
      sketchLine(Offset(6, y), Offset(endX, y), seed: 3, amp: 0.5),
      color: color,
      width: 4.5,
      ghost: false,
    );
    canvas.drawCircle(Offset(endX, y), 8, fillPaint(ToadColors.paper));
    canvas.drawCircle(Offset(endX, y), 8, strokePaint(color, 2.0));
    canvas.drawCircle(Offset(endX, y), 3, fillPaint(color));
  }

  @override
  bool shouldRepaint(covariant _SliderPainter oldDelegate) {
    return oldDelegate.ratio != ratio || oldDelegate.color != color;
  }
}
