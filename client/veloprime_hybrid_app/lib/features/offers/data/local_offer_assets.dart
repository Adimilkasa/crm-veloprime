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
}

class _LocalOfferAssetConfig {
  const _LocalOfferAssetConfig({
    required this.folderName,
    required this.specFileName,
    required this.imageFiles,
  });

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

  final List<String> premium;
  final List<String> details;
  final List<String> interior;
  final List<String> exterior;
}

const _assetRoot = 'assets/offers';

const List<({List<String> aliases, _LocalOfferAssetConfig config})> _modelAssetConfigs = [
  (
    aliases: ['byd atto 2', 'atto 2'],
    config: _LocalOfferAssetConfig(
      folderName: 'byd-atto-2',
      specFileName: 'byd-atto-2.pdf',
      imageFiles: _LocalOfferAssetImageGroup(
        premium: ['premium 1.jpg', 'premium1.jpg', 'premium2.jpg'],
        details: ['detal1.jpg', 'detal2.jpg', 'detal4.jpg', 'detal5.jpg', 'detal7.jpg'],
        interior: ['wewnatrz2.jpg', 'wewnatrz3.jpg', 'wewnatrz8.jpg', 'wewnatrz9.jpg'],
        exterior: ['zewnatrz 3.jpg', 'zewnatrz.jpg', 'zewnatrz1.jpg', 'zewnatrz10.jpg', 'zewnatrz3.jpg', 'zewnatrz6.jpg'],
      ),
    ),
  ),
  (
    aliases: ['byd dolphin surf', 'dolphin surf'],
    config: _LocalOfferAssetConfig(
      folderName: 'byd-dolphin-surf',
      specFileName: 'byd-dolphin-surf.pdf',
      imageFiles: _LocalOfferAssetImageGroup(
        premium: ['premium 1.jpg', 'premium 2.jpg', 'premium 3.jpg', 'premium 4.jpg'],
        details: ['detal 1.jpg', 'detal 2.jpg', 'detal 3.jpg', 'detal 4.jpg'],
        interior: ['wnetrze 1.jpg', 'wnetrze 2.jpg', 'wnetrze 3.jpg'],
        exterior: ['zewnatrz 1.jpg', 'zewnatrz 2.jpg', 'zewnatrz 4.jpg'],
      ),
    ),
  ),
  (
    aliases: ['byd seal excellence', 'byd seal', 'seal excellence', 'seal'],
    config: _LocalOfferAssetConfig(
      folderName: 'Seal',
      specFileName: 'byd-seal.pdf',
      imageFiles: _LocalOfferAssetImageGroup(
        premium: ['premium 1.jpg', 'premium 2.jpg', 'premium 3.jpg'],
        details: ['detal 2.jpg', 'detal 3.jpg', 'detal 4.jpg', 'detal 5.jpg', 'detal.jpg'],
        interior: ['wnetrze 1.jpg', 'wnetrze 2.jpg', 'wnetrze 3.jpg', 'wnetrze.jpg'],
        exterior: ['zewnatrz 2.jpg', 'zewnatrz 3.jpg', 'zewnatrz.jpg'],
      ),
    ),
  ),
  (
    aliases: ['byd seal 5', 'seal 5'],
    config: _LocalOfferAssetConfig(
      folderName: 'Seal 5',
      specFileName: 'byd-seal-5.pdf',
      imageFiles: _LocalOfferAssetImageGroup(
        premium: ['premium 1.jpg', 'premium 2.jpg', 'premium.jpg'],
        details: ['detal 2.jpg', 'detal 3.jpg', 'detal.jpg'],
        interior: ['wewnatrz 2.jpg', 'wewnatrz 4.jpg', 'wewnatrz 5.jpg', 'wewnatrz.jpg'],
        exterior: ['zewnatrz 3.jpg', 'zewnatrz 4.jpg', 'zewnatrz 5.jpg', 'zewnatrz.jpg'],
      ),
    ),
  ),
  (
    aliases: ['byd seal 6 touring', 'seal 6 touring'],
    config: _LocalOfferAssetConfig(
      folderName: 'Seal 6 touring',
      specFileName: 'byd-seal-6-touring.pdf',
      imageFiles: _LocalOfferAssetImageGroup(
        premium: ['premium 2.jpg', 'premium.jpg'],
        details: ['detal 1.jpg', 'detal 2.jpg', 'detal 3.jpg', 'detal 4.jpg', 'detal 5.jpg', 'detal.jpg'],
        interior: ['wnetrze 1.jpg', 'wnetrze 2.jpg', 'wnetrze.jpg'],
        exterior: ['zewnatrz (2).jpg', 'zewnatrz 2.jpg', 'zewnatrz 3.jpg', 'zewnatrz 4.jpg', 'zewnatrz 5.jpg', 'zewnatrz.jpg'],
      ),
    ),
  ),
  (
    aliases: ['byd seal 6 dmi', 'byd seal 6 dm-i', 'seal 6 dmi', 'seal 6 dm-i'],
    config: _LocalOfferAssetConfig(
      folderName: 'seal-6-dmi',
      specFileName: 'seal-6-dmi.pdf',
      imageFiles: _LocalOfferAssetImageGroup(
        premium: ['premium 3.jpg', 'premium bok.jpg', 'premium przod 2.jpg', 'premium przod.jpg', 'premium przud 4.png', 'premium tył samochodu.jpg'],
        details: ['klamka led.jpg', 'koło.jpg', 'otwieranie smartfonem.jpg', 'przednie leflektory.jpg', 'szklany dach.jpg'],
        interior: ['kanapy tylne jasne.jpg', 'kokpit ciemne kanapy.jpg', 'kokpit jasne kanapy 2.jpg', 'kokpit jasne kanapy.jpg', 'przód wnętrze.jpg', 'tylne kanapy ciemne.jpg', 'wyświetlacz.webp'],
        exterior: ['03、SEAL-6_LHD_Sandstone_Exterior_Rear_download_JPG_5000PX_RGB (1).jpg', 'ładowanie samochodu.jpg'],
      ),
    ),
  ),
  (
    aliases: ['byd seal u', 'seal u', 'seal-u'],
    config: _LocalOfferAssetConfig(
      folderName: 'Seal-U',
      specFileName: 'byd-seal-u.pdf',
      imageFiles: _LocalOfferAssetImageGroup(
        premium: [],
        details: ['deta.jpg', 'detal 3.jpg', 'detal 5.webp', 'detal.jpg', 'detal2.jpg'],
        interior: ['wewnatrz 1.jpg', 'wewnatrz 2.jpg', 'wewnatrz 3.jpg', 'wewnatrz.jpg'],
        exterior: ['zewnatrz 4.jpg', 'zewnatrz 5.jpg', 'zewnatrz 6.jpg', 'zewnatrz 7.jpg', 'zewnatrz 7.webp', 'zewnatrz.jpg'],
      ),
    ),
  ),
  (
    aliases: ['byd sealion 7', 'sealion 7', 'byd seal 7', 'seal 7'],
    config: _LocalOfferAssetConfig(
      folderName: 'Seal 7',
      specFileName: 'byd-sealion-7.pdf',
      imageFiles: _LocalOfferAssetImageGroup(
        premium: ['premium 1.jpg', 'premium 2.jpg', 'premium 3.jpg'],
        details: ['Detal 1.jpg', 'detal 2.jpg', 'detal 3.jpg', 'detal 4.jpg', 'detal 5.jpg', 'detal.jpg'],
        interior: ['Wnetrze 2.jpg', 'Wnetrze 4.jpg', 'wnetrze 3.jpg', 'wnetrze 5.jpg', 'wnetrze 6.jpg', 'wnetrze.jpg'],
        exterior: ['zewnatrz 2.jpg', 'zewnatrz 3.jpg', 'zewnatrz 4.jpg', 'zewnatrz 5.jpg', 'zewnatrz.jpg', 'zewnatrz5.jpg'],
      ),
    ),
  ),
];

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
        bestConfig = entry.config;
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