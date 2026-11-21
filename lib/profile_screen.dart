import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart' show FlowRoute;
import 'appearance.dart';
import 'screens/appearance_screen.dart';
import 'charts.dart';
import 'data.dart';
import 'icon_painter.dart';
import 'sketchy.dart';
import 'state/app_services.dart';
import 'theme.dart';
import 'toad_painter.dart';
import 'widgets.dart';

/// Profile: your toad identity plus the security & privacy command center -
/// app password, recovery code, encrypted portable backups, demo/erase.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _goalSteps = 8000;
  double _goalWater = 8;
  double _goalSleep = 480;
  bool _goalsSaved = false;

  @override
  void initState() {
    super.initState();
    _goalSteps = HealthData.stepsGoal.toDouble();
    _goalWater = HealthData.waterGoal.toDouble();
    _goalSleep = HealthData.sleepGoalMin.toDouble();
  }

  // ---------- small dialog helpers ----------

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: ToadText.body),
        backgroundColor: ToadColors.moss,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<Map<String, String>?> _twoFieldDialog({
    required String title,
    required String hint1,
    required String hint2,
    bool obscure = true,
    bool multiline = false,
  }) async {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ToadColors.paper,
          title: Text(title, style: ToadText.h2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: c1,
                obscureText: obscure,
                maxLines: multiline ? 3 : 1,
                decoration: InputDecoration(hintText: hint1),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: c2,
                obscureText: obscure,
                maxLines: multiline ? 3 : 1,
                decoration: InputDecoration(hintText: hint2),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop({'a': c1.text, 'b': c2.text}),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    c1.dispose();
    c2.dispose();
    return result;
  }

  Future<bool> _confirmDialog(String title, String body) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ToadColors.paper,
          title: Text(title, style: ToadText.h2),
          content: Text(body, style: ToadText.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes, do it'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _codeDialog(String title, String code, String note) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ToadColors.paper,
          title: Text(title, style: ToadText.h2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ToadColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ToadColors.toad, width: 1.5),
                ),
                child: SelectableText(
                  code,
                  style: TextStyle(
                    fontFamily: 'PatrickHand',
                    fontSize: 16,
                    color: ToadColors.ink,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(note, style: ToadText.label),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                HapticFeedback.selectionClick();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _toast('Copied to the clipboard.');
                }
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // ---------- security flows ----------

  Future<void> _setPasswordFlow() async {
    final r = await _twoFieldDialog(
      title: 'Set app password',
      hint1: 'new password (8+ characters)',
      hint2: 'repeat it',
    );
    if (r == null) return;
    final pw = r['a'] ?? '';
    if (pw.length < 8 || pw != (r['b'] ?? '')) {
      _toast('Passwords must match and be at least 8 characters.');
      return;
    }
    try {
      final code = await AppServices.vault.setPassword(pw);
      await _codeDialog(
        'Recovery code - shown once',
        code,
        'Write this down or store it in your password manager. It restores '
        'access to this vault if you ever forget the password. It is not '
        'stored anywhere and cannot be shown again.',
      );
      setState(() {});
      _toast('App password set. Vault re-keyed.');
    } catch (_) {
      _toast('Could not set the password right now.');
    }
  }

  Future<void> _changePasswordFlow() async {
    final r = await _twoFieldDialog(
      title: 'Change app password',
      hint1: 'current password',
      hint2: 'new password (8+ characters)',
    );
    if (r == null) return;
    final ok = await AppServices.vault
        .changePassword(r['a'] ?? '', r['b'] ?? '');
    setState(() {});
    _toast(ok ? 'Password changed.' : 'The current password did not match.');
  }

  Future<void> _removeLockFlow() async {
    final ok = await _confirmDialog(
      'Remove app password?',
      'Your data stays encrypted, but it will unlock automatically with the '
      'device key. Anyone holding this device could read it.',
    );
    if (!ok) return;
    try {
      await AppServices.vault.clearPassword();
      setState(() {});
      _toast('App lock removed.');
    } catch (_) {
      _toast('Could not remove the lock right now.');
    }
  }

  Future<void> _exportFlow() async {
    final r = await _twoFieldDialog(
      title: 'Encrypted backup',
      hint1: 'backup passphrase (8+ characters)',
      hint2: 'repeat it',
    );
    if (r == null) return;
    final pass = r['a'] ?? '';
    if (pass.length < 8 || pass != (r['b'] ?? '')) {
      _toast('Passphrase must match and be at least 8 characters.');
      return;
    }
    final code = await AppServices.controller.exportBackup(pass);
    await _codeDialog(
      'Backup code',
      code,
      'This is ciphertext. Without the passphrase it is noise. Store it '
      'anywhere you like - notes, email, a file - and paste it back via '
      'Import backup to restore.',
    );
  }

  Future<void> _importFlow() async {
    final r = await _twoFieldDialog(
      title: 'Restore backup',
      hint1: 'paste the TOAD1: backup code',
      hint2: 'backup passphrase',
      obscure: false,
      multiline: true,
    );
    if (r == null) return;
    final ok = await AppServices.controller.importBackup(
      r['a'] ?? '',
      r['b'] ?? '',
    );
    if (!ok) {
      _toast('Import failed - code or passphrase wrong.');
      return;
    }
    setState(() {
      _goalSteps = HealthData.stepsGoal.toDouble();
      _goalWater = HealthData.waterGoal.toDouble();
      _goalSleep = HealthData.sleepGoalMin.toDouble();
      _goalsSaved = false;
    });
    _toast('Backup restored into the vault.');
  }

  Future<void> _seedDemoFlow() async {
    await AppServices.controller.seedDemo();
    setState(() {});
    _toast('Demo pond filled - 30 days of pretend data.');
  }

  Future<void> _wipeFlow() async {
    final ok = await _confirmDialog(
      'Erase everything?',
      'This deletes every record on this device and re-keys the vault with '
      'a fresh encryption key. There is no undo (unless you exported a '
      'backup).',
    );
    if (!ok) return;
    await AppServices.controller.wipeData();
    setState(() {
      _goalSteps = HealthData.stepsGoal.toDouble();
      _goalWater = HealthData.waterGoal.toDouble();
      _goalSleep = HealthData.sleepGoalMin.toDouble();
      _goalsSaved = false;
    });
    _toast('Vault wiped and re-keyed.');
  }

  Future<void> _saveGoals() async {
    await AppServices.controller.updateGoals(
      stepsGoal: _goalSteps.round(),
      waterGoal: _goalWater.round(),
      sleepGoalMin: _goalSleep.round(),
    );
    setState(() => _goalsSaved = true);
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = AppServices.vault.hasPassword;
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
                _buildAvatar(),
                const SizedBox(height: 20),
                SketchCard(
                  seed: 2.4,
                  child: Row(
                    children: [
                      SketchIcon(
                        icon: ToadIcon.flame,
                        size: 30,
                        color: ToadColors.sun,
                        seed: 4,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${HealthData.streakDays}-day hop streak',
                              style: ToadText.h2),
                          Text('longest ever: kept in your vault',
                              style: ToadText.label),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionHeader(title: 'Goals', accent: ToadColors.toad),
                const SizedBox(height: 10),
                _buildGoals(),
                const SizedBox(height: 20),
                SectionHeader(title: 'Appearance', accent: ToadColors.pond),
                const SizedBox(height: 10),
                _buildAppearance(),
                const SizedBox(height: 20),
                SectionHeader(title: 'Security', accent: ToadColors.toad),
                const SizedBox(height: 10),
                _buildSecurity(hasPassword),
                const SizedBox(height: 20),
                SectionHeader(title: 'Backup', accent: ToadColors.toad),
                const SizedBox(height: 10),
                _buildBackup(),
                const SizedBox(height: 20),
                SectionHeader(title: 'Data', accent: ToadColors.toad),
                const SizedBox(height: 10),
                _buildData(),
                const SizedBox(height: 20),
                SectionHeader(title: 'About', accent: ToadColors.toad),
                const SizedBox(height: 10),
                _buildAbout(),
                const SizedBox(height: 24),
                Center(
                  child: Text('local-first. de-googled. toad-approved.',
                      style: ToadText.label),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
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
                      painter: ToadPainter(pose: ToadPose.idle, phase: 0.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Lily Padmore', style: ToadText.h1),
          Text('hop member since spring 2024', style: ToadText.label),
        ],
      ),
    );
  }

  Widget _buildGoals() {
    return SketchCard(
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
            onChanged: (v) => setState(() {
              _goalSteps = v;
              _goalsSaved = false;
            }),
          ),
          const SizedBox(height: 16),
          _GoalSlider(
            label: 'Glasses of water',
            value: _goalWater,
            min: 4,
            max: 12,
            display: (v) => '${v.round()} glasses',
            color: ToadColors.pond,
            onChanged: (v) => setState(() {
              _goalWater = v;
              _goalsSaved = false;
            }),
          ),
          const SizedBox(height: 16),
          _GoalSlider(
            label: 'Hours of sleep',
            value: _goalSleep,
            min: 360,
            max: 600,
            display: (v) => '${(v / 60).toStringAsFixed(1)} hours',
            color: ToadColors.moss,
            onChanged: (v) => setState(() {
              _goalSleep = v;
              _goalsSaved = false;
            }),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SketchButton(
                onTap: _saveGoals,
                background: _goalsSaved ? ToadColors.toadLight : ToadColors.toad,
                borderColor: ToadColors.toadDeep,
                child: Text(
                  _goalsSaved ? 'Saved to the vault' : 'Save goals',
                  style: TextStyle(
                    fontFamily: 'PatrickHand',
                    fontSize: 15,
                    color: _goalsSaved ? ToadColors.toadDeep : ToadColors.paper,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppearance() {
    final style = Appearance.instance.style;
    final styleName = switch (style) {
      ToadThemeStyle.sketchbook => 'Sketchbook - ink on paper',
      ToadThemeStyle.toad => 'Toad - crafted moss green',
      ToadThemeStyle.toadmark => 'Toadmark - the family brand',
      ToadThemeStyle.material => 'System Material - Material You',
    };
    return SketchCard(
      seed: 6.2,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          FlowRoute(page: const AppearanceScreen()),
        ),
        child: Row(
          children: [
            SketchIcon(
              icon: ToadIcon.gear,
              size: 22,
              color: ToadColors.pondDeep,
              seed: 15,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme & daylight', style: ToadText.body),
                  Text(styleName, style: ToadText.label),
                ],
              ),
            ),
            SketchIcon(
              icon: ToadIcon.chevron,
              size: 18,
              color: ToadColors.inkSoft,
              seed: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurity(bool hasPassword) {
    return SketchCard(
      seed: 7.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SketchIcon(
                icon: ToadIcon.lock,
                size: 22,
                color: hasPassword ? ToadColors.toad : ToadColors.inkSoft,
                seed: 15,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasPassword
                      ? 'App lock: ON - password + recovery code'
                      : 'App lock: OFF - sealed by the device key',
                  style: ToadText.body,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your health data is encrypted with AES-256-GCM. On Android the '
            'master key is guarded by the hardware Keystore. This app has no '
            'INTERNET permission - records physically cannot leave the '
            'device.',
            style: ToadText.label,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!hasPassword)
                SketchButton(
                  onTap: _setPasswordFlow,
                  background: ToadColors.toadLight,
                  borderColor: ToadColors.toadDeep,
                  child: const Text(
                    'Set app password',
                    style: TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
                  ),
                )
              else ...[
                SketchButton(
                  onTap: _changePasswordFlow,
                  child: const Text(
                    'Change password',
                    style: TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
                  ),
                ),
                SketchButton(
                  onTap: _removeLockFlow,
                  child: const Text(
                    'Remove lock',
                    style: TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackup() {
    return SketchCard(
      seed: 8.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backups are sealed with AES-256 under a passphrase only you '
            'know. The code is pure ciphertext - store it anywhere, it is '
            'useless without your passphrase.',
            style: ToadText.label,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SketchButton(
                onTap: _exportFlow,
                background: ToadColors.pond.withOpacity(0.18),
                borderColor: ToadColors.pondDeep,
                child: const Text(
                  'Export backup',
                  style: TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
                ),
              ),
              SketchButton(
                onTap: _importFlow,
                child: const Text(
                  'Import backup',
                  style: TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildData() {
    return SketchCard(
      seed: 9.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fill the pond with 30 days of clearly-labelled pretend data to '
            'explore the app - or wipe the vault and re-key it.',
            style: ToadText.label,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SketchButton(
                onTap: _seedDemoFlow,
                child: const Text(
                  'Fill demo pond',
                  style: TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
                ),
              ),
              SketchButton(
                onTap: _wipeFlow,
                background: ToadColors.coral.withOpacity(0.14),
                borderColor: ToadColors.coral,
                child: const Text(
                  'Erase everything',
                  style: TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbout() {
    return SketchCard(
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
                Text('toadHEALTH v1.1.0', style: ToadText.body),
                const SizedBox(height: 2),
                Text(
                  'Local-first, end-to-end encrypted, zero trackers. Every '
                  'stroke is drawn by a toad holding a very steady pen.',
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
            final ratio =
                ((value - min) / (max - min)).clamp(0.0, 1.0).toDouble();
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
