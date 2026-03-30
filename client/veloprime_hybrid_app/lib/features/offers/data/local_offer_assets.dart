import 'dart:convert';

import 'package:flutter/services.dart';

class LocalOfferAssetBundle {
  const LocalOfferAssetBundle({
    required this.specPdfAssetPath,
    required this.premiumImages,
    required this.detailImages,
    required this.interiorImages,
    required this.exteriorImages,
  });

  final String? specPdfAssetPath;
  final List<String> premiumImages;
  final List<String> detailImages;
  final List<String> interiorImages;
  final List<String> exteriorImages;

  List<String> get galleryImages => [
        ...premiumImages,
        ...exteriorImages,
        ...interiorImages,
        ...detailImages,
      ].toSet().toList(growable: false);

  String? get heroImageAsset {
    final heroCandidates = [
      ...premiumImages,
      ...exteriorImages,
      ...detailImages,
    ];

    return heroCandidates.cast<String?>().firstWhere((item) => item != null, orElse: () => null);
  }
}

class _LocalOfferAssetConfig {
  const _LocalOfferAssetConfig({
    required this.aliases,
    required this.folderName,
    required this.specFileName,
    required this.imageFiles,
  });

  factory _LocalOfferAssetConfig.fromJson(Map<String, dynamic> json) {
    return _LocalOfferAssetConfig(
      aliases: _readStringList(json['aliases']),
      folderName: json['folderName'] as String? ?? '',
      specFileName: json['specFileName'] as String? ?? '',
      imageFiles: _LocalOfferAssetImageGroup.fromJson(json['images'] as Map<String, dynamic>? ?? const {}),
    );
  }

  final List<String> aliases;
  final String folderName;
  final String specFileName;
  final _LocalOfferAssetImageGroup imageFiles;
}

class _LocalOfferAssetImageGroup {
  const _LocalOfferAssetImageGroup({
    required this.premium,
    required this.details,
    required this.interior,
    required this.exterior,
  });

  factory _LocalOfferAssetImageGroup.fromJson(Map<String, dynamic> json) {
    return _LocalOfferAssetImageGroup(
      premium: _readStringList(json['premium']),
      details: _readStringList(json['details']),
      interior: _readStringList(json['interior']),
      exterior: _readStringList(json['exterior']),
    );
  }

  final List<String> premium;
  final List<String> details;
  final List<String> interior;
  final List<String> exterior;
}

const _assetRoot = 'assets/offers';
const _assetManifestPath = 'assets/offers/asset_manifest.json';

bool _isAssetManifestLoaded = false;
List<_LocalOfferAssetConfig> _modelAssetConfigs = const [];

Future<void> initializeLocalOfferAssets() async {
  if (_isAssetManifestLoaded) {
    return;
  }

  final rawManifest = await rootBundle.loadString(_assetManifestPath);
  final decoded = jsonDecode(rawManifest);
  if (decoded is! List<dynamic>) {
    throw StateError('Offer asset manifest must be a JSON array.');
  }

  _modelAssetConfigs = decoded
      .whereType<Map<String, dynamic>>()
      .map(_LocalOfferAssetConfig.fromJson)
      .where((entry) => entry.aliases.isNotEmpty && entry.folderName.isNotEmpty && entry.specFileName.isNotEmpty)
      .toList(growable: false);
  _isAssetManifestLoaded = true;
}

List<String> _readStringList(Object? rawValue) {
  if (rawValue is! List<dynamic>) {
    return const [];
  }

  return rawValue.whereType<String>().toList(growable: false);
}

String _normalizeValue(String value) {
  const diacritics = {
    'ą': 'a',
    'ć': 'c',
    'ę': 'e',
    'ł': 'l',
    'ń': 'n',
    'ó': 'o',
    'ś': 's',
    'ź': 'z',
    'ż': 'z',
    'Ą': 'a',
    'Ć': 'c',
    'Ę': 'e',
    'Ł': 'l',
    'Ń': 'n',
    'Ó': 'o',
    'Ś': 's',
    'Ź': 'z',
    'Ż': 'z',
  };

  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(diacritics[char] ?? char);
  }

  return buffer
      .toString()
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
      .trim()
      .toLowerCase();
}

String _assetPath(String category, String folder, String fileName) {
  return '$_assetRoot/$category/$folder/$fileName';
}

_LocalOfferAssetConfig? _getAssetConfig(String? modelName) {
  if (!_isAssetManifestLoaded) {
    throw StateError('Offer asset manifest is not initialized. Call initializeLocalOfferAssets() before using offer assets.');
  }

  if (modelName == null || modelName.trim().isEmpty) {
    return null;
  }

  final normalized = ' ${_normalizeValue(modelName)} ';
  _LocalOfferAssetConfig? bestConfig;
  var bestAliasLength = -1;

  for (final entry in _modelAssetConfigs) {
    for (final alias in entry.aliases) {
      final normalizedAlias = _normalizeValue(alias);
      if (normalizedAlias.isEmpty || !normalized.contains(' $normalizedAlias ')) {
        continue;
      }

      if (normalizedAlias.length > bestAliasLength) {
        bestAliasLength = normalizedAlias.length;
        bestConfig = entry;
      }
    }
  }

  return bestConfig;
}

LocalOfferAssetBundle getLocalOfferAssetBundle(String? modelName) {
  final config = _getAssetConfig(modelName);
  if (config == null) {
    return const LocalOfferAssetBundle(
      specPdfAssetPath: null,
      premiumImages: [],
      detailImages: [],
      interiorImages: [],
      exteriorImages: [],
    );
  }

  return LocalOfferAssetBundle(
    specPdfAssetPath: '$_assetRoot/spec/${config.specFileName}',
    premiumImages: config.imageFiles.premium.map((fileName) => _assetPath('grafiki', config.folderName, fileName)).toList(),
    detailImages: config.imageFiles.details.map((fileName) => _assetPath('grafiki', config.folderName, fileName)).toList(),
    interiorImages: config.imageFiles.interior.map((fileName) => _assetPath('grafiki', config.folderName, fileName)).toList(),
    exteriorImages: config.imageFiles.exterior.map((fileName) => _assetPath('grafiki', config.folderName, fileName)).toList(),
  );
}