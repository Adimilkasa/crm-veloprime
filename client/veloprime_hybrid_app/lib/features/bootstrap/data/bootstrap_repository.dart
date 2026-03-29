import '../../../core/network/api_client.dart';
import '../models/bootstrap_payload.dart';

class BootstrapRepository {
  BootstrapRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<BootstrapPayload> loadBootstrap() async {
    final json = await _apiClient.getJson('/api/client/bootstrap');
    return BootstrapPayload.fromJson(json);
  }
}