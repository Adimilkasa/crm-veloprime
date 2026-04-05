class ManagedReminderInfo {
  const ManagedReminderInfo({
    required this.id,
    required this.title,
    required this.note,
    required this.remindAt,
    required this.isCompleted,
    required this.completedAt,
    required this.leadId,
    required this.leadName,
    required this.ownerUserId,
    required this.ownerName,
    required this.createdByUserId,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? note;
  final String remindAt;
  final bool isCompleted;
  final String? completedAt;
  final String? leadId;
  final String? leadName;
  final String? ownerUserId;
  final String? ownerName;
  final String? createdByUserId;
  final String? createdByName;
  final String createdAt;
  final String updatedAt;

  factory ManagedReminderInfo.fromJson(Map<String, dynamic> json) {
    return ManagedReminderInfo(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      note: json['note'] as String?,
      remindAt: json['remindAt'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] as String?,
      leadId: json['leadId'] as String?,
      leadName: json['leadName'] as String?,
      ownerUserId: json['ownerUserId'] as String?,
      ownerName: json['ownerName'] as String?,
      createdByUserId: json['createdByUserId'] as String?,
      createdByName: json['createdByName'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}