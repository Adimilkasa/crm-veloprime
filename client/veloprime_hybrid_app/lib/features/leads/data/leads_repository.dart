import '../../../core/network/api_client.dart';
import '../models/lead_models.dart';

class LeadsRepository {
  LeadsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<LeadsOverview> fetchLeads() async {
    final json = await _apiClient.getJson('/api/client/leads');
    final stages = (json['stages'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LeadStageInfo.fromJson)
        .toList()
      ..sort((left, right) => left.order.compareTo(right.order));
    final salespeople = (json['salespeople'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SalespersonOption.fromJson)
        .toList();

    final offersByLeadId = (json['leadOffersByLeadId'] as Map<String, dynamic>? ?? const {})
        .map(
          (leadId, value) => MapEntry(
            leadId,
            (value as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(LeadOfferSummary.fromJson)
                .toList(),
          ),
        );

    final leads = (json['leads'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (entry) => ManagedLeadSummary.fromJson(
            entry,
            linkedOffers: offersByLeadId[entry['id'] as String? ?? ''] ?? const [],
          ),
        )
        .toList();

    return LeadsOverview(
      leads: leads,
      stages: stages,
      salespeople: salespeople,
    );
  }

  Future<LeadDetailPayload> createLead(Map<String, dynamic> payload) async {
    final json = await _apiClient.postJson('/api/client/leads', payload);
    final lead = json['lead'] as Map<String, dynamic>? ?? const {};
    final leadId = lead['id'] as String? ?? '';

    if (leadId.isEmpty) {
      throw Exception('Nie udalo sie odczytac identyfikatora nowego leada.');
    }

    return fetchLeadDetail(leadId);
  }

  Future<LeadDetailPayload> fetchLeadDetail(String leadId) async {
    final json = await _apiClient.getJson('/api/client/leads/$leadId');
    final stages = (json['stages'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LeadStageInfo.fromJson)
        .toList()
      ..sort((left, right) => left.order.compareTo(right.order));

    final linkedOffers = (json['linkedOffers'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LeadOfferSummary.fromJson)
        .toList();
    final salespeople = (json['salespeople'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SalespersonOption.fromJson)
        .toList();

    final lead = ManagedLeadDetail.fromJson(
      json['lead'] as Map<String, dynamic>? ?? const {},
      linkedOffers: linkedOffers,
    );

    return LeadDetailPayload(
      lead: lead,
      stages: stages,
      salespeople: salespeople,
    );
  }

  Future<LeadDetailPayload> moveLeadToStage({
    required String leadId,
    required String stageId,
  }) async {
    await _apiClient.patchJson('/api/client/leads/$leadId/stage', {
      'stageId': stageId,
    });

    return fetchLeadDetail(leadId);
  }

  Future<LeadDetailPayload> assignSalesperson({
    required String leadId,
    required String salespersonId,
  }) async {
    await _apiClient.patchJson('/api/client/leads/$leadId/salesperson', {
      'salespersonId': salespersonId,
    });

    return fetchLeadDetail(leadId);
  }

  Future<LeadDetailPayload> addDetailEntry({
    required String leadId,
    required String kind,
    String? label,
    required String value,
  }) async {
    final json = await _apiClient.postJson('/api/client/leads/$leadId/details', {
      'kind': kind,
      'label': label,
      'value': value,
    });

    final entry = LeadDetailEntryModel.fromJson(
      json['entry'] as Map<String, dynamic>? ?? const {},
    );

    if (entry.id.isEmpty) {
      throw Exception('Nie udalo sie zapisac wpisu historii leada.');
    }

    return fetchLeadDetail(leadId);
  }

  Future<void> createStage({
    required String name,
    required String color,
    required String kind,
    String? afterStageId,
  }) async {
    await _apiClient.postJson('/api/client/leads/stages', {
      'name': name,
      'color': color,
      'kind': kind,
      'afterStageId': afterStageId ?? '',
    });
  }

  Future<void> deleteStage({
    required String stageId,
    String? fallbackStageId,
  }) async {
    await _apiClient.deleteJson('/api/client/leads/stages/$stageId', {
      'fallbackStageId': fallbackStageId ?? '',
    });
  }
}