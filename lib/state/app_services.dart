import '../data.dart';
import '../data/vault_service.dart';
import 'app_controller.dart';
import 'watch_controller.dart';

/// Tiny service locator. Boot starts in main() (parallel with the splash
/// animation) and runs exactly once; screens are only ever built after it.
class AppServices {
  AppServices._();

  static final VaultService vault = VaultService();
  static AppController? _controller;
  static Future<void>? _boot;

  static AppController get controller {
    assert(_controller != null, 'AppServices.boot() has not finished');
    return _controller!;
  }

  static bool get booted => _controller != null;

  /// The app's smart-watch link (lives on the controller; one owner).
  static WatchController get watch => controller.watch;

  /// True while the vault exists but no credential has opened it yet
  /// (password set, device unlock unavailable). The splash routes to the
  /// lock screen in that case.
  static bool get locked => !vault.unlocked;

  static Future<void> boot() {
    return _boot ??= _run();
  }

  static Future<void> _run() async {
    await vault.init();
    final controller = AppController(vault);
    _controller = controller;
    if (vault.unlocked) {
      await controller.load();
      await controller.startSensor();
    }
    watch.ensureListener();
    HealthData.attach(controller);
  }

  /// Called by the lock screen after a successful unlock / restore.
  static Future<void> afterUnlock() async {
    final controller = controllerOf();
    await controller.load();
    await controller.startSensor();
    watch.ensureListener();
  }

  static AppController controllerOf() {
    assert(_controller != null, 'boot() has not finished');
    return _controller!;
  }
}
