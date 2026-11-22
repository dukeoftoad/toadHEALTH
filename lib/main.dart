import 'package:flutter/material.dart';

import 'appearance.dart';
import 'app.dart';
import 'state/app_services.dart';
import 'update/update_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Boot the encrypted vault in parallel with the splash animation.
  AppServices.boot();
  // Wear the saved appearance on the very first frame; the tiny JSON file
  // sits outside the sealed vault so no unlock is needed to dress the app.
  await Appearance.instance.load();
  // The silent once-per-process update probe: any failure stays quiet; a
  // newer release only raises the home banner. Never downloads on its own.
  UpdateController.instance.checkSilentlyOnce();
  runApp(const ToadHealthApp());
}
