import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/config/api_config.dart';
import 'core/platform/windows_desktop_shortcut.dart';
import 'features/offers/data/local_offer_assets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isWindows) {
    await windowManager.ensureInitialized();
  }
  await ApiConfig.initialize();
  await ensureWindowsDesktopShortcut();
  await initializeLocalOfferAssets();
  runApp(const VeloPrimeApp());
}
