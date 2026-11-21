import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'sketchy.dart';
import 'theme.dart';

/// Every icon in toadHEALTH is a hand-drawn ink sketch - and the running and
/// walking toads are the stars of the set.
enum ToadIcon {
  home,
  run,
  walk,
  drop,
  heart,
  watch,
  moon,
  flame,
  paws,
  face,
  chart,
  leaf,
  plus,
  minus,
  gear,
  chevron,
  sparkle,
  target,
  lock,
}

/// Paints a [ToadIcon] with wobbly ink strokes in a 24x24 design space.
class SketchIconPainter extends CustomPainter {
  final ToadIcon icon;
  final Color color;
  final double strokeWidth;
  final double seed;
  final bool filled;

  SketchIconPainter({
    required this.icon,
    required this.color,
    this.strokeWidth = 1.7,
    this.seed = 1,
    this.filled = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 24.0;
    canvas.save();
    canvas.translate((size.width - 24 * s) / 2, (size.height - 24 * s) / 2);
    canvas.scale(s, s);
    switch (icon) {
      case ToadIcon.home:
        _home(canvas);
        break;
      case ToadIcon.run:
        _run(canvas);
        break;
      case ToadIcon.walk:
        _walk(canvas);
        break;
      case ToadIcon.drop:
        _drop(canvas);
        break;
      case ToadIcon.heart:
        _heart(canvas);
        break;
      case ToadIcon.watch:
        _watch(canvas);
        break;
      case ToadIcon.moon:
        _moon(canvas);
        break;
      case ToadIcon.flame:
        _flame(canvas);
        break;
      case ToadIcon.paws:
        _paws(canvas);
        break;
      case ToadIcon.face:
        _face(canvas);
        break;
      case ToadIcon.chart:
        _chart(canvas);
        break;
      case ToadIcon.leaf:
        _leaf(canvas);
        break;
      case ToadIcon.plus:
        _plus(canvas);
        break;
      case ToadIcon.minus:
        _minus(canvas);
        break;
      case ToadIcon.gear:
        _gear(canvas);
        break;
      case ToadIcon.chevron:
        _chevron(canvas);
        break;
      case ToadIcon.sparkle:
        _sparkle(canvas);
        break;
      case ToadIcon.target:
        _target(canvas);
        break;
      case ToadIcon.lock:
        _lock(canvas);
        break;
    }
    canvas.restore();
  }

  void _stroke(Canvas canvas, Path path, {double opacity = 1.0, double width = 1}) {
    drawSketchStroke(
      canvas,
      path,
      color: color,
      width: strokeWidth * width,
      opacity: opacity,
      ghost: false,
    );
  }

  void _fillIf(Canvas canvas, Path path, {double opacity = 0.22}) {
    if (filled) {
      canvas.drawPath(path, fillPaint(color, opacity: opacity));
    }
  }

  // The running toad: tilted body, forward stride, speed lines.
  void _run(Canvas canvas) {
    _stroke(canvas,
        sketchLine(const Offset(1.5, 9), const Offset(6, 9), seed: seed + 0.3, amp: 0.3),
        opacity: 0.8, width: 0.8);
    _stroke(canvas,
        sketchLine(const Offset(1, 12.5), const Offset(4.6, 12.5), seed: seed + 0.6, amp: 0.3),
        opacity: 0.8, width: 0.8);
    _stroke(canvas,
        sketchLine(const Offset(2, 16), const Offset(5.4, 16), seed: seed + 0.9, amp: 0.3),
        opacity: 0.8, width: 0.8);

    canvas.save();
    canvas.translate(13.5, 12.5);
    canvas.rotate(-0.30);
    canvas.translate(-13.5, -12.5);
    final body = sketchEllipse(const Offset(13.5, 12.5), 5.4, 3.5, seed: seed + 1.4, amp: 0.5);
    _fillIf(canvas, body);
    _stroke(canvas, body);
    canvas.restore();

    final head = sketchEllipse(const Offset(18.0, 9.2), 2.5, 2.2, seed: seed + 2.8, amp: 0.4);
    _stroke(canvas, head, width: 0.9);
    canvas.drawCircle(const Offset(18.8, 8.8), 1.0, fillPaint(color));

    _stroke(canvas,
        sketchThrough(const [Offset(16.5, 14.5), Offset(19, 15.8), Offset(20.8, 18.6)],
            seed: seed + 3.3, amp: 0.4),
        width: 0.9);
    _stroke(canvas,
        sketchThrough(const [Offset(10.5, 14.8), Offset(9.2, 16.6), Offset(6.8, 18.4)],
            seed: seed + 4.1, amp: 0.4),
        width: 0.9);
  }

  // The walking toad: upright, one little foot lifted.
  void _walk(Canvas canvas) {
    final body = sketchEllipse(const Offset(12.5, 12.5), 5.0, 3.6, seed: seed, amp: 0.5);
    _fillIf(canvas, body);
    _stroke(canvas, body);

    final head = sketchEllipse(const Offset(16.6, 8.8), 2.5, 2.2, seed: seed + 1.9, amp: 0.4);
    _stroke(canvas, head, width: 0.9);
    canvas.drawCircle(const Offset(17.4, 8.4), 1.0, fillPaint(color));

    _stroke(canvas,
        sketchThrough(const [Offset(15.5, 15), Offset(16.6, 17), Offset(17.6, 19)],
            seed: seed + 2.6, amp: 0.4),
        width: 0.9);
    _stroke(canvas,
        sketchThrough(const [Offset(9.5, 15), Offset(10.4, 17), Offset(8.6, 19)],
            seed: seed + 3.4, amp: 0.4),
        width: 0.9);
    _stroke(canvas,
        sketchLine(const Offset(19.5, 12), const Offset(21.5, 11.2), seed: seed + 5, amp: 0.2),
        opacity: 0.5, width: 0.7);
  }

  void _home(Canvas canvas) {
    _stroke(canvas,
        sketchThrough(const [Offset(2.5, 12.5), Offset(12, 3.5), Offset(21.5, 12.5)],
            seed: seed, amp: 0.5));
    _stroke(canvas,
        sketchThrough(
            const [Offset(5, 10.5), Offset(5, 20.5), Offset(19, 20.5), Offset(19, 10.5)],
            seed: seed + 1.1,
            amp: 0.5));
    _stroke(canvas,
        sketchThrough(
            const [Offset(10, 20.5), Offset(10, 14.5), Offset(14, 14.5), Offset(14, 20.5)],
            seed: seed + 2.2,
            amp: 0.4),
        width: 0.9);
  }

  void _drop(Canvas canvas) {
    final d = sketchThrough(
      const [
        Offset(12, 3.2),
        Offset(15.2, 6.8),
        Offset(18.6, 11.5),
        Offset(19, 14.6),
        Offset(16.8, 18.2),
        Offset(12, 20.6),
        Offset(7.2, 18.2),
        Offset(5, 14.6),
        Offset(5.4, 11.5),
        Offset(8.8, 6.8),
      ],
      closed: true,
      seed: seed,
      amp: 0.5,
    );
    _fillIf(canvas, d, opacity: 0.25);
    _stroke(canvas, d);
    _stroke(canvas,
        sketchArc(const Offset(9.6, 11), 2.6, 2.4, 1.6, seed: seed + 2, amp: 0.3),
        opacity: 0.7, width: 0.8);
  }

  void _heart(Canvas canvas) {
    final h = sketchThrough(
      const [
        Offset(12, 20),
        Offset(6.2, 14.6),
        Offset(4.2, 10.4),
        Offset(5.4, 6.8),
        Offset(8.8, 5.4),
        Offset(12, 7.6),
        Offset(15.2, 5.4),
        Offset(18.6, 6.8),
        Offset(19.8, 10.4),
        Offset(17.8, 14.6),
      ],
      closed: true,
      seed: seed,
      amp: 0.5,
    );
    _fillIf(canvas, h, opacity: 0.25);
    _stroke(canvas, h);
  }

  void _watch(Canvas canvas) {
    // Straps above and below the case.
    final top = sketchRoundRect(
      const Rect.fromLTWH(8.4, 1.4, 7.2, 4.4),
      radius: 1.8,
      seed: seed,
      amp: 0.3,
    );
    _fillIf(canvas, top, opacity: 0.18);
    _stroke(canvas, top, width: 0.95);
    final bottom = sketchRoundRect(
      const Rect.fromLTWH(8.4, 18.2, 7.2, 4.4),
      radius: 1.8,
      seed: seed + 1.2,
      amp: 0.3,
    );
    _fillIf(canvas, bottom, opacity: 0.18);
    _stroke(canvas, bottom, width: 0.95);

    // Case: a wobbly pen-drawn circle.
    final casePath = sketchEllipse(
      const Offset(12, 12),
      6.8,
      6.8,
      seed: seed + 2.4,
      amp: 0.45,
    );
    _fillIf(canvas, casePath, opacity: 0.12);
    _stroke(canvas, casePath);

    // Dial ticks at the four cardinal points.
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final o1 = Offset(12 + math.cos(a) * 5.5, 12 + math.sin(a) * 5.5);
      final o2 = Offset(12 + math.cos(a) * 4.5, 12 + math.sin(a) * 4.5);
      _stroke(
        canvas,
        sketchLine(o1, o2, seed: seed + 10.0 + i, amp: 0.15),
        width: 0.85,
      );
    }

    // A little heart on the dial: it is a health watch, after all.
    final heart = sketchThrough(
      const [
        Offset(12, 15.1),
        Offset(10.1, 13.3),
        Offset(9.7, 11.7),
        Offset(10.5, 10.6),
        Offset(12, 11.4),
        Offset(13.5, 10.6),
        Offset(14.3, 11.7),
        Offset(13.9, 13.3),
      ],
      closed: true,
      seed: seed + 4.1,
      amp: 0.2,
    );
    _fillIf(canvas, heart, opacity: 0.30);
    _stroke(canvas, heart, width: 0.9);
  }

