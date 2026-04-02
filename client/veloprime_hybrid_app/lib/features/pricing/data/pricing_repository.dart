import '../../../core/network/api_client.dart';
import '../models/pricing_models.dart';

class PricingRepository {
  PricingRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<CatalogWorkspaceData> fetchWorkspace() async {
    final json = await _apiClient.getJson('/api/client/catalog/workspace');
    return CatalogWorkspaceData.fromJson(json['workspace'] as Map<String, dynamic>? ?? const {});
  }

  Future<CatalogBrand> createBrand({
    required String name,
    int? sortOrder,
  }) async {
    final json = await _apiClient.postJson('/api/client/catalog/brands', {
      'name': name,
      if (sortOrder != null) 'sortOrder': sortOrder,
    });

    return CatalogBrand.fromJson(json['brand'] as Map<String, dynamic>? ?? const {});
  }

  Future<CatalogBrand> updateBrand({
    required String brandId,
    required String name,
    int? sortOrder,
  }) async {
    final json = await _apiClient.patchJson('/api/client/catalog/brands/$brandId', {
      'name': name,
      if (sortOrder != null) 'sortOrder': sortOrder,
    });

    return CatalogBrand.fromJson(json['brand'] as Map<String, dynamic>? ?? const {});
  }

  Future<CatalogModel> createModel({
    required String brandId,
    required String name,
    String? marketingName,
    int? sortOrder,
  }) async {
    final json = await _apiClient.postJson('/api/client/catalog/models', {
      'brandId': brandId,
      'name': name,
      if (marketingName != null && marketingName.trim().isNotEmpty) 'marketingName': marketingName.trim(),
      if (sortOrder != null) 'sortOrder': sortOrder,
    });

    return CatalogModel.fromJson(json['model'] as Map<String, dynamic>? ?? const {});
  }

  Future<CatalogModel> updateModel({
    required String modelId,
    required String brandId,
    required String name,
    String? marketingName,
    int? sortOrder,
  }) async {
    final json = await _apiClient.patchJson('/api/client/catalog/models/$modelId', {
      'brandId': brandId,
      'name': name,
      'marketingName': marketingName?.trim().isEmpty ?? true ? null : marketingName!.trim(),
      if (sortOrder != null) 'sortOrder': sortOrder,
    });

    return CatalogModel.fromJson(json['model'] as Map<String, dynamic>? ?? const {});
  }

  Future<void> archiveModel(String modelId) async {
    await _apiClient.postJson('/api/client/catalog/models/$modelId/archive', const {});
  }

  Future<void> restoreModel(String modelId) async {
    await _apiClient.postJson('/api/client/catalog/models/$modelId/restore', const {});
  }

  Future<CatalogVersion> createVersion({
    required String modelId,
    required String name,
    required String powertrainType,
    int? year,
    int? sortOrder,
    String? driveType,
    num? systemPowerHp,
    num? batteryCapacityKwh,
    num? combustionEnginePowerHp,
    num? engineDisplacementCc,
    num? rangeKm,
    String? notes,
  }) async {
    final json = await _apiClient.postJson('/api/client/catalog/versions', {
      'modelId': modelId,
      'name': name,
      'powertrainType': powertrainType,
      if (year != null) 'year': year,
      if (sortOrder != null) 'sortOrder': sortOrder,
      if (driveType != null && driveType.isNotEmpty) 'driveType': driveType,
      if (systemPowerHp != null) 'systemPowerHp': systemPowerHp,
      if (batteryCapacityKwh != null) 'batteryCapacityKwh': batteryCapacityKwh,
      if (combustionEnginePowerHp != null) 'combustionEnginePowerHp': combustionEnginePowerHp,
      if (engineDisplacementCc != null) 'engineDisplacementCc': engineDisplacementCc,
      if (rangeKm != null) 'rangeKm': rangeKm,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });

    return CatalogVersion.fromJson(json['version'] as Map<String, dynamic>? ?? const {});
  }

  Future<CatalogVersion> updateVersion({
    required String versionId,
    required String modelId,
    required String name,
    required String powertrainType,
    int? year,
    int? sortOrder,
    String? driveType,
    num? systemPowerHp,
    num? batteryCapacityKwh,
    num? combustionEnginePowerHp,
    num? engineDisplacementCc,
    num? rangeKm,
    String? notes,
  }) async {
    final json = await _apiClient.patchJson('/api/client/catalog/versions/$versionId', {
      'modelId': modelId,
      'name': name,
      'powertrainType': powertrainType,
      if (year != null) 'year': year,
      if (sortOrder != null) 'sortOrder': sortOrder,
      'driveType': driveType?.isEmpty ?? true ? null : driveType,
      'systemPowerHp': systemPowerHp,
      'batteryCapacityKwh': batteryCapacityKwh,
      'combustionEnginePowerHp': combustionEnginePowerHp,
      'engineDisplacementCc': engineDisplacementCc,
      'rangeKm': rangeKm,
      'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
    });

    return CatalogVersion.fromJson(json['version'] as Map<String, dynamic>? ?? const {});
  }

