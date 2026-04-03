import 'package:intl/intl.dart';

import '../../bootstrap/models/bootstrap_payload.dart';
import '../models/offer_detail.dart';
import '../models/offer_document.dart';
import 'local_offer_assets.dart';

const double _vatRate = 1.23;
const double _leaseTotalFactor = 1.2;
const Map<int, int> _buyoutLimits = {
  24: 70,
  36: 60,
  48: 50,
  60: 40,
  71: 30,
};

const String _financingDisclaimer =
    'Przedstawione warunki finansowania mają charakter szacunkowy i poglądowy, nie stanowią wiążącej oferty w rozumieniu przepisów prawa oraz wymagają indywidualnej weryfikacji zdolności finansowej klienta.';

final NumberFormat _moneyFormat = NumberFormat.currency(
  locale: 'pl_PL',
  symbol: 'zł',
  decimalDigits: 2,
);

OfferDocumentSnapshot buildLocalOfferDocumentSnapshot({
  required OfferDetail offer,
  required SessionInfo session,
  SalesCatalogBootstrapInfo? catalog,
}) {
  final generatedAt = DateTime.now().toIso8601String();
  final calculation = offer.calculation;
  final selectedColorName = calculation?.selectedColorName ?? offer.selectedColorName;
  final version = offer.versions.isNotEmpty ? offer.versions.first : null;
  final versionNumber = version?.versionNumber ?? (offer.versions.isNotEmpty ? offer.versions.length : 1);
  final finalPriceGross = calculation?.finalPriceGross ?? offer.totalGross;
  final finalPriceNet = calculation?.finalPriceNet ?? offer.totalNet ?? _toNet(finalPriceGross);
  final listPriceGross = calculation?.listPriceGross ?? offer.totalGross;
  final listPriceNet = _toNet(listPriceGross) ?? offer.totalNet ?? finalPriceNet;
  final referencePrice = offer.customerType == 'BUSINESS'
      ? (listPriceNet ?? finalPriceNet)
      : (listPriceGross ?? finalPriceGross);
  final discountAmount = calculation?.appliedDiscount ?? 0;
  final discountPercent = referencePrice != null && referencePrice > 0
      ? (discountAmount / referencePrice) * 100
      : 0;
  final financing = _calculateLocalFinancing(
    customerType: offer.customerType,
    finalPriceGross: finalPriceGross,
    finalPriceNet: finalPriceNet,
    termMonths: offer.financingTermMonths,
    downPaymentAmount: offer.financingInputValue,
    buyoutPercent: offer.financingBuyoutPercent,
  );
  final financingSummary = financing != null
      ? '${financing.termMonths} mies. / wplata ${_formatMoney(financing.downPaymentAmount)} / wykup ${_formatPercent(financing.buyoutPercent)} / rata od ${_formatMoney(financing.estimatedInstallment)}'
      : offer.financingVariant;
  final modelLabel = offer.modelName?.trim().isNotEmpty == true ? offer.modelName! : offer.title;
  final selectedVersion = catalog?.versions.cast<SalesCatalogVersionInfo?>().firstWhere(
        (version) => version?.catalogKey == offer.pricingCatalogKey,
        orElse: () => null,
      );
  final localAssets = getLocalOfferAssetBundle(
    modelName: modelLabel,
    catalogKey: offer.pricingCatalogKey,
    powertrainType: selectedVersion?.powertrainType,
  );
  final advisorName = offer.ownerName.trim().isNotEmpty ? offer.ownerName : session.fullName;
  final advisorEmail = advisorName == session.fullName ? session.email : null;
  final ownerRole = calculation?.ownerRole ?? session.role;

  return OfferDocumentSnapshot(
    offerId: offer.id,
    offerNumber: offer.number,
    title: offer.title,
    version: version == null
        ? null
        : OfferDocumentVersion(
            id: version.id,
            versionNumber: version.versionNumber,
            summary: version.summary,
            createdAt: version.createdAt,
          ),
    payload: OfferDocumentPayloadData(
      versionId: version?.id ?? 'offer-live-${offer.id}',
      versionNumber: versionNumber,
      createdAt: generatedAt,
      customer: OfferDocumentCustomerSnapshot(
        offerNumber: offer.number,
        title: offer.title,
        customerName: offer.customerName,
        customerEmail: offer.customerEmail,
        customerPhone: offer.customerPhone,
        modelName: offer.modelName,
        selectedColorName: selectedColorName,
        financingVariant: offer.financingVariant,
        notes: offer.notes,
        validUntil: offer.validUntil,
        listPriceLabel: _formatMoney(offer.customerType == 'BUSINESS' ? listPriceNet : listPriceGross),
        discountLabel: _formatMoney(discountAmount),
        discountPercentLabel: _formatPercent(discountPercent),
        finalGrossLabel: _formatMoney(finalPriceGross),
        finalNetLabel: _formatMoney(finalPriceNet),
        financingSummary: financingSummary,
        financingDisclaimer: financing?.disclaimerText,
        createdAt: generatedAt,
      ),
      advisor: OfferDocumentAdvisorSnapshot(
        fullName: advisorName,
        email: advisorEmail,
        phone: null,
        avatarUrl: null,
        role: ownerRole,
      ),
      internal: OfferDocumentInternalSnapshot(
        catalogKey: offer.pricingCatalogKey,
        powertrainType: selectedVersion?.powertrainType,
        customerType: offer.customerType,
        finalPriceGross: finalPriceGross,
        finalPriceNet: finalPriceNet,
        selectedColorName: selectedColorName,
        baseColorName: calculation?.baseColorName,
        ownerName: advisorName,
        ownerRole: ownerRole,
        generatedAt: generatedAt,
      ),
    ),
    assets: OfferDocumentAssets(
      logoUrl: 'assets/offers/grafiki/LOGO.png',
      specPdfUrl: localAssets.specPdfAssetPath,
      premiumImages: localAssets.premiumImages,
      detailImages: localAssets.detailImages,
      interiorImages: localAssets.interiorImages,
      exteriorImages: localAssets.exteriorImages,
    ),
  );
}

