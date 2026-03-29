import '../../../core/network/api_client.dart';

class AccountRepository {
  AccountRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.postJson('/api/client/account/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}