  void _moon(Canvas canvas) {
    _stroke(canvas,
        sketchThrough(
            const [Offset(14.5, 3.8), Offset(9.5, 6.5), Offset(6.5, 12), Offset(9.5, 17.5), Offset(14.5, 20.2)],
            seed: seed,
            amp: 0.5));
    _stroke(canvas,
        sketchThrough(
            const [Offset(14.5, 3.8), Offset(11.5, 7.5), Offset(10.5, 12), Offset(11.8, 16.5), Offset(14.5, 20.2)],
            seed: seed + 1.7,
            amp: 0.5),
        width: 0.85);
    _sparkleAt(canvas, const Offset(18.6, 6.2), 1.8);
    _sparkleAt(canvas, const Offset(20.0, 13.5), 1.4);
  }

  void _flame(Canvas canvas) {
    final f = sketchThrough(
      const [
        Offset(12, 3),
        Offset(14.8, 7),
        Offset(17.8, 11),
        Offset(17.4, 15.2),
        Offset(14.6, 18.6),
        Offset(12, 20.4),
        Offset(9.4, 18.6),
        Offset(6.6, 15.2),
        Offset(6.2, 11),
        Offset(9.2, 7),
      ],
      closed: true,
      seed: seed,
      amp: 0.5,
    );
    _fillIf(canvas, f, opacity: 0.25);
    _stroke(canvas, f);
    _stroke(canvas,
        sketchThrough(const [Offset(12, 9.5), Offset(13.6, 12.5), Offset(12, 16.2)],
            seed: seed + 3, amp: 0.3),
        opacity: 0.7, width: 0.8);
  }

