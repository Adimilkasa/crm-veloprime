import 'server-only'

import { Prisma, PowertrainType, SalesModelStatus, SalesPricingStatus } from '@prisma/client'

import sharedOfferAssetManifest from '../../client/veloprime_hybrid_app/assets/offers/asset_manifest.json'

import type { SharedDetailedPricingCatalogItem } from '@/lib/offer-calculations-shared'
import { buildModelColorPaletteKey, listColorPalettes, type ModelColorPalette } from '@/lib/color-management'
import { db } from '@/lib/db'
import { buildDetailedPricingCatalog } from '@/lib/pricing-catalog'
import { getActivePricingSheet } from '@/lib/pricing-management'
import {
  buildDerivedPricing,
  buildStableCatalogCode,
  calculateNetFromGross,
  DEFAULT_VAT_RATE,
  SALES_ASSET_CATEGORIES,
} from '@/lib/sales-catalog-model'

type LegacyOfferAssetManifestEntry = {
  aliases: string[]
  folderName: string
  specFileName: string
  preferredPremiumFileName?: string
  images: {
    premium: string[]
    details: string[]
    interior: string[]
    exterior: string[]
    other: string[]
  }
}

export type SalesCatalogRuntimeItem = SharedDetailedPricingCatalogItem

export type SalesCatalogSyncSummary = {
  brands: number
  models: number
  versions: number
  pricingRecords: number
  colors: number
  assetBundles: number
  assetFiles: number
}

export type SalesCatalogBootstrapBrand = {
  code: string
  name: string
  sortOrder: number
}

export type SalesCatalogBootstrapModel = {
  brandCode: string
  code: string
  name: string
  marketingName: string | null
  status: 'ACTIVE' | 'ARCHIVED'
  sortOrder: number
  availablePowertrains: PowertrainType[]
}

export type SalesCatalogBootstrapVersion = {
  catalogKey: string
  brandCode: string
  modelCode: string
  code: string
  name: string
  year: number | null
  powertrainType: PowertrainType | null
  powerHp: string | null
  systemPowerHp: number | null
  batteryCapacityKwh: number | null
  combustionEnginePowerHp: number | null
  engineDisplacementCc: number | null
  driveType: string | null
  rangeKm: number | null
  notes: string | null
}

export type SalesCatalogBootstrapAssetSummary = {
  brandCode: string | null
  modelCode: string
  modelName: string
  assetsVersionTag: string | null
  totalFiles: number
  categories: Record<(typeof SALES_ASSET_CATEGORIES)[number], number>
  specPowertrains: PowertrainType[]
  hasGenericSpecPdf: boolean
  source: 'DATABASE' | 'LEGACY'
}

export type SalesCatalogBootstrapPayload = {
  brands: SalesCatalogBootstrapBrand[]
  models: SalesCatalogBootstrapModel[]
  versions: SalesCatalogBootstrapVersion[]
  pricingRecords: SalesCatalogRuntimeItem[]
  colorPalettes: ModelColorPalette[]
  assetBundles: SalesCatalogBootstrapAssetSummary[]
  stats: {
    brands: number
    models: number
    versions: number
    pricingRecords: number
    colorPalettes: number
    colors: number
    assetBundles: number
    assetFiles: number
  }
}

const LEGACY_ASSET_MANIFEST = sharedOfferAssetManifest as LegacyOfferAssetManifestEntry[]

function toNumber(value: Prisma.Decimal | number | null | undefined) {
  if (value === null || value === undefined) {
    return null
  }

  if (typeof value === 'number') {
    return Number.isFinite(value) ? value : null
  }

  return value.toNumber()
}

function normalizeText(value: string | null | undefined) {
  return value?.trim() ?? ''
}

function normalizeLookup(value: string | null | undefined) {
  return normalizeText(value)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z0-9]+/g, ' ')
    .trim()
    .toLowerCase()
}

function buildCatalogKey(brand: string, model: string, version: string, year: string | null) {
  return [brand, model, version, year || ''].join('::').toLowerCase()
}

