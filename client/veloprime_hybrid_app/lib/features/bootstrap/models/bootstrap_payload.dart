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

class PublishedArtifactSnapshot {
  const PublishedArtifactSnapshot({
    required this.source,
    required this.generatedAt,
    required this.stats,
    required this.notes,
  });

  final String source;
  final String generatedAt;
  final Map<String, num> stats;
  final List<String> notes;

  factory PublishedArtifactSnapshot.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'];
    final stats = <String, num>{};

    if (rawStats is Map<String, dynamic>) {
      for (final entry in rawStats.entries) {
        final value = entry.value;
        if (value is num) {
          stats[entry.key] = value;
        }
      }
    }

    return PublishedArtifactSnapshot(
      source: json['source'] as String? ?? 'STATIC',
      generatedAt: json['generatedAt'] as String? ?? '',
      stats: stats,
      notes: (json['notes'] as List<dynamic>? ?? const []).whereType<String>().toList(),
    );
  }
}

class PublishedVersionInfo {
  const PublishedVersionInfo({
    required this.artifactType,
    required this.version,
    required this.publishedAt,
    required this.publishedBy,
    required this.summary,
    required this.priority,
    required this.snapshot,
  });

  final String artifactType;
  final String version;
  final String? publishedAt;
  final String? publishedBy;
  final String? summary;
  final String priority;
  final PublishedArtifactSnapshot? snapshot;

  factory PublishedVersionInfo.fromJson(Map<String, dynamic> json) {
    final rawSnapshot = json['snapshot'];

    return PublishedVersionInfo(
      artifactType: json['artifactType'] as String? ?? 'UNKNOWN',
      version: json['version'] as String? ?? 'v1',
      publishedAt: json['publishedAt'] as String?,
      publishedBy: json['publishedBy'] as String?,
      summary: json['summary'] as String?,
      priority: json['priority'] as String? ?? 'STANDARD',
      snapshot: rawSnapshot is Map<String, dynamic> ? PublishedArtifactSnapshot.fromJson(rawSnapshot) : null,
    );
  }
}

class UpdateManifestInfo {
  const UpdateManifestInfo({
    required this.versions,
  });

  final List<PublishedVersionInfo> versions;

  PublishedVersionInfo? findVersion(String artifactType) {
    for (final version in versions) {
      if (version.artifactType == artifactType) {
        return version;
      }
    }

    return null;
  }

  factory UpdateManifestInfo.fromJson(Map<String, dynamic> json) {
    final rawVersions = json['versions'] as List<dynamic>? ?? const [];

    return UpdateManifestInfo(
      versions: rawVersions.whereType<Map<String, dynamic>>().map(PublishedVersionInfo.fromJson).toList(),
    );
  }
}

class SalesCatalogBrandInfo {
  const SalesCatalogBrandInfo({
    required this.code,
    required this.name,
    required this.sortOrder,
  });

  final String code;
  final String name;
  final int sortOrder;

