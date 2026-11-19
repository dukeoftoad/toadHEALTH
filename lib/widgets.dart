import 'package:flutter/material.dart';

import 'charts.dart';
import 'data.dart';
import 'icon_painter.dart';
import 'sketchy.dart';
import 'theme.dart';

/// A paper card with a wobbly hand-drawn ink border.
class SketchCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color background;
  final Color borderColor;
  final double seed;
  final double wobble;
  final double rotation;
  final double radius;

  const SketchCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.background = ToadColors.paper,
    this.borderColor = ToadColors.ink,
    this.seed = 1.0,
    this.wobble = 1.2,
    this.rotation = 0,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x162B2B20),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: SketchBorderPainter(
                    color: borderColor,
                    seed: seed,
                    radius: radius,
                    amp: wobble,
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// The wobbly ink border itself.
class SketchBorderPainter extends CustomPainter {
  final Color color;
  final double seed;
  final double radius;
  final double amp;

  const SketchBorderPainter({
    required this.color,
    required this.seed,
    this.radius = 18,
    this.amp = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = sketchRoundRect(
      rect.deflate(1.2),
      radius: radius,
      seed: seed,
      amp: amp,
    );
    drawSketchStroke(
      canvas,
      path,
      color: color,
      width: 1.8,
      opacity: 0.9,
      ghost: false,
    );
  }

  @override
  bool shouldRepaint(covariant SketchBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.seed != seed ||
        oldDelegate.radius != radius ||
        oldDelegate.amp != amp;
  }
}

/// A pressable sketchy button that squashes when tapped.
class SketchButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color background;
  final Color borderColor;
  final EdgeInsets padding;
  final double radius;
  final double seed;

  const SketchButton({
    super.key,
    required this.child,
    this.onTap,
    this.background = ToadColors.paper,
    this.borderColor = ToadColors.ink,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.radius = 18,
    this.seed = 1.0,
  });

  @override
  State<SketchButton> createState() => _SketchButtonState();
}

class _SketchButtonState extends State<SketchButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x142B2B20),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: SketchBorderPainter(
                      color: widget.borderColor,
                      seed: widget.seed,
                      radius: widget.radius,
                      amp: 1.0,
                    ),
                  ),
                ),
              ),
              Padding(padding: widget.padding, child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}

/// A hand-drawn speech bubble with a little tail.
class SpeechBubble extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const SpeechBubble({
    super.key,
    required this.text,
    this.color = ToadColors.paper,
    this.textColor = ToadColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(color: color),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          text,
          style: ToadText.body.copyWith(color: textColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final Color color;

  _BubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bubble = sketchRoundRect(
      rect.deflate(1.5),
      radius: 16,
      seed: 6.1,
      amp: 1.3,
    );
    canvas.drawPath(bubble, fillPaint(color));
    drawSketchStroke(
      canvas,
      bubble,
      color: ToadColors.ink,
      width: 1.8,
      opacity: 0.85,
      ghost: false,
    );

    final tail = sketchThrough(
      [
        Offset(size.width * 0.22, size.height - 2),
        Offset(size.width * 0.18, size.height + 10),
        Offset(size.width * 0.22 + 14, size.height - 2),
      ],
      seed: 9.4,
      amp: 0.4,
    );
    canvas.drawPath(tail, fillPaint(color));
    drawSketchStroke(
      canvas,
      tail,
      color: ToadColors.ink,
      width: 1.8,
      opacity: 0.85,
      ghost: false,
    );
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Section title with a hand-drawn underline squiggle.
class SectionHeader extends StatelessWidget {
  final String title;
  final Color accent;

  const SectionHeader({
    super.key,
    required this.title,
    this.accent = ToadColors.toad,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ToadText.h2),
        const SizedBox(height: 4),
        SizedBox(
          height: 8,
          width: 96,
          child: CustomPaint(painter: SquigglePainter(color: accent)),
        ),
      ],
    );
  }
}

/// A number that counts up smoothly whenever it changes.
class AnimatedNumber extends StatelessWidget {
  final int value;
  final TextStyle style;
  final String suffix;
  final Duration duration;

  const AnimatedNumber({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Text(fmtNumber(v.round()) + suffix, style: style);
      },
    );
  }
}

/// A vitals tile: sketch icon in a tinted bubble, value and label.
class StatTile extends StatelessWidget {
  final ToadIcon icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback? onTap;
  final double seed;

  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.onTap,
    this.seed = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SketchCard(
        seed: seed,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.16),
              ),
              child: Center(
                child: SketchIcon(icon: icon, size: 20, color: accent, seed: seed + 1),
              ),
            ),
            const SizedBox(height: 10),
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
}