num? _toNet(num? grossValue) {
  if (grossValue == null) {
    return null;
  }

  return grossValue / _vatRate;
}

String _formatMoney(num? value) {
  if (value == null) {
    return 'kwota do ustalenia';
  }

  return _moneyFormat.format(value);
}

String _formatPercent(num value) {
  return '${value.toStringAsFixed(2).replaceAll('.', ',')}%';
}

_LocalFinancingSummary? _calculateLocalFinancing({
  required String customerType,
  required num? finalPriceGross,
  required num? finalPriceNet,
  required int? termMonths,
  required num? downPaymentAmount,
  required num? buyoutPercent,
}) {
  if (termMonths == null || downPaymentAmount == null || buyoutPercent == null) {
    return null;
  }

  final buyoutLimit = _buyoutLimits[termMonths];
  if (buyoutLimit == null || buyoutPercent < 0 || buyoutPercent > buyoutLimit || downPaymentAmount < 0) {
    return null;
  }

  final financedAssetValue = customerType == 'BUSINESS' ? finalPriceNet : finalPriceGross;
  if (financedAssetValue == null || financedAssetValue <= 0) {
    return null;
  }

  final buyoutAmount = _roundMoney(financedAssetValue * (buyoutPercent / 100));
  final totalLeaseCost = _roundMoney(financedAssetValue * _leaseTotalFactor);
  final estimatedInstallment = _roundMoney((totalLeaseCost - downPaymentAmount - buyoutAmount) / termMonths);

  return _LocalFinancingSummary(
    termMonths: termMonths,
    downPaymentAmount: _roundMoney(downPaymentAmount),
    buyoutPercent: _roundMoney(buyoutPercent),
    estimatedInstallment: estimatedInstallment,
    disclaimerText: _financingDisclaimer,
  );
}

double _roundMoney(num value) {
  return double.parse(value.toStringAsFixed(2));
}

class _LocalFinancingSummary {
  const _LocalFinancingSummary({
    required this.termMonths,
    required this.downPaymentAmount,
    required this.buyoutPercent,
    required this.estimatedInstallment,
    required this.disclaimerText,
  });

  final int termMonths;
  final double downPaymentAmount;
  final double buyoutPercent;
  final double estimatedInstallment;
  final String disclaimerText;
}