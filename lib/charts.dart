import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'sketchy.dart';
import 'theme.dart';

/// A soft organic blob that fills its box - used for backgrounds.
class BlobPainter extends CustomPainter {
  final Color color;
  final double seed;

  BlobPainter({required this.color, this.seed = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final path = blobPath(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.62,
      size.height * 0.62,
      seed: seed,
      wobbleAmp: 0.10,
    );
    canvas.drawPath(path, fillPaint(color));
  }

  @override
  bool shouldRepaint(covariant BlobPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.seed != seed;
  }
}

/// A flowing wave that fills from a wobbly sine line down to the bottom.
class WavePainter extends CustomPainter {
  final Color color;
  final double base;
  final double amp;
  final double phase;

  WavePainter({
    required this.color,
    this.base = 0.12,
    this.amp = 12,
    this.phase = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pts = <Offset>[];
    for (var i = 0; i <= 48; i++) {
      final x = w * i / 48;
      pts.add(Offset(
        x,
        h * base + math.sin(x / w * math.pi * 2 * 1.6 + phase) * amp,
      ));
    }
    final path = sketchThrough(pts, amp: 0.0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, fillPaint(color));
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.base != base ||
        oldDelegate.phase != phase;
  }
}

/// A sketchy circular progress ring.
class SketchRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;
  final double seed;

  SketchRingPainter({
    required this.progress,
    this.trackColor = ToadColors.ink,
    this.progressColor = ToadColors.toad,
    this.strokeWidth = 6,
    this.seed = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - strokeWidth - 2;

    final track = sketchEllipse(center, r, r, seed: seed, amp: 1.2);
    drawSketchStroke(
      canvas,
      track,
      color: trackColor,
      width: strokeWidth * 0.9,
      opacity: 0.28,
      ghost: false,
    );

    if (progress > 0.01) {
      final sweep = math.pi * 2 * progress;
      final arc = sketchArc(
        center,
        r,
        -math.pi / 2,
        sweep,
        seed: seed + 2,
        amp: 1.0,
        steps: 40,
      );
      drawSketchStroke(canvas, arc, color: progressColor, width: strokeWidth);
    }
  }

  @override
  bool shouldRepaint(covariant SketchRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}

/// A hand-drawn bar chart with wobbly bars and handwritten labels.
class SketchBarsPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final int activeIndex;
  final Color ink;
  final Color barFill;
  final Color activeFill;

  SketchBarsPainter({
    required this.values,
    required this.labels,
    this.activeIndex = -1,
    this.ink = ToadColors.ink,
    this.barFill = ToadColors.toadLight,
    this.activeFill = ToadColors.toad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const plotLeft = 10.0;
    final plotRight = w - 6.0;
    final plotBottom = h - 24.0;
    const plotTop = 8.0;

    drawSketchStroke(
      canvas,
      sketchLine(Offset(plotLeft, plotTop - 2), Offset(plotLeft, plotBottom), seed: 1.1, amp: 0.6),
      color: ink,
      width: 1.4,
      opacity: 0.45,
      ghost: false,
    );
    drawSketchStroke(
      canvas,
      sketchLine(Offset(plotLeft, plotBottom), Offset(plotRight, plotBottom), seed: 2.2, amp: 0.6),
      color: ink,
      width: 1.4,
      opacity: 0.45,
      ghost: false,
    );

    final n = values.length;
    final slot = (plotRight - plotLeft) / n;
    for (var i = 0; i < n; i++) {
      final barW = slot * 0.44;
      final x = plotLeft + slot * i + (slot - barW) / 2;
      final bh = values[i] * (plotBottom - plotTop - 6);
      final rect = Rect.fromLTWH(x, plotBottom - math.max(bh, 6.0), barW, math.max(bh, 6.0));
      final bar = sketchRoundRect(rect, radius: 5, seed: 10 + i * 1.7, amp: 0.9);
      canvas.drawPath(bar, fillPaint(i == activeIndex ? activeFill : barFill));
      drawSketchStroke(
        canvas,
        bar,
        color: ink,
        width: i == activeIndex ? 2.0 : 1.5,
        opacity: i == activeIndex ? 0.95 : 0.5,
        ghost: false,
      );

      if (i < labels.length) {
        final tp = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: const TextStyle(
              fontFamily: 'PatrickHand',
              fontSize: 11,
              color: ToadColors.inkSoft,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, plotBottom + 6));
        tp.dispose();
      }
    }
  }

  @override
  bool shouldRepaint(covariant SketchBarsPainter oldDelegate) {
    return oldDelegate.activeIndex != activeIndex ||
        !listEquals(oldDelegate.values, values) ||
        oldDelegate.barFill != barFill ||
        oldDelegate.activeFill != activeFill;
  }
}

/// A sketchy line chart with a hatched (cross-hatched ink) fill underneath.
class SketchLinePainter extends CustomPainter {
  final List<double> points;
  final Color ink;
  final Color accent;

