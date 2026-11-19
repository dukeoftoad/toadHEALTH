import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The hand-drawn ink engine.
///
/// Every line, circle and blob in toadHEALTH goes through these helpers so
/// the whole app looks like it was sketched with a wobbly pen. The wobble is
/// deterministic (seeded value noise), so frames stay stable while animating.

/// Deterministic hash noise in [0, 1).
double hash01(double x) {
  final s = math.sin(x * 127.1 + 311.7) * 43758.5453;
  return s - s.floorToDouble();
}

/// Smooth 1D value noise in [0, 1].
double noise01(double seed, double t) {
  final i = t.floorToDouble();
  final f = t - i;
  final a = hash01(seed + i * 1.13);
  final b = hash01(seed + (i + 1.0) * 1.13);
  final u = f * f * (3.0 - 2.0 * f);
  return a + (b - a) * u;
}

/// Smooth signed noise in [-amp, amp].
double wobble(double seed, double t, double amp) {
  return (noise01(seed, t) - 0.5) * 2.0 * amp;
}

/// A hand-drawn, slightly wobbly line from [a] to [b].
Path sketchLine(Offset a, Offset b,
    {double seed = 0, double amp = 0.8, int steps = 10}) {
  final d = b - a;
  final len = d.distance;
  if (len == 0) {
    return Path()..moveTo(a.dx, a.dy);
  }
  final dir = d / len;
  final perp = Offset(-dir.dy, dir.dx);
  final path = Path()..moveTo(a.dx, a.dy);
  for (var i = 1; i <= steps; i++) {
    final t = i / steps;
    final p = Offset.lerp(a, b, t)!;
    final n = wobble(seed, t * 3.0, amp) * (1.0 - t * 0.15);
    path.lineTo(p.dx + perp.dx * n, p.dy + perp.dy * n);
  }
  return path;
}

/// Smooth sketchy curve through [pts] (quadratic through midpoints).
Path sketchThrough(List<Offset> pts,
    {bool closed = false, double seed = 0, double amp = 0.6}) {
  final p = <Offset>[];
  for (var i = 0; i < pts.length; i++) {
    p.add(Offset(
      pts[i].dx + wobble(seed + i * 3.7, i * 0.9, amp),
      pts[i].dy + wobble(seed + 11.0 + i * 3.7, i * 0.9, amp),
    ));
  }
  final path = Path();
  if (p.isEmpty) return path;
  if (closed) {
    final mid =
        Offset((p.last.dx + p.first.dx) / 2, (p.last.dy + p.first.dy) / 2);
    path.moveTo(mid.dx, mid.dy);
    for (var i = 0; i < p.length; i++) {
      final cur = p[i];
      final next = p[(i + 1) % p.length];
      final m = Offset((cur.dx + next.dx) / 2, (cur.dy + next.dy) / 2);
      path.quadraticBezierTo(cur.dx, cur.dy, m.dx, m.dy);
    }
    path.close();
  } else {
    path.moveTo(p.first.dx, p.first.dy);
    for (var i = 1; i < p.length - 1; i++) {
      final m =
          Offset((p[i].dx + p[i + 1].dx) / 2, (p[i].dy + p[i + 1].dy) / 2);
      path.quadraticBezierTo(p[i].dx, p[i].dy, m.dx, m.dy);
    }
    path.lineTo(p.last.dx, p.last.dy);
  }
  return path;
}

/// Sketchy ellipse that slightly overshoots, like a pen-drawn circle.
Path sketchEllipse(
  Offset c,
  double rx,
  double ry, {
  double seed = 0,
  double amp = 1.0,
  double startAngle = -2.2,
  double sweep = math.pi * 2 * 1.06,
  int steps = 30,
}) {
  final pts = <Offset>[];
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final a = startAngle + sweep * t;
    final n = 1.0 + wobble(seed, t * 4.0, amp / math.max(rx, ry));
    pts.add(Offset(
      c.dx + math.cos(a) * rx * n,
      c.dy + math.sin(a) * ry * n,
    ));
  }
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 1; i < pts.length; i++) {
    path.lineTo(pts[i].dx, pts[i].dy);
  }
  return path;
}

/// Sketchy arc segment, optionally elliptical.
Path sketchArc(
  Offset c,
  double r,
  double startAngle,
  double sweep, {
  double seed = 0,
  double amp = 0.5,
  int steps = 14,
  double rx = -1,
  double ry = -1,
}) {
  final ex = rx < 0 ? r : rx;
  final ey = ry < 0 ? r : ry;
  final pts = <Offset>[];
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final a = startAngle + sweep * t;
    final n = 1.0 + wobble(seed, t * 3.0, amp / math.max(ex, ey));
    pts.add(Offset(
      c.dx + math.cos(a) * ex * n,
      c.dy + math.sin(a) * ey * n,
    ));
  }
  return sketchThrough(pts, seed: seed + 5.0, amp: 0.3);
}

/// Sketchy rounded rectangle (stroke it yourself).
Path sketchRoundRect(Rect rect,
    {double radius = 12, double seed = 0, double amp = 1.2}) {
  final pts = <Offset>[
    Offset(rect.left + radius, rect.top),
    Offset(rect.right - radius, rect.top),
    Offset(rect.right - radius * 0.4, rect.top + radius * 0.4),
    Offset(rect.right, rect.top + radius),
    Offset(rect.right, rect.bottom - radius),
    Offset(rect.right - radius * 0.4, rect.bottom - radius * 0.4),
    Offset(rect.right - radius, rect.bottom),
    Offset(rect.left + radius, rect.bottom),
    Offset(rect.left + radius * 0.4, rect.bottom - radius * 0.4),
    Offset(rect.left, rect.bottom - radius),
    Offset(rect.left, rect.top + radius),
    Offset(rect.left + radius * 0.4, rect.top + radius * 0.4),
  ];
  return sketchThrough(pts, closed: true, seed: seed, amp: amp);
}

/// Organic filled blob used for backgrounds.
Path blobPath(
  Offset center,
  double radiusX,
  double radiusY, {
  double seed = 1,
  double wobbleAmp = 0.14,
  int points = 14,
}) {
  final pts = <Offset>[];
  for (var i = 0; i < points; i++) {
    final t = i / points;
    final a = t * math.pi * 2;
    final n = 1.0 + wobble(seed + i * 1.7, i * 1.3, wobbleAmp);
    pts.add(Offset(
      center.dx + math.cos(a) * radiusX * n,
      center.dy + math.sin(a) * radiusY * n,
    ));
  }
  return sketchThrough(pts, closed: true, seed: seed * 0.7, amp: 0.0);
}

Paint strokePaint(Color color, double width, {double opacity = 1.0}) {
  return Paint()
    ..color = color.withOpacity(opacity)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}

Paint fillPaint(Color color, {double opacity = 1.0}) {
  return Paint()
    ..color = color.withOpacity(opacity)
    ..style = PaintingStyle.fill;
}

/// Draws [path] as a pen stroke, with an optional lighter ghost pass for an
/// authentic double-line pen feel.
void drawSketchStroke(
  Canvas canvas,
  Path path, {
  required Color color,
  required double width,
  double opacity = 1.0,
  bool ghost = true,
  double ghostShift = 1.1,
}) {
  canvas.drawPath(path, strokePaint(color, width, opacity: opacity));
  if (ghost) {
    canvas.save();
    canvas.translate(ghostShift, -ghostShift * 0.6);
    canvas.drawPath(
        path, strokePaint(color, width * 0.5, opacity: opacity * 0.35));
    canvas.restore();
  }
}
