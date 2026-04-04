import 'package:flutter/material.dart';

import 'core/config/api_config.dart';
import 'dev/offer_preview_lab.dart';
import 'features/offers/data/local_offer_assets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initialize();
  await initializeLocalOfferAssets();
  runApp(const OfferPreviewLabApp());
}