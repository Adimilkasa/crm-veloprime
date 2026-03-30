import { readdir } from 'node:fs/promises'
import path from 'node:path'

type OfferAssetConfig = {
  folderName: string
  specFileName: string
  preferredPremiumFileName?: string
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
    },
  },
  {
    aliases: ['byd dolphin surf', 'dolphin surf'],
    config: {
      folderName: 'byd-dolphin-surf',
      specFileName: 'byd-dolphin-surf.pdf',
    },
  },
  {
    aliases: ['byd seal excellence', 'byd seal', 'seal excellence', 'seal'],
    config: {
      folderName: 'Seal',
      specFileName: 'byd-seal.pdf',
    },
  },
  {
    aliases: ['byd seal 5', 'seal 5'],
    config: {
      folderName: 'Seal 5',
      specFileName: 'byd-seal-5.pdf',
    },
  },
  {
    aliases: ['byd seal 6 touring', 'seal 6 touring'],
    config: {
      folderName: 'Seal 6 touring',
      specFileName: 'byd-seal-6-touring.pdf',
    },
  },
  {
    aliases: ['byd seal 6 dmi', 'byd seal 6 dm-i', 'seal 6 dmi', 'seal 6 dm-i'],
    config: {
      folderName: 'seal-6-dmi',
      specFileName: 'seal-6-dmi.pdf',
    },
  },
  {
    aliases: ['byd seal u', 'seal u', 'seal-u'],
    config: {
      folderName: 'Seal-U',
      specFileName: 'byd-seal-u.pdf',
    },
  },
  {
    aliases: ['byd sealion 7', 'sealion 7', 'byd seal 7', 'seal 7'],
    config: {
      folderName: 'Seal 7',
      specFileName: 'byd-sealion-7.pdf',
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

function classifyImageFile(fileName: string) {
  const normalized = normalizeValue(fileName)

  if (normalized.includes('premium')) {
    return 'premium'
  }

  if (normalized.includes('detal') || normalized.includes('detail')) {
    return 'details'
  }

  if (normalized.includes('wewnatrz') || normalized.includes('wnetrze') || normalized.includes('kokpit') || normalized.includes('kanapy')) {
    return 'interior'
  }

  if (normalized.includes('zewnatrz') || normalized.includes('przod') || normalized.includes('tyl') || normalized.includes('bok') || normalized.includes('dach')) {
    return 'exterior'
  }

  return 'other'
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

  const folderPath = path.join(process.cwd(), 'grafiki', config.folderName)
  const images: OfferAssetImageGroup = {
    premium: [],
    details: [],
    interior: [],
    exterior: [],
    other: [],
  }

  try {
    const files = await readdir(folderPath, { withFileTypes: true })

    for (const file of files) {
      if (!file.isFile()) {
        continue
      }

      const group = classifyImageFile(file.name)
      images[group].push(buildPublicAssetUrl('grafiki', config.folderName, file.name))
    }

    for (const key of Object.keys(images) as Array<keyof OfferAssetImageGroup>) {
      images[key].sort((left, right) => left.localeCompare(right, 'pl'))
    }

    if (config.preferredPremiumFileName) {
      const preferredPremiumUrl = buildPublicAssetUrl('grafiki', config.folderName, config.preferredPremiumFileName)
      const preferredIndex = images.premium.indexOf(preferredPremiumUrl)

      if (preferredIndex > 0) {
        const [preferredImage] = images.premium.splice(preferredIndex, 1)
        images.premium.unshift(preferredImage)
      }
    }
  } catch {
    // Serverless traces may omit local asset folders; return an empty gallery instead of failing the document snapshot.
  }

  return {
    logoUrl: LOGO_URL,
    modelKey: normalizeValue(modelName ?? ''),
    folderName: config.folderName,
    specPdfUrl: buildPublicAssetUrl('spec', config.specFileName),
    images,
  }
}