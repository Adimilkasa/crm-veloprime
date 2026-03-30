class OfferDocumentVersion {
  const OfferDocumentVersion({
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

  factory OfferDocumentVersion.fromJson(Map<String, dynamic> json) {
    return OfferDocumentVersion(
      id: json['id'] as String? ?? '',
      versionNumber: json['versionNumber'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      pdfUrl: json['pdfUrl'] as String?,
    );
  }
}

class OfferDocumentCustomerSnapshot {
  const OfferDocumentCustomerSnapshot({
    required this.offerNumber,
    required this.title,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.modelName,
    required this.selectedColorName,
    required this.financingVariant,
    required this.notes,
    required this.validUntil,
    required this.listPriceLabel,
    required this.discountLabel,
    required this.discountPercentLabel,
    required this.finalGrossLabel,
    required this.finalNetLabel,
    required this.financingSummary,
    required this.financingDisclaimer,
    required this.createdAt,
  });

  final String offerNumber;
  final String title;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? modelName;
  final String? selectedColorName;
  final String? financingVariant;
  final String? notes;
  final String? validUntil;
  final String listPriceLabel;
  final String discountLabel;
  final String discountPercentLabel;
  final String finalGrossLabel;
  final String finalNetLabel;
  final String? financingSummary;
  final String? financingDisclaimer;
  final String createdAt;

  factory OfferDocumentCustomerSnapshot.fromJson(Map<String, dynamic> json) {
    return OfferDocumentCustomerSnapshot(
      offerNumber: json['offerNumber'] as String? ?? '',
      title: json['title'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerEmail: json['customerEmail'] as String?,
      customerPhone: json['customerPhone'] as String?,
      modelName: json['modelName'] as String?,
      selectedColorName: json['selectedColorName'] as String?,
      financingVariant: json['financingVariant'] as String?,
      notes: json['notes'] as String?,
      validUntil: json['validUntil'] as String?,
      listPriceLabel: json['listPriceLabel'] as String? ?? '-',
      discountLabel: json['discountLabel'] as String? ?? '-',
      discountPercentLabel: json['discountPercentLabel'] as String? ?? '-',
      finalGrossLabel: json['finalGrossLabel'] as String? ?? '-',
      finalNetLabel: json['finalNetLabel'] as String? ?? '-',
      financingSummary: json['financingSummary'] as String?,
      financingDisclaimer: json['financingDisclaimer'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class OfferDocumentInternalSnapshot {
  const OfferDocumentInternalSnapshot({
    required this.catalogKey,
    required this.customerType,
    required this.finalPriceGross,
    required this.finalPriceNet,
    required this.selectedColorName,
    required this.baseColorName,
    required this.ownerName,
    required this.ownerRole,
    required this.generatedAt,
  });

  final String? catalogKey;
  final String customerType;
  final num? finalPriceGross;
  final num? finalPriceNet;
  final String? selectedColorName;
  final String? baseColorName;
  final String ownerName;
  final String ownerRole;
  final String generatedAt;

  factory OfferDocumentInternalSnapshot.fromJson(Map<String, dynamic> json) {
    return OfferDocumentInternalSnapshot(
      catalogKey: json['catalogKey'] as String?,
      customerType: json['customerType'] as String? ?? '',
      finalPriceGross: json['finalPriceGross'] as num?,
      finalPriceNet: json['finalPriceNet'] as num?,
      selectedColorName: json['selectedColorName'] as String?,
      baseColorName: json['baseColorName'] as String?,
      ownerName: json['ownerName'] as String? ?? '',
      ownerRole: json['ownerRole'] as String? ?? '',
      generatedAt: json['generatedAt'] as String? ?? '',
    );
  }
}

class OfferDocumentAdvisorSnapshot {
  const OfferDocumentAdvisorSnapshot({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
  });

  final String fullName;
  final String? email;
  final String? phone;
  final String role;

  factory OfferDocumentAdvisorSnapshot.fromJson(Map<String, dynamic> json) {
    return OfferDocumentAdvisorSnapshot(
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'SALES',
    );
  }
}

class OfferDocumentPayloadData {
  const OfferDocumentPayloadData({
    required this.versionId,
    required this.versionNumber,
    required this.createdAt,
    required this.customer,
    required this.advisor,
    required this.internal,
  });

  final String versionId;
  final int versionNumber;
  final String createdAt;
  final OfferDocumentCustomerSnapshot customer;
  final OfferDocumentAdvisorSnapshot advisor;
  final OfferDocumentInternalSnapshot internal;

  factory OfferDocumentPayloadData.fromJson(Map<String, dynamic> json) {
    return OfferDocumentPayloadData(
      versionId: json['versionId'] as String? ?? '',
      versionNumber: json['versionNumber'] as int? ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      customer: OfferDocumentCustomerSnapshot.fromJson(json['customer'] as Map<String, dynamic>? ?? const {}),
      advisor: OfferDocumentAdvisorSnapshot.fromJson(json['advisor'] as Map<String, dynamic>? ?? const {}),
      internal: OfferDocumentInternalSnapshot.fromJson(json['internal'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class OfferDocumentAssets {
  const OfferDocumentAssets({
    required this.logoUrl,
    required this.specPdfUrl,
    required this.premiumImages,
    required this.detailImages,
    required this.interiorImages,
    required this.exteriorImages,
  });

  final String logoUrl;
  final String? specPdfUrl;
  final List<String> premiumImages;
  final List<String> detailImages;
  final List<String> interiorImages;
  final List<String> exteriorImages;

  factory OfferDocumentAssets.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>? ?? const {};

    List<String> readList(String key) {
      return (images[key] as List<dynamic>? ?? const []).whereType<String>().toList();
    }

    return OfferDocumentAssets(
      logoUrl: json['logoUrl'] as String? ?? '',
      specPdfUrl: json['specPdfUrl'] as String?,
      premiumImages: readList('premium'),
      detailImages: readList('details'),
      interiorImages: readList('interior'),
      exteriorImages: readList('exterior'),
    );
  }
}

class OfferDocumentSnapshot {
  const OfferDocumentSnapshot({
    required this.offerId,
    required this.offerNumber,
    required this.title,
    required this.version,
    required this.payload,
    required this.assets,
  });

  final String offerId;
  final String offerNumber;
  final String title;
  final OfferDocumentVersion? version;
  final OfferDocumentPayloadData payload;
  final OfferDocumentAssets assets;

  factory OfferDocumentSnapshot.fromJson(Map<String, dynamic> json) {
    return OfferDocumentSnapshot(
      offerId: json['offerId'] as String? ?? '',
      offerNumber: json['offerNumber'] as String? ?? '',
      title: json['title'] as String? ?? '',
      version: json['version'] is Map<String, dynamic>
          ? OfferDocumentVersion.fromJson(json['version'] as Map<String, dynamic>)
          : null,
      payload: OfferDocumentPayloadData.fromJson(json['payload'] as Map<String, dynamic>? ?? const {}),
      assets: OfferDocumentAssets.fromJson(json['assets'] as Map<String, dynamic>? ?? const {}),
    );
  }
}