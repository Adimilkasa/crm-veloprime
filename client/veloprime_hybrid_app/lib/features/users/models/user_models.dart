class ManagedUserAccount {
  const ManagedUserAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.region,
    required this.teamName,
    required this.reportsToUserId,
    required this.createdAt,
    required this.source,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final String? region;
  final String? teamName;
  final String? reportsToUserId;
  final String createdAt;
  final String source;

  factory ManagedUserAccount.fromJson(Map<String, dynamic> json) {
    return ManagedUserAccount(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'SALES',
      isActive: json['isActive'] as bool? ?? false,
      region: json['region'] as String?,
      teamName: json['teamName'] as String?,
      reportsToUserId: json['reportsToUserId'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      source: json['source'] as String? ?? 'custom',
    );
  }
}

class SupervisorOptionModel {
  const SupervisorOptionModel({
    required this.id,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String fullName;
  final String role;

  factory SupervisorOptionModel.fromJson(Map<String, dynamic> json) {
    return SupervisorOptionModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'SALES',
    );
  }
}

class UsersOverview {
  const UsersOverview({
    required this.users,
    required this.supervisors,
  });

  final List<ManagedUserAccount> users;
  final List<SupervisorOptionModel> supervisors;
}

class UserCreationResult {
  const UserCreationResult({
    required this.user,
    required this.temporaryPassword,
  });

  final ManagedUserAccount user;
  final String? temporaryPassword;
}