import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'activity_screen.dart';
import 'home_screen.dart';
import 'icon_painter.dart';
import 'profile_screen.dart';
import 'sketchy.dart';
import 'sleep_screen.dart';
import 'theme.dart';
import 'toad_painter.dart';
import 'water_screen.dart';

/// The app shell: five screens held in an IndexedStack, plus the signature
/// bottom navigation where a tiny hand-drawn toad physically HOPS from tab
/// to tab. The toad is the body of the app - it never leaves you.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  int _index = 0;
  int _prev = 0;

  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 580),
  );
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  late final List<Widget> _screens = [
    const HomeScreen(),
    const ActivityScreen(),
    const WaterScreen(),
    const SleepScreen(),
    const ProfileScreen(),
  ];

  @override
  void dispose() {
    _hop.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    setState(() {
      _prev = _index;
      _index = i;
    });
    _hop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _ToadNavBar(
        index: _index,
        prev: _prev,
        hop: _hop,
        idle: _idle,
        onTap: _select,
      ),
    );
  }
}

class _ToadNavBar extends StatelessWidget {
  final int index;
  final int prev;
  final Animation<double> hop;
  final Animation<double> idle;
  final ValueChanged<int> onTap;

  static const _labels = ['Home', 'Motion', 'Water', 'Sleep', 'You'];
  static const _icons = [
    ToadIcon.home,
    ToadIcon.run,
    ToadIcon.drop,
    ToadIcon.moon,
    ToadIcon.face,
  ];

  const _ToadNavBar({
    required this.index,
    required this.prev,
    required this.hop,
    required this.idle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final itemW = w / 5;
            final fromX = itemW * prev + itemW / 2;
            final toX = itemW * index + itemW / 2;
            return SizedBox(
              height: 78,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _NavBarPainter()),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Expanded(
                          child: _NavItem(
                            icon: _icons[i],
                            label: _labels[i],
                            seed: i * 1.9,
                            selected: i == index,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                  // The hopping toad.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([hop, idle]),
                        builder: (context, _) {
                          final hopping = hop.isAnimating;
                          final t = hop.value;
                          double x;
                          double y;
                          double phase;
                          ToadPose pose;
                          if (hopping) {
                            x = lerpDouble(fromX, toX, t)!;
                            y = -math.sin(t * math.pi) * 30;
                            phase = t * 3;
                            pose = ToadPose.walk;
                          } else {
                            x = toX;
                            y = math.sin(idle.value * 2 * math.pi) * 1.2;
                            phase = idle.value;
                            pose = ToadPose.idle;
                          }
                          return Align(
                            alignment: Alignment((x / w) * 2 - 1, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, -16 + y),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: CustomPaint(
                                  painter: ToadPainter(pose: pose, phase: phase),
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
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final ToadIcon icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double seed;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.seed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutBack,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  selected ? ToadColors.lilypad.withOpacity(0.45) : Colors.transparent,
            ),
            child: Center(
              child: SketchIcon(
                icon: icon,
                size: 24,
                color: selected ? ToadColors.toadDeep : ToadColors.inkSoft,
                seed: seed,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'PatrickHand',
              fontSize: 10.5,
              height: 1.0,
              color: selected ? ToadColors.toadDeep : ToadColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = sketchRoundRect(
      rect.deflate(1.5),
      radius: 26,
      seed: 7.7,
      amp: 1.3,
    );
    canvas.drawPath(path, fillPaint(ToadColors.paper));
    drawSketchStroke(
      canvas,
      path,
      color: ToadColors.ink,
      width: 2.0,
      opacity: 0.85,
      ghost: false,
    );
  }

  @override
  bool shouldRepaint(covariant _NavBarPainter oldDelegate) => false;
}
