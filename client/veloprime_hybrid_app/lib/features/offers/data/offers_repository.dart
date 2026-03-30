import '../../../core/network/api_client.dart';
import '../../../core/config/client_artifact_versions.dart';
import '../models/offer_detail.dart';
import '../models/offer_document.dart';
import '../models/offer_finalization.dart';
import '../models/offer_pdf_version.dart';

class OfferShareLinkResult {
  const OfferShareLinkResult({
    required this.url,
    required this.expiresAt,
    required this.versionId,
    required this.token,
  });

  final String url;
  final String? expiresAt;
  final String versionId;
  final String token;

  factory OfferShareLinkResult.fromJson(Map<String, dynamic> json) {
    return OfferShareLinkResult(
      url: json['url'] as String? ?? '',
      expiresAt: json['expiresAt'] as String?,
      versionId: json['versionId'] as String? ?? '',
      token: json['token'] as String? ?? '',
    );
  }
}

class OfferEmailSendResult {
  const OfferEmailSendResult({
    required this.to,
    required this.publicUrl,
    required this.expiresAt,
    required this.versionId,
  });

  final String to;
  final String publicUrl;
  final String? expiresAt;
  final String versionId;

  factory OfferEmailSendResult.fromJson(Map<String, dynamic> json) {
    return OfferEmailSendResult(
      to: json['to'] as String? ?? '',
      publicUrl: json['publicUrl'] as String? ?? '',
      expiresAt: json['expiresAt'] as String?,
      versionId: json['versionId'] as String? ?? '',
    );
  }
}

class OffersRepository {
  OffersRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<OfferDetail> fetchOfferDetail(String offerId) async {
    final json = await _apiClient.getJson('/api/client/offers/$offerId');
    return OfferDetail.fromJson(json['offer'] as Map<String, dynamic>? ?? const {});
  }

  Future<OfferFinalizationResult> validateFinalization({
    required String offerId,
  }) async {
    const payload = {
      'offerId': null,
      'versions': {
        'DATA': ClientArtifactVersions.data,
        'ASSETS': ClientArtifactVersions.assets,
        'APPLICATION': ClientArtifactVersions.application,
      },
    };

    try {
      final json = await _apiClient.postJson('/api/offers/validate-finalization', {
        ...payload,
        'offerId': offerId,
      });
      return OfferFinalizationResult.success(OfferFinalizationSuccess.fromJson(json));
    } on ApiException catch (error) {
      return OfferFinalizationResult.failure(
        OfferFinalizationFailure.fromJson(
          error.payload,
          statusCode: error.statusCode,
        ),
      );
    }
  }

  Future<OfferPdfVersionResult> createPdfVersion({
    required String offerId,
  }) async {
    final json = await _apiClient.postJson('/api/client/offers/$offerId/pdf-version', const {});
    return OfferPdfVersionResult.fromJson(json['version'] as Map<String, dynamic>? ?? const {});
  }

  Future<OfferDocumentSnapshot> fetchDocumentSnapshot({
    required String offerId,
    String? versionId,
  }) async {
    final suffix = versionId != null && versionId.isNotEmpty ? '?versionId=$versionId' : '';
    final json = await _apiClient.getJson('/api/client/offers/$offerId/document$suffix');
    return OfferDocumentSnapshot.fromJson(json['document'] as Map<String, dynamic>? ?? const {});
  }

  Future<OfferShareLinkResult> createShareLink({
    required String offerId,
    String? versionId,
  }) async {
    final json = await _apiClient.postJson('/api/client/offers/$offerId/share', {
      'versionId': versionId,
    });
    return OfferShareLinkResult.fromJson(json['share'] as Map<String, dynamic>? ?? const {});
  }

  Future<OfferEmailSendResult> sendOfferEmail({
    required String offerId,
    String? versionId,
    String? toEmail,
  }) async {
    final json = await _apiClient.postJson('/api/client/offers/$offerId/send-email', {
      'versionId': versionId,
      'toEmail': toEmail,
    });
    return OfferEmailSendResult.fromJson(json['email'] as Map<String, dynamic>? ?? const {});
  }

  Future<OfferDetail> updateOffer({
    required String offerId,
    required Map<String, dynamic> payload,
  }) async {
    final json = await _apiClient.patchJson('/api/client/offers/$offerId', payload);
    return OfferDetail.fromJson(json['offer'] as Map<String, dynamic>? ?? const {});
  }

  Future<OfferDetail> createOffer(Map<String, dynamic> payload) async {
    final json = await _apiClient.postJson('/api/client/offers', payload);
    return OfferDetail.fromJson(json['offer'] as Map<String, dynamic>? ?? const {});
  }

  Future<OfferDetail> assignLead({
    required String offerId,
    required String leadId,
  }) async {
    final json = await _apiClient.postJson('/api/client/offers/$offerId/lead', {
      'leadId': leadId,
    });
    return OfferDetail.fromJson(json['offer'] as Map<String, dynamic>? ?? const {});
  }

  Future<OfferDetail> createLeadForOffer({
    required String offerId,
    required String fullName,
    String? email,
    String? phone,
    String? region,
  }) async {
    final json = await _apiClient.postJson('/api/client/offers/$offerId/lead', {
      'fullName': fullName,
      'email': email ?? '',
      'phone': phone ?? '',
      'region': region ?? '',
    });
    return OfferDetail.fromJson(json['offer'] as Map<String, dynamic>? ?? const {});
  }
}