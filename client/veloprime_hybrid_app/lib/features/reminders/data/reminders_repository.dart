import '../../../core/network/api_client.dart';
import '../models/reminder_models.dart';

class RemindersRepository {
  RemindersRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ManagedReminderInfo>> fetchActiveReminders() async {
    final json = await _apiClient.getJson('/api/client/reminders');
    return (json['reminders'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ManagedReminderInfo.fromJson)
        .toList();
  }

  Future<ManagedReminderInfo> createReminder({
    required String title,
    String? note,
    required String remindAt,
    String? leadId,
  }) async {
    final json = await _apiClient.postJson('/api/client/reminders', {
      'title': title,
      'note': note,
      'remindAt': remindAt,
      'leadId': leadId,
    });

    return ManagedReminderInfo.fromJson(
      json['reminder'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<ManagedReminderInfo> completeReminder(String reminderId) async {
    final json = await _apiClient.patchJson('/api/client/reminders/$reminderId', const {});
    return ManagedReminderInfo.fromJson(
      json['reminder'] as Map<String, dynamic>? ?? const {},
    );
  }
}