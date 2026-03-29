import '../../../core/network/api_client.dart';
import '../models/update_models.dart';

class UpdateRepository {
  UpdateRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<VersionComparisonResult> compareVersions(ClientVersionPayload payload) async {
    final json = await _apiClient.postJson('/api/updates/compare', payload.toJson());
    return VersionComparisonResult.fromJson(json);
  }
}