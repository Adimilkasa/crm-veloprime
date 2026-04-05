class LeadStageInfo {
  const LeadStageInfo({
    required this.id,
    required this.name,
    required this.color,
    required this.order,
    required this.kind,
  });

  final String id;
  final String name;
  final String color;
  final int order;
  final String kind;

  factory LeadStageInfo.fromJson(Map<String, dynamic> json) {
    return LeadStageInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      color: json['color'] as String? ?? '#D1D5DB',
      order: json['order'] as int? ?? 0,
      kind: json['kind'] as String? ?? 'OPEN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'order': order,
      'kind': kind,
    };
  }
}

class CustomerWorkflowStageInfo {
  const CustomerWorkflowStageInfo({
    required this.key,
    required this.label,
    required this.color,
    required this.order,
  });

  final String key;
  final String label;
  final String color;
  final int order;

  factory CustomerWorkflowStageInfo.fromJson(Map<String, dynamic> json) {
    return CustomerWorkflowStageInfo(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      color: json['color'] as String? ?? '#D1D5DB',
      order: json['order'] as int? ?? 0,
    );
  }

  CustomerWorkflowStageInfo copyWith({
    String? key,
    String? label,
    String? color,
    int? order,
  }) {
    return CustomerWorkflowStageInfo(
      key: key ?? this.key,
      label: label ?? this.label,
      color: color ?? this.color,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'color': color,
      'order': order,
    };
  }
}

class LeadOfferSummary {
  const LeadOfferSummary({
    required this.id,
    required this.number,
    required this.title,
    required this.status,
    required this.updatedAt,
    required this.versionCount,
  });

  final String id;
  final String number;
  final String title;
  final String status;
  final String updatedAt;
  final int versionCount;

