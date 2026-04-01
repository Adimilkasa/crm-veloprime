import '../../../core/network/api_client.dart';
import '../models/update_models.dart';

class UpdateRepository {
  UpdateRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<VersionComparisonResult> compareVersions(ClientVersionPayload payload) async {
    final json = await _apiClient.postJson('/api/updates/compare', payload.toJson());
    return VersionComparisonResult.fromJson(json);
  }

  Future<UpdateManifestInfo> fetchManifest() async {
    final json = await _apiClient.getJson('/api/updates/manifest');
    return UpdateManifestInfo.fromJson(json['manifest'] as Map<String, dynamic>? ?? const {});
  }

  Future<UpdateManifestInfo> publishUpdate({
    required String artifactType,
    required String priority,
    String? summary,
  }) async {
    final json = await _apiClient.postJson('/api/updates/publish', {
      'artifactType': artifactType,
      'priority': priority,
      'summary': summary,
    });

    return UpdateManifestInfo.fromJson(json['manifest'] as Map<String, dynamic>? ?? const {});
  }
}