  factory SalesCatalogBrandInfo.fromJson(Map<String, dynamic> json) {
    return SalesCatalogBrandInfo(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class SalesCatalogModelInfo {
  const SalesCatalogModelInfo({
    required this.brandCode,
    required this.code,
    required this.name,
    required this.marketingName,
    required this.status,
    required this.sortOrder,
    required this.availablePowertrains,
  });

  final String brandCode;
  final String code;
  final String name;
  final String? marketingName;
  final String status;
  final int sortOrder;
  final List<String> availablePowertrains;

  factory SalesCatalogModelInfo.fromJson(Map<String, dynamic> json) {
    return SalesCatalogModelInfo(
      brandCode: json['brandCode'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      marketingName: json['marketingName'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      sortOrder: json['sortOrder'] as int? ?? 0,
      availablePowertrains: (json['availablePowertrains'] as List<dynamic>? ?? const []).whereType<String>().toList(),
    );
  }
}

class SalesCatalogVersionInfo {
  const SalesCatalogVersionInfo({
    required this.catalogKey,
    required this.brandCode,
    required this.modelCode,
    required this.code,
    required this.name,
    required this.year,
    required this.powertrainType,
    required this.powerHp,
    required this.systemPowerHp,
    required this.batteryCapacityKwh,
    required this.combustionEnginePowerHp,
    required this.engineDisplacementCc,
    required this.driveType,
    required this.rangeKm,
    required this.notes,
  });

  final String catalogKey;
  final String brandCode;
  final String modelCode;
  final String code;
  final String name;
  final int? year;
  final String? powertrainType;
  final String? powerHp;
  final num? systemPowerHp;
  final num? batteryCapacityKwh;
  final num? combustionEnginePowerHp;
  final num? engineDisplacementCc;
  final String? driveType;
  final num? rangeKm;
  final String? notes;

  factory SalesCatalogVersionInfo.fromJson(Map<String, dynamic> json) {
    return SalesCatalogVersionInfo(
      catalogKey: json['catalogKey'] as String? ?? '',
      brandCode: json['brandCode'] as String? ?? '',
      modelCode: json['modelCode'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      year: json['year'] as int?,
      powertrainType: json['powertrainType'] as String?,
      powerHp: json['powerHp'] as String?,
      systemPowerHp: json['systemPowerHp'] as num?,
      batteryCapacityKwh: json['batteryCapacityKwh'] as num?,
      combustionEnginePowerHp: json['combustionEnginePowerHp'] as num?,
      engineDisplacementCc: json['engineDisplacementCc'] as num?,
      driveType: json['driveType'] as String?,
      rangeKm: json['rangeKm'] as num?,
      notes: json['notes'] as String?,
    );
  }
}

class SalesCatalogColorOptionInfo {
  const SalesCatalogColorOptionInfo({
    required this.name,
    required this.isBase,
    required this.surchargeGross,
    required this.surchargeNet,
    required this.sortOrder,
  });

  final String name;
  final bool isBase;
  final num? surchargeGross;
  final num? surchargeNet;
  final int sortOrder;

  factory SalesCatalogColorOptionInfo.fromJson(Map<String, dynamic> json) {
    return SalesCatalogColorOptionInfo(
      name: json['name'] as String? ?? '',
      isBase: json['isBase'] as bool? ?? false,
      surchargeGross: json['surchargeGross'] as num?,
      surchargeNet: json['surchargeNet'] as num?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class SalesCatalogColorPaletteInfo {
  const SalesCatalogColorPaletteInfo({
    required this.paletteKey,
    required this.brandCode,
    required this.modelCode,
    required this.brand,
    required this.model,
    required this.baseColorName,
    required this.optionalColorSurchargeGross,
    required this.optionalColorSurchargeNet,
    required this.colors,
  });

  final String paletteKey;
  final String? brandCode;
  final String? modelCode;
  final String brand;
  final String model;
  final String baseColorName;
  final num? optionalColorSurchargeGross;
  final num? optionalColorSurchargeNet;
  final List<SalesCatalogColorOptionInfo> colors;

  factory SalesCatalogColorPaletteInfo.fromJson(Map<String, dynamic> json) {
    final rawColors = json['colors'] as List<dynamic>? ?? const [];

    return SalesCatalogColorPaletteInfo(
      paletteKey: json['paletteKey'] as String? ?? '',
      brandCode: json['brandCode'] as String?,
      modelCode: json['modelCode'] as String?,
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      baseColorName: json['baseColorName'] as String? ?? '',
      optionalColorSurchargeGross: json['optionalColorSurchargeGross'] as num?,
      optionalColorSurchargeNet: json['optionalColorSurchargeNet'] as num?,
      colors: rawColors.whereType<Map<String, dynamic>>().map(SalesCatalogColorOptionInfo.fromJson).toList(),
    );
  }
}

class SalesCatalogAssetSummaryInfo {
  const SalesCatalogAssetSummaryInfo({
    required this.brandCode,
    required this.modelCode,
    required this.modelName,
    required this.assetsVersionTag,
    required this.totalFiles,
    required this.categories,
    required this.specPowertrains,
    required this.hasGenericSpecPdf,
    required this.source,
  });

  final String? brandCode;
  final String modelCode;
  final String modelName;
  final String? assetsVersionTag;
  final int totalFiles;
  final Map<String, num> categories;
  final List<String> specPowertrains;
  final bool hasGenericSpecPdf;
  final String source;

  factory SalesCatalogAssetSummaryInfo.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    final categories = <String, num>{};

    if (rawCategories is Map<String, dynamic>) {
      for (final entry in rawCategories.entries) {
        final value = entry.value;
        if (value is num) {
          categories[entry.key] = value;
        }
      }
    }

    return SalesCatalogAssetSummaryInfo(
      brandCode: json['brandCode'] as String?,
      modelCode: json['modelCode'] as String? ?? '',
      modelName: json['modelName'] as String? ?? '',
      assetsVersionTag: json['assetsVersionTag'] as String?,
      totalFiles: json['totalFiles'] as int? ?? 0,
      categories: categories,
      specPowertrains: (json['specPowertrains'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      hasGenericSpecPdf: json['hasGenericSpecPdf'] as bool? ?? false,
      source: json['source'] as String? ?? 'STATIC',
    );
  }
}

class SalesCatalogStatsInfo {
  const SalesCatalogStatsInfo({
    required this.brands,
    required this.models,
    required this.versions,
    required this.pricingRecords,
    required this.colorPalettes,
    required this.colors,
    required this.assetBundles,
    required this.assetFiles,
  });

  final int brands;
  final int models;
  final int versions;
  final int pricingRecords;
  final int colorPalettes;
  final int colors;
  final int assetBundles;
  final int assetFiles;

  factory SalesCatalogStatsInfo.fromJson(Map<String, dynamic> json) {
    return SalesCatalogStatsInfo(
      brands: json['brands'] as int? ?? 0,
      models: json['models'] as int? ?? 0,
      versions: json['versions'] as int? ?? 0,
      pricingRecords: json['pricingRecords'] as int? ?? 0,
      colorPalettes: json['colorPalettes'] as int? ?? 0,
      colors: json['colors'] as int? ?? 0,
      assetBundles: json['assetBundles'] as int? ?? 0,
      assetFiles: json['assetFiles'] as int? ?? 0,
    );
  }
}

class SalesCatalogBootstrapInfo {
  const SalesCatalogBootstrapInfo({
    required this.brands,
    required this.models,
    required this.versions,
    required this.pricingRecords,
    required this.colorPalettes,
    required this.assetBundles,
    required this.stats,
  });

  final List<SalesCatalogBrandInfo> brands;
  final List<SalesCatalogModelInfo> models;
  final List<SalesCatalogVersionInfo> versions;
  final List<OfferPricingOption> pricingRecords;
  final List<SalesCatalogColorPaletteInfo> colorPalettes;
  final List<SalesCatalogAssetSummaryInfo> assetBundles;
  final SalesCatalogStatsInfo stats;

  factory SalesCatalogBootstrapInfo.fromJson(Map<String, dynamic> json) {
    final rawBrands = json['brands'] as List<dynamic>? ?? const [];
    final rawModels = json['models'] as List<dynamic>? ?? const [];
    final rawVersions = json['versions'] as List<dynamic>? ?? const [];
    final rawPricingRecords = json['pricingRecords'] as List<dynamic>? ?? const [];
    final rawColorPalettes = json['colorPalettes'] as List<dynamic>? ?? const [];
    final rawAssetBundles = json['assetBundles'] as List<dynamic>? ?? const [];

    return SalesCatalogBootstrapInfo(
      brands: rawBrands.whereType<Map<String, dynamic>>().map(SalesCatalogBrandInfo.fromJson).toList(),
      models: rawModels.whereType<Map<String, dynamic>>().map(SalesCatalogModelInfo.fromJson).toList(),
      versions: rawVersions.whereType<Map<String, dynamic>>().map(SalesCatalogVersionInfo.fromJson).toList(),
      pricingRecords: rawPricingRecords.whereType<Map<String, dynamic>>().map(OfferPricingOption.fromJson).toList(),
      colorPalettes: rawColorPalettes.whereType<Map<String, dynamic>>().map(SalesCatalogColorPaletteInfo.fromJson).toList(),
      assetBundles: rawAssetBundles.whereType<Map<String, dynamic>>().map(SalesCatalogAssetSummaryInfo.fromJson).toList(),
      stats: SalesCatalogStatsInfo.fromJson(json['stats'] as Map<String, dynamic>? ?? const {}),
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
    required this.year,
    required this.powertrain,
    required this.powerHp,
    required this.listPriceNet,
    required this.listPriceGross,
    required this.basePriceNet,
    required this.basePriceGross,
    required this.marginPoolNet,
    required this.marginPoolGross,
  });

  final String key;
  final String label;
  final String brand;
  final String model;
  final String version;
  final String? year;
  final String? powertrain;
  final String? powerHp;
  final num? listPriceNet;
  final num? listPriceGross;
  final num? basePriceNet;
  final num? basePriceGross;
  final num? marginPoolNet;
  final num? marginPoolGross;

  factory OfferPricingOption.fromJson(Map<String, dynamic> json) {
    return OfferPricingOption(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? 'Pozycja cenowa',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      version: json['version'] as String? ?? '',
      year: json['year'] as String?,
      powertrain: json['powertrain'] as String?,
      powerHp: json['powerHp'] as String?,
      listPriceNet: json['listPriceNet'] as num?,
      listPriceGross: json['listPriceGross'] as num?,
      basePriceNet: json['basePriceNet'] as num?,
      basePriceGross: json['basePriceGross'] as num?,
      marginPoolNet: json['marginPoolNet'] as num?,
      marginPoolGross: json['marginPoolGross'] as num?,
    );
  }
}

class BootstrapPayload {
  const BootstrapPayload({
    required this.session,
    required this.manifest,
    required this.catalog,
    required this.offers,
    required this.leadOptions,
    required this.pricingOptions,
  });

  final SessionInfo session;
  final UpdateManifestInfo? manifest;
  final SalesCatalogBootstrapInfo? catalog;
  final List<ManagedOfferSummary> offers;
  final List<OfferLeadOption> leadOptions;
  final List<OfferPricingOption> pricingOptions;

  factory BootstrapPayload.fromJson(Map<String, dynamic> json) {
    final rawOffers = (json['offers'] as List<dynamic>? ?? const []);
    final rawLeadOptions = (json['leadOptions'] as List<dynamic>? ?? const []);
    final rawPricingOptions = (json['pricingOptions'] as List<dynamic>? ?? const []);
    final rawManifest = json['manifest'];
    final rawCatalog = json['catalog'];

    return BootstrapPayload(
      session: SessionInfo.fromJson(json['session'] as Map<String, dynamic>? ?? const {}),
      manifest: rawManifest is Map<String, dynamic> ? UpdateManifestInfo.fromJson(rawManifest) : null,
      catalog: rawCatalog is Map<String, dynamic> ? SalesCatalogBootstrapInfo.fromJson(rawCatalog) : null,
      offers: rawOffers.whereType<Map<String, dynamic>>().map(ManagedOfferSummary.fromJson).toList(),
      leadOptions: rawLeadOptions.whereType<Map<String, dynamic>>().map(OfferLeadOption.fromJson).toList(),
      pricingOptions: rawPricingOptions.whereType<Map<String, dynamic>>().map(OfferPricingOption.fromJson).toList(),
    );
  }
}