  Future<CatalogPricingRecord> createPricing({
    required String versionId,
    required num listPriceNet,
    required num basePriceNet,
    num vatRate = 23,
    String? effectiveFrom,
    String? effectiveTo,
  }) async {
    final json = await _apiClient.postJson('/api/client/catalog/versions/$versionId/pricing', {
      'listPriceNet': listPriceNet,
      'basePriceNet': basePriceNet,
      'vatRate': vatRate,
      if (effectiveFrom != null && effectiveFrom.isNotEmpty) 'effectiveFrom': effectiveFrom,
      if (effectiveTo != null && effectiveTo.isNotEmpty) 'effectiveTo': effectiveTo,
    });

    return CatalogPricingRecord.fromJson(json['pricing'] as Map<String, dynamic>? ?? const {});
  }

  Future<CatalogPricingRecord> updatePricing({
    required String pricingId,
    required num listPriceNet,
    required num basePriceNet,
    num vatRate = 23,
    String? effectiveFrom,
    String? effectiveTo,
  }) async {
    final json = await _apiClient.patchJson('/api/client/catalog/pricing/$pricingId', {
      'listPriceNet': listPriceNet,
      'basePriceNet': basePriceNet,
      'vatRate': vatRate,
      if (effectiveFrom != null) 'effectiveFrom': effectiveFrom.isEmpty ? null : effectiveFrom,
      if (effectiveTo != null) 'effectiveTo': effectiveTo.isEmpty ? null : effectiveTo,
    });

    return CatalogPricingRecord.fromJson(json['pricing'] as Map<String, dynamic>? ?? const {});
  }

  Future<void> publishPricing(String pricingId) async {
    await _apiClient.postJson('/api/client/catalog/pricing/$pricingId/publish', const {});
  }

  Future<void> archivePricing(String pricingId) async {
    await _apiClient.postJson('/api/client/catalog/pricing/$pricingId/archive', const {});
  }

  Future<CatalogColorRecord> createColor({
    required String modelId,
    required String name,
    String? finishType,
    required bool isBaseColor,
    required bool hasSurcharge,
    num? surchargeNet,
    int? sortOrder,
  }) async {
    final json = await _apiClient.postJson('/api/client/catalog/models/$modelId/colors', {
      'name': name,
      if (finishType != null && finishType.trim().isNotEmpty) 'finishType': finishType.trim(),
      'isBaseColor': isBaseColor,
      'hasSurcharge': hasSurcharge,
      if (surchargeNet != null) 'surchargeNet': surchargeNet,
      if (sortOrder != null) 'sortOrder': sortOrder,
    });

    return CatalogColorRecord.fromJson(json['color'] as Map<String, dynamic>? ?? const {});
  }

  Future<CatalogColorRecord> updateColor({
    required String colorId,
    required String name,
    String? finishType,
    required bool isBaseColor,
    required bool hasSurcharge,
    num? surchargeNet,
    int? sortOrder,
  }) async {
    final json = await _apiClient.patchJson('/api/client/catalog/colors/$colorId', {
      'name': name,
      'finishType': finishType?.trim().isEmpty ?? true ? null : finishType!.trim(),
      'isBaseColor': isBaseColor,
      'hasSurcharge': hasSurcharge,
      'surchargeNet': hasSurcharge ? surchargeNet : null,
      if (sortOrder != null) 'sortOrder': sortOrder,
    });

    return CatalogColorRecord.fromJson(json['color'] as Map<String, dynamic>? ?? const {});
  }

  Future<void> deleteColor(String colorId) async {
    await _apiClient.deleteJson('/api/client/catalog/colors/$colorId');
  }

  Future<void> updateModelAssets({
    required String modelId,
    String? assetsVersionTag,
    bool? isActive,
  }) async {
    await _apiClient.patchJson('/api/client/catalog/models/$modelId/assets', {
      if (assetsVersionTag != null) 'assetsVersionTag': assetsVersionTag,
      if (isActive != null) 'isActive': isActive,
    });
  }

  Future<CatalogAssetBundle> createAssetFile({
    required String modelId,
    required String category,
    String? powertrainType,
    required String fileName,
    required String sourceFilePath,
    String? mimeType,
    int? sortOrder,
  }) async {
    final json = await _apiClient.postMultipart(
      '/api/client/catalog/models/$modelId/assets/files',
      fields: {
        'category': category,
        if (powertrainType != null && powertrainType.isNotEmpty) 'powertrainType': powertrainType,
        'fileName': fileName,
        if (mimeType != null && mimeType.trim().isNotEmpty) 'mimeType': mimeType.trim(),
        if (sortOrder != null) 'sortOrder': '$sortOrder',
      },
      fileField: 'file',
      filePath: sourceFilePath,
      fileName: fileName,
    );

    return CatalogAssetBundle.fromJson(json['assetBundle'] as Map<String, dynamic>? ?? const {});
  }

  Future<void> deleteAssetFile(String fileId) async {
    await _apiClient.deleteJson('/api/client/catalog/assets/files/$fileId');
  }
}