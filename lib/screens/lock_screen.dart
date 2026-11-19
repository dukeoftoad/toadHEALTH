import 'package:flutter/material.dart';

import '../app.dart';
import '../charts.dart';
import '../nav_shell.dart';
import '../state/app_services.dart';
import '../theme.dart';
import '../toad_painter.dart';
import '../widgets.dart';

/// Shown when the vault exists but is sealed: an app password was set, and
/// only the password (or the one-time recovery code) can wake the toad.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();

  bool _busy = false;
  bool _showRestore = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _code.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await AppServices.vault.unlockWithPassword(_password.text);
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'That password did not open the pond. Try again.';
      });
      return;
    }
    await AppServices.afterUnlock();
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(FlowRoute(page: const HomeShell()));
  }

  Future<void> _restore() async {
    if (_busy) return;
    if (_code.text.trim().isEmpty || _newPassword.text.length < 8) {
      setState(() {
        _error =
            'Enter the recovery code and a new password (8+ characters).';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await AppServices.vault
        .restoreWithRecoveryCode(_code.text, _newPassword.text);
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'That recovery code did not match.';
      });
      return;
    }
    await AppServices.afterUnlock();
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(FlowRoute(page: const HomeShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ToadColors.cream,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BlobPainter(
                color: ToadColors.moss.withOpacity(0.12),
                seed: 4.0,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: BlobPainter(
                color: ToadColors.toadLight.withOpacity(0.25),
                seed: 8.0,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              children: [
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: 130,
                    height: 130,
                    child: CustomPaint(
                      painter: ToadPainter(pose: ToadPose.sleep, phase: 0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(child: Text('The pond is locked', style: ToadText.h1)),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Your records are sealed. Wake the toad to open them.',
                    style: ToadText.label,
                  ),
                ),
                const SizedBox(height: 20),
                SketchCard(
                  seed: 2.2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _password,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _unlock(),
                        decoration: const InputDecoration(
                          hintText: 'app password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SketchButton(
                        onTap: _unlock,
                        background: ToadColors.toad,
                        borderColor: ToadColors.toadDeep,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: _busy && !_showRestore
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      ToadColors.paper,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Unlock the pond',
                                  style: TextStyle(
                                    fontFamily: 'PatrickHand',
                                    fontSize: 16,
                                    color: ToadColors.paper,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: ToadText.body.copyWith(color: ToadColors.coral),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _showRestore = !_showRestore),
                    child: Text(
                      _showRestore
                          ? 'Hide recovery options'
                          : 'Forgot password? Restore access',
                      style: ToadText.body.copyWith(color: ToadColors.toadDeep),
                    ),
                  ),
                ),
                if (_showRestore) ...[
                  const SizedBox(height: 8),
                  SketchCard(
                    seed: 5.5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Password restore', style: ToadText.h2),
                        const SizedBox(height: 4),
                        const Text(
                          'Enter the recovery code you saved when setting '
                          'the password, and pick a new one. The vault is '
                          're-keyed on this device only.',
                          style: ToadText.label,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _code,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'recovery code (XXXXXX-XXXXXX-...)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _newPassword,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'new password (8+ characters)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SketchButton(
                          onTap: _restore,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: _busy && _showRestore
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Restore and set new password',
                                    style: TextStyle(
                                      fontFamily: 'PatrickHand',
                                      fontSize: 15,
                                      color: ToadColors.toadDeep,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
