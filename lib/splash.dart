import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app.dart';
import 'charts.dart';
import 'nav_shell.dart';
import 'theme.dart';
import 'toad_painter.dart';

/// Splash: the toad hops in three times, the handwritten logo ink-fades in,
/// and a little toad walks along the bottom of the screen before the app
/// flows into the home shell.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void initState() {
    super.initState();
    _c.addStatusListener(_onDone);
    _c.forward();
  }

  void _onDone(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(FlowRoute(page: const HomeShell()));
    });
  }

  @override
  void dispose() {
    _c.removeStatusListener(_onDone);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ToadColors.cream,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final p = _c.value;
          final hopT = (p * 3) % 1.0;
          final titleOpacity = CurvedAnimation(
            parent: _c,
            curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
          ).value;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: BlobPainter(
                    color: ToadColors.toadLight.withOpacity(0.30),
                    seed: 2.0,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: BlobPainter(
                    color: ToadColors.lilypad.withOpacity(0.25),
                    seed: 5.0,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: Offset(0, -34 * math.sin(hopT * math.pi)),
                      child: SizedBox(
                        width: 170,
                        height: 170,
                        child: CustomPaint(
                          painter: ToadPainter(pose: ToadPose.walk, phase: p * 6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: titleOpacity,
                      child: Column(
                        children: [
                          const Text('toadHEALTH', style: ToadText.display),
                          SizedBox(
                            height: 8,
                            width: 130,
                            child: CustomPaint(
                              painter: SquigglePainter(color: ToadColors.toad),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('hop your way to healthy', style: ToadText.label),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 46,
                left: 0,
                child: Transform.translate(
                  offset: Offset(
                    -80 + p * (MediaQuery.of(context).size.width + 160),
                    0,
                  ),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: CustomPaint(
                      painter: ToadPainter(pose: ToadPose.walk, phase: p * 8),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
