import 'package:flutter_test/flutter_test.dart';
import 'package:veloprime_hybrid_app/features/bootstrap/models/bootstrap_payload.dart';
import 'package:veloprime_hybrid_app/features/offers/data/local_offer_assets.dart';
import 'package:veloprime_hybrid_app/features/offers/data/local_offer_document_snapshot.dart';
import 'package:veloprime_hybrid_app/features/offers/models/offer_detail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeLocalOfferAssets();
  });

  test('local preview gallery includes bundled assets for a known model', () {
    final snapshot = buildLocalOfferDocumentSnapshot(
      offer: const OfferDetail(
        id: 'offer-preview-test',
        number: 'OF/TEST/001',
        status: 'DRAFT',
        title: 'Test preview offer',
        leadId: null,
        customerName: 'Jan Testowy',
        customerEmail: 'jan.testowy@veloprime.pl',
        customerPhone: '+48123123123',
        modelName: 'BYD Atto 2',
        pricingCatalogKey: 'byd-atto-2-test',
        selectedColorName: 'Climbing Grey',
        customerType: 'PRIVATE',
        ownerName: 'Doradca Testowy',
        validUntil: '2026-04-30T00:00:00.000Z',
        totalGross: 129900,
        totalNet: 105609.76,
        financingVariant: 'leasing',
        financingTermMonths: 36,
        financingInputValue: 20000,
        financingBuyoutPercent: 30,
        notes: 'Preview gallery smoke test',
        createdAt: '2026-03-30T10:00:00.000Z',
        updatedAt: '2026-03-30T10:00:00.000Z',
        versions: [],
        calculation: null,
      ),
      session: const SessionInfo(
        sub: 'test-user',
        email: 'doradca.testowy@veloprime.pl',
        fullName: 'Doradca Testowy',
        role: 'SALES',
      ),
    );

    final bundle = getLocalOfferAssetBundle(snapshot.payload.customer.modelName);

    expect(snapshot.assets.specPdfUrl, isNotNull);
    expect(bundle.heroImageAsset, isNotNull);
    expect(bundle.galleryImages, isNotEmpty);
    expect(bundle.galleryImages.length, greaterThanOrEqualTo(4));
    expect(bundle.galleryImages.first, startsWith('assets/offers/grafiki/'));
    expect(bundle.galleryImages, containsAll(snapshot.assets.premiumImages));
  });
}