import '../../update/models/update_models.dart';

class OfferFinalizationApproval {
  const OfferFinalizationApproval({
    required this.approvalId,
    required this.approvedAt,
    required this.offerId,
    required this.offerNumber,
    required this.title,
    required this.totalGross,
    required this.totalNet,
    required this.customerName,
  });

  final String approvalId;
  final String approvedAt;
  final String offerId;
  final String offerNumber;
  final String title;
  final num? totalGross;
  final num? totalNet;
  final String customerName;

  factory OfferFinalizationApproval.fromJson(Map<String, dynamic> json) {
    return OfferFinalizationApproval(
      approvalId: json['approvalId'] as String? ?? '',
      approvedAt: json['approvedAt'] as String? ?? '',
      offerId: json['offerId'] as String? ?? '',
      offerNumber: json['offerNumber'] as String? ?? '',
      title: json['title'] as String? ?? '',
      totalGross: json['totalGross'] as num?,
      totalNet: json['totalNet'] as num?,
      customerName: json['customerName'] as String? ?? '',
    );
  }
}

class OfferFinalizationSuccess {
  const OfferFinalizationSuccess({
    required this.approval,
    required this.comparison,
  });

  final OfferFinalizationApproval approval;
  final List<VersionComparisonItem> comparison;

  factory OfferFinalizationSuccess.fromJson(Map<String, dynamic> json) {
    final rawComparison = json['comparison'] as List<dynamic>? ?? const [];

    return OfferFinalizationSuccess(
      approval: OfferFinalizationApproval.fromJson(json['approval'] as Map<String, dynamic>? ?? const {}),
      comparison: rawComparison
          .whereType<Map<String, dynamic>>()
          .map(VersionComparisonItem.fromJson)
          .toList(),
    );
  }
}

class OfferFinalizationFailure {
  const OfferFinalizationFailure({
    required this.message,
    required this.code,
    required this.statusCode,
    required this.comparison,
  });

  final String message;
  final String? code;
  final int statusCode;
  final List<VersionComparisonItem> comparison;

  factory OfferFinalizationFailure.fromJson(Map<String, dynamic> json, {required int statusCode}) {
    final rawComparison = json['comparison'] as List<dynamic>? ?? const [];

    return OfferFinalizationFailure(
      message: json['error'] as String? ?? 'Operacja nie powiodla sie.',
      code: json['code'] as String?,
      statusCode: statusCode,
      comparison: rawComparison
          .whereType<Map<String, dynamic>>()
          .map(VersionComparisonItem.fromJson)
          .toList(),
    );
  }
}

class OfferFinalizationResult {
  const OfferFinalizationResult._({
    required this.success,
    this.approval,
    this.failure,
  });

  final bool success;
  final OfferFinalizationSuccess? approval;
  final OfferFinalizationFailure? failure;

  factory OfferFinalizationResult.success(OfferFinalizationSuccess approval) {
    return OfferFinalizationResult._(
      success: true,
      approval: approval,
    );
  }

  factory OfferFinalizationResult.failure(OfferFinalizationFailure failure) {
    return OfferFinalizationResult._(
      success: false,
      failure: failure,
    );
  }
}