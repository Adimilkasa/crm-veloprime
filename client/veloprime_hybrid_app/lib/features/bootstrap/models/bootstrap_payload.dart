class SessionInfo {
  const SessionInfo({
    required this.sub,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final String sub;
  final String email;
  final String fullName;
  final String role;

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      sub: json['sub'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'SALES',
    );
  }
}

class ManagedOfferSummary {
  const ManagedOfferSummary({
    required this.id,
    required this.number,
    required this.status,
    required this.title,
    required this.customerName,
    required this.modelName,
    required this.ownerName,
    required this.totalGross,
    required this.validUntil,
    required this.updatedAt,
    required this.financingVariant,
  });

  final String id;
  final String number;
  final String status;
  final String title;
  final String customerName;
  final String? modelName;
  final String ownerName;
  final num? totalGross;
  final String? validUntil;
  final String updatedAt;
  final String? financingVariant;

  factory ManagedOfferSummary.fromJson(Map<String, dynamic> json) {
    return ManagedOfferSummary(
      id: json['id'] as String? ?? '',
      number: json['number'] as String? ?? '',
      status: json['status'] as String? ?? 'DRAFT',
      title: json['title'] as String? ?? 'Oferta bez tytułu',
      customerName: json['customerName'] as String? ?? 'Klient do uzupełnienia',
      modelName: json['modelName'] as String?,
      ownerName: json['ownerName'] as String? ?? 'Nieprzypisany',
      totalGross: json['totalGross'] as num?,
      validUntil: json['validUntil'] as String?,
      updatedAt: json['updatedAt'] as String? ?? '',
      financingVariant: json['financingVariant'] as String?,
    );
  }
}

class OfferLeadOption {
  const OfferLeadOption({
    required this.id,
    required this.label,
    required this.modelName,
    required this.contact,
    required this.ownerName,
  });

  final String id;
  final String label;
  final String? modelName;
  final String? contact;
  final String? ownerName;

  factory OfferLeadOption.fromJson(Map<String, dynamic> json) {
    return OfferLeadOption(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Lead',
      modelName: json['modelName'] as String?,
      contact: json['contact'] as String?,
      ownerName: json['ownerName'] as String?,
    );
  }
}

class OfferPricingOption {
  const OfferPricingOption({
    required this.key,
    required this.label,
    required this.brand,
    required this.model,
    required this.version,
    required this.listPriceGross,
    required this.basePriceGross,
    required this.marginPoolGross,
  });

  final String key;
  final String label;
  final String brand;
  final String model;
  final String version;
  final num? listPriceGross;
  final num? basePriceGross;
  final num? marginPoolGross;

  factory OfferPricingOption.fromJson(Map<String, dynamic> json) {
    return OfferPricingOption(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? 'Pozycja cenowa',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      version: json['version'] as String? ?? '',
      listPriceGross: json['listPriceGross'] as num?,
      basePriceGross: json['basePriceGross'] as num?,
      marginPoolGross: json['marginPoolGross'] as num?,
    );
  }
}

class BootstrapPayload {
  const BootstrapPayload({
    required this.session,
    required this.offers,
    required this.leadOptions,
    required this.pricingOptions,
  });

  final SessionInfo session;
  final List<ManagedOfferSummary> offers;
  final List<OfferLeadOption> leadOptions;
  final List<OfferPricingOption> pricingOptions;

  factory BootstrapPayload.fromJson(Map<String, dynamic> json) {
    final rawOffers = (json['offers'] as List<dynamic>? ?? const []);
    final rawLeadOptions = (json['leadOptions'] as List<dynamic>? ?? const []);
    final rawPricingOptions = (json['pricingOptions'] as List<dynamic>? ?? const []);

    return BootstrapPayload(
      session: SessionInfo.fromJson(json['session'] as Map<String, dynamic>? ?? const {}),
      offers: rawOffers.whereType<Map<String, dynamic>>().map(ManagedOfferSummary.fromJson).toList(),
      leadOptions: rawLeadOptions.whereType<Map<String, dynamic>>().map(OfferLeadOption.fromJson).toList(),
      pricingOptions: rawPricingOptions.whereType<Map<String, dynamic>>().map(OfferPricingOption.fromJson).toList(),
    );
  }
}