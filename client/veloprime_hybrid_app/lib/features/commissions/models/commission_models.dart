class CommissionUserOption {
  const CommissionUserOption({
    required this.id,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String fullName;
  final String role;

  factory CommissionUserOption.fromJson(Map<String, dynamic> json) {
    return CommissionUserOption(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'MANAGER',
    );
  }
}

class CommissionSummary {
  const CommissionSummary({
    required this.total,
    required this.configured,
    required this.missing,
    required this.archived,
  });

  final int total;
  final int configured;
  final int missing;
  final int archived;

  factory CommissionSummary.fromJson(Map<String, dynamic> json) {
    return CommissionSummary(
      total: json['total'] as int? ?? 0,
      configured: json['configured'] as int? ?? 0,
      missing: json['missing'] as int? ?? 0,
      archived: json['archived'] as int? ?? 0,
    );
  }
}

class CommissionRuleModel {
  const CommissionRuleModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.catalogKey,
    required this.brand,
    required this.model,
    required this.version,
    required this.year,
    required this.valueType,
    required this.value,
  });

  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String catalogKey;
  final String brand;
  final String model;
  final String version;
  final String? year;
  final String valueType;
  final num? value;

  factory CommissionRuleModel.fromJson(Map<String, dynamic> json) {
    return CommissionRuleModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userRole: json['userRole'] as String? ?? 'MANAGER',
      catalogKey: json['catalogKey'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      version: json['version'] as String? ?? '',
      year: json['year'] as String?,
      valueType: json['valueType'] as String? ?? 'AMOUNT',
      value: json['value'] as num?,
    );
  }

  CommissionRuleModel copyWith({
    String? valueType,
    num? value,
    bool clearValue = false,
  }) {
    return CommissionRuleModel(
      id: id,
      userId: userId,
      userName: userName,
      userRole: userRole,
      catalogKey: catalogKey,
      brand: brand,
      model: model,
      version: version,
      year: year,
      valueType: valueType ?? this.valueType,
      value: clearValue ? null : (value ?? this.value),
    );
  }
}

class CommissionsWorkspaceData {
  const CommissionsWorkspaceData({
    required this.targetUserId,
    required this.editable,
    required this.users,
    required this.rules,
    required this.summary,
    required this.updatedAt,
    required this.updatedBy,
  });

  final String? targetUserId;
  final bool editable;
  final List<CommissionUserOption> users;
  final List<CommissionRuleModel> rules;
  final CommissionSummary summary;
  final String? updatedAt;
  final String? updatedBy;

  factory CommissionsWorkspaceData.fromJson(Map<String, dynamic> json) {
    final rawUsers = (json['users'] as List<dynamic>? ?? const []);
    final rawRules = (json['rules'] as List<dynamic>? ?? const []);

    return CommissionsWorkspaceData(
      targetUserId: json['targetUserId'] as String?,
      editable: json['editable'] as bool? ?? false,
      users: rawUsers.whereType<Map<String, dynamic>>().map(CommissionUserOption.fromJson).toList(),
      rules: rawRules.whereType<Map<String, dynamic>>().map(CommissionRuleModel.fromJson).toList(),
      summary: CommissionSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? const {}),
      updatedAt: json['updatedAt'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }
}