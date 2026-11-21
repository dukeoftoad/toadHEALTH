import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../appearance.dart';
import '../charts.dart';
import '../icon_painter.dart';
import '../theme.dart';
import '../toad_painter.dart';
import '../widgets.dart';

/// Appearance: the paper the app is drawn on. The four family styles -
/// Sketchbook (the native ink-on-paper), Toad, Toadmark and System
/// Material - and the daylight choice: follow the system, keep the paper
/// bright, or sink to the night pond. Every pick re-inks the app at once.
class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  @override
  Widget build(BuildContext context) {
    final appearance = Appearance.instance;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BlobPainter(
                color: ToadColors.toadLight.withOpacity(0.18),
                seed: 3.0,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
              children: [
                Row(
                  children: [
                    SketchIcon(
                      icon: ToadIcon.face,
                      size: 26,
                      color: ToadColors.toad,
                      seed: 4,
                    ),
                    const SizedBox(width: 10),
                    Text('Appearance', style: ToadText.h1),
                    const Spacer(),
                    SketchButton(
                      onTap: () => Navigator.of(context).pop(),
                      background: ToadColors.paper,
                      borderColor: ToadColors.ink,
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontFamily: 'PatrickHand',
                          fontSize: 15,
                          color: ToadColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'the paper your toad is drawn on',
                  style: ToadText.label,
                ),
                const SizedBox(height: 18),
                SectionHeader(title: 'Theme style', accent: ToadColors.toad),
                const SizedBox(height: 12),
                _StyleCard(
                  selected: appearance.style == ToadThemeStyle.sketchbook,
                  title: 'Sketchbook',
                  subtitle:
                      'the native ink-on-paper - warm cream, swamp greens, '
                      'the toadHEALTH original',
                  preview: const _StylePreviewSwatch(
                    swatches: [
                      Color(0xFFF6F1E0),
                      Color(0xFF5F9C3F),
                      Color(0xFF4E93A3),
                      Color(0xFF2B2B20),
                    ],
                  ),
                  onTap: () => appearance.setStyle(ToadThemeStyle.sketchbook),
                ),
                const SizedBox(height: 12),
                _StyleCard(
                  selected: appearance.style == ToadThemeStyle.toad,
                  title: 'Toad',
                  subtitle:
                      "toadPLAYER's crafted palette - deep moss green with "
                      'warm earth accents, never follows the wallpaper',
                  preview: const _StylePreviewSwatch(
                    swatches: [
                      Color(0xFFF9FAF1),
                      Color(0xFF557B2F),
                      Color(0xFF56624A),
                      Color(0xFF38656A),
                    ],
                  ),
                  onTap: () => appearance.setStyle(ToadThemeStyle.toad),
                ),
                const SizedBox(height: 12),
                _StyleCard(
                  selected: appearance.style == ToadThemeStyle.toadmark,
                  title: 'Toadmark',
                  subtitle:
                      'the frog-lime family brand - ink on warm paper in '
                      'daylight, frog-lime glow on deep ink at night',
                  preview: const _StylePreviewSwatch(
                    swatches: [
                      Color(0xFFFEFAEC),
                      Color(0xFF446E17),
                      Color(0xFF84CC16),
                      Color(0xFF0B100F),
                    ],
                  ),
                  onTap: () => appearance.setStyle(ToadThemeStyle.toadmark),
                ),
                const SizedBox(height: 12),
                _StyleCard(
                  selected: appearance.style == ToadThemeStyle.material,
                  title: 'System Material',
                  subtitle:
                      "Material You - follows your wallpaper's colors on "
                      'Android 12+, toad green elsewhere',
                  preview: const _StylePreviewSwatch(
                    swatches: [
                      Color(0xFFF9FAF3),
                      Color(0xFF5F9C3F),
                      Color(0xFF6FB7C4),
                      Color(0xFF1C1E17),
                    ],
                  ),
                  onTap: () => appearance.setStyle(ToadThemeStyle.material),
                ),
                const SizedBox(height: 24),
                SectionHeader(title: 'Daylight', accent: ToadColors.pond),
                const SizedBox(height: 12),
                SketchCard(
                  seed: 4.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'When the sky dims, the paper can too.',
                        style: ToadText.body,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ModeChip(
                            label: 'System',
                            selected: appearance.mode == ToadMode.system,
                            icon: ToadIcon.face,
                            onTap: () => appearance.setMode(ToadMode.system),
                          ),
                          const SizedBox(width: 8),
                          _ModeChip(
                            label: 'Light',
                            selected: appearance.mode == ToadMode.light,
                            icon: ToadIcon.sparkle,
                            onTap: () => appearance.setMode(ToadMode.light),
                          ),
                          const SizedBox(width: 8),
                          _ModeChip(
                            label: 'Dark',
                            selected: appearance.mode == ToadMode.dark,
                            icon: ToadIcon.moon,
                            onTap: () => appearance.setMode(ToadMode.dark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        appearance.mode == ToadMode.dark
                            ? 'the night pond: deep moss surfaces, cream ink'
                            : appearance.mode == ToadMode.light
                                  ? 'bright paper all day, whatever the sky'
                                  : 'follows your device setting',
                        style: ToadText.label,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: CustomPaint(
                      painter: ToadPainter(
                        pose: ToadPose.cheer,
                        phase: 0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'he likes all of them, honestly',
                    style: ToadText.label,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One style choice: a sheet of paper with a hand-drawn border, the style's
/// palette swatches, and the family toad stamping his approval on the
/// picked one.
class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SketchCard(
        seed: selected ? 2.2 : 5.8,
        background:
            selected ? ToadColors.paper : ToadColors.paper.withOpacity(0.6),
        borderColor: selected ? ToadColors.toadDeep : ToadColors.inkSoft,
        child: Row(
          children: [
            preview,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ToadText.h2),
                  const SizedBox(height: 2),
                  Text(subtitle, style: ToadText.label),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                height: 44,
                child: CustomPaint(
                  painter: ToadPainter(pose: ToadPose.cheer, phase: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Four hand-drawn swatches of one style's palette.
class _StylePreviewSwatch extends StatelessWidget {
  const _StylePreviewSwatch({required this.swatches});

  final List<Color> swatches;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 52,
      child: CustomPaint(
        painter: _SwatchPainter(swatches: swatches),
      ),
    );
  }
}

class _SwatchPainter extends CustomPainter {
  const _SwatchPainter({required this.swatches});

  final List<Color> swatches;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = ToadColors.ink;
    // A loose 2x2 grid of wobbly blobs, each inked around.
    for (var i = 0; i < swatches.length && i < 4; i++) {
      final cx = size.width * (i.isEven ? 0.27 : 0.73);
      final cy = size.height * (i < 2 ? 0.28 : 0.72);
      final r = math.min(size.width, size.height) * 0.21;
      final path = Path()
        ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      paint.color = swatches[i];
      canvas.drawPath(path, paint);
      canvas.drawPath(path, ink);
    }
  }

  @override
  bool shouldRepaint(covariant _SwatchPainter oldDelegate) =>
      oldDelegate.swatches != swatches;
}

/// One daylight choice: a small sketchy chip that fills when picked.
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ToadIcon icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SketchButton(
        onTap: onTap,
        background:
            selected ? ToadColors.toadLight : ToadColors.paper,
        borderColor: selected ? ToadColors.toadDeep : ToadColors.inkSoft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SketchIcon(
              icon: icon,
              size: 16,
              color: selected ? ToadColors.toadDeep : ToadColors.inkSoft,
              seed: 6,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 14,
                  color: selected ? ToadColors.moss : ToadColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