function normalizePowerHpLabel(value: number | null) {
  if (value === null || value <= 0) {
    return null
  }

  return `${value} KM`
}

function buildCatalogLabel(item: Pick<SalesCatalogRuntimeItem, 'brand' | 'model' | 'version' | 'year'>) {
  return [item.brand, item.model, item.version, item.year].filter(Boolean).join(' / ')
}

function createEmptyAssetCategoryCounts() {
  return {
    PRIMARY: 0,
    EXTERIOR: 0,
    INTERIOR: 0,
    DETAILS: 0,
    PREMIUM: 0,
    SPEC_PDF: 0,
    LOGO: 0,
    OTHER: 0,
  } satisfies Record<(typeof SALES_ASSET_CATEGORIES)[number], number>
}

const salesAssetBootstrapFileSelect = {
  category: true,
  powertrainType: true,
} satisfies Prisma.SalesAssetFileSelect

function salesAssetBootstrapFileArgs() {
  return {
    select: salesAssetBootstrapFileSelect,
    orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }, { fileName: 'asc' }],
  } satisfies Prisma.SalesModelAssetBundle$filesArgs
}

function toRuntimePowertrain(value: string | null | undefined) {
  if (!value) {
    return null
  }

  if (value === PowertrainType.ELECTRIC || value === PowertrainType.HYBRID || value === PowertrainType.ICE) {
    return value
  }

  return parseLegacyPowertrainType(value)
}

function resolvePricingPriority(
  record: Pick<
    Prisma.SalesVersionPricingGetPayload<{}>,
    'pricingStatus' | 'effectiveFrom' | 'effectiveTo' | 'createdAt'
  >,
  now: Date
) {
  const startsOnOrBeforeNow = !record.effectiveFrom || record.effectiveFrom.getTime() <= now.getTime()
  const endsOnOrAfterNow = !record.effectiveTo || record.effectiveTo.getTime() >= now.getTime()
  const isActiveNow = startsOnOrBeforeNow && endsOnOrAfterNow

  if (record.pricingStatus === SalesPricingStatus.PUBLISHED && isActiveNow) {
    return 0
  }

  if (record.pricingStatus === SalesPricingStatus.PUBLISHED) {
    return 1
  }

  if (record.pricingStatus === SalesPricingStatus.DRAFT && isActiveNow) {
    return 2
  }

  if (record.pricingStatus === SalesPricingStatus.DRAFT) {
    return 3
  }

  return 4
}

function selectPreferredPricing(
  records: Array<
    Pick<
      Prisma.SalesVersionPricingGetPayload<{}>,
      | 'pricingStatus'
      | 'effectiveFrom'
      | 'effectiveTo'
      | 'createdAt'
      | 'listPriceGross'
      | 'listPriceNet'
      | 'basePriceGross'
      | 'basePriceNet'
      | 'marginPoolGross'
      | 'marginPoolNet'
    >
  >
) {
  const now = new Date()

  return [...records].sort((left, right) => {
    const priorityDiff = resolvePricingPriority(left, now) - resolvePricingPriority(right, now)

    if (priorityDiff !== 0) {
      return priorityDiff
    }

    const leftEffective = left.effectiveFrom?.getTime() ?? 0
    const rightEffective = right.effectiveFrom?.getTime() ?? 0

    if (rightEffective !== leftEffective) {
      return rightEffective - leftEffective
    }

    return right.createdAt.getTime() - left.createdAt.getTime()
  })[0] ?? null
}

function mapLegacyItem(item: SalesCatalogRuntimeItem): SalesCatalogRuntimeItem {
  return {
    ...item,
    label: buildCatalogLabel(item),
  }
}

