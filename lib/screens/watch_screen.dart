import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../charts.dart';
import '../icon_painter.dart';
import '../sketchy.dart';
import '../state/app_services.dart';
import '../state/watch_controller.dart';
import '../theme.dart';
import '../toad_painter.dart';
import '../widgets.dart';

/// Pond Watch: wire a smart watch to the pond.
///
/// The link is honest and de-Googled by design: plain BLE GATT to the
class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen>
    with TickerProviderStateMixin {
  /// Soft idle pulse for the watch illustration and ripples.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  /// Expanding radar rings while scanning.
  late final AnimationController _radar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  /// The toad's run cycle; its duration is re-tuned to the live BPM.
  late final AnimationController _pace = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  int _lastPacedBpm = 0;

  @override
  void dispose() {
    _pulse.dispose();
    _radar.dispose();
    _pace.dispose();
    super.dispose();
  }

  /// Re-tune the toad's run speed to the heartbeat. Faster heart, faster
  /// toad - the mascot literally keeps pace with the watch.
  void _paceTo(int bpm) {
    if (bpm == _lastPacedBpm) return;
    _lastPacedBpm = bpm;
    final ms = bpm <= 0
        ? 1100
        : (60000 / math.max(bpm, 30) * 3).round().clamp(360, 1600);
    _pace.duration = Duration(milliseconds: ms);
    if (!_pace.isAnimating) _pace.repeat();
  }

  void _tap() {
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final watch = AppServices.watch;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(
                color: ToadColors.pond.withOpacity(0.14),
                base: 0.07,
                amp: 12,
                phase: 0.6,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(
                color: ToadColors.lilypad.withOpacity(0.16),
                base: 0.14,
                amp: 15,
                phase: 2.2,
              ),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: watch,
              builder: (context, _) {
                if (watch.connected) {
                  _paceTo(watch.bpm);
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildErrorNote(watch.error),
                    switch (watch.state) {
                      WatchLinkState.off => _buildIntro(watch),
                      WatchLinkState.scanning => _buildScanning(watch),
                      WatchLinkState.connecting =>
                        _buildConnecting(watch.device?.name ?? 'your buddy'),
                      WatchLinkState.connected => _buildConnected(watch),
                    },
                    const SizedBox(height: 12),
                    _buildPrivacyNote(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        SketchButton(
          onTap: () => Navigator.of(context).pop(),
          padding: const EdgeInsets.all(8),
          radius: 24,
          seed: 4.2,
          child: const SketchIcon(
            icon: ToadIcon.chevron,
            size: 20,
            color: ToadColors.toadDeep,
            seed: 3,
          ),
        ),
        const SizedBox(width: 10),
        Text('Pond Watch', style: ToadText.h2),
        const Spacer(),
        const SketchIcon(
          icon: ToadIcon.watch,
          size: 26,
          color: ToadColors.pondDeep,
          seed: 8,
        ),
      ],
    );
  }

  Widget _buildErrorNote(String? error) {
    if (error == null) return const SizedBox(height: 0);
    final message = switch (error) {
      'perm' => 'Bluetooth needs the "Nearby devices" permission. Allow it '
          'for toadHEALTH and try again.',
      'bt_off' => 'Bluetooth seems to be napping. Switch it on and try again.',
      'scan' => 'The pond scan could not start. Try again in a moment.',
      'connect' => 'Could not hop over to that buddy. Make sure the watch '
          'is awake and in range, then try again.',
      'no_hr' => 'That buddy does not share a heart-rate service, so there '
          'is nothing to read yet.',
      _ => 'Something wobbled. Try again.',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SketchCard(
        seed: 9.3,
        padding: const EdgeInsets.all(12),
        background: ToadColors.coral.withOpacity(0.10),
        child: Row(
          children: [
            const SketchIcon(
              icon: ToadIcon.heart,
              size: 20,
              color: ToadColors.coral,
              seed: 5,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: ToadText.body)),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(WatchController watch) {
    return Column(
      children: [
        SketchCard(
          seed: 2.2,
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              SizedBox(
                width: 190,
                height: 230,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _WatchPainter(
                        pose: ToadPose.idle,
                        phase: _pulse.value,
                        bob: math.sin(_pulse.value * 2 * math.pi) * 2,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Clip a buddy onto your pond', style: ToadText.h2),
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'toadHEALTH listens for nearby smart watches and '
                  'heart-rate straps over Bluetooth. Pick yours from the '
                  'pond and the toad starts pacing to your heartbeat - '
                  'beats per minute become hops per minute.',
                  style: ToadText.body,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SketchButton(
                      onTap: () {
                        _tap();
                        watch.startScan();
                      },
                      child: const Text(
                        'Scan the pond',
                        style:
                            TextStyle(fontFamily: 'PatrickHand', fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SketchButton(
                      onTap: () {
                        _tap();
                        watch.startDemo();
                      },
                      background: ToadColors.toadLight,
                      borderColor: ToadColors.toadDeep,
                      child: const Text(
                        'Meet the demo buddy',
                        style:
                            TextStyle(fontFamily: 'PatrickHand', fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanning(WatchController watch) {
    return Column(
      children: [
        SketchCard(
          seed: 2.6,
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              SizedBox(
                width: 170,
                height: 170,
                child: AnimatedBuilder(
                  animation: _radar,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _RadarPainter(t: _radar.value),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text('listening over the pond...', style: ToadText.h2),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Wear OS buddies: keep the watch screen awake and turn on '
                  'heart-rate sharing. Straps: just wear them. Nearby '
                  'buddies hop in below as they are found.',
                  style: ToadText.body,
                ),
              ),
              const SizedBox(height: 12),
              SketchButton(
                onTap: () {
                  _tap();
                  watch.stopScan();
                },
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: const Text(
                  'Stop listening',
                  style: TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Buddies found', accent: ToadColors.pond),
        const SizedBox(height: 10),
        if (watch.devices.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'no buddies yet - keep the watch close and awake',
              style: ToadText.label,
            ),
          )
        else
          for (final buddy in watch.devices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DeviceCard(
                buddy: buddy,
                onConnect: () {
                  _tap();
                  watch.connect(buddy);
                },
              ),
            ),
        const SizedBox(height: 6),
        SketchButton(
          onTap: () {
            _tap();
            watch.startDemo();
          },
          background: ToadColors.toadLight,
          borderColor: ToadColors.toadDeep,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Text(
            'or meet the demo buddy',
            style: TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildConnecting(String name) {
    return SketchCard(
      seed: 3.7,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          SizedBox(
            width: 190,
            height: 190,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulse, _radar]),
              builder: (context, _) {
                final hop = math.sin(_pulse.value * 2 * math.pi);
                return Transform.translate(
                  offset: Offset(0, -14 * hop),
                  child: SizedBox(
                    width: 170,
                    height: 170,
                    child: CustomPaint(
                      painter: _RadarPainter(
                        t: _radar.value,
                        color: ToadColors.toad,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text('Hopping over to $name...', style: ToadText.h2),
          const SizedBox(height: 4),
          const Text(
            'negotiating the heart-rate pipe over Bluetooth',
            style: ToadText.label,
          ),
          const SizedBox(height: 12),
          SketchButton(
            onTap: () {
              _tap();
              AppServices.watch.disconnect();
            },
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: const Text(
              'Never mind',
              style: TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnected(WatchController watch) {
    final demo = watch.demoMode;
    final bpm = watch.bpm;
    final zone = ((bpm - 40) / 140).clamp(0.0, 1.0).toDouble();
    return Column(
      children: [
        SketchCard(
          seed: 4.1,
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  const SketchIcon(
                    icon: ToadIcon.watch,
                    size: 24,
                    color: ToadColors.pondDeep,
                    seed: 6,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      watch.device?.name ?? 'Pond buddy',
                      style: ToadText.h2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (demo)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ToadColors.sun.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'demo buddy',
                        style: TextStyle(
                          fontFamily: 'PatrickHand',
                          fontSize: 11.5,
                          color: ToadColors.ink,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 236,
                height: 236,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulse, _pace]),
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PulseRipplePainter(
                              t: _pulse.value,
                              color: ToadColors.coral,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: SketchRingPainter(
                              progress: zone,
                              progressColor: ToadColors.coral,
                              trackColor: ToadColors.ink,
                              strokeWidth: 7,
                              seed: 5.5,
                            ),
                          ),
                        ),
                        // The toad jogs inside the ring, paced by the heart.
                        Transform.translate(
                          offset: Offset(
                              0, -3 * math.sin(_pace.value * 2 * math.pi)),
                          child: SizedBox(
                            width: 150,
                            height: 150,
                            child: CustomPaint(
                              painter: ToadPainter(
                                pose: ToadPose.run,
                                phase: _pace.value,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedNumber(value: bpm, style: ToadText.number),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('bpm', style: ToadText.label),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                bpm == 0
                    ? 'waiting for the first heartbeat...'
                    : 'the toad is pacing your heartbeat',
                style: ToadText.label,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 110,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SparklinePainter(
                    values: List<int>.from(watch.bpmHistory),
                    color: ToadColors.coral,
                  ),
                ),
              ),
              const SizedBox(height: 14),
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
                      _zoneCopy(bpm),
                      style: ToadText.body,
                    ),
                  ),
                  if (watch.battery >= 0)
                    Text(
                      'watch battery ${watch.battery}%',
                      style: ToadText.label,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SketchButton(
                onTap: () {
                  _tap();
                  watch.disconnect();
                },
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                background: ToadColors.coral.withOpacity(0.12),
                borderColor: ToadColors.coral,
                child: const Text(
                  'Unlink buddy',
                  style: TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        if (bpm > 0) ...[
          const SizedBox(height: 16),
          SketchCard(
            seed: 6.3,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const SketchIcon(
                  icon: ToadIcon.sparkle,
                  size: 22,
                  color: ToadColors.toadDeep,
                  seed: 12,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Heartbeats and hops stay inside the vault, sealed with '
                    'AES-256. The buddy link is Bluetooth-only - no cloud, '
                    'no Google, no wires.',
                    style: ToadText.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _zoneCopy(int bpm) {
    if (bpm == 0) return 'The pond is calm.';
    if (bpm < 60) return 'Resting ripple. Lovely and slow.';
    if (bpm < 90) return 'Gentle paddle zone. Great for long hops.';
    if (bpm < 120) return 'Lively lily zone - the toad is working.';
    return 'Sprint of the pond! Ribbit at full speed.';
  }

  Widget _buildPrivacyNote() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'The watch link speaks the standard Bluetooth heart-rate profile '
        '(no Google Wear layer, no Play Services, no network). '
        'Readings never leave this device.',
        style: ToadText.label,
      ),
    );
  }
}

// Private painters

/// Hand-drawn watch: strap, case, ticks - and the toad living on the dial.
class _WatchPainter extends CustomPainter {
  final ToadPose pose;
  final double phase;
  final double bob;

  const _WatchPainter({required this.pose, required this.phase, this.bob = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 24.0;
    canvas.save();
    canvas.translate((size.width - 24 * s) / 2, (size.height - 24 * s) / 2);
    canvas.scale(s, s);

    // Straps.
    final top = sketchRoundRect(
      const Rect.fromLTWH(8.5, 1.2, 7, 4.6),
      radius: 1.8,
      seed: 1.1,
      amp: 0.3,
    );
    canvas.drawPath(top, fillPaint(ToadColors.pondDeep, opacity: 0.25));
    drawSketchStroke(canvas, top, color: ToadColors.ink, width: 0.95);
    final bottom = sketchRoundRect(
      const Rect.fromLTWH(8.5, 18.2, 7, 4.6),
      radius: 1.8,
      seed: 2.2,
      amp: 0.3,
    );
    canvas.drawPath(bottom, fillPaint(ToadColors.pondDeep, opacity: 0.25));
    drawSketchStroke(canvas, bottom, color: ToadColors.ink, width: 0.95);

    // Case.
    final casePath = sketchEllipse(
      const Offset(12, 12),
      6.9,
      6.9,
      seed: 3.3,
      amp: 0.5,
    );
    canvas.drawPath(casePath, fillPaint(ToadColors.paper));
    drawSketchStroke(canvas, casePath, color: ToadColors.ink, width: 1.15);

    // Ticks.
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final o1 = Offset(
        12 + math.cos(a) * 5.6,
        12 + math.sin(a) * 5.6,
      );
      final o2 = Offset(
        12 + math.cos(a) * 4.6,
        12 + math.sin(a) * 4.6,
      );
      drawSketchStroke(
        canvas,
        sketchLine(o1, o2, seed: 10.0 + i, amp: 0.12),
        color: ToadColors.inkSoft,
        width: 0.85,
      );
    }

    // The toad on the dial - the body of the app, on the wrist.
    canvas.save();
    canvas.translate(12, 12 + bob);
    canvas.translate(-14, -14);
    ToadPainter(pose: pose, phase: phase).paint(canvas, const Size(28, 28));
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WatchPainter oldDelegate) =>
      oldDelegate.pose != pose ||
      oldDelegate.phase != phase ||
      oldDelegate.bob != bob;
}

/// Expanding sketchy radar rings while listening for buddies.
class _RadarPainter extends CustomPainter {
  final double t;
  final Color color;

  const _RadarPainter({required this.t, this.color = ToadColors.pond});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final rMax = math.min(size.width, size.height) / 2 - 6;

    // Pond blob.
    canvas.drawPath(
      blobPath(c, rMax * 0.92, rMax * 0.86, seed: 4.4, wobbleAmp: 0.10),
      fillPaint(ToadColors.lilypad.withOpacity(0.16)),
    );

    for (var i = 0; i < 3; i++) {
      final tt = (t + i / 3) % 1.0;
      final r = 6 + tt * rMax;
      final opacity = (1 - tt) * 0.55;
      drawSketchStroke(
        canvas,
        sketchEllipse(c, r, r, seed: 5.0 + i, amp: 0.6),
        color: color,
        width: 1.4,
        opacity: opacity,
        ghost: false,
      );
    }

    // The little toad hopping in the middle of the radar.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    final hop = -math.sin(t * 2 * math.pi) * 4;
    canvas.translate(-11, hop - 11);
    ToadPainter(pose: ToadPose.walk, phase: t * 2).paint(
      canvas,
      const Size(22, 22),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}

/// Coral heartbeat ripples behind the progress ring.
class _PulseRipplePainter extends CustomPainter {
  final double t;
  final Color color;

  const _PulseRipplePainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final rMax = math.min(size.width, size.height) / 2 - 8;
    for (var i = 0; i < 2; i++) {
      final tt = (t + i / 2) % 1.0;
      final r = 40 + tt * (rMax - 40);
      drawSketchStroke(
        canvas,
        sketchEllipse(c, r, r, seed: 7.0 + i, amp: 0.7),
        color: color,
        width: 1.2,
        opacity: (1 - tt) * 0.35,
        ghost: false,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PulseRipplePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}

/// Sketchy sparkline of recent heart-rate samples.
class _SparklinePainter extends CustomPainter {
  final List<int> values;
  final Color color;

  const _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Baseline.
    drawSketchStroke(
      canvas,
      sketchLine(
        Offset(4, size.height - 8),
        Offset(size.width - 4, size.height - 8),
        seed: 8.1,
        amp: 0.8,
      ),
      color: ToadColors.inkSoft,
      width: 1.0,
      opacity: 0.5,
      ghost: false,
    );

    if (values.length < 2) {
      // Waiting dot.
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        2.4,
        fillPaint(ToadColors.inkSoft, opacity: 0.6),
      );
      return;
    }

    const lo = 40.0, hi = 180.0;
    final pts = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = 6 + (size.width - 12) * i / (values.length - 1);
      final norm = ((values[i] - lo) / (hi - lo)).clamp(0.0, 1.0).toDouble();
      final y = (size.height - 12) - norm * (size.height - 24);
      pts.add(Offset(x, y));
    }
    final path = sketchThrough(pts, seed: 9.4, amp: 0.5);
    drawSketchStroke(canvas, path, color: color, width: 2.0);

    // Last point heart-dot.
    canvas.drawCircle(pts.last, 2.6, fillPaint(color));
    canvas.drawCircle(pts.last, 2.6, strokePaint(ToadColors.ink, 0.9));
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values;
}

/// Signal-strength doodle bars for a discovered buddy.
class _SignalPainter extends CustomPainter {
  final int rssi;

  const _SignalPainter({required this.rssi});

  @override
  void paint(Canvas canvas, Size size) {
    // Map RSSI: -100 (far) .. -40 (close) -> 1..4 bars.
    final norm = ((rssi + 100) / 60).clamp(0.0, 1.0).toDouble();
    final bars = 1 + (norm * 3.999).floor();
    const barW = 3.4, gap = 2.2;
    for (var i = 0; i < 4; i++) {
      final h = 4.0 + i * 3.0;
      final x = i * (barW + gap);
      final filled = i < bars;
      final rect = Rect.fromLTWH(x, size.height - h, barW, h);
      final path = sketchRoundRect(rect, radius: 1.4, seed: 3.0 + i, amp: 0.2);
      if (filled) {
        canvas.drawPath(path, fillPaint(ToadColors.pondDeep, opacity: 0.85));
      }
      drawSketchStroke(canvas, path, color: ToadColors.inkSoft, width: 0.8);
    }
  }

  @override
  bool shouldRepaint(covariant _SignalPainter oldDelegate) =>
      oldDelegate.rssi != rssi;
}

class _DeviceCard extends StatelessWidget {
  final WatchDevice buddy;
  final VoidCallback onConnect;

  const _DeviceCard({required this.buddy, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return SketchCard(
      seed: buddy.address.hashCode % 9 + 1.0,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const SketchIcon(
            icon: ToadIcon.watch,
            size: 24,
            color: ToadColors.pondDeep,
            seed: 7,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  buddy.name,
                  style: ToadText.body,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'bluetooth buddy',
                  style: ToadText.label,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 26,
            height: 18,
            child: CustomPaint(painter: _SignalPainter(rssi: buddy.rssi)),
          ),
          const SizedBox(width: 10),
          SketchButton(
            onTap: onConnect,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: const Text(
              'Hop over',
              style: TextStyle(fontFamily: 'PatrickHand', fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}
