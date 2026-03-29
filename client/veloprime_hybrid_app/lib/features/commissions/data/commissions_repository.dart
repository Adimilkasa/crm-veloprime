import '../../../core/network/api_client.dart';
import '../models/commission_models.dart';

class CommissionsRepository {
  CommissionsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<CommissionsWorkspaceData> fetchWorkspace({String? targetUserId}) async {
    final suffix = targetUserId != null && targetUserId.isNotEmpty
        ? '?userId=${Uri.encodeQueryComponent(targetUserId)}'
        : '';
    final json = await _apiClient.getJson('/api/client/commissions$suffix');
    return CommissionsWorkspaceData.fromJson(json['workspace'] as Map<String, dynamic>? ?? const {});
  }

  Future<CommissionsWorkspaceData> saveRules({
    required String targetUserId,
    required List<CommissionRuleModel> rules,
  }) async {
    final json = await _apiClient.patchJson('/api/client/commissions', {
      'targetUserId': targetUserId,
      'rules': rules
          .map(
            (rule) => {
              'id': rule.id,
              'valueType': rule.valueType,
              'value': rule.value,
            },
          )
          .toList(),
    });
    return CommissionsWorkspaceData.fromJson(json['workspace'] as Map<String, dynamic>? ?? const {});
  }
}