import '../../../core/network/api_client.dart';
import '../models/user_models.dart';

class UsersRepository {
  UsersRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<UsersOverview> fetchUsers() async {
    final json = await _apiClient.getJson('/api/client/users');
    final users = (json['users'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ManagedUserAccount.fromJson)
        .toList();
    final supervisors = (json['supervisorOptions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SupervisorOptionModel.fromJson)
        .toList();

    return UsersOverview(users: users, supervisors: supervisors);
  }

  Future<UserCreationResult> createUser(Map<String, dynamic> payload) async {
    final json = await _apiClient.postJson('/api/client/users', payload);
    return UserCreationResult(
      user: ManagedUserAccount.fromJson(json['user'] as Map<String, dynamic>? ?? const {}),
      temporaryPassword: json['temporaryPassword'] as String?,
    );
  }

  Future<ManagedUserAccount> toggleStatus(String userId) async {
    final json = await _apiClient.patchJson('/api/client/users/$userId/status', const {});
    return ManagedUserAccount.fromJson(json['user'] as Map<String, dynamic>? ?? const {});
  }

  Future<String> resetPassword(String userId, {String? newPassword}) async {
    final json = await _apiClient.postJson('/api/client/users/$userId/password-reset', {
      'newPassword': newPassword,
    });
    return json['temporaryPassword'] as String? ?? '';
  }
}