  factory LeadOfferSummary.fromJson(Map<String, dynamic> json) {
    return LeadOfferSummary(
      id: json['id'] as String? ?? '',
      number: json['number'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'DRAFT',
      updatedAt: json['updatedAt'] as String? ?? '',
      versionCount: json['versionCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'title': title,
      'status': status,
      'updatedAt': updatedAt,
      'versionCount': versionCount,
    };
  }
}

class LeadDetailEntryModel {
  const LeadDetailEntryModel({
    required this.id,
    required this.kind,
    required this.label,
    required this.value,
    required this.authorName,
    required this.createdAt,
  });

  final String id;
  final String kind;
  final String label;
  final String value;
  final String? authorName;
  final String createdAt;

  factory LeadDetailEntryModel.fromJson(Map<String, dynamic> json) {
    return LeadDetailEntryModel(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'INFO',
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      authorName: json['authorName'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  LeadDetailEntryModel copyWith({
    String? id,
    String? kind,
    String? label,
    String? value,
    String? authorName,
    String? createdAt,
  }) {
    return LeadDetailEntryModel(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      value: value ?? this.value,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind,
      'label': label,
      'value': value,
      'authorName': authorName,
      'createdAt': createdAt,
    };
  }
}

class LeadAttachmentModel {
  const LeadAttachmentModel({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedByUserId,
    required this.uploadedByName,
    required this.createdAt,
  });

  final String id;
  final String fileName;
  final String fileUrl;
  final String? mimeType;
  final int sizeBytes;
  final String? uploadedByUserId;
  final String? uploadedByName;
  final String createdAt;

  factory LeadAttachmentModel.fromJson(Map<String, dynamic> json) {
    return LeadAttachmentModel(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      mimeType: json['mimeType'] as String?,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      uploadedByUserId: json['uploadedByUserId'] as String?,
      uploadedByName: json['uploadedByName'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'uploadedByUserId': uploadedByUserId,
      'uploadedByName': uploadedByName,
      'createdAt': createdAt,
    };
  }
}

class SalespersonOption {
  const SalespersonOption({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;

  factory SalespersonOption.fromJson(Map<String, dynamic> json) {
    return SalespersonOption(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
    };
  }
}

class ManagedLeadSummary {
  const ManagedLeadSummary({
    required this.id,
    required this.source,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.customerId,
    required this.customerWorkflowStage,
    required this.interestedModel,
    required this.region,
    required this.stageId,
    required this.message,
    required this.managerName,
    required this.salespersonName,
    required this.nextActionAt,
    required this.acceptedOfferId,
    required this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.detailCount,
    required this.attachmentCount,
    required this.linkedOffers,
  });

  final String id;
  final String source;
  final String fullName;
  final String? email;
  final String? phone;
  final String? customerId;
  final String? customerWorkflowStage;
  final String? interestedModel;
  final String? region;
  final String stageId;
  final String? message;
  final String? managerName;
  final String? salespersonName;
  final String? nextActionAt;
  final String? acceptedOfferId;
  final String? acceptedAt;
  final String createdAt;
  final String updatedAt;
  final int detailCount;
  final int attachmentCount;
  final List<LeadOfferSummary> linkedOffers;

  factory ManagedLeadSummary.fromJson(
    Map<String, dynamic> json, {
    List<LeadOfferSummary> linkedOffers = const [],
  }) {
    final details = json['details'] as List<dynamic>? ?? const [];
    final attachments = json['attachments'] as List<dynamic>? ?? const [];

    return ManagedLeadSummary(
      id: json['id'] as String? ?? '',
      source: json['source'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      customerId: json['customerId'] as String?,
      customerWorkflowStage: json['customerWorkflowStage'] as String?,
      interestedModel: json['interestedModel'] as String?,
      region: json['region'] as String?,
      stageId: json['stageId'] as String? ?? '',
      message: json['message'] as String?,
      managerName: json['managerName'] as String?,
      salespersonName: json['salespersonName'] as String?,
      nextActionAt: json['nextActionAt'] as String?,
      acceptedOfferId: json['acceptedOfferId'] as String?,
      acceptedAt: json['acceptedAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      detailCount: json['detailCount'] as int? ?? details.length,
      attachmentCount: json['attachmentCount'] as int? ?? attachments.length,
      linkedOffers: linkedOffers,
    );
  }

  ManagedLeadSummary copyWith({
    String? stageId,
    String? updatedAt,
    int? detailCount,
    int? attachmentCount,
    String? salespersonName,
    String? acceptedOfferId,
    String? acceptedAt,
    String? customerWorkflowStage,
    List<LeadOfferSummary>? linkedOffers,
  }) {
    return ManagedLeadSummary(
      id: id,
      source: source,
      fullName: fullName,
      email: email,
      phone: phone,
      customerId: customerId,
      customerWorkflowStage:
          customerWorkflowStage ?? this.customerWorkflowStage,
      interestedModel: interestedModel,
      region: region,
      stageId: stageId ?? this.stageId,
      message: message,
      managerName: managerName,
      salespersonName: salespersonName ?? this.salespersonName,
      nextActionAt: nextActionAt,
      acceptedOfferId: acceptedOfferId ?? this.acceptedOfferId,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      detailCount: detailCount ?? this.detailCount,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      linkedOffers: linkedOffers ?? this.linkedOffers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'customerId': customerId,
      'customerWorkflowStage': customerWorkflowStage,
      'interestedModel': interestedModel,
      'region': region,
      'stageId': stageId,
      'message': message,
      'managerName': managerName,
      'salespersonName': salespersonName,
      'nextActionAt': nextActionAt,
      'acceptedOfferId': acceptedOfferId,
      'acceptedAt': acceptedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'detailCount': detailCount,
      'attachmentCount': attachmentCount,
      'linkedOffers': linkedOffers.map((offer) => offer.toJson()).toList(),
    };
  }
}

class ManagedLeadDetail {
  const ManagedLeadDetail({
    required this.id,
    required this.source,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.customerId,
    required this.customerWorkflowStage,
    required this.interestedModel,
    required this.region,
    required this.stageId,
    required this.message,
    required this.managerName,
    required this.salespersonName,
    required this.nextActionAt,
    required this.acceptedOfferId,
    required this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.details,
    required this.attachments,
    required this.linkedOffers,
  });

  final String id;
  final String source;
  final String fullName;
  final String? email;
  final String? phone;
  final String? customerId;
  final String? customerWorkflowStage;
  final String? interestedModel;
  final String? region;
  final String stageId;
  final String? message;
  final String? managerName;
  final String? salespersonName;
  final String? nextActionAt;
  final String? acceptedOfferId;
  final String? acceptedAt;
  final String createdAt;
  final String updatedAt;
  final List<LeadDetailEntryModel> details;
  final List<LeadAttachmentModel> attachments;
  final List<LeadOfferSummary> linkedOffers;

  factory ManagedLeadDetail.fromJson(
    Map<String, dynamic> json, {
    List<LeadOfferSummary> linkedOffers = const [],
  }) {
    final rawDetails = json['details'] as List<dynamic>? ?? const [];

    return ManagedLeadDetail(
      id: json['id'] as String? ?? '',
      source: json['source'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      customerId: json['customerId'] as String?,
      customerWorkflowStage: json['customerWorkflowStage'] as String?,
      interestedModel: json['interestedModel'] as String?,
      region: json['region'] as String?,
      stageId: json['stageId'] as String? ?? '',
      message: json['message'] as String?,
      managerName: json['managerName'] as String?,
      salespersonName: json['salespersonName'] as String?,
      nextActionAt: json['nextActionAt'] as String?,
      acceptedOfferId: json['acceptedOfferId'] as String?,
      acceptedAt: json['acceptedAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      details: rawDetails
          .whereType<Map<String, dynamic>>()
          .map(LeadDetailEntryModel.fromJson)
          .toList(),
      attachments: (json['attachments'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LeadAttachmentModel.fromJson)
          .toList(),
      linkedOffers: linkedOffers,
    );
  }

  ManagedLeadDetail copyWith({
    String? id,
    String? source,
    String? fullName,
    String? email,
    String? phone,
    String? customerId,
    String? customerWorkflowStage,
    String? interestedModel,
    String? region,
    String? stageId,
    String? message,
    String? managerName,
    String? salespersonName,
    String? nextActionAt,
    String? acceptedOfferId,
    String? acceptedAt,
    bool clearAcceptedOfferId = false,
    bool clearAcceptedAt = false,
    String? createdAt,
    String? updatedAt,
    List<LeadDetailEntryModel>? details,
    List<LeadAttachmentModel>? attachments,
    List<LeadOfferSummary>? linkedOffers,
  }) {
    return ManagedLeadDetail(
      id: id ?? this.id,
      source: source ?? this.source,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      customerId: customerId ?? this.customerId,
      customerWorkflowStage:
          customerWorkflowStage ?? this.customerWorkflowStage,
      interestedModel: interestedModel ?? this.interestedModel,
      region: region ?? this.region,
      stageId: stageId ?? this.stageId,
      message: message ?? this.message,
      managerName: managerName ?? this.managerName,
      salespersonName: salespersonName ?? this.salespersonName,
      nextActionAt: nextActionAt ?? this.nextActionAt,
      acceptedOfferId:
          clearAcceptedOfferId ? null : acceptedOfferId ?? this.acceptedOfferId,
      acceptedAt: clearAcceptedAt ? null : acceptedAt ?? this.acceptedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      details: details ?? this.details,
      attachments: attachments ?? this.attachments,
      linkedOffers: linkedOffers ?? this.linkedOffers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'customerId': customerId,
      'customerWorkflowStage': customerWorkflowStage,
      'interestedModel': interestedModel,
      'region': region,
      'stageId': stageId,
      'message': message,
      'managerName': managerName,
      'salespersonName': salespersonName,
      'nextActionAt': nextActionAt,
      'acceptedOfferId': acceptedOfferId,
      'acceptedAt': acceptedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'details': details.map((entry) => entry.toJson()).toList(),
      'attachments': attachments.map((entry) => entry.toJson()).toList(),
      'linkedOffers': linkedOffers.map((offer) => offer.toJson()).toList(),
    };
  }
}

class LeadsOverview {
  const LeadsOverview({
    required this.leads,
    required this.stages,
    required this.salespeople,
    required this.customerWorkflowStages,
  });

  final List<ManagedLeadSummary> leads;
  final List<LeadStageInfo> stages;
  final List<SalespersonOption> salespeople;
  final List<CustomerWorkflowStageInfo> customerWorkflowStages;

  factory LeadsOverview.fromJson(Map<String, dynamic> json) {
    final rawLeads = json['leads'] as List<dynamic>? ?? const [];
    final rawStages = json['stages'] as List<dynamic>? ?? const [];
    final rawSalespeople = json['salespeople'] as List<dynamic>? ?? const [];
    final rawCustomerWorkflowStages =
        json['customerWorkflowStages'] as List<dynamic>? ?? const [];

    return LeadsOverview(
      leads: rawLeads
          .whereType<Map<String, dynamic>>()
          .map(
            (entry) => ManagedLeadSummary.fromJson(
              entry,
              linkedOffers:
                  (entry['linkedOffers'] as List<dynamic>? ?? const [])
                      .whereType<Map<String, dynamic>>()
                      .map(LeadOfferSummary.fromJson)
                      .toList(),
            ),
          )
          .toList(),
      stages: rawStages
          .whereType<Map<String, dynamic>>()
          .map(LeadStageInfo.fromJson)
          .toList(),
      salespeople: rawSalespeople
          .whereType<Map<String, dynamic>>()
          .map(SalespersonOption.fromJson)
          .toList(),
      customerWorkflowStages: rawCustomerWorkflowStages
          .whereType<Map<String, dynamic>>()
          .map(CustomerWorkflowStageInfo.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leads': leads.map((lead) => lead.toJson()).toList(),
      'stages': stages.map((stage) => stage.toJson()).toList(),
      'salespeople':
          salespeople.map((salesperson) => salesperson.toJson()).toList(),
      'customerWorkflowStages':
          customerWorkflowStages.map((stage) => stage.toJson()).toList(),
    };
  }
}

class LeadDetailPayload {
  const LeadDetailPayload({
    required this.lead,
    required this.stages,
    required this.salespeople,
    required this.customerWorkflowStages,
  });

  final ManagedLeadDetail lead;
  final List<LeadStageInfo> stages;
  final List<SalespersonOption> salespeople;
  final List<CustomerWorkflowStageInfo> customerWorkflowStages;

  factory LeadDetailPayload.fromJson(Map<String, dynamic> json) {
    return LeadDetailPayload(
      lead: ManagedLeadDetail.fromJson(
        json['lead'] as Map<String, dynamic>? ?? const {},
        linkedOffers: (json['linkedOffers'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(LeadOfferSummary.fromJson)
            .toList(),
      ),
      stages: (json['stages'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LeadStageInfo.fromJson)
          .toList(),
      salespeople: (json['salespeople'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SalespersonOption.fromJson)
          .toList(),
      customerWorkflowStages:
          (json['customerWorkflowStages'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(CustomerWorkflowStageInfo.fromJson)
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lead': lead.toJson(),
      'linkedOffers': lead.linkedOffers.map((offer) => offer.toJson()).toList(),
      'stages': stages.map((stage) => stage.toJson()).toList(),
      'salespeople':
          salespeople.map((salesperson) => salesperson.toJson()).toList(),
      'customerWorkflowStages':
          customerWorkflowStages.map((stage) => stage.toJson()).toList(),
    };
  }
}
