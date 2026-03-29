import 'dart:convert';
import 'dart:io';

class ApiConfig {
  static const String _definedBaseUrl = String.fromEnvironment(
    'VELOPRIME_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );
  static const String configFileName = 'veloprime_client_config.json';

  static String _baseUrl = _definedBaseUrl;

  static String get baseUrl => _baseUrl;

  static Future<void> initialize() async {
    _baseUrl = await resolveBaseUrl();
  }

  static Future<String> resolveBaseUrl({
    String definedBaseUrl = _definedBaseUrl,
    List<String>? candidatePaths,
  }) async {
    final normalizedDefinedBaseUrl = _normalizeBaseUrl(definedBaseUrl);

    for (final candidatePath in candidatePaths ?? _defaultCandidatePaths()) {
      final configuredBaseUrl = await _tryReadBaseUrl(candidatePath);

      if (configuredBaseUrl != null) {
        return configuredBaseUrl;
      }
    }

    return normalizedDefinedBaseUrl;
  }

  static List<String> _defaultCandidatePaths() {
    final candidates = <String>{
      '${Directory.current.path}${Platform.pathSeparator}$configFileName',
    };

    try {
      final executableDirectory = File(Platform.resolvedExecutable).parent.path;
      candidates.add('$executableDirectory${Platform.pathSeparator}$configFileName');
    } catch (_) {
      // Ignore runtime environments that do not expose a resolved executable path.
    }

    return candidates.toList(growable: false);
  }

  static Future<String?> _tryReadBaseUrl(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      return null;
    }

    try {
      final raw = await file.readAsString();
      final json = jsonDecode(raw);

      if (json is! Map<String, dynamic>) {
        return null;
      }

      final configured = json['baseUrl'] ?? json['apiBaseUrl'];

      if (configured is! String || configured.trim().isEmpty) {
        return null;
      }

      return _normalizeBaseUrl(configured);
    } catch (_) {
      return null;
    }
  }

  static String _normalizeBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}