import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared offer asset manifest matches bundled files', () async {
    final projectRoot = Directory.current;
    final manifestFile = File('${projectRoot.path}${Platform.pathSeparator}assets${Platform.pathSeparator}offers${Platform.pathSeparator}asset_manifest.json');

    expect(await manifestFile.exists(), isTrue, reason: 'Shared offer asset manifest is missing.');

    final decoded = jsonDecode(await manifestFile.readAsString());
    expect(decoded, isA<List<dynamic>>(), reason: 'Offer asset manifest must be a JSON array.');

    final manifestEntries = decoded as List<dynamic>;
    expect(manifestEntries, isNotEmpty, reason: 'Offer asset manifest cannot be empty.');

    final seenAliases = <String>{};

    for (final rawEntry in manifestEntries) {
      expect(rawEntry, isA<Map<String, dynamic>>(), reason: 'Each manifest entry must be a JSON object.');
      final entry = rawEntry as Map<String, dynamic>;
      final aliases = (entry['aliases'] as List<dynamic>? ?? const []).whereType<String>().toList();
      final folderName = entry['folderName'] as String? ?? '';
      final specFileName = entry['specFileName'] as String? ?? '';
      final images = entry['images'] as Map<String, dynamic>? ?? const {};

      expect(aliases, isNotEmpty, reason: 'Manifest entry for $folderName must define aliases.');
      expect(folderName, isNotEmpty, reason: 'Manifest entry must define folderName.');
      expect(specFileName, isNotEmpty, reason: 'Manifest entry for $folderName must define specFileName.');

      for (final alias in aliases) {
        final normalizedAlias = alias.trim().toLowerCase();
        expect(seenAliases.add(normalizedAlias), isTrue, reason: 'Duplicate alias found in offer asset manifest: $alias');
      }

      final imageFolder = Directory('${projectRoot.path}${Platform.pathSeparator}assets${Platform.pathSeparator}offers${Platform.pathSeparator}grafiki${Platform.pathSeparator}$folderName');
      final specFile = File('${projectRoot.path}${Platform.pathSeparator}assets${Platform.pathSeparator}offers${Platform.pathSeparator}spec${Platform.pathSeparator}$specFileName');

      expect(await imageFolder.exists(), isTrue, reason: 'Missing bundled image folder for $folderName.');
      expect(await specFile.exists(), isTrue, reason: 'Missing bundled spec PDF for $folderName: $specFileName');

      for (final category in const ['premium', 'details', 'interior', 'exterior']) {
        final fileNames = (images[category] as List<dynamic>? ?? const []).whereType<String>().toList();
        for (final fileName in fileNames) {
          final imageFile = File('${imageFolder.path}${Platform.pathSeparator}$fileName');
          expect(await imageFile.exists(), isTrue, reason: 'Missing $category asset for $folderName: $fileName');
        }
      }
    }
  });
}