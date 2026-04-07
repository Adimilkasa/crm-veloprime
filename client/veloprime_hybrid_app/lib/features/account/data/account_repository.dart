import '../../../core/network/api_client.dart';

class AccountProfile {
  const AccountProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? avatarUrl;

  factory AccountProfile.fromJson(Map<String, dynamic> json) {
    return AccountProfile(
      id: json['sub'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'SALES',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class AccountAvatarUpdateResult {
  const AccountAvatarUpdateResult({
    required this.profile,
    this.warning,
  });

  final AccountProfile profile;
  final String? warning;
}

class AccountRepository {
  AccountRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AccountProfile> fetchProfile() async {
    final json = await _apiClient.getJson('/api/client/account');
    return AccountProfile.fromJson(
        json['profile'] as Map<String, dynamic>? ?? const {});
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.postJson('/api/client/account/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<AccountAvatarUpdateResult> uploadAvatar({
    required String filePath,
    required String fileName,
  }) async {
    final json = await _apiClient.postMultipart(
      '/api/client/account/avatar',
      fields: const {},
      fileField: 'file',
      filePath: filePath,
      fileName: fileName,
    );

    return AccountAvatarUpdateResult(
      profile: AccountProfile.fromJson(
          json['profile'] as Map<String, dynamic>? ?? const {}),
      warning: json['warning']?.toString(),
    );
  }

  Future<AccountAvatarUpdateResult> removeAvatar() async {
    final json = await _apiClient.deleteJson('/api/client/account/avatar');
    return AccountAvatarUpdateResult(
      profile: AccountProfile.fromJson(
          json['profile'] as Map<String, dynamic>? ?? const {}),
      warning: json['warning']?.toString(),
    );
  }
}
