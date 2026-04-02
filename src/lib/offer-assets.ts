import { PowertrainType, Prisma } from '@prisma/client'
import sharedOfferAssetManifest from '../../client/veloprime_hybrid_app/assets/offers/asset_manifest.json'

import { db } from '@/lib/db'

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

type OfferAssetLookupInput = {
  modelName?: string | null
  catalogKey?: string | null
  powertrainType?: string | null
}

type SalesModelAssetBundleWithFiles = Prisma.SalesModelAssetBundleGetPayload<{
  include: {
    files: true
  }
}>

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

function buildPublicAssetUrlFromRelativePath(filePath: string) {
  if (/^https?:\/\//i.test(filePath)) {
    return filePath
  }

  const sanitizedPath = filePath
    .split('/')
    .map((segment) => segment.trim())
    .filter((segment) => segment.length > 0)

  if (sanitizedPath.length == 1) {
    return buildPublicAssetUrl('uploads', sanitizedPath[0])
  }

  return buildPublicAssetUrl(...sanitizedPath)
}

function parseCatalogKey(catalogKey: string | null | undefined) {
  if (!catalogKey) {
    return null
  }

  const [brand, model, version, year] = catalogKey.split('::')
  if (!brand || !model || !version) {
    return null
  }

  return {
    brand,
    model,
    version,
     year: year && year.trim().length > 0 ? year.trim() : null,
  }
}

function normalizePowertrainType(value: string | null | undefined) {
  if (value === PowertrainType.ELECTRIC || value === PowertrainType.HYBRID || value === PowertrainType.ICE) {
    return value
  }

  return null
}

async function getDatabaseAssetBundle(input: OfferAssetLookupInput): Promise<OfferAssetBundle | null> {
  if (!db) {
    return null
  }

  const parsedCatalogKey = parseCatalogKey(input.catalogKey)
  const requestedPowertrain = normalizePowertrainType(input.powertrainType)
  let resolvedPowertrain: PowertrainType | null = requestedPowertrain
  let bundle: SalesModelAssetBundleWithFiles | null = null

  if (parsedCatalogKey) {
    const version = await db.salesVersion.findFirst({
      where: {
        name: {
          equals: parsedCatalogKey.version,
          mode: 'insensitive',
        },
        ...(parsedCatalogKey.year
          ? {
              year: Number(parsedCatalogKey.year),
            }
          : {}),
        model: {
          name: {
            equals: parsedCatalogKey.model,
            mode: 'insensitive',
          },
          brand: {
            name: {
              equals: parsedCatalogKey.brand,
              mode: 'insensitive',
            },
          },
        },
      },
      include: {
        model: {
          include: {
            assetBundle: {
              include: {
                files: {
                  orderBy: [{ sortOrder: 'asc' }, { fileName: 'asc' }],
                },
              },
            },
          },
        },
      },
    })

    bundle = version?.model.assetBundle?.isActive ? version.model.assetBundle : null
    resolvedPowertrain ??= version?.powertrainType ?? null
  }

  if (!bundle && input.modelName) {
    bundle = await db.salesModelAssetBundle.findFirst({
      where: {
        isActive: true,
        model: {
          name: {
            equals: input.modelName,
            mode: 'insensitive',
          },
        },
      },
      include: {
        files: {
          orderBy: [{ sortOrder: 'asc' }, { fileName: 'asc' }],
        },
      },
    })
  }

  if (!bundle) {
    return null
  }

  const logoFile = bundle.files.find((file) => file.category === 'LOGO') ?? null
  const primaryImages = bundle.files
    .filter((file) => file.category === 'PRIMARY')
    .map((file) => buildPublicAssetUrlFromRelativePath(file.filePath))
  const premiumImages = bundle.files
    .filter((file) => file.category === 'PREMIUM')
    .map((file) => buildPublicAssetUrlFromRelativePath(file.filePath))
  const detailImages = bundle.files
    .filter((file) => file.category === 'DETAILS')
    .map((file) => buildPublicAssetUrlFromRelativePath(file.filePath))
  const interiorImages = bundle.files
    .filter((file) => file.category === 'INTERIOR')
    .map((file) => buildPublicAssetUrlFromRelativePath(file.filePath))
  const exteriorImages = bundle.files
    .filter((file) => file.category === 'EXTERIOR')
    .map((file) => buildPublicAssetUrlFromRelativePath(file.filePath))
  const otherImages = bundle.files
    .filter((file) => file.category === 'OTHER')
    .map((file) => buildPublicAssetUrlFromRelativePath(file.filePath))
  const specFile = bundle.files.find(
    (file) => file.category === 'SPEC_PDF' && file.powertrainType === resolvedPowertrain,
  ) ?? bundle.files.find((file) => file.category === 'SPEC_PDF' && file.powertrainType === null)
    ?? bundle.files.find((file) => file.category === 'SPEC_PDF')
    ?? null

  return {
    logoUrl: logoFile ? buildPublicAssetUrlFromRelativePath(logoFile.filePath) : LOGO_URL,
    modelKey: normalizeValue(input.modelName ?? parsedCatalogKey?.model ?? ''),
    folderName: null,
    specPdfUrl: specFile ? buildPublicAssetUrlFromRelativePath(specFile.filePath) : null,
    images: {
      premium: [...primaryImages, ...premiumImages],
      details: detailImages,
      interior: interiorImages,
      exterior: exteriorImages,
      other: otherImages,
    },
  }
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

export async function getOfferAssetBundle(input: string | null | undefined | OfferAssetLookupInput): Promise<OfferAssetBundle> {
  const lookup = typeof input === 'string' || input === null || input === undefined
    ? { modelName: input ?? null }
    : input

  const databaseBundle = await getDatabaseAssetBundle(lookup)

  if (databaseBundle) {
    return databaseBundle
  }

  const modelName = lookup.modelName
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