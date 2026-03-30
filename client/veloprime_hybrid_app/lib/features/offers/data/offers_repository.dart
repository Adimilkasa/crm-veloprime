import '../../../core/network/api_client.dart';
import '../models/offer_detail.dart';
import '../models/offer_document.dart';
import '../models/offer_finalization.dart';
import '../models/offer_pdf_version.dart';

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
        'DATA': 'v1',
        'ASSETS': 'v1',
        'APPLICATION': 'v5',
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