function mapDbItem(input: {
  brandName: string
  modelName: string
  versionName: string
  year: number | null
  powertrainType: PowertrainType
  systemPowerHp: number | null
  pricing: {
    listPriceGross: Prisma.Decimal
    listPriceNet: Prisma.Decimal
    basePriceGross: Prisma.Decimal
    basePriceNet: Prisma.Decimal
    marginPoolGross: Prisma.Decimal
    marginPoolNet: Prisma.Decimal
  } | null
}) {
  const year = input.year !== null ? String(input.year) : null

  const item: SalesCatalogRuntimeItem = {
    key: buildCatalogKey(input.brandName, input.modelName, input.versionName, year),
    brand: input.brandName,
    model: input.modelName,
    version: input.versionName,
    year,
    powertrain: input.powertrainType,
    powerHp: normalizePowerHpLabel(input.systemPowerHp),
    listPriceGross: input.pricing ? toNumber(input.pricing.listPriceGross) : null,
    listPriceNet: input.pricing ? toNumber(input.pricing.listPriceNet) : null,
    basePriceGross: input.pricing ? toNumber(input.pricing.basePriceGross) : null,
    basePriceNet: input.pricing ? toNumber(input.pricing.basePriceNet) : null,
    marginPoolGross: input.pricing ? toNumber(input.pricing.marginPoolGross) : null,
    marginPoolNet: input.pricing ? toNumber(input.pricing.marginPoolNet) : null,
    label: '',
  }

  return mapLegacyItem(item)
}

function parseLegacyPowertrainType(value: string | null) {
  const normalized = normalizeLookup(value)

  if (!normalized) {
    return PowertrainType.ICE
  }

  if (normalized.includes('hybrid') || normalized.includes('hybryda') || normalized.includes('dm i') || normalized.includes('dmi')) {
    return PowertrainType.HYBRID
  }

  if (normalized.includes('electric') || normalized.includes('elektryk') || normalized === 'ev') {
    return PowertrainType.ELECTRIC
  }

  return PowertrainType.ICE
}

function parseLegacyPowerHp(value: string | null) {
  const match = normalizeText(value).match(/\d+/)

  if (!match) {
    return null
  }

  const parsed = Number(match[0])
  return Number.isFinite(parsed) ? parsed : null
}

function parseLegacyYear(value: string | null) {
  const parsed = Number(normalizeText(value))
  return Number.isFinite(parsed) ? parsed : null
}

function inferMimeType(fileName: string) {
  const normalized = fileName.toLowerCase()

  if (normalized.endsWith('.png')) {
    return 'image/png'
  }

  if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
    return 'image/jpeg'
  }

  if (normalized.endsWith('.webp')) {
    return 'image/webp'
  }

  if (normalized.endsWith('.pdf')) {
    return 'application/pdf'
  }

  return null
}

function getAssetManifestForModel(modelName: string) {
  const normalizedModel = ` ${normalizeLookup(modelName)} `
  let bestMatch: LegacyOfferAssetManifestEntry | null = null
  let bestMatchLength = -1

  for (const entry of LEGACY_ASSET_MANIFEST) {
    for (const alias of entry.aliases) {
      const normalizedAlias = normalizeLookup(alias)

      if (!normalizedAlias || !normalizedModel.includes(` ${normalizedAlias} `)) {
        continue
      }

      if (normalizedAlias.length > bestMatchLength) {
        bestMatch = entry
        bestMatchLength = normalizedAlias.length
      }
    }
  }

  return bestMatch
}

async function readCatalogFromDatabase() {
  if (!db) {
    return []
  }

  const brands = await db.salesBrand.findMany({
    orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    include: {
      models: {
        where: {
          status: SalesModelStatus.ACTIVE,
        },
        orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
        include: {
          versions: {
            orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
            include: {
              pricingRecords: true,
            },
          },
        },
      },
    },
  })

  const catalogItems: SalesCatalogRuntimeItem[] = []

  for (const brand of brands) {
    for (const model of brand.models) {
      for (const version of model.versions) {
        catalogItems.push(
          mapDbItem({
            brandName: brand.name,
            modelName: model.name,
            versionName: version.name,
            year: version.year,
            powertrainType: version.powertrainType,
            systemPowerHp: version.systemPowerHp,
            pricing: selectPreferredPricing(version.pricingRecords),
          })
        )
      }
    }
  }

  return catalogItems.filter((item) => item.listPriceNet !== null || item.basePriceNet !== null)
}

