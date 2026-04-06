import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/lead_models.dart';

class PendingLeadMutation {
  const PendingLeadMutation({
    required this.id,
    required this.type,
    required this.leadId,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String leadId;
  final Map<String, dynamic> payload;
  final String createdAt;

  factory PendingLeadMutation.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];

    return PendingLeadMutation(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      leadId: json['leadId'] as String? ?? '',
      payload: payload is Map<String, dynamic>
          ? payload
          : payload is Map
              ? payload.map(
                  (key, value) => MapEntry(key.toString(), value),
                )
              : const {},
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'leadId': leadId,
      'payload': payload,
      'createdAt': createdAt,
    };
  }
}

class LeadsLocalStore {
  static const String _overviewKey = 'veloprime.leads.overview.v1';
  static const String _detailsKey = 'veloprime.leads.details.v1';
  static const String _queueKey = 'veloprime.leads.pending-mutations.v1';
  final Future<SharedPreferences> _preferences = SharedPreferences.getInstance();

  Future<LeadsOverview?> readOverview() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_overviewKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }

    return LeadsOverview.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<void> writeOverview(LeadsOverview overview) async {
    final prefs = await _preferences;
    await prefs.setString(_overviewKey, jsonEncode(overview.toJson()));
  }

  Future<LeadDetailPayload?> readDetail(String leadId) async {
    final prefs = await _preferences;
    final details = await _readRawDetailsMap(prefs);
    final rawDetail = details[leadId];
    if (rawDetail is! Map) {
      return null;
    }

    return LeadDetailPayload.fromJson(
      rawDetail.map((entryKey, entryValue) => MapEntry(entryKey.toString(), entryValue)),
    );
  }

  Future<Map<String, LeadDetailPayload>> readDetails() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_detailsKey);
    if (raw == null || raw.isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const {};
    }

    return decoded.map(
      (key, value) => MapEntry(
        key.toString(),
        LeadDetailPayload.fromJson(
          (value as Map).map((entryKey, entryValue) => MapEntry(entryKey.toString(), entryValue)),
        ),
      ),
    );
  }

  Future<void> writeDetail(LeadDetailPayload payload) async {
    final prefs = await _preferences;
    final details = await _readRawDetailsMap(prefs);
    details[payload.lead.id] = payload.toJson();
    await prefs.setString(_detailsKey, jsonEncode(details));
  }

  Future<List<PendingLeadMutation>> readPendingMutations() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (entry) => PendingLeadMutation.fromJson(
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<void> writePendingMutations(List<PendingLeadMutation> mutations) async {
    final prefs = await _preferences;
    await prefs.setString(
      _queueKey,
      jsonEncode(mutations.map((mutation) => mutation.toJson()).toList()),
    );
  }

  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.remove(_overviewKey);
    await prefs.remove(_detailsKey);
    await prefs.remove(_queueKey);
  }

  Future<Map<String, dynamic>> _readRawDetailsMap(SharedPreferences prefs) async {
    final raw = prefs.getString(_detailsKey);
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return <String, dynamic>{};
    }

    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
}