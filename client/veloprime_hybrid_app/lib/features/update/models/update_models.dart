class ClientVersionPayload {
  const ClientVersionPayload({
    required this.dataVersion,
    required this.assetsVersion,
    required this.applicationVersion,
  });

  final String? dataVersion;
  final String? assetsVersion;
  final String? applicationVersion;

  Map<String, dynamic> toJson() {
    return {
      'versions': {
        'DATA': dataVersion,
        'ASSETS': assetsVersion,
        'APPLICATION': applicationVersion,
      },
    };
  }
}

class VersionComparisonItem {
  const VersionComparisonItem({
    required this.artifactType,
    required this.currentVersion,
    required this.publishedVersion,
    required this.priority,
    required this.requiresUpdate,
  });

  final String artifactType;
  final String? currentVersion;
  final String publishedVersion;
  final String priority;
  final bool requiresUpdate;

  factory VersionComparisonItem.fromJson(Map<String, dynamic> json) {
    return VersionComparisonItem(
      artifactType: json['artifactType'] as String? ?? 'UNKNOWN',
      currentVersion: json['currentVersion'] as String?,
      publishedVersion: json['publishedVersion'] as String? ?? 'v1',
      priority: json['priority'] as String? ?? 'STANDARD',
      requiresUpdate: json['requiresUpdate'] as bool? ?? false,
    );
  }
}

class VersionComparisonResult {
  const VersionComparisonResult({
    required this.requiresAnyUpdate,
    required this.requiresCriticalUpdate,
    required this.items,
  });

  final bool requiresAnyUpdate;
  final bool requiresCriticalUpdate;
  final List<VersionComparisonItem> items;

  factory VersionComparisonResult.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['comparison'] as List<dynamic>? ?? const []);

    return VersionComparisonResult(
      requiresAnyUpdate: json['requiresAnyUpdate'] as bool? ?? false,
      requiresCriticalUpdate: json['requiresCriticalUpdate'] as bool? ?? false,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(VersionComparisonItem.fromJson)
          .toList(),
    );
  }
}