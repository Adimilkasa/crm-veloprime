import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veloprime_hybrid_app/features/offers/data/local_offer_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeLocalOfferAssets();
  });

  test('local offer asset bundle includes bundled assets for a known model', () {
    final bundle = getLocalOfferAssetBundle(modelName: 'BYD Atto 2');

    expect(bundle.specPdfAssetPath, isNotNull);
    expect(bundle.heroImageAsset, isNotNull);
    expect(bundle.galleryImages, isNotEmpty);
    expect(bundle.galleryImages.length, greaterThanOrEqualTo(4));
    expect(bundle.galleryImages.first, startsWith('assets/offers/grafiki/'));
    expect(bundle.galleryImages, containsAll(bundle.premiumImages));
  });

  testWidgets('bundled nested model image is available in root bundle', (tester) async {
    final bytes = await rootBundle.load('assets/offers/grafiki/byd-atto-2/premium 1.jpg');

    expect(bytes.lengthInBytes, greaterThan(0));
  });
}