  SketchLinePainter({
    required this.points,
    this.ink = ToadColors.ink,
    this.accent = ToadColors.toad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const plotL = 8.0;
    final plotR = w - 8.0;
    const plotT = 12.0;
    final plotB = h - 10.0;
    final n = points.length;
    if (n < 2) return;

    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      pts.add(Offset(
        plotL + (plotR - plotL) * i / (n - 1),
        plotB - points[i].clamp(0.0, 1.0).toDouble() * (plotB - plotT),
      ));
    }

    final line = sketchThrough(pts, seed: 5.5, amp: 1.1);
    final area = Path.from(line)
      ..lineTo(plotR, plotB)
      ..lineTo(plotL, plotB)
      ..close();

    canvas.drawPath(area, fillPaint(accent, opacity: 0.10));

    // Diagonal ink hatching under the curve.
    canvas.save();
    canvas.clipPath(area);
    final span = plotB - plotT;
    for (double x = plotL - span; x < plotR; x += 9) {
      drawSketchStroke(
        canvas,
        sketchLine(Offset(x, plotB), Offset(x + span, plotT), seed: x, amp: 0.3, steps: 4),
        color: accent,
        width: 1.2,
        opacity: 0.28,
        ghost: false,
      );
    }
    canvas.restore();

    drawSketchStroke(canvas, line, color: ink, width: 2.2);

    for (var i = 0; i < n; i += 3) {
      canvas.drawCircle(pts[i], 2.2, fillPaint(ToadColors.paper));
      canvas.drawCircle(pts[i], 2.2, strokePaint(ink, 1.4, opacity: 0.8));
    }
  }

  @override
  bool shouldRepaint(covariant SketchLinePainter oldDelegate) {
    return oldDelegate.ink != ink ||
        oldDelegate.accent != accent ||
        !listEquals(oldDelegate.points, points);
  }
}

/// Three rising "Z" glyphs for the sleeping toad.
class ZzzPainter extends CustomPainter {
  final double phase;
  final Color color;

  ZzzPainter({required this.phase, this.color = ToadColors.ink});

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final t = (phase + i * 0.34) % 1.0;
      final s = 7.0 + i * 3.5;
      final x = size.width * 0.58 + i * 10;
      final y = size.height * 0.34 - i * 13 - t * 14;
      final op = math.sin(t * math.pi) * 0.8;
      final z = sketchThrough(
        [
          Offset(x, y),
          Offset(x + s, y),
          Offset(x, y + s * 0.85),
          Offset(x + s, y + s * 0.85),
        ],
        seed: i * 2.2,
        amp: 0.4,
      );
      drawSketchStroke(canvas, z, color: color, width: 2.0, opacity: op, ghost: false);
    }
  }

  @override
  bool shouldRepaint(covariant ZzzPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}

/// Expanding ripples (for taps and splashes).
class RipplePainter extends CustomPainter {
  final double phase;
  final Color color;
  final double cx;
  final double cy;

  RipplePainter({
    required this.phase,
    this.color = ToadColors.pondDeep,
    this.cx = 0.5,
    this.cy = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * cx, size.height * cy);
    for (var i = 0; i < 3; i++) {
      final t = (phase + i * 0.34) % 1.0;
      final r = 8 + t * 30;
      final op = (1 - t) * 0.4;
      canvas.drawCircle(center, r, strokePaint(color, 1.6, opacity: op));
    }
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.color != color;
  }
}

/// The pond: wobbly water surface that rises with [level], plus a lily pad.
class PondPainter extends CustomPainter {
  final double level;
  final double phase;
  final Color water;
  final Color ink;

