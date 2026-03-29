import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:veloprime_hybrid_app/core/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('uses runtime config file when present', () async {
      final tempDirectory = await Directory.systemTemp.createTemp('veloprime_api_config_test');
      final configFile = File('${tempDirectory.path}${Platform.pathSeparator}${ApiConfig.configFileName}');

      await configFile.writeAsString('{"baseUrl":"https://crm.veloprime.pl/"}');

      final resolvedBaseUrl = await ApiConfig.resolveBaseUrl(
        definedBaseUrl: 'http://127.0.0.1:3000',
        candidatePaths: [configFile.path],
      );

      expect(resolvedBaseUrl, 'https://crm.veloprime.pl');

      await tempDirectory.delete(recursive: true);
    });

    test('falls back to dart-define value when config file is missing', () async {
      final resolvedBaseUrl = await ApiConfig.resolveBaseUrl(
        definedBaseUrl: 'http://127.0.0.1:3005/',
        candidatePaths: ['Z:/does-not-exist/${ApiConfig.configFileName}'],
      );

      expect(resolvedBaseUrl, 'http://127.0.0.1:3005');
    });

    test('ignores invalid config file payload', () async {
      final tempDirectory = await Directory.systemTemp.createTemp('veloprime_api_config_invalid');
      final configFile = File('${tempDirectory.path}${Platform.pathSeparator}${ApiConfig.configFileName}');

      await configFile.writeAsString('{"baseUrl":true}');

      final resolvedBaseUrl = await ApiConfig.resolveBaseUrl(
        definedBaseUrl: 'http://127.0.0.1:3000',
        candidatePaths: [configFile.path],
      );

      expect(resolvedBaseUrl, 'http://127.0.0.1:3000');

      await tempDirectory.delete(recursive: true);
    });
  });
}