  void _paw(Canvas canvas, Offset center, double s, double sd) {
    final pad = sketchEllipse(center, s * 0.75, s * 0.55, seed: sd, amp: 0.3);
    _stroke(canvas, pad, width: 0.85);
    for (var i = -1; i <= 1; i++) {
      canvas.drawCircle(center.translate(i * s * 0.62, -s * 0.75), s * 0.18, fillPaint(color));
    }
  }

  void _paws(Canvas canvas) {
    _paw(canvas, const Offset(7, 13), 2.6, seed);
    _paw(canvas, const Offset(16, 17), 2.3, seed + 2.2);
    _stroke(canvas,
        sketchLine(const Offset(9.5, 7), const Offset(12, 5.5), seed: seed + 5, amp: 0.2),
        opacity: 0.5, width: 0.6);
  }

  void _face(Canvas canvas) {
    final head = sketchEllipse(const Offset(12, 13.6), 7.8, 6.8, seed: seed, amp: 0.5);
    _fillIf(canvas, head);
    _stroke(canvas, head);
    for (final sx in const [-1.0, 1.0]) {
      final bump =
          sketchEllipse(Offset(12 + sx * 3.6, 7.4), 2.6, 2.4, seed: seed + sx + 2, amp: 0.3);
      _stroke(canvas, bump, width: 0.85);
      canvas.drawCircle(Offset(12 + sx * 3.6, 7.4), 1.0, fillPaint(color));
    }
    _stroke(canvas,
        sketchArc(const Offset(12, 14.8), 4.2, 0.5, 2.2, seed: seed + 4, amp: 0.3, rx: 4.2, ry: 3.0),
        width: 0.85);
    canvas.drawCircle(const Offset(10.6, 11.6), 0.55, fillPaint(color, opacity: 0.8));
    canvas.drawCircle(const Offset(13.4, 11.6), 0.55, fillPaint(color, opacity: 0.8));
  }

