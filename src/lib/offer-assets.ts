import sharedOfferAssetManifest from '../../client/veloprime_hybrid_app/assets/offers/asset_manifest.json'

type OfferAssetConfig = {
  aliases: string[]
  folderName: string
  specFileName: string
  preferredPremiumFileName?: string
  images: OfferAssetImageGroup
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

const MODEL_ASSET_CONFIGS = sharedOfferAssetManifest as OfferAssetConfig[]

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
          config: entry,
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
    premium: config.images.premium.map((fileName) => buildPublicAssetUrl('grafiki', config.folderName, fileName)),
    details: config.images.details.map((fileName) => buildPublicAssetUrl('grafiki', config.folderName, fileName)),
    interior: config.images.interior.map((fileName) => buildPublicAssetUrl('grafiki', config.folderName, fileName)),
    exterior: config.images.exterior.map((fileName) => buildPublicAssetUrl('grafiki', config.folderName, fileName)),
    other: config.images.other.map((fileName) => buildPublicAssetUrl('grafiki', config.folderName, fileName)),
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