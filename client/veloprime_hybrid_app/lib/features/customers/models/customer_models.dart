class ManagedCustomerRecord {
  const ManagedCustomerRecord({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.companyName,
    required this.taxId,
    required this.city,
    required this.notes,
    required this.ownerId,
    required this.ownerName,
    required this.leadCount,
    required this.offerCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? companyName;
  final String? taxId;
  final String? city;
  final String? notes;
  final String? ownerId;
  final String? ownerName;
  final int leadCount;
  final int offerCount;
  final String createdAt;
  final String updatedAt;

  factory ManagedCustomerRecord.fromJson(Map<String, dynamic> json) {
    return ManagedCustomerRecord(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      companyName: json['companyName'] as String?,
      taxId: json['taxId'] as String?,
      city: json['city'] as String?,
      notes: json['notes'] as String?,
      ownerId: json['ownerId'] as String?,
      ownerName: json['ownerName'] as String?,
      leadCount: json['leadCount'] as int? ?? 0,
      offerCount: json['offerCount'] as int? ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class ManagedCustomerOwnerOption {
  const ManagedCustomerOwnerOption({
    required this.id,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String fullName;
  final String role;

  factory ManagedCustomerOwnerOption.fromJson(Map<String, dynamic> json) {
    return ManagedCustomerOwnerOption(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? 'SALES',
    );
  }
}

class ManagedCustomerLeadHistoryItem {
  const ManagedCustomerLeadHistoryItem({
    required this.id,
    required this.fullName,
    required this.stageLabel,
    required this.salespersonName,
    required this.updatedAt,
    required this.acceptedAt,
  });

  final String id;
  final String fullName;
  final String stageLabel;
  final String? salespersonName;
  final String updatedAt;
  final String? acceptedAt;

  factory ManagedCustomerLeadHistoryItem.fromJson(Map<String, dynamic> json) {
    return ManagedCustomerLeadHistoryItem(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      stageLabel: json['stageLabel'] as String? ?? '',
      salespersonName: json['salespersonName'] as String?,
      updatedAt: json['updatedAt'] as String? ?? '',
      acceptedAt: json['acceptedAt'] as String?,
    );
  }
}

class ManagedCustomerOfferHistoryItem {
  const ManagedCustomerOfferHistoryItem({
    required this.id,
    required this.number,
    required this.title,
    required this.status,
    required this.ownerName,
    required this.updatedAt,
  });

  final String id;
  final String number;
  final String title;
  final String status;
  final String? ownerName;
  final String updatedAt;

  factory ManagedCustomerOfferHistoryItem.fromJson(Map<String, dynamic> json) {
    return ManagedCustomerOfferHistoryItem(
      id: json['id'] as String? ?? '',
      number: json['number'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      ownerName: json['ownerName'] as String?,
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class ManagedCustomerWorkspace {
  const ManagedCustomerWorkspace({
    required this.customer,
    required this.ownerOptions,
    required this.relatedLeads,
    required this.relatedOffers,
  });

  final ManagedCustomerRecord customer;
  final List<ManagedCustomerOwnerOption> ownerOptions;
  final List<ManagedCustomerLeadHistoryItem> relatedLeads;
  final List<ManagedCustomerOfferHistoryItem> relatedOffers;

  factory ManagedCustomerWorkspace.fromJson(Map<String, dynamic> json) {
    return ManagedCustomerWorkspace(
      customer: ManagedCustomerRecord.fromJson(json['customer'] as Map<String, dynamic>? ?? const {}),
      ownerOptions: (json['ownerOptions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ManagedCustomerOwnerOption.fromJson)
          .toList(),
      relatedLeads: (json['relatedLeads'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ManagedCustomerLeadHistoryItem.fromJson)
          .toList(),
      relatedOffers: (json['relatedOffers'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ManagedCustomerOfferHistoryItem.fromJson)
          .toList(),
    );
  }
}