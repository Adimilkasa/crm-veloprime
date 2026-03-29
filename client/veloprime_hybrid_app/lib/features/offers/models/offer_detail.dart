class OfferVersionInfo {
  const OfferVersionInfo({
    required this.id,
    required this.versionNumber,
    required this.summary,
    required this.createdAt,
    required this.pdfUrl,
  });

  final String id;
  final int versionNumber;
  final String summary;
  final String createdAt;
  final String? pdfUrl;

  factory OfferVersionInfo.fromJson(Map<String, dynamic> json) {
    return OfferVersionInfo(
      id: json['id'] as String? ?? '',
      versionNumber: json['versionNumber'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      pdfUrl: json['pdfUrl'] as String?,
    );
  }
}

class OfferCalculationDetails {
  const OfferCalculationDetails({
    required this.catalogLabel,
    required this.customerType,
    required this.ownerRole,
    required this.directorName,
    required this.managerName,
    required this.baseColorName,
    required this.selectedColorName,
    required this.colorSurchargeGross,
    required this.listPriceGross,
    required this.basePriceGross,
    required this.marginPoolGross,
    required this.availableDiscount,
    required this.appliedDiscount,
    required this.salespersonCommission,
    required this.finalPriceGross,
    required this.finalPriceNet,
  });

  final String catalogLabel;
  final String customerType;
  final String? ownerRole;
  final String? directorName;
  final String? managerName;
  final String? baseColorName;
  final String? selectedColorName;
  final num colorSurchargeGross;
  final num? listPriceGross;
  final num? basePriceGross;
  final num? marginPoolGross;
  final num availableDiscount;
  final num appliedDiscount;
  final num salespersonCommission;
  final num? finalPriceGross;
  final num? finalPriceNet;

  factory OfferCalculationDetails.fromJson(Map<String, dynamic> json) {
    return OfferCalculationDetails(
      catalogLabel: json['catalogLabel'] as String? ?? '',
      customerType: json['customerType'] as String? ?? '',
      ownerRole: json['ownerRole'] as String?,
      directorName: json['directorName'] as String?,
      managerName: json['managerName'] as String?,
      baseColorName: json['baseColorName'] as String?,
      selectedColorName: json['selectedColorName'] as String?,
      colorSurchargeGross: json['colorSurchargeGross'] as num? ?? 0,
      listPriceGross: json['listPriceGross'] as num?,
      basePriceGross: json['basePriceGross'] as num?,
      marginPoolGross: json['marginPoolGross'] as num?,
      availableDiscount: json['availableDiscount'] as num? ?? 0,
      appliedDiscount: json['appliedDiscount'] as num? ?? 0,
      salespersonCommission: json['salespersonCommission'] as num? ?? 0,
      finalPriceGross: json['finalPriceGross'] as num?,
      finalPriceNet: json['finalPriceNet'] as num?,
    );
  }
}

class OfferDetail {
  const OfferDetail({
    required this.id,
    required this.number,
    required this.status,
    required this.title,
    required this.leadId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.modelName,
    required this.pricingCatalogKey,
    required this.selectedColorName,
    required this.customerType,
    required this.ownerName,
    required this.validUntil,
    required this.totalGross,
    required this.totalNet,
    required this.financingVariant,
    required this.financingTermMonths,
    required this.financingInputValue,
    required this.financingBuyoutPercent,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.versions,
    required this.calculation,
  });

  final String id;
  final String number;
  final String status;
  final String title;
  final String? leadId;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? modelName;
  final String? pricingCatalogKey;
  final String? selectedColorName;
  final String customerType;
  final String ownerName;
  final String? validUntil;
  final num? totalGross;
  final num? totalNet;
  final String? financingVariant;
  final int? financingTermMonths;
  final num? financingInputValue;
  final num? financingBuyoutPercent;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final List<OfferVersionInfo> versions;
  final OfferCalculationDetails? calculation;

  factory OfferDetail.fromJson(Map<String, dynamic> json) {
    final rawVersions = json['versions'] as List<dynamic>? ?? const [];

    return OfferDetail(
      id: json['id'] as String? ?? '',
      number: json['number'] as String? ?? '',
      status: json['status'] as String? ?? 'DRAFT',
      title: json['title'] as String? ?? 'Oferta',
      leadId: json['leadId'] as String?,
      customerName: json['customerName'] as String? ?? '',
      customerEmail: json['customerEmail'] as String?,
      customerPhone: json['customerPhone'] as String?,
      modelName: json['modelName'] as String?,
      pricingCatalogKey: json['pricingCatalogKey'] as String?,
      selectedColorName: json['selectedColorName'] as String?,
      customerType: json['customerType'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      validUntil: json['validUntil'] as String?,
      totalGross: json['totalGross'] as num?,
      totalNet: json['totalNet'] as num?,
      financingVariant: json['financingVariant'] as String?,
      financingTermMonths: json['financingTermMonths'] as int?,
      financingInputValue: json['financingInputValue'] as num?,
      financingBuyoutPercent: json['financingBuyoutPercent'] as num?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      versions: rawVersions.whereType<Map<String, dynamic>>().map(OfferVersionInfo.fromJson).toList(),
      calculation: json['calculation'] is Map<String, dynamic>
          ? OfferCalculationDetails.fromJson(json['calculation'] as Map<String, dynamic>)
          : null,
    );
  }
}