num? _readNum(dynamic value) {
  if (value is num) {
    return value;
  }

  if (value is String) {
    return num.tryParse(value.replaceAll(',', '.'));
  }

  return null;
}

int? _readInt(dynamic value) {
  final number = _readNum(value);
  return number?.toInt();
}

class CatalogWorkspaceData {
  const CatalogWorkspaceData({
    required this.databaseReady,
    required this.source,
    required this.brands,
    required this.models,
    required this.versions,
    required this.pricingRecords,
    required this.colors,
    required this.assetBundles,
    required this.dictionaries,
    required this.stats,
  });

  final bool databaseReady;
  final String source;
  final List<CatalogBrand> brands;
  final List<CatalogModel> models;
  final List<CatalogVersion> versions;
  final List<CatalogPricingRecord> pricingRecords;
  final List<CatalogColorRecord> colors;
  final List<CatalogAssetBundle> assetBundles;
  final CatalogWorkspaceDictionaries dictionaries;
  final CatalogWorkspaceStats stats;

  factory CatalogWorkspaceData.fromJson(Map<String, dynamic> json) {
    final rawBrands = json['brands'] as List<dynamic>? ?? const [];
    final rawModels = json['models'] as List<dynamic>? ?? const [];
    final rawVersions = json['versions'] as List<dynamic>? ?? const [];
    final rawPricing = json['pricingRecords'] as List<dynamic>? ?? const [];
    final rawColors = json['colors'] as List<dynamic>? ?? const [];
    final rawBundles = json['assetBundles'] as List<dynamic>? ?? const [];

    return CatalogWorkspaceData(
      databaseReady: json['databaseReady'] == true,
      source: json['source'] as String? ?? 'database',
      brands: rawBrands.whereType<Map<String, dynamic>>().map(CatalogBrand.fromJson).toList(),
      models: rawModels.whereType<Map<String, dynamic>>().map(CatalogModel.fromJson).toList(),
      versions: rawVersions.whereType<Map<String, dynamic>>().map(CatalogVersion.fromJson).toList(),
      pricingRecords: rawPricing.whereType<Map<String, dynamic>>().map(CatalogPricingRecord.fromJson).toList(),
      colors: rawColors.whereType<Map<String, dynamic>>().map(CatalogColorRecord.fromJson).toList(),
      assetBundles: rawBundles.whereType<Map<String, dynamic>>().map(CatalogAssetBundle.fromJson).toList(),
      dictionaries: CatalogWorkspaceDictionaries.fromJson(json['dictionaries'] as Map<String, dynamic>? ?? const {}),
      stats: CatalogWorkspaceStats.fromJson(json['stats'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class CatalogWorkspaceDictionaries {
  const CatalogWorkspaceDictionaries({
    required this.modelStatuses,
    required this.powertrainTypes,
    required this.driveTypes,
    required this.pricingStatuses,
    required this.assetCategories,
    required this.defaultVatRate,
  });

  final List<String> modelStatuses;
  final List<String> powertrainTypes;
  final List<String> driveTypes;
  final List<String> pricingStatuses;
  final List<String> assetCategories;
  final num defaultVatRate;

  factory CatalogWorkspaceDictionaries.fromJson(Map<String, dynamic> json) {
    return CatalogWorkspaceDictionaries(
      modelStatuses: (json['modelStatuses'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      powertrainTypes: (json['powertrainTypes'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      driveTypes: (json['driveTypes'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      pricingStatuses: (json['pricingStatuses'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      assetCategories: (json['assetCategories'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      defaultVatRate: _readNum(json['defaultVatRate']) ?? 23,
    );
  }
}

class CatalogWorkspaceStats {
  const CatalogWorkspaceStats({
    required this.brands,
    required this.models,
    required this.versions,
    required this.pricingRecords,
    required this.colors,
    required this.assetBundles,
    required this.assetFiles,
  });

  final int brands;
  final int models;
  final int versions;
  final int pricingRecords;
  final int colors;
  final int assetBundles;
  final int assetFiles;

  factory CatalogWorkspaceStats.fromJson(Map<String, dynamic> json) {
    return CatalogWorkspaceStats(
      brands: _readInt(json['brands']) ?? 0,
      models: _readInt(json['models']) ?? 0,
      versions: _readInt(json['versions']) ?? 0,
      pricingRecords: _readInt(json['pricingRecords']) ?? 0,
      colors: _readInt(json['colors']) ?? 0,
      assetBundles: _readInt(json['assetBundles']) ?? 0,
      assetFiles: _readInt(json['assetFiles']) ?? 0,
    );
  }
}

class CatalogBrand {
  const CatalogBrand({
    required this.id,
    required this.code,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  factory CatalogBrand.fromJson(Map<String, dynamic> json) {
    return CatalogBrand(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sortOrder: _readInt(json['sortOrder']) ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class CatalogModel {
  const CatalogModel({
    required this.id,
    required this.brandId,
    required this.code,
    required this.name,
    required this.marketingName,
    required this.status,
    required this.sortOrder,
    required this.availablePowertrains,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String brandId;
  final String code;
  final String name;
  final String? marketingName;
  final String status;
  final int sortOrder;
  final List<String> availablePowertrains;
  final String createdAt;
  final String updatedAt;

  bool get isArchived => status == 'ARCHIVED';

  factory CatalogModel.fromJson(Map<String, dynamic> json) {
    return CatalogModel(
      id: json['id'] as String? ?? '',
      brandId: json['brandId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      marketingName: json['marketingName'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      sortOrder: _readInt(json['sortOrder']) ?? 0,
      availablePowertrains: (json['availablePowertrains'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class CatalogVersion {
  const CatalogVersion({
    required this.id,
    required this.modelId,
    required this.code,
    required this.name,
    required this.year,
    required this.powertrainType,
    required this.driveType,
    required this.systemPowerHp,
    required this.batteryCapacityKwh,
    required this.combustionEnginePowerHp,
    required this.engineDisplacementCc,
    required this.rangeKm,
    required this.notes,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String modelId;
  final String code;
  final String name;
  final int? year;
  final String powertrainType;
  final String? driveType;
  final num? systemPowerHp;
  final num? batteryCapacityKwh;
  final num? combustionEnginePowerHp;
  final num? engineDisplacementCc;
  final num? rangeKm;
  final String? notes;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  factory CatalogVersion.fromJson(Map<String, dynamic> json) {
    return CatalogVersion(
      id: json['id'] as String? ?? '',
      modelId: json['modelId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      year: _readInt(json['year']),
      powertrainType: json['powertrainType'] as String? ?? 'ELECTRIC',
      driveType: json['driveType'] as String?,
      systemPowerHp: _readNum(json['systemPowerHp']),
      batteryCapacityKwh: _readNum(json['batteryCapacityKwh']),
      combustionEnginePowerHp: _readNum(json['combustionEnginePowerHp']),
      engineDisplacementCc: _readNum(json['engineDisplacementCc']),
      rangeKm: _readNum(json['rangeKm']),
      notes: json['notes'] as String?,
      sortOrder: _readInt(json['sortOrder']) ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class CatalogPricingRecord {
  const CatalogPricingRecord({
    required this.id,
    required this.versionId,
    required this.listPriceNet,
    required this.listPriceGross,
    required this.basePriceNet,
    required this.basePriceGross,
    required this.vatRate,
    required this.marginPoolNet,
    required this.marginPoolGross,
    required this.pricingStatus,
    required this.effectiveFrom,
    required this.effectiveTo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String versionId;
  final num listPriceNet;
  final num listPriceGross;
  final num basePriceNet;
  final num basePriceGross;
  final num vatRate;
  final num marginPoolNet;
  final num marginPoolGross;
  final String pricingStatus;
  final String? effectiveFrom;
  final String? effectiveTo;
  final String createdAt;
  final String updatedAt;

  bool get isPublished => pricingStatus == 'PUBLISHED';
  bool get isArchived => pricingStatus == 'ARCHIVED';

  factory CatalogPricingRecord.fromJson(Map<String, dynamic> json) {
    return CatalogPricingRecord(
      id: json['id'] as String? ?? '',
      versionId: json['versionId'] as String? ?? '',
      listPriceNet: _readNum(json['listPriceNet']) ?? 0,
      listPriceGross: _readNum(json['listPriceGross']) ?? 0,
      basePriceNet: _readNum(json['basePriceNet']) ?? 0,
      basePriceGross: _readNum(json['basePriceGross']) ?? 0,
      vatRate: _readNum(json['vatRate']) ?? 23,
      marginPoolNet: _readNum(json['marginPoolNet']) ?? 0,
      marginPoolGross: _readNum(json['marginPoolGross']) ?? 0,
      pricingStatus: json['pricingStatus'] as String? ?? 'DRAFT',
      effectiveFrom: json['effectiveFrom'] as String?,
      effectiveTo: json['effectiveTo'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class CatalogColorRecord {
  const CatalogColorRecord({
    required this.id,
    required this.modelId,
    required this.code,
    required this.name,
    required this.finishType,
    required this.isBaseColor,
    required this.hasSurcharge,
    required this.surchargeNet,
    required this.surchargeGross,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String modelId;
  final String code;
  final String name;
  final String? finishType;
  final bool isBaseColor;
  final bool hasSurcharge;
  final num? surchargeNet;
  final num? surchargeGross;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  factory CatalogColorRecord.fromJson(Map<String, dynamic> json) {
    return CatalogColorRecord(
      id: json['id'] as String? ?? '',
      modelId: json['modelId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      finishType: json['finishType'] as String?,
      isBaseColor: json['isBaseColor'] as bool? ?? false,
      hasSurcharge: json['hasSurcharge'] as bool? ?? false,
      surchargeNet: _readNum(json['surchargeNet']),
      surchargeGross: _readNum(json['surchargeGross']),
      sortOrder: _readInt(json['sortOrder']) ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class CatalogAssetBundle {
  const CatalogAssetBundle({
    required this.id,
    required this.modelId,
    required this.assetsVersionTag,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.files,
  });

  final String id;
  final String modelId;
  final String? assetsVersionTag;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final List<CatalogAssetFile> files;

  factory CatalogAssetBundle.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'] as List<dynamic>? ?? const [];

    return CatalogAssetBundle(
      id: json['id'] as String? ?? '',
      modelId: json['modelId'] as String? ?? '',
      assetsVersionTag: json['assetsVersionTag'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      files: rawFiles.whereType<Map<String, dynamic>>().map(CatalogAssetFile.fromJson).toList(),
    );
  }
}

class CatalogAssetFile {
  const CatalogAssetFile({
    required this.id,
    required this.bundleId,
    required this.category,
    required this.powertrainType,
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String bundleId;
  final String category;
  final String? powertrainType;
  final String fileName;
  final String filePath;
  final String? mimeType;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  bool get isSpecPdf => category == 'SPEC_PDF';

  factory CatalogAssetFile.fromJson(Map<String, dynamic> json) {
    return CatalogAssetFile(
      id: json['id'] as String? ?? '',
      bundleId: json['bundleId'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      powertrainType: json['powertrainType'] as String?,
      fileName: json['fileName'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      mimeType: json['mimeType'] as String?,
      sortOrder: _readInt(json['sortOrder']) ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}