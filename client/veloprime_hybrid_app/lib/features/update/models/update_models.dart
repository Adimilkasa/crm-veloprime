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

class PublishedArtifactSnapshot {
  const PublishedArtifactSnapshot({
    required this.source,
    required this.generatedAt,
    required this.stats,
    required this.notes,
  });

  final String source;
  final String generatedAt;
  final Map<String, num> stats;
  final List<String> notes;

  factory PublishedArtifactSnapshot.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'];
    final stats = <String, num>{};

    if (rawStats is Map<String, dynamic>) {
      for (final entry in rawStats.entries) {
        final value = entry.value;
        if (value is num) {
          stats[entry.key] = value;
        }
      }
    }

    return PublishedArtifactSnapshot(
      source: json['source'] as String? ?? 'STATIC',
      generatedAt: json['generatedAt'] as String? ?? '',
      stats: stats,
      notes: (json['notes'] as List<dynamic>? ?? const []).whereType<String>().toList(),
    );
  }
}

class PublishedVersionInfo {
  const PublishedVersionInfo({
    required this.artifactType,
    required this.version,
    required this.publishedAt,
    required this.publishedBy,
    required this.summary,
    required this.priority,
    required this.snapshot,
  });

  final String artifactType;
  final String version;
  final String? publishedAt;
  final String? publishedBy;
  final String? summary;
  final String priority;
  final PublishedArtifactSnapshot? snapshot;

  factory PublishedVersionInfo.fromJson(Map<String, dynamic> json) {
    final rawSnapshot = json['snapshot'];

    return PublishedVersionInfo(
      artifactType: json['artifactType'] as String? ?? 'UNKNOWN',
      version: json['version'] as String? ?? 'v1',
      publishedAt: json['publishedAt'] as String?,
      publishedBy: json['publishedBy'] as String?,
      summary: json['summary'] as String?,
      priority: json['priority'] as String? ?? 'STANDARD',
      snapshot: rawSnapshot is Map<String, dynamic> ? PublishedArtifactSnapshot.fromJson(rawSnapshot) : null,
    );
  }
}

class UpdateManifestInfo {
  const UpdateManifestInfo({
    required this.versions,
  });

  final List<PublishedVersionInfo> versions;

  PublishedVersionInfo? findVersion(String artifactType) {
    for (final version in versions) {
      if (version.artifactType == artifactType) {
        return version;
      }
    }

    return null;
  }

  factory UpdateManifestInfo.fromJson(Map<String, dynamic> json) {
    final rawVersions = json['versions'] as List<dynamic>? ?? const [];

    return UpdateManifestInfo(
      versions: rawVersions.whereType<Map<String, dynamic>>().map(PublishedVersionInfo.fromJson).toList(),
    );
  }
}

class VersionComparisonItem {
  const VersionComparisonItem({
    required this.artifactType,
    required this.currentVersion,
    required this.publishedVersion,
    required this.priority,
    required this.requiresUpdate,
    this.snapshot,
  });

  final String artifactType;
  final String? currentVersion;
  final String publishedVersion;
  final String priority;
  final bool requiresUpdate;
  final PublishedArtifactSnapshot? snapshot;

  factory VersionComparisonItem.fromJson(Map<String, dynamic> json) {
    final rawSnapshot = json['snapshot'];

    return VersionComparisonItem(
      artifactType: json['artifactType'] as String? ?? 'UNKNOWN',
      currentVersion: json['currentVersion'] as String?,
      publishedVersion: json['publishedVersion'] as String? ?? 'v1',
      priority: json['priority'] as String? ?? 'STANDARD',
      requiresUpdate: json['requiresUpdate'] as bool? ?? false,
      snapshot: rawSnapshot is Map<String, dynamic> ? PublishedArtifactSnapshot.fromJson(rawSnapshot) : null,
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