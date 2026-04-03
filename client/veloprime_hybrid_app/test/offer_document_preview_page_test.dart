import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:veloprime_hybrid_app/core/network/api_client.dart';
import 'package:veloprime_hybrid_app/features/offers/data/local_offer_assets.dart';
import 'package:veloprime_hybrid_app/features/offers/data/offers_repository.dart';
import 'package:veloprime_hybrid_app/features/offers/models/offer_document.dart';
import 'package:veloprime_hybrid_app/features/offers/presentation/offer_document_preview_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeLocalOfferAssets();
  });

  testWidgets('generated offer preview exposes email action', (tester) async {
    const snapshot = OfferDocumentSnapshot(
      offerId: 'offer-1',
      offerNumber: 'OF/2026/001',
      title: 'BYD Seal 7 Excellence',
      version: OfferDocumentVersion(
        id: 'version-1',
        versionNumber: 1,
        summary: 'PDF ready',
        createdAt: '2026-03-31T08:00:00.000Z',
      ),
      payload: OfferDocumentPayloadData(
        versionId: 'version-1',
        versionNumber: 1,
        createdAt: '2026-03-31T08:00:00.000Z',
        customer: OfferDocumentCustomerSnapshot(
          offerNumber: 'OF/2026/001',
          title: 'BYD Seal 7 Excellence',
          customerName: 'Jan Testowy',
          customerEmail: 'jan.testowy@veloprime.pl',
          customerPhone: '+48123123123',
          modelName: 'BYD Seal 7',
          selectedColorName: 'Atlantis Grey',
          financingVariant: 'Leasing operacyjny',
          notes: 'Notatka testowa',
          validUntil: '2026-04-30T00:00:00.000Z',
          listPriceLabel: '219 900 PLN',
          discountLabel: '5 000 PLN',
          discountPercentLabel: '2.27%',
          finalGrossLabel: '214 900 PLN',
          finalNetLabel: '174 715 PLN',
          financingSummary: '36 mies. / wpłata 30 000 PLN / wykup 30% / rata od 2 999 PLN',
          financingDisclaimer: 'Finalne warunki zależą od oceny zdolności finansowej.',
          createdAt: '2026-03-31T08:00:00.000Z',
        ),
        advisor: OfferDocumentAdvisorSnapshot(
          fullName: 'Doradca Testowy',
          email: 'doradca@veloprime.pl',
          phone: '+48999111222',
          avatarUrl: null,
          role: 'SALES',
        ),
        internal: OfferDocumentInternalSnapshot(
          catalogKey: 'seal-7-excellence',
          powertrainType: null,
          customerType: 'PRIVATE',
          finalPriceGross: 214900,
          finalPriceNet: 174715,
          selectedColorName: 'Atlantis Grey',
          baseColorName: 'Atlantis Grey',
          ownerName: 'Doradca Testowy',
          ownerRole: 'SALES',
          generatedAt: '2026-03-31T08:00:00.000Z',
        ),
      ),
      assets: OfferDocumentAssets(
        logoUrl: '/assets/grafiki/LOGO.png',
        specPdfUrl: '/assets/spec/byd-sealion-7.pdf',
        premiumImages: ['/assets/grafiki/Seal%207/premium%201.jpg'],
        detailImages: ['/assets/grafiki/Seal%207/Detal%201.jpg'],
        interiorImages: ['/assets/grafiki/Seal%207/Wnetrze%202.jpg'],
        exteriorImages: ['/assets/grafiki/Seal%207/zewnatrz%202.jpg'],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OfferDocumentPreviewPage(
          offerId: snapshot.offerId,
          repository: OffersRepository(ApiClient()),
          initialDocument: snapshot,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Wyślij ofertę'), findsOneWidget);
    expect(find.text('Otwórz specyfikację PDF'), findsOneWidget);
    expect(find.text('BYD Seal 7'), findsOneWidget);
  });
}