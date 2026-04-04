import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../core/presentation/veloprime_ui.dart';
import '../features/offers/data/offers_repository.dart';
import '../features/offers/models/offer_document.dart';
import '../features/offers/presentation/offer_document_preview_page.dart';

class OfferPreviewLabApp extends StatelessWidget {
  const OfferPreviewLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme.light(
      primary: VeloPrimePalette.bronzeDeep,
      secondary: VeloPrimePalette.olive,
      surface: VeloPrimePalette.ivory,
      error: Color(0xFF9A3C2B),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: VeloPrimePalette.ink,
    );

    return MaterialApp(
      title: 'Offer Preview Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: VeloPrimePalette.sand,
        useMaterial3: true,
        fontFamily: 'Segoe UI Variable Display',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink, height: 1.08),
          headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink, height: 1.12),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
          bodyLarge: TextStyle(fontSize: 16, color: VeloPrimePalette.ink, height: 1.58),
          bodyMedium: TextStyle(fontSize: 14, color: VeloPrimePalette.muted, height: 1.58),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: VeloPrimePalette.ink,
          elevation: 0,
          centerTitle: false,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: VeloPrimePalette.bronze,
            foregroundColor: const Color(0xFF181512),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            side: const BorderSide(color: Color(0x26BE933E)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: VeloPrimePalette.ink,
            side: const BorderSide(color: VeloPrimePalette.line),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            backgroundColor: Colors.white,
          ),
        ),
      ),
      home: OfferDocumentPreviewPage(
        offerId: _sampleSnapshot.offerId,
        versionId: _sampleSnapshot.version?.id ?? _sampleSnapshot.payload.versionId,
        repository: _OfferPreviewLabRepository(_sampleSnapshot),
      ),
    );
  }
}

class _OfferPreviewLabRepository extends OffersRepository {
  _OfferPreviewLabRepository(this.snapshot) : super(ApiClient());

  final OfferDocumentSnapshot snapshot;

  @override
  Future<OfferDocumentSnapshot> fetchDocumentSnapshot({
    required String offerId,
    String? versionId,
  }) async {
    return snapshot;
  }

  @override
  Future<OfferEmailSendResult> sendOfferEmail({
    required String offerId,
    String? versionId,
    String? toEmail,
  }) async {
    return OfferEmailSendResult(
      to: toEmail ?? snapshot.payload.customer.customerEmail ?? 'preview@veloprime.pl',
      publicUrl: 'https://crm.veloprime.pl/oferta/podglad-lokalny',
      expiresAt: snapshot.payload.customer.validUntil,
      versionId: versionId ?? snapshot.payload.versionId,
    );
  }
}

const OfferDocumentSnapshot _sampleSnapshot = OfferDocumentSnapshot(
  offerId: 'offer-preview-lab',
  offerNumber: 'OF/2026/021',
  title: 'BYD Sealion 7 Excellence',
  version: OfferDocumentVersion(
    id: 'version-preview-lab',
    versionNumber: 1,
    summary: 'Roboczy podglad lokalny',
    createdAt: '2026-04-04T12:00:00.000Z',
  ),
  payload: OfferDocumentPayloadData(
    versionId: 'version-preview-lab',
    versionNumber: 1,
    createdAt: '2026-04-04T12:00:00.000Z',
    customer: OfferDocumentCustomerSnapshot(
      offerNumber: 'OF/2026/021',
      title: 'BYD Sealion 7 Excellence',
      customerName: 'Jan Testowy',
      customerEmail: 'jan.testowy@veloprime.pl',
      customerPhone: '+48 123 123 123',
      modelName: 'BYD Sealion 7 Excellence',
      selectedColorName: 'Atlantis Grey',
      financingVariant: 'Leasing operacyjny',
      notes: 'Klient chce porownac wariant premium z wariantem bazowym i zalezy mu na czytelnym pokazaniu ceny oraz raty.',
      validUntil: '2026-04-30T00:00:00.000Z',
      listPriceLabel: '219 900 PLN',
      discountLabel: '5 000 PLN',
      discountPercentLabel: '2.27%',
      finalGrossLabel: '214 900 PLN',
      finalNetLabel: '174 715 PLN',
      financingSummary: '36 mies. / wplata 30 000 PLN / wykup 30% / rata od 2 999 PLN',
      financingDisclaimer: 'Finalne warunki zaleza od oceny zdolnosci finansowej klienta.',
      createdAt: '2026-04-04T12:00:00.000Z',
    ),
    advisor: OfferDocumentAdvisorSnapshot(
      fullName: 'Doradca Testowy',
      email: 'doradca@veloprime.pl',
      phone: '+48 999 111 222',
      avatarUrl: null,
      role: 'SALES',
    ),
    internal: OfferDocumentInternalSnapshot(
      catalogKey: 'byd-sealion-7-excellence',
      powertrainType: 'EV',
      year: '2026',
      powerHp: '313 KM',
      systemPowerHp: '313 KM',
      batteryCapacityKwh: '82.5',
      combustionEnginePowerHp: null,
      engineDisplacementCc: null,
      driveType: 'AWD',
      rangeKm: '502 km',
      customerType: 'PRIVATE',
      salespersonCommission: 5290,
      finalPriceGross: 214900,
      finalPriceNet: 174715,
      selectedColorName: 'Atlantis Grey',
      baseColorName: 'Polar White',
      ownerName: 'Doradca Testowy',
      ownerRole: 'SALES',
      generatedAt: '2026-04-04T12:00:00.000Z',
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