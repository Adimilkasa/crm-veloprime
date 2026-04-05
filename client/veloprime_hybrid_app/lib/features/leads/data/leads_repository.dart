import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'leads_local_store.dart';
import '../models/lead_models.dart';

enum LeadSyncPhase { synchronized, syncing, pending, error }

class LeadSyncSnapshot {
  const LeadSyncSnapshot({
    required this.pendingChanges,
    required this.isSyncing,
    required this.lastSuccessfulSyncAt,
    required this.lastError,
  });

  const LeadSyncSnapshot.initial()
      : pendingChanges = 0,
        isSyncing = false,
        lastSuccessfulSyncAt = null,
        lastError = null;

  final int pendingChanges;
  final bool isSyncing;
  final DateTime? lastSuccessfulSyncAt;
  final String? lastError;

  LeadSyncPhase get phase {
    if (isSyncing) {
      return LeadSyncPhase.syncing;
    }
    if ((lastError ?? '').isNotEmpty) {
      return LeadSyncPhase.error;
    }
    if (pendingChanges > 0) {
      return LeadSyncPhase.pending;
    }
    return LeadSyncPhase.synchronized;
  }

  LeadSyncSnapshot copyWith({
    int? pendingChanges,
    bool? isSyncing,
    DateTime? lastSuccessfulSyncAt,
    bool clearLastSuccessfulSyncAt = false,
    String? lastError,
    bool clearLastError = false,
  }) {
    return LeadSyncSnapshot(
      pendingChanges: pendingChanges ?? this.pendingChanges,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSuccessfulSyncAt: clearLastSuccessfulSyncAt
          ? null
          : lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      lastError: clearLastError ? null : lastError ?? this.lastError,
    );
  }
}

class LeadsRepository {
  LeadsRepository(this._apiClient, {LeadsLocalStore? localStore})
      : _localStore = localStore ?? LeadsLocalStore() {
    unawaited(_restoreSyncSnapshot());
  }

  final ApiClient _apiClient;
  final LeadsLocalStore _localStore;
  final ValueNotifier<LeadSyncSnapshot> syncSnapshot =
      ValueNotifier<LeadSyncSnapshot>(const LeadSyncSnapshot.initial());
  Future<List<PendingLeadMutation>>? _activeFlushOperation;
  LeadsOverview? _cachedOverview;

  Future<LeadsOverview?> readCachedLeads() async {
    final cachedOverview = _cachedOverview;
    if (cachedOverview != null) {
      return cachedOverview;
    }

    final overview = await _localStore.readOverview();
    _cachedOverview = overview;
    return overview;
  }

  Future<LeadDetailPayload?> readCachedLeadDetail(String leadId) {
    return _localStore.readDetail(leadId);
  }

  Future<bool> synchronizeNow() async {
    final remaining = await _flushPendingMutations();
    return remaining.isEmpty;
  }

  Future<LeadsOverview> fetchLeads() async {
    try {
      final pendingMutations = await _localStore.readPendingMutations();
      final overview = await _fetchLeadsFromNetwork();
      final merged =
          _applyPendingMutationsToOverview(overview, pendingMutations);
      await _storeOverview(merged);
      return merged;
    } catch (_) {
      final cached = await readCachedLeads();
      if (cached != null) {
        return cached;
      }

      rethrow;
    }
  }

  Future<LeadDetailPayload> createLead(Map<String, dynamic> payload) async {
    final json = await _apiClient.postJson('/api/client/leads', payload);
    final lead = json['lead'] as Map<String, dynamic>? ?? const {};
    final leadId = lead['id'] as String? ?? '';

    if (leadId.isEmpty) {
      throw Exception('Nie udalo sie odczytac identyfikatora nowego leada.');
    }

    final detail = await _fetchLeadDetailFromNetwork(leadId);
    await _saveLeadPayload(detail);
    return detail;
  }

  Future<LeadDetailPayload> fetchLeadDetail(String leadId) async {
    try {
      final pendingMutations = await _localStore.readPendingMutations();
      final detail = await _fetchLeadDetailFromNetwork(leadId);
      final merged = _applyPendingMutationsToDetail(detail, pendingMutations);
      await _saveLeadPayload(merged);
      return merged;
    } catch (_) {
      final cached = await _localStore.readDetail(leadId);
      if (cached != null) {
        return cached;
      }

      rethrow;
    }
  }

