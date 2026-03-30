type OfferAssetConfig = {
  folderName: string
  specFileName: string
  preferredPremiumFileName?: string
  imageFiles: OfferAssetImageGroup
}

type OfferAssetImageGroup = {
  premium: string[]
  details: string[]
  interior: string[]
  exterior: string[]
  other: string[]
}

export type OfferAssetBundle = {
  logoUrl: string
  modelKey: string | null
  folderName: string | null
  specPdfUrl: string | null
  images: OfferAssetImageGroup
}

const LOGO_URL = '/assets/grafiki/LOGO.png?v=20260325-transparent'

const MODEL_ASSET_CONFIGS: Array<{ aliases: string[]; config: OfferAssetConfig }> = [
  {
    aliases: ['byd atto 2', 'atto 2'],
    config: {
      folderName: 'byd-atto-2',
      specFileName: 'byd-atto-2.pdf',
      preferredPremiumFileName: 'premium2.jpg',
      imageFiles: {
        premium: ['premium 1.jpg', 'premium1.jpg', 'premium2.jpg'],
        details: ['detal1.jpg', 'detal2.jpg', 'detal4.jpg', 'detal5.jpg', 'detal7.jpg'],
        interior: ['wewnatrz2.jpg', 'wewnatrz3.jpg', 'wewnatrz8.jpg', 'wewnatrz9.jpg'],
        exterior: ['zewnatrz 3.jpg', 'zewnatrz.jpg', 'zewnatrz1.jpg', 'zewnatrz10.jpg', 'zewnatrz3.jpg', 'zewnatrz6.jpg'],
        other: [],
      },
    },
  },
  {
    aliases: ['byd dolphin surf', 'dolphin surf'],
    config: {
      folderName: 'byd-dolphin-surf',
      specFileName: 'byd-dolphin-surf.pdf',
      imageFiles: {
        premium: ['premium 1.jpg', 'premium 2.jpg', 'premium 3.jpg', 'premium 4.jpg'],
        details: ['detal 1.jpg', 'detal 2.jpg', 'detal 3.jpg', 'detal 4.jpg'],
        interior: ['wnetrze 1.jpg', 'wnetrze 2.jpg', 'wnetrze 3.jpg'],
        exterior: ['zewnatrz 1.jpg', 'zewnatrz 2.jpg', 'zewnatrz 4.jpg'],
        other: [],
      },
    },
  },
  {
    aliases: ['byd seal excellence', 'byd seal', 'seal excellence', 'seal'],
    config: {
      folderName: 'Seal',
      specFileName: 'byd-seal.pdf',
      imageFiles: {
        premium: ['premium 1.jpg', 'premium 2.jpg', 'premium 3.jpg'],
        details: ['detal 2.jpg', 'detal 3.jpg', 'detal 4.jpg', 'detal 5.jpg', 'detal.jpg'],
        interior: ['wnetrze 1.jpg', 'wnetrze 2.jpg', 'wnetrze 3.jpg', 'wnetrze.jpg'],
        exterior: ['zewnatrz 2.jpg', 'zewnatrz 3.jpg', 'zewnatrz.jpg'],
        other: [],
      },
    },
  },
  {
    aliases: ['byd seal 5', 'seal 5'],
    config: {
      folderName: 'Seal 5',
      specFileName: 'byd-seal-5.pdf',
      imageFiles: {
        premium: ['premium 1.jpg', 'premium 2.jpg', 'premium.jpg'],
        details: ['detal 2.jpg', 'detal 3.jpg', 'detal.jpg'],
        interior: ['wewnatrz 2.jpg', 'wewnatrz 4.jpg', 'wewnatrz 5.jpg', 'wewnatrz.jpg'],
        exterior: ['zewnatrz 3.jpg', 'zewnatrz 4.jpg', 'zewnatrz 5.jpg', 'zewnatrz.jpg'],
        other: [],
      },
    },
  },
  {
    aliases: ['byd seal 6 touring', 'seal 6 touring'],
    config: {
      folderName: 'Seal 6 touring',
      specFileName: 'byd-seal-6-touring.pdf',
      imageFiles: {
        premium: ['premium 2.jpg', 'premium.jpg'],
        details: ['detal 1.jpg', 'detal 2.jpg', 'detal 3.jpg', 'detal 4.jpg', 'detal 5.jpg', 'detal.jpg'],
        interior: ['wnetrze 1.jpg', 'wnetrze 2.jpg', 'wnetrze.jpg'],
        exterior: ['zewnatrz (2).jpg', 'zewnatrz 2.jpg', 'zewnatrz 3.jpg', 'zewnatrz 4.jpg', 'zewnatrz 5.jpg', 'zewnatrz.jpg'],
        other: [],
      },
    },
  },
  {
    aliases: ['byd seal 6 dmi', 'byd seal 6 dm-i', 'seal 6 dmi', 'seal 6 dm-i'],
    config: {
      folderName: 'seal-6-dmi',
      specFileName: 'seal-6-dmi.pdf',
      imageFiles: {
        premium: ['premium 3.jpg', 'premium bok.jpg', 'premium przod 2.jpg', 'premium przod.jpg', 'premium przud 4.png', 'premium tył samochodu.jpg'],
        details: ['klamka led.jpg', 'koło.jpg', 'otwieranie smartfonem.jpg', 'przednie leflektory.jpg', 'szklany dach.jpg'],
        interior: ['kanapy tylne jasne.jpg', 'kokpit ciemne kanapy.jpg', 'kokpit jasne kanapy 2.jpg', 'kokpit jasne kanapy.jpg', 'przód wnętrze.jpg', 'tylne kanapy ciemne.jpg', 'wyświetlacz.webp'],
        exterior: ['03、SEAL-6_LHD_Sandstone_Exterior_Rear_download_JPG_5000PX_RGB (1).jpg', 'ładowanie samochodu.jpg'],
        other: [],
      },
    },
  },
  {
    aliases: ['byd seal u', 'seal u', 'seal-u'],
    config: {
      folderName: 'Seal-U',
      specFileName: 'byd-seal-u.pdf',
      imageFiles: {
        premium: [],
        details: ['deta.jpg', 'detal 3.jpg', 'detal 5.webp', 'detal.jpg', 'detal2.jpg'],
        interior: ['wewnatrz 1.jpg', 'wewnatrz 2.jpg', 'wewnatrz 3.jpg', 'wewnatrz.jpg'],
        exterior: ['zewnatrz 4.jpg', 'zewnatrz 5.jpg', 'zewnatrz 6.jpg', 'zewnatrz 7.jpg', 'zewnatrz 7.webp', 'zewnatrz.jpg'],
        other: [],
      },
    },
  },
  {
    aliases: ['byd sealion 7', 'sealion 7', 'byd seal 7', 'seal 7'],
    config: {
      folderName: 'Seal 7',
      specFileName: 'byd-sealion-7.pdf',
      imageFiles: {
        premium: ['premium 1.jpg', 'premium 2.jpg', 'premium 3.jpg'],
        details: ['Detal 1.jpg', 'detal 2.jpg', 'detal 3.jpg', 'detal 4.jpg', 'detal 5.jpg', 'detal.jpg'],
        interior: ['Wnetrze 2.jpg', 'Wnetrze 4.jpg', 'wnetrze 3.jpg', 'wnetrze 5.jpg', 'wnetrze 6.jpg', 'wnetrze.jpg'],
        exterior: ['zewnatrz 2.jpg', 'zewnatrz 3.jpg', 'zewnatrz 4.jpg', 'zewnatrz 5.jpg', 'zewnatrz.jpg', 'zewnatrz5.jpg'],
        other: [],
      },
    },
  },
]