async function readColorPalettesFromDatabase() {
  if (!db) {
    return []
  }

  const models = await db.salesModel.findMany({
    where: {
      status: SalesModelStatus.ACTIVE,
    },
    orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    include: {
      brand: true,
      colors: {
        orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      },
    },
  })

  return models
    .filter((model) => model.colors.length > 0)
    .reduce<ModelColorPalette[]>((palettes, model) => {
      const baseColor = model.colors.find((color) => color.isBaseColor) ?? model.colors[0] ?? null

      if (!baseColor) {
        return palettes
      }

      palettes.push({
        paletteKey: buildModelColorPaletteKey(model.brand.name, model.name),
        brandCode: model.brand.code,
        modelCode: model.code,
        brand: model.brand.name,
        model: model.name,
        baseColorName: baseColor.name,
        optionalColorSurchargeGross: null,
        optionalColorSurchargeNet: null,
        colors: model.colors.map((color) => ({
          name: color.name,
          isBase: color.isBaseColor,
          surchargeGross: toNumber(color.surchargeGross),
          surchargeNet: toNumber(color.surchargeNet),
          sortOrder: color.sortOrder,
        })),
      })

      return palettes
    }, [])
}

async function readAssetBundlesFromDatabase() {
  if (!db) {
    return []
  }

  const bundles = await db.salesModelAssetBundle.findMany({
    where: {
      isActive: true,
      model: {
        status: SalesModelStatus.ACTIVE,
      },
    },
    orderBy: [{ updatedAt: 'desc' }],
    include: {
      model: {
        include: {
          brand: true,
        },
      },
      files: salesAssetBootstrapFileArgs(),
    },
  })

  return bundles.map((bundle) => {
    const categories = createEmptyAssetCategoryCounts()
    const specPowertrains = new Set<PowertrainType>()
    let hasGenericSpecPdf = false

    for (const file of bundle.files) {
      categories[file.category] += 1

      if (file.category === 'SPEC_PDF') {
        if (file.powertrainType) {
          specPowertrains.add(file.powertrainType)
        } else {
          hasGenericSpecPdf = true
        }
      }
    }

    return {
      brandCode: bundle.model.brand.code,
      modelCode: bundle.model.code,
      modelName: bundle.model.name,
      assetsVersionTag: bundle.assetsVersionTag,
      totalFiles: bundle.files.length,
      categories,
      specPowertrains: [...specPowertrains].sort(),
      hasGenericSpecPdf,
      source: 'DATABASE' as const,
    } satisfies SalesCatalogBootstrapAssetSummary
  })
}

function buildLegacyAssetBundles(catalogItems: SalesCatalogRuntimeItem[]) {
  const identityByModelLookup = new Map(
    catalogItems.map((item) => [normalizeLookup(item.model), item] as const)
  )

  return LEGACY_ASSET_MANIFEST.map((entry) => {
    const matchedCatalogItem = entry.aliases
      .map((alias) => identityByModelLookup.get(normalizeLookup(alias)))
      .find((item) => item)
      ?? identityByModelLookup.get(normalizeLookup(entry.aliases[0] ?? ''))
      ?? null

    const modelName = matchedCatalogItem?.model ?? normalizeText(entry.aliases[0] ?? entry.folderName)
    const categories = createEmptyAssetCategoryCounts()
    const primaryImage = entry.preferredPremiumFileName
      ?? entry.images.premium[0]
      ?? entry.images.exterior[0]
      ?? null

    categories.PRIMARY = primaryImage ? 1 : 0
    categories.PREMIUM = entry.images.premium.length
    categories.DETAILS = entry.images.details.length
    categories.INTERIOR = entry.images.interior.length
    categories.EXTERIOR = entry.images.exterior.length
    categories.OTHER = entry.images.other.length
    categories.SPEC_PDF = entry.specFileName ? 1 : 0

    const totalFiles = Object.values(categories).reduce((sum, value) => sum + value, 0)

    return {
      brandCode: matchedCatalogItem ? buildStableCatalogCode(matchedCatalogItem.brand) : null,
      modelCode: buildStableCatalogCode(modelName),
      modelName,
      assetsVersionTag: null,
      totalFiles,
      categories,
      specPowertrains: [],
      hasGenericSpecPdf: Boolean(entry.specFileName),
      source: 'LEGACY' as const,
    } satisfies SalesCatalogBootstrapAssetSummary
  })
}

