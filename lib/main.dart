import 'package:flutter/material.dart';

import 'app.dart';
import 'state/app_services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Boot the encrypted vault in parallel with the splash animation.
  AppServices.boot();
  runApp(const ToadHealthApp());
}