  void _chart(Canvas canvas) {
    _stroke(canvas,
        sketchThrough(const [Offset(4.5, 4.5), Offset(4.5, 19.5), Offset(19.5, 19.5)],
            seed: seed, amp: 0.4));
    _stroke(canvas, sketchLine(const Offset(8, 16), const Offset(8, 19.2), seed: seed + 1, amp: 0.3),
        width: 1.5);
    _stroke(canvas, sketchLine(const Offset(12, 11.5), const Offset(12, 19.2), seed: seed + 2, amp: 0.3),
        width: 1.5);
    _stroke(canvas, sketchLine(const Offset(16, 13.8), const Offset(16, 19.2), seed: seed + 3, amp: 0.3),
        width: 1.5);
    canvas.drawCircle(const Offset(16, 12.2), 1.0, fillPaint(color));
  }

  void _leaf(Canvas canvas) {
    final l = sketchThrough(
      const [
        Offset(19, 4.8),
        Offset(13.5, 6.2),
        Offset(9, 9.5),
        Offset(6.5, 14),
        Offset(7, 18.5),
        Offset(10.5, 17.5),
        Offset(14.5, 14.5),
        Offset(17, 10),
      ],
      closed: true,
      seed: seed,
      amp: 0.5,
    );
    _fillIf(canvas, l);
    _stroke(canvas, l);
    _stroke(canvas,
        sketchLine(const Offset(18, 5.8), const Offset(8.2, 17.6), seed: seed + 2, amp: 0.4),
        opacity: 0.7, width: 0.8);
    _stroke(canvas,
        sketchLine(const Offset(14.4, 8.2), const Offset(12.8, 11.4), seed: seed + 3, amp: 0.2),
        opacity: 0.5, width: 0.6);
    _stroke(canvas,
        sketchLine(const Offset(11.2, 10.6), const Offset(9.4, 13.6), seed: seed + 4, amp: 0.2),
        opacity: 0.5, width: 0.6);
  }

