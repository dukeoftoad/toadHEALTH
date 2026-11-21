import 'package:flutter/material.dart';

import '../theme.dart';
import '../toad_painter.dart';
import '../widgets.dart';
import 'update_checker.dart';
import 'update_controller.dart';

/// The self-update card in the About section: check the latest GitHub
/// release, download the APK through the system download manager, and hand
/// it to the package installer. Drawn in the app's own hand-drawn style;
/// ported from the family's toadFILES flow.
class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key, this.controller});

  final UpdateController? controller;

  @override
  Widget build(BuildContext context) {
    final update = controller ?? UpdateController.instance;
    return ListenableBuilder(
      listenable: update,
      builder: (context, _) => _UpdateCardView(update: update),
    );
  }
}

class _UpdateCardView extends StatelessWidget {
  const _UpdateCardView({required this.update});

  final UpdateController update;

  @override
  Widget build(BuildContext context) {
    final state = update.state;
    return SketchCard(
      seed: 8.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SketchIcon(
                icon: ToadIcon.leaf,
                size: 20,
                color: ToadColors.toad,
                seed: 9,
              ),
              const SizedBox(width: 8),
              Text('Update', style: ToadText.h2),
            ],
          ),
          const SizedBox(height: 6),
          switch (state.status) {
            UpdateStatus.idle || UpdateStatus.upToDate => _IdleView(
              update: update,
            ),
            UpdateStatus.checking => const _CheckingView(),
            UpdateStatus.available => _AvailableView(update: update),
            UpdateStatus.downloading => _DownloadingView(update: update),
            UpdateStatus.installing => const Text(
              'The installer has the update — confirm it there.',
              style: ToadText.body,
            ),
            UpdateStatus.needsPermission => _NeedsPermissionView(
              update: update,
            ),
            UpdateStatus.error => _ErrorView(update: update),
          },
        ],
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.update});

  final UpdateController update;

  @override
  Widget build(BuildContext context) {
    final upToDate = update.state.status == UpdateStatus.upToDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (upToDate)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SketchIcon(
                  icon: ToadIcon.leaf,
                  size: 16,
                  color: ToadColors.toadDeep,
                  seed: 9,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "You're on the latest release",
                    style: ToadText.body,
                  ),
                ),
              ],
            ),
          ),
        SketchButton(
          onTap: update.checkForUpdates,
          child: const Text(
            'Check for updates',
            style: TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _CheckingView extends StatelessWidget {
  const _CheckingView();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const SizedBox.square(
        dimension: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text('Checking for updates…', style: ToadText.body),
      ),
    ],
  );
}

class _AvailableView extends StatelessWidget {
  const _AvailableView({required this.update});

  final UpdateController update;

  @override
  Widget build(BuildContext context) {
    final state = update.state;
    final release = state.release;
    if (release == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('toadHEALTH ${release.tagName} is available', style: ToadText.h2),
        const SizedBox(height: 2),
        const Text(
          'Downloaded only if you ask.',
          style: ToadText.label,
        ),
        if (state.message != null) ...[
          const SizedBox(height: 6),
          Text(state.message!, style: ToadText.label),
        ],
        if (release.apkSizeBytes > 0) ...[
          const SizedBox(height: 6),
          Text(
            '${(release.apkSizeBytes / 1024 / 1024).toStringAsFixed(1)} MB',
            style: ToadText.label,
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SketchButton(
              onTap: release.apkUrl == null ? null : update.downloadAndInstall,
              background: ToadColors.toadLight,
              borderColor: ToadColors.toadDeep,
              child: Text(
                'Download & install',
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 14,
                  color: ToadColors.moss,
                ),
              ),
            ),
            SketchButton(
              onTap: update.openReleasePage,
              child: Text(
                'View on GitHub',
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 14,
                  color: ToadColors.ink,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DownloadingView extends StatelessWidget {
  const _DownloadingView({required this.update});

  final UpdateController update;

  @override
  Widget build(BuildContext context) {
    final progress = update.state.progress;
    final total = progress?.totalBytes ?? -1;
    final bytes = progress?.bytesSoFar ?? 0;
    final fraction = total > 0 ? (bytes / total).clamp(0.0, 1.0) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                total > 0
                    ? '${(bytes / 1024 / 1024).toStringAsFixed(1)} / '
                          '${(total / 1024 / 1024).toStringAsFixed(1)} MB'
                    : '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB',
                style: ToadText.body,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: ToadColors.inkSoft.withOpacity(0.25),
            color: ToadColors.toad,
          ),
        ),
      ],
    );
  }
}

class _NeedsPermissionView extends StatelessWidget {
  const _NeedsPermissionView({required this.update});

  final UpdateController update;

  @override
  Widget build(BuildContext context) {
    final state = update.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Allow installs from this app in Android Settings, then tap Install '
          'again.',
          style: ToadText.body,
        ),
        if (state.message != null) ...[
          const SizedBox(height: 6),
          Text(state.message!, style: ToadText.label),
        ],
        const SizedBox(height: 10),
        SketchButton(
          onTap: update.retryInstall,
          background: ToadColors.toadLight,
          borderColor: ToadColors.toadDeep,
          child: Text(
            'Install now',
            style: TextStyle(
              fontFamily: 'PatrickHand',
              fontSize: 14,
              color: ToadColors.moss,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.update});

  final UpdateController update;

  @override
  Widget build(BuildContext context) {
    final state = update.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.message ?? 'The update check failed — try again.',
          style: ToadText.body,
        ),
        const SizedBox(height: 10),
        SketchButton(
          onTap: update.checkForUpdates,
          child: const Text(
            'Check for updates',
            style: TextStyle(fontFamily: 'PatrickHand', fontSize: 14),
          ),
        ),
      ],
    );
  }
}

/// The quiet, dismissible "update available" card the silent startup check
/// can raise at the top of the home screen. Nothing downloads until the
/// user acts; the toad delivers the news himself.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key, this.controller});

  final UpdateController? controller;

  @override
  Widget build(BuildContext context) {
    final update = controller ?? UpdateController.instance;
    return ListenableBuilder(
      listenable: update,
      builder: (context, _) {
        final GitHubRelease release = update.bannerRelease;
        if (release == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          child: SketchCard(
            seed: 5.4,
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CustomPaint(
                    painter: ToadPainter(pose: ToadPose.cheer, phase: 0.4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'toadHEALTH ${release.tagName} available',
                        style: ToadText.body,
                      ),
                      Text(
                        'Downloaded only if you ask.',
                        style: ToadText.label,
                      ),
                    ],
                  ),
                ),
                SketchButton(
                  onTap: update.dismissBanner,
                  child: Text(
                    'Later',
                    style: TextStyle(
                      fontFamily: 'PatrickHand',
                      fontSize: 13,
                      color: ToadColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