function enrichColorPalettesWithCatalogCodes(
  palettes: ModelColorPalette[],
  catalogItems: SalesCatalogRuntimeItem[]
) {
  const identityByPaletteKey = new Map(
    catalogItems.map((item) => [
      buildModelColorPaletteKey(item.brand, item.model),
      {
        brandCode: buildStableCatalogCode(item.brand),
        modelCode: buildStableCatalogCode(item.model),
      },
    ] as const)
  )

  return palettes.map((palette) => {
    const identity = identityByPaletteKey.get(palette.paletteKey)

    if (!identity) {
      return palette
    }

    return {
      ...palette,
      brandCode: palette.brandCode ?? identity.brandCode,
      modelCode: palette.modelCode ?? identity.modelCode,
    }
  })
}

async function readCatalogBootstrapFromDatabase(): Promise<SalesCatalogBootstrapPayload | null> {
  if (!db) {
    return null
  }

  const [brands, models, versions, colorPalettes, assetBundles] = await Promise.all([
    db.salesBrand.findMany({
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    }),
    db.salesModel.findMany({
      where: { status: SalesModelStatus.ACTIVE },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      include: {
        brand: true,
        versions: {
          select: {
            powertrainType: true,
          },
        },
      },
    }),
    db.salesVersion.findMany({
      where: {
        model: {
          status: SalesModelStatus.ACTIVE,
        },
      },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      include: {
        model: {
          include: {
            brand: true,
          },
        },
        pricingRecords: true,
      },
    }),
    readColorPalettesFromDatabase(),
    readAssetBundlesFromDatabase(),
  ])

  if (brands.length === 0 && models.length === 0 && versions.length === 0) {
    return null
  }

  const pricingRecords = versions
    .map((version) =>
      mapDbItem({
        brandName: version.model.brand.name,
        modelName: version.model.name,
        versionName: version.name,
        year: version.year,
        powertrainType: version.powertrainType,
        systemPowerHp: version.systemPowerHp,
        pricing: selectPreferredPricing(version.pricingRecords),
      })
    )
    .filter((item) => item.listPriceNet !== null || item.basePriceNet !== null)

  const assetFiles = assetBundles.reduce((sum, bundle) => sum + bundle.totalFiles, 0)

  return {
    brands: brands.map((brand) => ({
      code: brand.code,
      name: brand.name,
      sortOrder: brand.sortOrder,
    })),
    models: models.map((model) => ({
      brandCode: model.brand.code,
      code: model.code,
      name: model.name,
      marketingName: model.marketingName,
      status: model.status,
      sortOrder: model.sortOrder,
      availablePowertrains: [...new Set(model.versions.map((version) => version.powertrainType))].sort(),
    })),
    versions: versions.map((version) => ({
      catalogKey: buildCatalogKey(version.model.brand.name, version.model.name, version.name, version.year !== null ? String(version.year) : null),
      brandCode: version.model.brand.code,
      modelCode: version.model.code,
      code: version.code,
      name: version.name,
      year: version.year,
      powertrainType: version.powertrainType,
      powerHp: normalizePowerHpLabel(version.systemPowerHp),
      systemPowerHp: version.systemPowerHp,
      batteryCapacityKwh: toNumber(version.batteryCapacityKwh),
      combustionEnginePowerHp: version.combustionEnginePowerHp,
      engineDisplacementCc: version.engineDisplacementCc,
      driveType: version.driveType,
      rangeKm: version.rangeKm,
      notes: version.notes,
    })),
    pricingRecords,
    colorPalettes,
    assetBundles,
    stats: {
      brands: brands.length,
      models: models.length,
      versions: versions.length,
      pricingRecords: pricingRecords.length,
      colorPalettes: colorPalettes.length,
      colors: colorPalettes.reduce((sum, palette) => sum + palette.colors.length, 0),
      assetBundles: assetBundles.length,
      assetFiles,
    },
  }
}