  Future<LeadDetailPayload> moveLeadToStage({
    required String leadId,
    required String stageId,
    String? acceptedOfferId,
  }) async {
    final current = await _ensureLeadPayload(leadId);
    final now = DateTime.now().toIso8601String();
    final targetStage =
        current.stages.where((stage) => stage.id == stageId).firstOrNull;
    final updated = LeadDetailPayload(
      lead: current.lead.copyWith(
        stageId: stageId,
        acceptedOfferId: acceptedOfferId,
        acceptedAt: acceptedOfferId == null ? null : now,
        customerWorkflowStage: targetStage?.kind == 'WON'
            ? (current.lead.customerWorkflowStage ?? 'CUSTOMER_STAGE_1')
            : null,
        clearAcceptedOfferId: acceptedOfferId == null,
        clearAcceptedAt: acceptedOfferId == null,
        updatedAt: now,
      ),
      stages: current.stages,
      salespeople: current.salespeople,
      customerWorkflowStages: current.customerWorkflowStages,
    );

    await _saveLeadPayload(updated);
    await _enqueueMutation(
      PendingLeadMutation(
        id: 'lead-stage-$leadId-${DateTime.now().microsecondsSinceEpoch}',
        type: 'moveStage',
        leadId: leadId,
        payload: {
          'stageId': stageId,
          'acceptedOfferId': acceptedOfferId,
        },
        createdAt: now,
      ),
    );
    unawaited(_flushPendingMutations());

    return updated;
  }

  Future<LeadDetailPayload> uploadAttachment({
    required String leadId,
    required String filePath,
    required String fileName,
  }) async {
    await _apiClient.postMultipart(
      '/api/client/leads/$leadId/attachments',
      fields: {'fileName': fileName},
      fileField: 'file',
      filePath: filePath,
      fileName: fileName,
    );

    final refreshed = await _fetchLeadDetailFromNetwork(leadId);
    await _saveLeadPayload(refreshed);
    return refreshed;
  }

  Future<LeadDetailPayload> updateCustomerWorkflowStage({
    required String leadId,
    required String customerWorkflowStage,
  }) async {
    final current = await _ensureLeadPayload(leadId);
    final now = DateTime.now().toIso8601String();
    final updated = LeadDetailPayload(
      lead: current.lead.copyWith(
        customerWorkflowStage: customerWorkflowStage,
        updatedAt: now,
      ),
      stages: current.stages,
      salespeople: current.salespeople,
      customerWorkflowStages: current.customerWorkflowStages,
    );

    await _saveLeadPayload(updated);
    await _enqueueMutation(
      PendingLeadMutation(
        id: 'lead-customer-stage-$leadId-${DateTime.now().microsecondsSinceEpoch}',
        type: 'setCustomerWorkflowStage',
        leadId: leadId,
        payload: {
          'customerWorkflowStage': customerWorkflowStage,
        },
        createdAt: now,
      ),
    );
    unawaited(_flushPendingMutations());

    return updated;
  }

  Future<LeadsOverview> updateCustomerWorkflowStageLabel({
    required String stageKey,
    required String label,
  }) async {
    final overview = await readCachedLeads() ?? await fetchLeads();
    final previousOverview = overview;
    final nextOverview = LeadsOverview(
      leads: overview.leads,
      stages: overview.stages,
      salespeople: overview.salespeople,
      customerWorkflowStages: overview.customerWorkflowStages
          .map(
            (stage) =>
                stage.key == stageKey ? stage.copyWith(label: label) : stage,
          )
          .toList(),
    );

    await _storeOverview(nextOverview);

    try {
      await _apiClient.patchJson(
        '/api/client/leads/customer-workflow-stages/$stageKey',
        {'label': label},
      );
      return nextOverview;
    } catch (_) {
      await _storeOverview(previousOverview);
      rethrow;
    }
  }

  Future<LeadDetailPayload> assignSalesperson({
    required String leadId,
    required String salespersonId,
  }) async {
    final current = await _ensureLeadPayload(leadId);
    final now = DateTime.now().toIso8601String();
    final salesperson = current.salespeople
        .where((entry) => entry.id == salespersonId)
        .firstOrNull;
    final updated = LeadDetailPayload(
      lead: current.lead.copyWith(
        salespersonName: salesperson?.fullName,
        updatedAt: now,
      ),
      stages: current.stages,
      salespeople: current.salespeople,
      customerWorkflowStages: current.customerWorkflowStages,
    );

    await _saveLeadPayload(updated);
    await _enqueueMutation(
      PendingLeadMutation(
        id: 'lead-salesperson-$leadId-${DateTime.now().microsecondsSinceEpoch}',
        type: 'assignSalesperson',
        leadId: leadId,
        payload: {
          'salespersonId': salespersonId,
          'salespersonName': salesperson?.fullName,
        },
        createdAt: now,
      ),
    );
    unawaited(_flushPendingMutations());

    return updated;
  }

