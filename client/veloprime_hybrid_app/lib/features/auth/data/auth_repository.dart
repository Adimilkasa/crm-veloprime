import '../../../core/network/api_client.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> login({required String email, required String password}) {
    return _apiClient.login(email: email, password: password);
  }

  Future<void> logout() {
    return _apiClient.logout();
  }
}