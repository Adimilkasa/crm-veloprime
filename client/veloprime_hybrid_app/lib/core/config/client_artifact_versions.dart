class ClientArtifactVersions {
  const ClientArtifactVersions._();

  static const String data = 'v1';
  static const String assets = 'v1';
  static const String application = 'v34';
  static const String release = '0.1.12.20';

  static String syncedDataVersion = data;
  static String syncedAssetsVersion = assets;
  static String syncedApplicationVersion = application;

  static void syncPublishedVersions({
    String? dataVersion,
    String? assetsVersion,
  }) {
    syncedDataVersion = _normalizeVersion(dataVersion, data);
    syncedAssetsVersion = _normalizeVersion(assetsVersion, assets);
    syncedApplicationVersion = application;
  }

  static void resetSessionSync() {
    syncedDataVersion = data;
    syncedAssetsVersion = assets;
    syncedApplicationVersion = application;
  }

  static String _normalizeVersion(String? value, String fallback) {
    final normalized = value?.trim();
    return normalized != null && normalized.isNotEmpty ? normalized : fallback;
  }

  static String get releaseLabel => 'wersja $release';
}