  Future<LeadDetailPayload> addDetailEntry({
    required String leadId,
    required String kind,
    String? label,
    required String value,
  }) async {
    final current = await _ensureLeadPayload(leadId);
    final now = DateTime.now().toIso8601String();
    final entry = LeadDetailEntryModel(
      id: 'local-entry-${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      label: label ?? '',
      value: value,
      authorName: null,
      createdAt: now,
    );
    final updated = LeadDetailPayload(
      lead: current.lead.copyWith(
        updatedAt: now,
        details: [entry, ...current.lead.details],
      ),
      stages: current.stages,
      salespeople: current.salespeople,
      customerWorkflowStages: current.customerWorkflowStages,
    );

    await _saveLeadPayload(updated);
    await _enqueueMutation(
      PendingLeadMutation(
        id: 'lead-detail-$leadId-${DateTime.now().microsecondsSinceEpoch}',
        type: 'addDetailEntry',
        leadId: leadId,
        payload: {
          'kind': kind,
          'label': label,
          'value': value,
          'entry': entry.toJson(),
        },
        createdAt: now,
      ),
    );
    unawaited(_flushPendingMutations());

    return updated;
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

  Future<LeadsOverview> _fetchLeadsFromNetwork() async {
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

    final offersByLeadId =
        (json['leadOffersByLeadId'] as Map<String, dynamic>? ?? const {}).map(
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
            linkedOffers:
                offersByLeadId[entry['id'] as String? ?? ''] ?? const [],
          ),
        )
        .toList();

    return LeadsOverview(
      leads: leads,
      stages: stages,
      salespeople: salespeople,
      customerWorkflowStages:
          (json['customerWorkflowStages'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(CustomerWorkflowStageInfo.fromJson)
              .toList(),
    );
  }

  Future<LeadDetailPayload> _fetchLeadDetailFromNetwork(String leadId) async {
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
      customerWorkflowStages:
          (json['customerWorkflowStages'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(CustomerWorkflowStageInfo.fromJson)
              .toList(),
    );
  }

  Future<LeadDetailPayload> _ensureLeadPayload(String leadId) async {
    final cached = await _localStore.readDetail(leadId);
    if (cached != null) {
      return cached;
    }

    final networkPayload = await _fetchLeadDetailFromNetwork(leadId);
    await _saveLeadPayload(networkPayload);
    return networkPayload;
  }

  Future<void> _saveLeadPayload(LeadDetailPayload payload) async {
    await _localStore.writeDetail(payload);

    final cachedOverview = _cachedOverview;
    if (cachedOverview == null) {
      return;
    }

    final nextSummary = _mapDetailToSummary(payload.lead);
    final existingIndex =
        cachedOverview.leads.indexWhere((lead) => lead.id == nextSummary.id);
    final nextLeads = [...cachedOverview.leads];

    if (existingIndex >= 0) {
      nextLeads[existingIndex] = nextSummary;
    } else {
      nextLeads.insert(0, nextSummary);
    }

    await _storeOverview(
      LeadsOverview(
        leads: nextLeads,
        stages: payload.stages,
        salespeople: payload.salespeople,
        customerWorkflowStages: payload.customerWorkflowStages,
      ),
    );
  }

  Future<void> _storeOverview(LeadsOverview overview) async {
    _cachedOverview = overview;
    await _localStore.writeOverview(overview);
  }

  ManagedLeadSummary _mapDetailToSummary(ManagedLeadDetail lead) {
    return ManagedLeadSummary(
      id: lead.id,
      source: lead.source,
      fullName: lead.fullName,
      email: lead.email,
      phone: lead.phone,
      customerId: lead.customerId,
      customerWorkflowStage: lead.customerWorkflowStage,
      interestedModel: lead.interestedModel,
      region: lead.region,
      stageId: lead.stageId,
      message: lead.message,
      managerName: lead.managerName,
      salespersonName: lead.salespersonName,
      nextActionAt: lead.nextActionAt,
      acceptedOfferId: lead.acceptedOfferId,
      acceptedAt: lead.acceptedAt,
      createdAt: lead.createdAt,
      updatedAt: lead.updatedAt,
      detailCount: lead.details.length,
      attachmentCount: lead.attachments.length,
      linkedOffers: lead.linkedOffers,
    );
  }

  LeadsOverview _applyPendingMutationsToOverview(
    LeadsOverview overview,
    List<PendingLeadMutation> mutations,
  ) {
    final leads = [...overview.leads];

    for (final mutation in mutations) {
      final index = leads.indexWhere((lead) => lead.id == mutation.leadId);
      if (index < 0) {
        continue;
      }

      final lead = leads[index];
      switch (mutation.type) {
        case 'moveStage':
          final acceptedOfferId =
              mutation.payload['acceptedOfferId'] as String?;
          final targetStage = overview.stages
              .where((stage) =>
                  stage.id == (mutation.payload['stageId'] as String? ?? ''))
              .firstOrNull;
          leads[index] = lead.copyWith(
            stageId: mutation.payload['stageId'] as String? ?? lead.stageId,
            acceptedOfferId: acceptedOfferId,
            acceptedAt: acceptedOfferId == null ? null : mutation.createdAt,
            customerWorkflowStage: targetStage?.kind == 'WON'
                ? (lead.customerWorkflowStage ?? 'CUSTOMER_STAGE_1')
                : null,
            updatedAt: mutation.createdAt,
          );
          break;
        case 'assignSalesperson':
          leads[index] = lead.copyWith(
            salespersonName: mutation.payload['salespersonName'] as String?,
            updatedAt: mutation.createdAt,
          );
          break;
        case 'addDetailEntry':
          leads[index] = lead.copyWith(
            detailCount: lead.detailCount + 1,
            updatedAt: mutation.createdAt,
          );
          break;
        case 'setCustomerWorkflowStage':
          leads[index] = lead.copyWith(
            customerWorkflowStage:
                mutation.payload['customerWorkflowStage'] as String?,
            updatedAt: mutation.createdAt,
          );
          break;
      }
    }

    return LeadsOverview(
      leads: leads,
      stages: overview.stages,
      salespeople: overview.salespeople,
      customerWorkflowStages: overview.customerWorkflowStages,
    );
  }

  LeadDetailPayload _applyPendingMutationsToDetail(
    LeadDetailPayload payload,
    List<PendingLeadMutation> mutations,
  ) {
    var lead = payload.lead;

    for (final mutation
        in mutations.where((entry) => entry.leadId == lead.id)) {
      switch (mutation.type) {
        case 'moveStage':
          final acceptedOfferId =
              mutation.payload['acceptedOfferId'] as String?;
          final targetStage = payload.stages
              .where((stage) =>
                  stage.id == (mutation.payload['stageId'] as String? ?? ''))
              .firstOrNull;
          lead = lead.copyWith(
            stageId: mutation.payload['stageId'] as String? ?? lead.stageId,
            acceptedOfferId: acceptedOfferId,
            acceptedAt: acceptedOfferId == null ? null : mutation.createdAt,
            customerWorkflowStage: targetStage?.kind == 'WON'
                ? (lead.customerWorkflowStage ?? 'CUSTOMER_STAGE_1')
                : null,
            clearAcceptedOfferId: acceptedOfferId == null,
            clearAcceptedAt: acceptedOfferId == null,
            updatedAt: mutation.createdAt,
          );
          break;
        case 'assignSalesperson':
          lead = lead.copyWith(
            salespersonName: mutation.payload['salespersonName'] as String?,
            updatedAt: mutation.createdAt,
          );
          break;
        case 'addDetailEntry':
          final entryJson = mutation.payload['entry'];
          final entry = entryJson is Map<String, dynamic>
              ? LeadDetailEntryModel.fromJson(entryJson)
              : entryJson is Map
                  ? LeadDetailEntryModel.fromJson(
                      entryJson
                          .map((key, value) => MapEntry(key.toString(), value)),
                    )
                  : null;
          if (entry != null &&
              !lead.details.any((detail) => detail.id == entry.id)) {
            lead = lead.copyWith(
              updatedAt: mutation.createdAt,
              details: [entry, ...lead.details],
            );
          }
          break;
        case 'setCustomerWorkflowStage':
          lead = lead.copyWith(
            customerWorkflowStage:
                mutation.payload['customerWorkflowStage'] as String?,
            updatedAt: mutation.createdAt,
          );
          break;
      }
    }

    return LeadDetailPayload(
      lead: lead,
      stages: payload.stages,
      salespeople: payload.salespeople,
      customerWorkflowStages: payload.customerWorkflowStages,
    );
  }

  Future<void> _enqueueMutation(PendingLeadMutation mutation) async {
    final pending = [...await _localStore.readPendingMutations()];
    if (mutation.type == 'moveStage' || mutation.type == 'assignSalesperson') {
      pending.removeWhere(
        (entry) =>
            entry.type == mutation.type && entry.leadId == mutation.leadId,
      );
    }

    if (mutation.type == 'setCustomerWorkflowStage') {
      pending.removeWhere(
        (entry) =>
            entry.type == mutation.type && entry.leadId == mutation.leadId,
      );
    }

    pending.add(mutation);
    await _localStore.writePendingMutations(pending);
    _setSyncSnapshot(
      syncSnapshot.value.copyWith(
        pendingChanges: pending.length,
        clearLastError: true,
      ),
    );
  }

  Future<List<PendingLeadMutation>> _flushPendingMutations() async {
    final activeOperation = _activeFlushOperation;
    if (activeOperation != null) {
      return activeOperation;
    }

    final operation = _flushPendingMutationsInternal();
    _activeFlushOperation = operation;

    try {
      return await operation;
    } finally {
      if (identical(_activeFlushOperation, operation)) {
        _activeFlushOperation = null;
      }
    }
  }

  Future<List<PendingLeadMutation>> _flushPendingMutationsInternal() async {
    final pending = await _localStore.readPendingMutations();
    _setSyncSnapshot(
      syncSnapshot.value.copyWith(
        pendingChanges: pending.length,
        isSyncing: pending.isNotEmpty,
        clearLastError: pending.isNotEmpty,
      ),
    );

    if (pending.isEmpty) {
      _setSyncSnapshot(
        syncSnapshot.value.copyWith(
          pendingChanges: 0,
          isSyncing: false,
          clearLastError: true,
        ),
      );
      return const [];
    }

    final remaining = <PendingLeadMutation>[];
    var stopProcessing = false;
    String? lastError;

    for (final mutation in pending) {
      if (stopProcessing) {
        remaining.add(mutation);
        continue;
      }

      try {
        switch (mutation.type) {
          case 'moveStage':
            await _apiClient
                .patchJson('/api/client/leads/${mutation.leadId}/stage', {
              'stageId': mutation.payload['stageId'] ?? '',
              'acceptedOfferId': mutation.payload['acceptedOfferId'],
            });
            break;
          case 'assignSalesperson':
            await _apiClient
                .patchJson('/api/client/leads/${mutation.leadId}/salesperson', {
              'salespersonId': mutation.payload['salespersonId'] ?? '',
            });
            break;
          case 'addDetailEntry':
            await _apiClient
                .postJson('/api/client/leads/${mutation.leadId}/details', {
              'kind': mutation.payload['kind'] ?? 'INFO',
              'label': mutation.payload['label'],
              'value': mutation.payload['value'] ?? '',
            });
            break;
          case 'setCustomerWorkflowStage':
            await _apiClient.patchJson(
                '/api/client/leads/${mutation.leadId}/customer-workflow-stage',
                {
                  'customerWorkflowStage':
                      mutation.payload['customerWorkflowStage'] ?? '',
                });
            break;
          default:
            break;
        }
      } catch (error) {
        stopProcessing = true;
        lastError = error.toString();
        remaining.add(mutation);
      }
    }

    await _localStore.writePendingMutations(remaining);
    _setSyncSnapshot(
      syncSnapshot.value.copyWith(
        pendingChanges: remaining.length,
        isSyncing: false,
        lastSuccessfulSyncAt: remaining.isEmpty
            ? DateTime.now()
            : syncSnapshot.value.lastSuccessfulSyncAt,
        lastError: lastError,
        clearLastError: remaining.isEmpty,
      ),
    );
    return remaining;
  }

  Future<void> _restoreSyncSnapshot() async {
    final pending = await _localStore.readPendingMutations();
    _setSyncSnapshot(
        syncSnapshot.value.copyWith(pendingChanges: pending.length));
  }

  void _setSyncSnapshot(LeadSyncSnapshot nextSnapshot) {
    final current = syncSnapshot.value;
    if (current.pendingChanges == nextSnapshot.pendingChanges &&
        current.isSyncing == nextSnapshot.isSyncing &&
        current.lastSuccessfulSyncAt == nextSnapshot.lastSuccessfulSyncAt &&
        current.lastError == nextSnapshot.lastError) {
      return;
    }

    syncSnapshot.value = nextSnapshot;
  }
}