  PondPainter({
    required this.level,
    this.phase = 0,
    this.water = ToadColors.pond,
    this.ink = ToadColors.ink,
  });

  Path _waveLine(double w, double y, double ph, double amp) {
    final pts = <Offset>[];
    for (var i = 0; i <= 40; i++) {
      final x = w * i / 40;
      pts.add(Offset(x, y + math.sin(x / w * math.pi * 3 + ph) * amp));
    }
    return sketchThrough(pts, amp: 0.3);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final waterTop = h * (1 - level.clamp(0.0, 1.0) * 0.8);
    final ph = phase * math.pi * 2;

    final backPath = _waveLine(w, waterTop - 6, ph + 1.2, 5)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(backPath, fillPaint(water, opacity: 0.35));

    final path = _waveLine(w, waterTop, ph, 7)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, fillPaint(water, opacity: 0.75));

    drawSketchStroke(
      canvas,
      _waveLine(w, waterTop, ph, 7),
      color: ink,
      width: 1.5,
      opacity: 0.30,
      ghost: false,
    );

    // Lily pad the toad sits on.
    final padC = Offset(w * 0.62, waterTop + h * 0.12);
    final pad = sketchEllipse(padC, w * 0.17, 8.5, seed: 3.3, amp: 0.8, sweep: math.pi * 2.03);
    canvas.drawPath(pad, fillPaint(ToadColors.lilypad));
    drawSketchStroke(canvas, pad, color: ink, width: 1.6, opacity: 0.8, ghost: false);
    drawSketchStroke(
      canvas,
      sketchLine(padC, padC + Offset(w * 0.17 - 4, -2.5), seed: 8.8, amp: 0.4),
      color: ink,
      width: 1.3,
      opacity: 0.6,
      ghost: false,
    );

    // Pebbles at the bottom.
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(w * (0.12 + i * 0.22), h - 10 + (i % 2) * 3),
        3.0 - (i % 2),
        fillPaint(ink, opacity: 0.15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant PondPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.phase != phase;
  }
}

/// A small horizontal fill bar (sleep breakdown rows).
class MiniBarPainter extends CustomPainter {
  final double ratio;
  final Color color;
  final Color ink;

  MiniBarPainter({
    required this.ratio,
    this.color = ToadColors.toad,
    this.ink = ToadColors.ink,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final track =
        sketchRoundRect(Rect.fromLTWH(2, h * 0.25, w - 4, h * 0.5), radius: h * 0.25, seed: 2, amp: 0.4);
    drawSketchStroke(canvas, track, color: ink, width: 1.5, opacity: 0.3, ghost: false);

    final fw = math.max(6.0, ratio.clamp(0.0, 1.0).toDouble() * (w - 4));
    final fill =
        sketchRoundRect(Rect.fromLTWH(2, h * 0.25, fw, h * 0.5), radius: h * 0.25, seed: 3, amp: 0.4);
    canvas.drawPath(fill, fillPaint(color, opacity: 0.85));
    drawSketchStroke(canvas, fill, color: ink, width: 1.4, opacity: 0.5, ghost: false);
  }

  @override
  bool shouldRepaint(covariant MiniBarPainter oldDelegate) {
    return oldDelegate.ratio != ratio || oldDelegate.color != color;
  }
}

/// A short wobbly underline squiggle.
class SquigglePainter extends CustomPainter {
  final Color color;

  SquigglePainter({this.color = ToadColors.toad});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final pts = <Offset>[];
    for (var i = 0; i <= 20; i++) {
      pts.add(Offset(w * i / 20, i % 2 == 0 ? 3.0 : 5.2));
    }
    final path = sketchThrough(pts, seed: 4, amp: 0.35);
    drawSketchStroke(canvas, path, color: color, width: 2.2, ghost: false);
  }

  @override
  bool shouldRepaint(covariant SquigglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