  void _plus(Canvas canvas) {
    _stroke(canvas, sketchLine(const Offset(12, 5.5), const Offset(12, 18.5), seed: seed, amp: 0.3));
    _stroke(canvas, sketchLine(const Offset(5.5, 12), const Offset(18.5, 12), seed: seed + 1, amp: 0.3));
  }

  void _minus(Canvas canvas) {
    _stroke(canvas, sketchLine(const Offset(5.5, 12), const Offset(18.5, 12), seed: seed, amp: 0.3));
  }

  void _gear(Canvas canvas) {
    final ring = sketchEllipse(const Offset(12, 12), 6.2, 6.2, seed: seed, amp: 0.4);
    _stroke(canvas, ring);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + 0.26;
      final p1 = Offset(12 + math.cos(a) * 7.6, 12 + math.sin(a) * 7.6);
      final p2 = Offset(12 + math.cos(a) * 10.2, 12 + math.sin(a) * 10.2);
      _stroke(canvas, sketchLine(p1, p2, seed: i * 1.3, amp: 0.2), width: 0.9);
    }
    canvas.drawCircle(const Offset(12, 12), 1.4, fillPaint(color));
  }

  void _chevron(Canvas canvas) {
    _stroke(canvas,
        sketchThrough(const [Offset(9, 5.5), Offset(15.5, 12), Offset(9, 18.5)],
            seed: seed, amp: 0.35));
  }

  void _sparkleAt(Canvas canvas, Offset p, double r) {
    _stroke(canvas, sketchLine(p.translate(-r, 0), p.translate(r, 0), seed: p.dx, amp: 0.15),
        width: 0.7);
    _stroke(canvas, sketchLine(p.translate(0, -r), p.translate(0, r), seed: p.dy + 1, amp: 0.15),
        width: 0.7);
  }

  void _sparkle(Canvas canvas) {
    _sparkleAt(canvas, const Offset(12, 12), 6);
    _sparkleAt(canvas, const Offset(19, 5.5), 2);
  }

  void _target(Canvas canvas) {
    _stroke(canvas, sketchEllipse(const Offset(12, 12), 7.2, 7.2, seed: seed, amp: 0.4));
    _stroke(canvas, sketchEllipse(const Offset(12, 12), 3.2, 3.2, seed: seed + 1, amp: 0.3),
        width: 0.9);
    canvas.drawCircle(const Offset(12, 12), 1.2, fillPaint(color));
  }

  void _lock(Canvas canvas) {
    // Shackle.
    _stroke(canvas,
        sketchArc(const Offset(12, 9.5), 4.6, math.pi, math.pi * 1.15, seed: seed, amp: 0.3),
        width: 0.95);
    // Body.
    final body =
        sketchRoundRect(const Rect.fromLTWH(6, 10, 12, 9.5), radius: 3, seed: seed + 1.5, amp: 0.4);
    _fillIf(canvas, body, opacity: 0.22);
    _stroke(canvas, body);
    canvas.drawCircle(const Offset(12, 14.5), 1.4, fillPaint(color));
    _stroke(canvas,
        sketchLine(const Offset(12, 14.5), const Offset(12, 17), seed: seed + 3, amp: 0.2),
        width: 0.85);
  }

  @override
  bool shouldRepaint(covariant SketchIconPainter oldDelegate) {
    return oldDelegate.icon != icon ||
        oldDelegate.color != color ||
        oldDelegate.seed != seed ||
        oldDelegate.filled != filled;
  }
}

/// Convenience widget wrapping [SketchIconPainter].
class SketchIcon extends StatelessWidget {
  final ToadIcon icon;
  final double size;
  final Color? color;
  final double strokeWidth;
  final double seed;
  final bool filled;

  const SketchIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.strokeWidth = 1.7,
    this.seed = 1,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? ToadColors.ink;
    return CustomPaint(
      size: Size.square(size),
      painter: SketchIconPainter(
        icon: icon,
        color: color,
        strokeWidth: strokeWidth,
        seed: seed,
        filled: filled,
      ),
    );
  }
}
