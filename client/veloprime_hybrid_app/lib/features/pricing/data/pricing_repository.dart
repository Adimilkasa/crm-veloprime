import '../../../core/network/api_client.dart';
import '../models/pricing_models.dart';

class PricingRepository {
  PricingRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PricingSheetData> fetchSheet() async {
    final json = await _apiClient.getJson('/api/client/pricing');
    return PricingSheetData.fromJson(json['sheet'] as Map<String, dynamic>? ?? const {});
  }

  Future<PricingSheetData> saveSheet({
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final json = await _apiClient.patchJson('/api/client/pricing', {
      'headers': headers,
      'rows': rows,
    });
    return PricingSheetData.fromJson(json['sheet'] as Map<String, dynamic>? ?? const {});
  }

  Future<PricingSheetData> importSheet(String sheetInput) async {
    final json = await _apiClient.postJson('/api/client/pricing/import', {
      'sheetInput': sheetInput,
    });
    return PricingSheetData.fromJson(json['sheet'] as Map<String, dynamic>? ?? const {});
  }

  Future<PricingSheetData> clearSheet() async {
    final json = await _apiClient.deleteJson('/api/client/pricing');
    return PricingSheetData.fromJson(json['sheet'] as Map<String, dynamic>? ?? const {});
  }
}