export async function listSalesCatalogItems() {
  try {
    return await readCatalogFromDatabase()
  } catch {
    return []
  }
}

export async function findSalesCatalogItemByKey(key: string) {
  const catalog = await listSalesCatalogItems()
  return catalog.find((item) => item.key === key) ?? null
}

export async function listSalesModelColorPalettes() {
  try {
    return await readColorPalettesFromDatabase()
  } catch {
    return []
  }
}

export async function syncLegacyCatalogItemsToDb(catalogItems: SalesCatalogRuntimeItem[]) {
  if (!db) {
    return new Map<string, string>()
  }

  const idsByKey = new Map<string, string>()

  for (const item of catalogItems) {
    const brandSetting = await db.brandSetting.upsert({
      where: { brand: item.brand },
      update: {
        isActive: true,
      },
      create: {
        brand: item.brand,
      },
    })

    const existing = await db.salesCatalogItem.findFirst({
      where: {
        brand: item.brand,
        model: item.model,
        version: item.version,
        year: item.year,
      },
    })

    const record = existing
      ? await db.salesCatalogItem.update({
          where: { id: existing.id },
          data: {
            powertrain: item.powertrain,
            powerHp: item.powerHp,
            listPriceGross: item.listPriceGross,
            listPriceNet: item.listPriceNet,
            basePriceGross: item.basePriceGross,
            basePriceNet: item.basePriceNet,
            isActive: true,
            brandSettingId: brandSetting.id,
          },
        })
      : await db.salesCatalogItem.create({
          data: {
            brand: item.brand,
            model: item.model,
            version: item.version,
            year: item.year,
            powertrain: item.powertrain,
            powerHp: item.powerHp,
            listPriceGross: item.listPriceGross,
            listPriceNet: item.listPriceNet,
            basePriceGross: item.basePriceGross,
            basePriceNet: item.basePriceNet,
            isActive: true,
            brandSettingId: brandSetting.id,
          },
        })

    idsByKey.set(item.key, record.id)
  }

  return idsByKey
}