function normalizeValue(value: string) {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z0-9]+/g, ' ')
    .trim()
    .toLowerCase()
}

function buildPublicAssetUrl(...segments: string[]) {
  return `/assets/${segments.map((segment) => encodeURIComponent(segment)).join('/')}`
}

function getAssetConfig(modelName: string | null | undefined) {
  if (!modelName) {
    return null
  }

  const normalized = normalizeValue(modelName)
  const paddedNormalized = ` ${normalized} `
  let bestMatch: { config: OfferAssetConfig; aliasLength: number } | null = null

  for (const entry of MODEL_ASSET_CONFIGS) {
    for (const alias of entry.aliases) {
      const normalizedAlias = normalizeValue(alias)

      if (!normalizedAlias || !paddedNormalized.includes(` ${normalizedAlias} `)) {
        continue
      }

      if (!bestMatch || normalizedAlias.length > bestMatch.aliasLength) {
        bestMatch = {
          config: entry.config,
          aliasLength: normalizedAlias.length,
        }
      }
    }
  }

  return bestMatch?.config ?? null
}

export async function getOfferAssetBundle(modelName: string | null | undefined): Promise<OfferAssetBundle> {
  const config = getAssetConfig(modelName)

  if (!config) {
    return {
      logoUrl: LOGO_URL,
      modelKey: null,
      folderName: null,
      specPdfUrl: null,
      images: {
        premium: [],
        details: [],
        interior: [],
        exterior: [],
        other: [],
      },
    }
  }

  const images: OfferAssetImageGroup = {
    premium: config.imageFiles.premium.map((fileName) => buildPublicAssetUrl('grafiki', config.folderName, fileName)),
    details: config.imageFiles.details.map((fileName) => buildPublicAssetUrl('grafiki', config.folderName, fileName)),
    interior: config.imageFiles.interior.map((fileName) => buildPublicAssetUrl('grafiki', config.folderName, fileName)),
    exterior: config.imageFiles.exterior.map((fileName) => buildPublicAssetUrl('grafiki', config.folderName, fileName)),
    other: config.imageFiles.other.map((fileName) => buildPublicAssetUrl('grafiki', config.folderName, fileName)),
  }

  if (config.preferredPremiumFileName) {
    const preferredPremiumUrl = buildPublicAssetUrl('grafiki', config.folderName, config.preferredPremiumFileName)
    const preferredIndex = images.premium.indexOf(preferredPremiumUrl)

    if (preferredIndex > 0) {
      const [preferredImage] = images.premium.splice(preferredIndex, 1)
      images.premium.unshift(preferredImage)
    }
  }

  return {
    logoUrl: LOGO_URL,
    modelKey: normalizeValue(modelName ?? ''),
    folderName: config.folderName,
    specPdfUrl: buildPublicAssetUrl('spec', config.specFileName),
    images,
  }
}