export async function syncLegacySalesCatalogToDatabase() {
  if (!db) {
    return { ok: false as const, error: 'Brak aktywnego połączenia z bazą danych.' }
  }

  const [pricingSheet, legacyPalettes] = await Promise.all([
    getActivePricingSheet(),
    listColorPalettes(),
  ])

  const legacyCatalog = buildDetailedPricingCatalog(pricingSheet).map(mapLegacyItem)
  const summary: SalesCatalogSyncSummary = {
    brands: 0,
    models: 0,
    versions: 0,
    pricingRecords: 0,
    colors: 0,
    assetBundles: 0,
    assetFiles: 0,
  }

  const brandCache = new Map<string, string>()
  const modelCache = new Map<string, string>()
  const versionCache = new Map<string, string>()

  for (const [index, item] of legacyCatalog.entries()) {
    const brandKey = normalizeLookup(item.brand)
    let brandId = brandCache.get(brandKey)

    if (!brandId) {
      const brand = await db.salesBrand.upsert({
        where: { code: buildStableCatalogCode(item.brand) },
        update: {
          name: item.brand,
          sortOrder: brandCache.size,
        },
        create: {
          code: buildStableCatalogCode(item.brand),
          name: item.brand,
          sortOrder: brandCache.size,
        },
      })

      brandId = brand.id
      brandCache.set(brandKey, brand.id)
    }

    const modelKey = `${brandKey}::${normalizeLookup(item.model)}`
    let modelId = modelCache.get(modelKey)

    if (!modelId) {
      const model = await db.salesModel.upsert({
        where: {
          brandId_code: {
            brandId,
            code: buildStableCatalogCode(item.model),
          },
        },
        update: {
          name: item.model,
          status: SalesModelStatus.ACTIVE,
          sortOrder: modelCache.size,
        },
        create: {
          brandId,
          code: buildStableCatalogCode(item.model),
          name: item.model,
          status: SalesModelStatus.ACTIVE,
          sortOrder: modelCache.size,
        },
      })

      modelId = model.id
      modelCache.set(modelKey, model.id)
    }

    const powertrainType = parseLegacyPowertrainType(item.powertrain)
    const versionCode = buildStableCatalogCode(item.version, item.year, powertrainType)
    const versionKey = `${modelKey}::${versionCode}`
    let versionId = versionCache.get(versionKey)

    if (!versionId) {
      const version = await db.salesVersion.upsert({
        where: {
          modelId_code: {
            modelId,
            code: versionCode,
          },
        },
        update: {
          name: item.version,
          year: parseLegacyYear(item.year),
          powertrainType,
          systemPowerHp: parseLegacyPowerHp(item.powerHp),
          sortOrder: index,
        },
        create: {
          modelId,
          code: versionCode,
          name: item.version,
          year: parseLegacyYear(item.year),
          powertrainType,
          systemPowerHp: parseLegacyPowerHp(item.powerHp),
          sortOrder: index,
        },
      })

      versionId = version.id
      versionCache.set(versionKey, version.id)
    }

    const listPriceNet = item.listPriceNet ?? (item.listPriceGross !== null ? calculateNetFromGross(item.listPriceGross, DEFAULT_VAT_RATE) : null)
    const basePriceNet = item.basePriceNet ?? (item.basePriceGross !== null ? calculateNetFromGross(item.basePriceGross, DEFAULT_VAT_RATE) : null)

    if (listPriceNet !== null && basePriceNet !== null) {
      const derivedPricing = buildDerivedPricing({
        listPriceNet,
        basePriceNet,
        pricingStatus: 'PUBLISHED',
      })

      const currentPricing = await db.salesVersionPricing.findFirst({
        where: {
          versionId,
          pricingStatus: SalesPricingStatus.PUBLISHED,
          effectiveFrom: null,
          effectiveTo: null,
        },
      })

      if (currentPricing) {
        await db.salesVersionPricing.update({
          where: { id: currentPricing.id },
          data: derivedPricing,
        })
      } else {
        await db.salesVersionPricing.create({
          data: {
            versionId,
            ...derivedPricing,
          },
        })
      }

      summary.pricingRecords += 1
    }
  }

  for (const palette of legacyPalettes) {
    const brandKey = normalizeLookup(palette.brand)
    let brandId = brandCache.get(brandKey)

    if (!brandId) {
      const brand = await db.salesBrand.upsert({
        where: { code: buildStableCatalogCode(palette.brand) },
        update: {
          name: palette.brand,
        },
        create: {
          code: buildStableCatalogCode(palette.brand),
          name: palette.brand,
        },
      })

      brandId = brand.id
      brandCache.set(brandKey, brand.id)
    }

    const modelKey = `${brandKey}::${normalizeLookup(palette.model)}`
    let modelId = modelCache.get(modelKey)

    if (!modelId) {
      const model = await db.salesModel.upsert({
        where: {
          brandId_code: {
            brandId,
            code: buildStableCatalogCode(palette.model),
          },
        },
        update: {
          name: palette.model,
          status: SalesModelStatus.ACTIVE,
        },
        create: {
          brandId,
          code: buildStableCatalogCode(palette.model),
          name: palette.model,
          status: SalesModelStatus.ACTIVE,
        },
      })

      modelId = model.id
      modelCache.set(modelKey, model.id)
    }

    for (const [index, color] of palette.colors.entries()) {
      const surchargeNet = color.surchargeNet ?? (color.surchargeGross !== null ? calculateNetFromGross(color.surchargeGross, DEFAULT_VAT_RATE) : null)
      const surchargeGross = color.surchargeGross ?? (surchargeNet !== null ? surchargeNet * (1 + DEFAULT_VAT_RATE / 100) : null)

      await db.salesModelColor.upsert({
        where: {
          modelId_code: {
            modelId,
            code: buildStableCatalogCode(color.name),
          },
        },
        update: {
          name: color.name,
          isBaseColor: color.isBase,
          hasSurcharge: (surchargeNet ?? 0) > 0 || (surchargeGross ?? 0) > 0,
          surchargeNet,
          surchargeGross,
          sortOrder: index,
        },
        create: {
          modelId,
          code: buildStableCatalogCode(color.name),
          name: color.name,
          isBaseColor: color.isBase,
          hasSurcharge: (surchargeNet ?? 0) > 0 || (surchargeGross ?? 0) > 0,
          surchargeNet,
          surchargeGross,
          sortOrder: index,
        },
      })

      summary.colors += 1
    }

    const assetManifest = getAssetManifestForModel(palette.model)

    if (!assetManifest) {
      continue
    }

    const bundle = await db.salesModelAssetBundle.upsert({
      where: { modelId },
      update: {
        isActive: true,
      },
      create: {
        modelId,
        isActive: true,
      },
    })

    await db.salesAssetFile.deleteMany({
      where: { bundleId: bundle.id },
    })

    const files = [] as Prisma.SalesAssetFileCreateManyInput[]
    const primaryImage = assetManifest.preferredPremiumFileName
      ?? assetManifest.images.premium[0]
      ?? assetManifest.images.exterior[0]
      ?? null

    if (primaryImage) {
      files.push({
        bundleId: bundle.id,
        category: 'PRIMARY',
        powertrainType: null,
        fileName: primaryImage,
        filePath: `grafiki/${assetManifest.folderName}/${primaryImage}`,
        mimeType: inferMimeType(primaryImage),
        sortOrder: 0,
      })
    }

    const pushCategoryFiles = (
      category: 'PREMIUM' | 'DETAILS' | 'INTERIOR' | 'EXTERIOR' | 'OTHER',
      fileNames: string[]
    ) => {
      for (const [index, fileName] of fileNames.entries()) {
        files.push({
          bundleId: bundle.id,
          category,
          powertrainType: null,
          fileName,
          filePath: `grafiki/${assetManifest.folderName}/${fileName}`,
          mimeType: inferMimeType(fileName),
          sortOrder: index,
        })
      }
    }

    pushCategoryFiles('PREMIUM', assetManifest.images.premium)
    pushCategoryFiles('DETAILS', assetManifest.images.details)
    pushCategoryFiles('INTERIOR', assetManifest.images.interior)
    pushCategoryFiles('EXTERIOR', assetManifest.images.exterior)
    pushCategoryFiles('OTHER', assetManifest.images.other)

    files.push({
      bundleId: bundle.id,
      category: 'SPEC_PDF',
      powertrainType: null,
      fileName: assetManifest.specFileName,
      filePath: `spec/${assetManifest.specFileName}`,
      mimeType: inferMimeType(assetManifest.specFileName),
      sortOrder: 0,
    })

    if (files.length > 0) {
      await db.salesAssetFile.createMany({ data: files })
      summary.assetBundles += 1
      summary.assetFiles += files.length
    }
  }

  summary.brands = brandCache.size
  summary.models = modelCache.size
  summary.versions = versionCache.size

  return {
    ok: true as const,
    summary,
  }
}

export async function listSalesAssetBundles() {
  try {
    return await readAssetBundlesFromDatabase()
  } catch {
    return []
  }
}

export async function getSalesCatalogBootstrap() {
  try {
    const databaseBootstrap = await readCatalogBootstrapFromDatabase()

    if (databaseBootstrap) {
      return databaseBootstrap
    }
  } catch {
    // Ignore and return an empty bootstrap below.
  }

  return {
    brands: [],
    models: [],
    versions: [],
    pricingRecords: [],
    colorPalettes: [],
    assetBundles: [],
    stats: {
      brands: 0,
      models: 0,
      versions: 0,
      pricingRecords: 0,
      colorPalettes: 0,
      colors: 0,
      assetBundles: 0,
      assetFiles: 0,
    },
  } satisfies SalesCatalogBootstrapPayload
}