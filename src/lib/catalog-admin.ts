import 'server-only'

import { AssetCategory, DriveType, PowertrainType, Prisma, SalesModelStatus, SalesPricingStatus } from '@prisma/client'
import { deleteBlobIfManaged } from '@/lib/blob-storage'

import sharedOfferAssetManifest from '../../client/veloprime_hybrid_app/assets/offers/asset_manifest.json'

import {
  buildDerivedPricing,
  buildStableCatalogCode,
  calculateGrossFromNet,
  collectModelPowertrainTypes,
  DEFAULT_VAT_RATE,
  SALES_ASSET_CATEGORIES,
  SALES_DRIVE_TYPES,
  SALES_MODEL_STATUSES,
  SALES_POWERTRAIN_TYPES,
  SALES_PRICING_STATUSES,
  type SalesAssetCategory,
  type SalesBrandRecord,
  type SalesDriveType,
  type SalesModelAssetBundleRecord,
  type SalesModelColorRecord,
  type SalesModelRecord,
  type SalesModelStatus as SalesModelStatusValue,
  type SalesPowertrainType,
  type SalesPricingStatus as SalesPricingStatusValue,
  type SalesVersionPricingRecord,
  type SalesVersionRecord,
} from '@/lib/sales-catalog-model'
import { db } from '@/lib/db'
import {
  getSalesCatalogBootstrap,
  syncLegacySalesCatalogToDatabase,
  type SalesCatalogBootstrapPayload,
  type SalesCatalogSyncSummary,
} from '@/lib/sales-catalog-management'

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

type CatalogAdminSuccess<T> = {
  ok: true
  data: T
}

type CatalogAdminFailure = {
  ok: false
  error: string
  status: number
}

export type CatalogAdminResult<T> = CatalogAdminSuccess<T> | CatalogAdminFailure

export type SalesCatalogWorkspace = {
  databaseReady: boolean
  source: 'database' | 'legacy-fallback'
  brands: SalesBrandRecord[]
  models: SalesModelRecord[]
  versions: SalesVersionRecord[]
  pricingRecords: SalesVersionPricingRecord[]
  colors: SalesModelColorRecord[]
  assetBundles: SalesModelAssetBundleRecord[]
  dictionaries: {
    modelStatuses: readonly SalesModelStatusValue[]
    powertrainTypes: readonly SalesPowertrainType[]
    driveTypes: readonly SalesDriveType[]
    pricingStatuses: readonly SalesPricingStatusValue[]
    assetCategories: readonly SalesAssetCategory[]
    defaultVatRate: number
  }
  stats: {
    brands: number
    models: number
    versions: number
    pricingRecords: number
    colors: number
    assetBundles: number
    assetFiles: number
  }
}

export type SalesCatalogSyncStatus = {
  databaseReady: boolean
  stats: SalesCatalogWorkspace['stats']
}

const LEGACY_ASSET_MANIFEST = sharedOfferAssetManifest as LegacyOfferAssetManifestEntry[]

function ok<T>(data: T): CatalogAdminResult<T> {
  return { ok: true, data }
}

function fail<T>(error: string, status = 400): CatalogAdminResult<T> {
  return { ok: false, error, status }
}

function requireDb<T>(): CatalogAdminResult<T> | null {
  if (!db) {
    return fail('Administracja katalogiem wymaga aktywnego połączenia z bazą danych.', 503)
  }

  return null
}

function toNumber(value: Prisma.Decimal | number | null | undefined) {
  if (value === null || value === undefined) {
    return null
  }

  if (typeof value === 'number') {
    return Number.isFinite(value) ? value : null
  }

  return value.toNumber()
}

function normalizeString(value: unknown) {
  return typeof value === 'string' ? value.trim() : ''
}

function nullableString(value: unknown) {
  const normalized = normalizeString(value)
  return normalized.length > 0 ? normalized : null
}

function normalizeLookup(value: string | null | undefined) {
  return (value ?? '')
    .trim()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z0-9]+/g, ' ')
    .trim()
    .toLowerCase()
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

function findLegacyAssetManifestEntry(modelName: string) {
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

function buildLegacyAssetFiles(bundleId: string, modelName: string): SalesModelAssetBundleRecord['files'] {
  const manifest = findLegacyAssetManifestEntry(modelName)

  if (!manifest) {
    return []
  }

  const createdAt = new Date(0).toISOString()
  const files = [] as SalesModelAssetBundleRecord['files']
  const primaryImage = manifest.preferredPremiumFileName
    ?? manifest.images.premium[0]
    ?? manifest.images.exterior[0]
    ?? null

  if (primaryImage) {
    files.push({
      id: `${bundleId}:PRIMARY:0`,
      bundleId,
      category: 'PRIMARY',
      powertrainType: null,
      fileName: primaryImage,
      filePath: `grafiki/${manifest.folderName}/${primaryImage}`,
      mimeType: inferMimeType(primaryImage),
      sortOrder: 0,
      createdAt,
      updatedAt: createdAt,
    })
  }

  const pushFiles = (category: SalesModelAssetBundleRecord['files'][number]['category'], names: string[]) => {
    names.forEach((fileName, index) => {
      files.push({
        id: `${bundleId}:${category}:${index}`,
        bundleId,
        category,
        powertrainType: null,
        fileName,
        filePath: `grafiki/${manifest.folderName}/${fileName}`,
        mimeType: inferMimeType(fileName),
        sortOrder: index,
        createdAt,
        updatedAt: createdAt,
      })
    })
  }

  pushFiles('PREMIUM', manifest.images.premium)
  pushFiles('DETAILS', manifest.images.details)
  pushFiles('INTERIOR', manifest.images.interior)
  pushFiles('EXTERIOR', manifest.images.exterior)
  pushFiles('OTHER', manifest.images.other)

  if (manifest.specFileName) {
    files.push({
      id: `${bundleId}:SPEC_PDF:0`,
      bundleId,
      category: 'SPEC_PDF',
      powertrainType: null,
      fileName: manifest.specFileName,
      filePath: `spec/${manifest.specFileName}`,
      mimeType: inferMimeType(manifest.specFileName),
      sortOrder: 0,
      createdAt,
      updatedAt: createdAt,
    })
  }

  return files
}

function optionalNumber(value: unknown) {
  if (value === null || value === undefined || value === '') {
    return null
  }

  const parsed = typeof value === 'number' ? value : Number(String(value).replace(',', '.'))

  if (!Number.isFinite(parsed)) {
    return null
  }

  return parsed
}

function requiredTextField(input: Record<string, unknown>, key: string, error: string) {
  const value = normalizeString(input[key])
  return value.length > 0 ? value : error
}

function ensureEnumValue<T extends readonly string[]>(
  value: unknown,
  allowed: T,
  fallback: T[number] | null = null,
) {
  const normalized = normalizeString(value).toUpperCase()

  if (!normalized) {
    return fallback
  }

  return (allowed as readonly string[]).includes(normalized) ? (normalized as T[number]) : null
}

function buildPrismaDate(value: unknown) {
  const raw = nullableString(value)

  if (!raw) {
    return null
  }

  const parsed = new Date(raw)
  return Number.isNaN(parsed.getTime()) ? null : parsed
}

function mapBrandRecord(record: {
  id: string
  code: string
  name: string
  sortOrder: number
  createdAt: Date
  updatedAt: Date
}): SalesBrandRecord {
  return {
    id: record.id,
    code: record.code,
    name: record.name,
    sortOrder: record.sortOrder,
    createdAt: record.createdAt.toISOString(),
    updatedAt: record.updatedAt.toISOString(),
  }
}

function mapModelRecord(
  record: {
    id: string
    brandId: string
    code: string
    name: string
    marketingName: string | null
    status: SalesModelStatus
    sortOrder: number
    createdAt: Date
    updatedAt: Date
  },
  availablePowertrains: SalesPowertrainType[],
): SalesModelRecord {
  return {
    id: record.id,
    brandId: record.brandId,
    code: record.code,
    name: record.name,
    marketingName: record.marketingName,
    status: record.status,
    sortOrder: record.sortOrder,
    availablePowertrains,
    createdAt: record.createdAt.toISOString(),
    updatedAt: record.updatedAt.toISOString(),
  }
}

function mapVersionRecord(record: {
  id: string
  modelId: string
  code: string
  name: string
  year: number | null
  powertrainType: PowertrainType
  driveType: DriveType | null
  systemPowerHp: number | null
  batteryCapacityKwh: Prisma.Decimal | null
  combustionEnginePowerHp: number | null
  engineDisplacementCc: number | null
  rangeKm: number | null
  notes: string | null
  sortOrder: number
  createdAt: Date
  updatedAt: Date
}): SalesVersionRecord {
  return {
    id: record.id,
    modelId: record.modelId,
    code: record.code,
    name: record.name,
    year: record.year,
    powertrainType: record.powertrainType,
    driveType: record.driveType,
    systemPowerHp: record.systemPowerHp,
    batteryCapacityKwh: toNumber(record.batteryCapacityKwh),
    combustionEnginePowerHp: record.combustionEnginePowerHp,
    engineDisplacementCc: record.engineDisplacementCc,
    rangeKm: record.rangeKm,
    notes: record.notes,
    sortOrder: record.sortOrder,
    createdAt: record.createdAt.toISOString(),
    updatedAt: record.updatedAt.toISOString(),
  }
}

function mapPricingRecord(record: {
  id: string
  versionId: string
  listPriceNet: Prisma.Decimal
  listPriceGross: Prisma.Decimal
  basePriceNet: Prisma.Decimal
  basePriceGross: Prisma.Decimal
  vatRate: Prisma.Decimal
  marginPoolNet: Prisma.Decimal
  marginPoolGross: Prisma.Decimal
  pricingStatus: SalesPricingStatus
  effectiveFrom: Date | null
  effectiveTo: Date | null
  createdAt: Date
  updatedAt: Date
}): SalesVersionPricingRecord {
  return {
    id: record.id,
    versionId: record.versionId,
    listPriceNet: toNumber(record.listPriceNet) ?? 0,
    listPriceGross: toNumber(record.listPriceGross) ?? 0,
    basePriceNet: toNumber(record.basePriceNet) ?? 0,
    basePriceGross: toNumber(record.basePriceGross) ?? 0,
    vatRate: toNumber(record.vatRate) ?? DEFAULT_VAT_RATE,
    marginPoolNet: toNumber(record.marginPoolNet) ?? 0,
    marginPoolGross: toNumber(record.marginPoolGross) ?? 0,
    pricingStatus: record.pricingStatus,
    effectiveFrom: record.effectiveFrom?.toISOString() ?? null,
    effectiveTo: record.effectiveTo?.toISOString() ?? null,
    createdAt: record.createdAt.toISOString(),
    updatedAt: record.updatedAt.toISOString(),
  }
}

function mapColorRecord(record: {
  id: string
  modelId: string
  code: string
  name: string
  finishType: string | null
  isBaseColor: boolean
  hasSurcharge: boolean
  surchargeNet: Prisma.Decimal | null
  surchargeGross: Prisma.Decimal | null
  sortOrder: number
  createdAt: Date
  updatedAt: Date
}): SalesModelColorRecord {
  return {
    id: record.id,
    modelId: record.modelId,
    code: record.code,
    name: record.name,
    finishType: record.finishType,
    isBaseColor: record.isBaseColor,
    hasSurcharge: record.hasSurcharge,
    surchargeNet: toNumber(record.surchargeNet),
    surchargeGross: toNumber(record.surchargeGross),
    sortOrder: record.sortOrder,
    createdAt: record.createdAt.toISOString(),
    updatedAt: record.updatedAt.toISOString(),
  }
}

function mapAssetBundleRecord(record: {
  id: string
  modelId: string
  assetsVersionTag: string | null
  isActive: boolean
  createdAt: Date
  updatedAt: Date
  files: Array<{
    id: string
    bundleId: string
    category: AssetCategory
    powertrainType: PowertrainType | null
    fileName: string
    filePath: string
    fileDataBase64: string | null
    mimeType: string | null
    sortOrder: number
    createdAt: Date
    updatedAt: Date
  }>
}): SalesModelAssetBundleRecord {
  return {
    id: record.id,
    modelId: record.modelId,
    assetsVersionTag: record.assetsVersionTag,
    isActive: record.isActive,
    createdAt: record.createdAt.toISOString(),
    updatedAt: record.updatedAt.toISOString(),
    files: record.files.map((file) => ({
      id: file.id,
      bundleId: file.bundleId,
      category: file.category,
      powertrainType: file.powertrainType,
      fileName: file.fileName,
      filePath: file.filePath,
      mimeType: file.mimeType,
      sortOrder: file.sortOrder,
      createdAt: file.createdAt.toISOString(),
      updatedAt: file.updatedAt.toISOString(),
    })),
  }
}

function handleCatalogAdminError<T>(error: unknown, fallbackMessage: string): CatalogAdminResult<T> {
  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
    return fail('Taki rekord już istnieje w katalogu.', 409)
  }

  return fail(fallbackMessage, 500)
}

async function resolveNextSortOrder(table: 'brand' | 'model' | 'version' | 'color' | 'assetFile', parentId?: string) {
  if (!db) {
    return 0
  }

  switch (table) {
    case 'brand':
      return db.salesBrand.count()
    case 'model':
      return db.salesModel.count({ where: parentId ? { brandId: parentId } : undefined })
    case 'version':
      return db.salesVersion.count({ where: parentId ? { modelId: parentId } : undefined })
    case 'color':
      return db.salesModelColor.count({ where: parentId ? { modelId: parentId } : undefined })
    case 'assetFile':
      return db.salesAssetFile.count({ where: parentId ? { bundleId: parentId } : undefined })
  }
}

async function upsertAssetBundle(modelId: string, input: { assetsVersionTag?: string | null; isActive?: boolean }) {
  if (!db) {
    throw new Error('DB_UNAVAILABLE')
  }

  return db.salesModelAssetBundle.upsert({
    where: { modelId },
    update: {
      ...(input.assetsVersionTag !== undefined ? { assetsVersionTag: input.assetsVersionTag } : {}),
      ...(input.isActive !== undefined ? { isActive: input.isActive } : {}),
    },
    create: {
      modelId,
      assetsVersionTag: input.assetsVersionTag ?? null,
      isActive: input.isActive ?? true,
    },
    include: {
      files: {
        orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }, { fileName: 'asc' }],
      },
    },
  })
}

function validateVersionBusinessRules(input: {
  powertrainType: PowertrainType
  systemPowerHp: number | null
  batteryCapacityKwh: number | null
  engineDisplacementCc: number | null
}) {
  if (input.powertrainType === PowertrainType.HYBRID) {
    if (input.systemPowerHp === null) {
      return 'Dla hybrydy podaj moc główną układu.'
    }

    if (input.batteryCapacityKwh === null) {
      return 'Dla hybrydy podaj pojemność baterii.'
    }

    if (input.engineDisplacementCc === null) {
      return 'Dla hybrydy podaj pojemność silnika spalinowego.'
    }
  }

  if (input.powertrainType === PowertrainType.ELECTRIC) {
    if (input.systemPowerHp === null) {
      return 'Dla elektryka podaj moc układu.'
    }

    if (input.batteryCapacityKwh === null) {
      return 'Dla elektryka podaj pojemność baterii.'
    }
  }

  if (input.powertrainType === PowertrainType.ICE && input.engineDisplacementCc === null) {
    return 'Dla wersji spalinowej podaj pojemność silnika.'
  }

  return null
}

function validatePricing(input: { listPriceNet: number | null; basePriceNet: number | null; vatRate: number | null }) {
  if (input.listPriceNet === null || input.listPriceNet <= 0) {
    return 'Podaj poprawną cenę katalogową netto.'
  }

  if (input.basePriceNet === null || input.basePriceNet <= 0) {
    return 'Podaj poprawną cenę bazową netto.'
  }

  if (input.basePriceNet > input.listPriceNet) {
    return 'Cena bazowa netto nie może być wyższa od ceny katalogowej netto.'
  }

  if (input.vatRate !== null && input.vatRate < 0) {
    return 'Stawka VAT nie może być ujemna.'
  }

  return null
}

function validateColorInput(input: { hasSurcharge: boolean; surchargeNet: number | null }) {
  if (input.hasSurcharge && (input.surchargeNet === null || input.surchargeNet < 0)) {
    return 'Dla koloru płatnego podaj poprawną dopłatę netto.'
  }

  return null
}

function buildLegacyWorkspaceFromBootstrap(bootstrap: SalesCatalogBootstrapPayload): SalesCatalogWorkspace {
  const createdAt = new Date(0).toISOString()
  const brandIdsByCode = new Map<string, string>()
  const modelIdsByCode = new Map<string, string>()
  const versionIdsByCatalogKey = new Map<string, string>()

  const brands = bootstrap.brands.map((brand) => {
    const id = `legacy-brand:${brand.code}`
    brandIdsByCode.set(brand.code, id)

    return {
      id,
      code: brand.code,
      name: brand.name,
      sortOrder: brand.sortOrder,
      createdAt,
      updatedAt: createdAt,
    } satisfies SalesBrandRecord
  })

  const models = bootstrap.models.map((model) => {
    const id = `legacy-model:${model.code}`
    modelIdsByCode.set(model.code, id)

    return {
      id,
      brandId: brandIdsByCode.get(model.brandCode) ?? `legacy-brand:${model.brandCode}`,
      code: model.code,
      name: model.name,
      marketingName: model.marketingName,
      status: model.status,
      sortOrder: model.sortOrder,
      availablePowertrains: model.availablePowertrains,
      createdAt,
      updatedAt: createdAt,
    } satisfies SalesModelRecord
  })

  const versions = bootstrap.versions.map((version, index) => {
    const id = `legacy-version:${version.catalogKey}`
    versionIdsByCatalogKey.set(version.catalogKey, id)

    return {
      id,
      modelId: modelIdsByCode.get(version.modelCode) ?? `legacy-model:${version.modelCode}`,
      code: version.code,
      name: version.name,
      year: version.year,
      powertrainType: version.powertrainType ?? 'ICE',
      driveType: version.driveType as SalesVersionRecord['driveType'],
      systemPowerHp: version.systemPowerHp,
      batteryCapacityKwh: version.batteryCapacityKwh,
      combustionEnginePowerHp: version.combustionEnginePowerHp,
      engineDisplacementCc: version.engineDisplacementCc,
      rangeKm: version.rangeKm,
      notes: version.notes,
      sortOrder: index,
      createdAt,
      updatedAt: createdAt,
    } satisfies SalesVersionRecord
  })

  const pricingRecords = bootstrap.pricingRecords.map((record) => {
    const versionId = versionIdsByCatalogKey.get(record.key) ?? `legacy-version:${record.key}`
    const derived = buildDerivedPricing({
      listPriceNet: record.listPriceNet ?? 0,
      basePriceNet: record.basePriceNet ?? 0,
      vatRate: DEFAULT_VAT_RATE,
      pricingStatus: 'PUBLISHED',
    })

    return {
      id: `legacy-pricing:${record.key}`,
      versionId,
      ...derived,
      createdAt,
      updatedAt: createdAt,
    } satisfies SalesVersionPricingRecord
  })

  const colors = bootstrap.colorPalettes.flatMap((palette) => {
    const matchingModel = bootstrap.models.find((model) => normalizeLookup(model.name) === normalizeLookup(palette.model))
    const modelId = matchingModel
      ? (modelIdsByCode.get(matchingModel.code) ?? `legacy-model:${matchingModel.code}`)
      : `legacy-model:${buildStableCatalogCode(palette.model)}`

    return palette.colors.map((color) => ({
      id: `legacy-color:${palette.paletteKey}:${buildStableCatalogCode(color.name)}`,
      modelId,
      code: buildStableCatalogCode(color.name),
      name: color.name,
      finishType: null,
      isBaseColor: color.isBase,
      hasSurcharge: !color.isBase && ((color.surchargeNet ?? 0) > 0 || (color.surchargeGross ?? 0) > 0),
      surchargeNet: color.surchargeNet,
      surchargeGross: color.surchargeGross,
      sortOrder: color.sortOrder,
      createdAt,
      updatedAt: createdAt,
    } satisfies SalesModelColorRecord))
  })

  const assetBundles = models.map((model) => {
    const bundleId = `legacy-bundle:${model.code}`
    const files = buildLegacyAssetFiles(bundleId, model.name)

    return {
      id: bundleId,
      modelId: model.id,
      assetsVersionTag: null,
      isActive: true,
      createdAt,
      updatedAt: createdAt,
      files,
    } satisfies SalesModelAssetBundleRecord
  }).filter((bundle) => bundle.files.length > 0)

  return {
    databaseReady: false,
    source: 'legacy-fallback',
    brands,
    models,
    versions,
    pricingRecords,
    colors,
    assetBundles,
    dictionaries: {
      modelStatuses: SALES_MODEL_STATUSES,
      powertrainTypes: SALES_POWERTRAIN_TYPES,
      driveTypes: SALES_DRIVE_TYPES,
      pricingStatuses: SALES_PRICING_STATUSES,
      assetCategories: SALES_ASSET_CATEGORIES,
      defaultVatRate: DEFAULT_VAT_RATE,
    },
    stats: {
      brands: brands.length,
      models: models.length,
      versions: versions.length,
      pricingRecords: pricingRecords.length,
      colors: colors.length,
      assetBundles: assetBundles.length,
      assetFiles: assetBundles.reduce((sum, bundle) => sum + bundle.files.length, 0),
    },
  }
}

export async function getSalesCatalogWorkspace(): Promise<CatalogAdminResult<SalesCatalogWorkspace>> {
  const unavailable = requireDb<SalesCatalogWorkspace>()

  if (unavailable) {
    return unavailable
  }

  try {
    const [brands, models, versions, pricingRecords, colors, assetBundles] = await Promise.all([
      db!.salesBrand.findMany({ orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }] }),
      db!.salesModel.findMany({ orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }] }),
      db!.salesVersion.findMany({ orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }] }),
      db!.salesVersionPricing.findMany({ orderBy: [{ updatedAt: 'desc' }] }),
      db!.salesModelColor.findMany({ orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }] }),
      db!.salesModelAssetBundle.findMany({
        include: {
          files: {
            orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }, { fileName: 'asc' }],
          },
        },
        orderBy: { updatedAt: 'desc' },
      }),
    ])

    const versionsByModelId = versions.reduce<Map<string, SalesVersionRecord[]>>((accumulator, version) => {
      const bucket = accumulator.get(version.modelId) ?? []
      bucket.push(mapVersionRecord(version))
      accumulator.set(version.modelId, bucket)
      return accumulator
    }, new Map())

    const mappedBundles = assetBundles.map(mapAssetBundleRecord)
    const assetFileCount = mappedBundles.reduce((sum, bundle) => sum + bundle.files.length, 0)

    return ok({
      databaseReady: true,
      source: 'database',
      brands: brands.map(mapBrandRecord),
      models: models.map((model) =>
        mapModelRecord(model, collectModelPowertrainTypes(versionsByModelId.get(model.id) ?? []))
      ),
      versions: versions.map(mapVersionRecord),
      pricingRecords: pricingRecords.map(mapPricingRecord),
      colors: colors.map(mapColorRecord),
      assetBundles: mappedBundles,
      dictionaries: {
        modelStatuses: SALES_MODEL_STATUSES,
        powertrainTypes: SALES_POWERTRAIN_TYPES,
        driveTypes: SALES_DRIVE_TYPES,
        pricingStatuses: SALES_PRICING_STATUSES,
        assetCategories: SALES_ASSET_CATEGORIES,
        defaultVatRate: DEFAULT_VAT_RATE,
      },
      stats: {
        brands: brands.length,
        models: models.length,
        versions: versions.length,
        pricingRecords: pricingRecords.length,
        colors: colors.length,
        assetBundles: mappedBundles.length,
        assetFiles: assetFileCount,
      },
    })
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się pobrać workspace katalogu.')
  }
}

export async function createSalesBrand(input: Record<string, unknown>): Promise<CatalogAdminResult<SalesBrandRecord>> {
  const unavailable = requireDb<SalesBrandRecord>()

  if (unavailable) {
    return unavailable
  }

  const name = requiredTextField(input, 'name', 'Podaj nazwę marki.')

  if (typeof name !== 'string') {
    return fail(name)
  }

  const sortOrder = optionalNumber(input.sortOrder) ?? await resolveNextSortOrder('brand')

  try {
    const brand = await db!.salesBrand.create({
      data: {
        code: buildStableCatalogCode(name),
        name,
        sortOrder,
      },
    })

    return ok(mapBrandRecord(brand))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się utworzyć marki.')
  }
}

export async function updateSalesBrand(brandId: string, input: Record<string, unknown>): Promise<CatalogAdminResult<SalesBrandRecord>> {
  const unavailable = requireDb<SalesBrandRecord>()

  if (unavailable) {
    return unavailable
  }

  const existing = await db!.salesBrand.findUnique({ where: { id: brandId } })

  if (!existing) {
    return fail('Nie znaleziono marki do aktualizacji.', 404)
  }

  const name = nullableString(input.name) ?? existing.name
  const sortOrder = optionalNumber(input.sortOrder) ?? existing.sortOrder

  if (!name) {
    return fail('Podaj nazwę marki.')
  }

  try {
    const brand = await db!.salesBrand.update({
      where: { id: brandId },
      data: {
        name,
        code: buildStableCatalogCode(name),
        sortOrder,
      },
    })

    return ok(mapBrandRecord(brand))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się zaktualizować marki.')
  }
}

export async function createSalesModel(input: Record<string, unknown>): Promise<CatalogAdminResult<SalesModelRecord>> {
  const unavailable = requireDb<SalesModelRecord>()

  if (unavailable) {
    return unavailable
  }

  const brandId = requiredTextField(input, 'brandId', 'Wybierz markę dla modelu.')
  const name = requiredTextField(input, 'name', 'Podaj nazwę modelu.')

  if (typeof brandId !== 'string') {
    return fail(brandId)
  }

  if (typeof name !== 'string') {
    return fail(name)
  }

  const brand = await db!.salesBrand.findUnique({ where: { id: brandId } })

  if (!brand) {
    return fail('Wybrana marka nie istnieje.', 404)
  }

  const sortOrder = optionalNumber(input.sortOrder) ?? await resolveNextSortOrder('model', brandId)
  const marketingName = nullableString(input.marketingName)

  try {
    const model = await db!.salesModel.create({
      data: {
        brandId,
        code: buildStableCatalogCode(name),
        name,
        marketingName,
        sortOrder,
        status: SalesModelStatus.ACTIVE,
      },
    })

    return ok(mapModelRecord(model, []))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się utworzyć modelu.')
  }
}

export async function updateSalesModel(modelId: string, input: Record<string, unknown>): Promise<CatalogAdminResult<SalesModelRecord>> {
  const unavailable = requireDb<SalesModelRecord>()

  if (unavailable) {
    return unavailable
  }

  const existing = await db!.salesModel.findUnique({
    where: { id: modelId },
    include: {
      versions: {
        select: { powertrainType: true },
      },
    },
  })

  if (!existing) {
    return fail('Nie znaleziono modelu do aktualizacji.', 404)
  }

  const brandId = nullableString(input.brandId) ?? existing.brandId
  const name = nullableString(input.name) ?? existing.name
  const marketingName = input.marketingName === null ? null : nullableString(input.marketingName) ?? existing.marketingName
  const sortOrder = optionalNumber(input.sortOrder) ?? existing.sortOrder

  if (brandId !== existing.brandId) {
    const brand = await db!.salesBrand.findUnique({ where: { id: brandId } })

    if (!brand) {
      return fail('Wybrana marka nie istnieje.', 404)
    }
  }

  try {
    const model = await db!.salesModel.update({
      where: { id: modelId },
      data: {
        brandId,
        code: buildStableCatalogCode(name),
        name,
        marketingName,
        sortOrder,
      },
    })

    return ok(mapModelRecord(model, collectModelPowertrainTypes(existing.versions)))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się zaktualizować modelu.')
  }
}

export async function archiveSalesModel(modelId: string): Promise<CatalogAdminResult<SalesModelRecord>> {
  return setSalesModelStatus(modelId, SalesModelStatus.ARCHIVED)
}

export async function restoreSalesModel(modelId: string): Promise<CatalogAdminResult<SalesModelRecord>> {
  return setSalesModelStatus(modelId, SalesModelStatus.ACTIVE)
}

async function setSalesModelStatus(modelId: string, status: SalesModelStatus): Promise<CatalogAdminResult<SalesModelRecord>> {
  const unavailable = requireDb<SalesModelRecord>()

  if (unavailable) {
    return unavailable
  }

  const existing = await db!.salesModel.findUnique({
    where: { id: modelId },
    include: {
      versions: {
        select: { powertrainType: true },
      },
    },
  })

  if (!existing) {
    return fail('Nie znaleziono modelu.', 404)
  }

  try {
    const model = await db!.salesModel.update({
      where: { id: modelId },
      data: { status },
    })

    return ok(mapModelRecord(model, collectModelPowertrainTypes(existing.versions)))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się zmienić statusu modelu.')
  }
}

export async function createSalesVersion(input: Record<string, unknown>): Promise<CatalogAdminResult<SalesVersionRecord>> {
  const unavailable = requireDb<SalesVersionRecord>()

  if (unavailable) {
    return unavailable
  }

  const modelId = requiredTextField(input, 'modelId', 'Wybierz model dla wersji.')
  const name = requiredTextField(input, 'name', 'Podaj nazwę wersji.')
  const powertrainType = ensureEnumValue(input.powertrainType, SALES_POWERTRAIN_TYPES)

  if (typeof modelId !== 'string') {
    return fail(modelId)
  }

  if (typeof name !== 'string') {
    return fail(name)
  }

  if (!powertrainType) {
    return fail('Wybierz poprawny typ napędu.')
  }

  const model = await db!.salesModel.findUnique({ where: { id: modelId } })

  if (!model) {
    return fail('Wybrany model nie istnieje.', 404)
  }

  const payload = {
    powertrainType: powertrainType as PowertrainType,
    systemPowerHp: optionalNumber(input.systemPowerHp),
    batteryCapacityKwh: optionalNumber(input.batteryCapacityKwh),
    engineDisplacementCc: optionalNumber(input.engineDisplacementCc),
  }
  const businessRuleError = validateVersionBusinessRules(payload)

  if (businessRuleError) {
    return fail(businessRuleError)
  }

  const sortOrder = optionalNumber(input.sortOrder) ?? await resolveNextSortOrder('version', modelId)
  const year = optionalNumber(input.year)
  const driveType = ensureEnumValue(input.driveType, SALES_DRIVE_TYPES, null) as DriveType | null

  try {
    const version = await db!.salesVersion.create({
      data: {
        modelId,
        code: buildStableCatalogCode(name, year, powertrainType),
        name,
        year,
        powertrainType,
        driveType,
        systemPowerHp: payload.systemPowerHp,
        batteryCapacityKwh: payload.batteryCapacityKwh,
        combustionEnginePowerHp: optionalNumber(input.combustionEnginePowerHp),
        engineDisplacementCc: payload.engineDisplacementCc,
        rangeKm: optionalNumber(input.rangeKm),
        notes: nullableString(input.notes),
        sortOrder,
      },
    })

    return ok(mapVersionRecord(version))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się utworzyć wersji.')
  }
}

export async function updateSalesVersion(versionId: string, input: Record<string, unknown>): Promise<CatalogAdminResult<SalesVersionRecord>> {
  const unavailable = requireDb<SalesVersionRecord>()

  if (unavailable) {
    return unavailable
  }

  const existing = await db!.salesVersion.findUnique({ where: { id: versionId } })

  if (!existing) {
    return fail('Nie znaleziono wersji do aktualizacji.', 404)
  }

  const modelId = nullableString(input.modelId) ?? existing.modelId
  const name = nullableString(input.name) ?? existing.name
  const year = optionalNumber(input.year) ?? existing.year
  const powertrainType = (ensureEnumValue(input.powertrainType, SALES_POWERTRAIN_TYPES, existing.powertrainType) ?? existing.powertrainType) as PowertrainType
  const driveType = ensureEnumValue(input.driveType, SALES_DRIVE_TYPES, existing.driveType) as DriveType | null
  const payload = {
    powertrainType,
    systemPowerHp: optionalNumber(input.systemPowerHp) ?? existing.systemPowerHp,
    batteryCapacityKwh: optionalNumber(input.batteryCapacityKwh) ?? toNumber(existing.batteryCapacityKwh),
    engineDisplacementCc: optionalNumber(input.engineDisplacementCc) ?? existing.engineDisplacementCc,
  }
  const businessRuleError = validateVersionBusinessRules(payload)

  if (businessRuleError) {
    return fail(businessRuleError)
  }

  if (modelId !== existing.modelId) {
    const model = await db!.salesModel.findUnique({ where: { id: modelId } })

    if (!model) {
      return fail('Wybrany model nie istnieje.', 404)
    }
  }

  try {
    const version = await db!.salesVersion.update({
      where: { id: versionId },
      data: {
        modelId,
        code: buildStableCatalogCode(name, year, powertrainType),
        name,
        year,
        powertrainType,
        driveType,
        systemPowerHp: payload.systemPowerHp,
        batteryCapacityKwh: payload.batteryCapacityKwh,
        combustionEnginePowerHp: optionalNumber(input.combustionEnginePowerHp) ?? existing.combustionEnginePowerHp,
        engineDisplacementCc: payload.engineDisplacementCc,
        rangeKm: optionalNumber(input.rangeKm) ?? existing.rangeKm,
        notes: input.notes === null ? null : nullableString(input.notes) ?? existing.notes,
        sortOrder: optionalNumber(input.sortOrder) ?? existing.sortOrder,
      },
    })

    return ok(mapVersionRecord(version))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się zaktualizować wersji.')
  }
}

export async function createSalesPricing(versionId: string, input: Record<string, unknown>): Promise<CatalogAdminResult<SalesVersionPricingRecord>> {
  const unavailable = requireDb<SalesVersionPricingRecord>()

  if (unavailable) {
    return unavailable
  }

  const version = await db!.salesVersion.findUnique({ where: { id: versionId } })

  if (!version) {
    return fail('Wybrana wersja nie istnieje.', 404)
  }

  const listPriceNet = optionalNumber(input.listPriceNet)
  const basePriceNet = optionalNumber(input.basePriceNet)
  const vatRate = optionalNumber(input.vatRate) ?? DEFAULT_VAT_RATE
  const validationError = validatePricing({ listPriceNet, basePriceNet, vatRate })

  if (validationError) {
    return fail(validationError)
  }

  try {
    const pricing = await db!.salesVersionPricing.create({
      data: {
        versionId,
        ...buildDerivedPricing({
          listPriceNet: listPriceNet!,
          basePriceNet: basePriceNet!,
          vatRate,
          pricingStatus: 'DRAFT',
          effectiveFrom: buildPrismaDate(input.effectiveFrom)?.toISOString() ?? null,
          effectiveTo: buildPrismaDate(input.effectiveTo)?.toISOString() ?? null,
        }),
      },
    })

    return ok(mapPricingRecord(pricing))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się utworzyć rekordu cenowego.')
  }
}

export async function updateSalesPricing(pricingId: string, input: Record<string, unknown>): Promise<CatalogAdminResult<SalesVersionPricingRecord>> {
  const unavailable = requireDb<SalesVersionPricingRecord>()

  if (unavailable) {
    return unavailable
  }

  const existing = await db!.salesVersionPricing.findUnique({ where: { id: pricingId } })

  if (!existing) {
    return fail('Nie znaleziono rekordu cenowego.', 404)
  }

  const listPriceNet = optionalNumber(input.listPriceNet) ?? toNumber(existing.listPriceNet)
  const basePriceNet = optionalNumber(input.basePriceNet) ?? toNumber(existing.basePriceNet)
  const vatRate = optionalNumber(input.vatRate) ?? toNumber(existing.vatRate) ?? DEFAULT_VAT_RATE
  const validationError = validatePricing({ listPriceNet, basePriceNet, vatRate })

  if (validationError) {
    return fail(validationError)
  }

  try {
    const pricing = await db!.salesVersionPricing.update({
      where: { id: pricingId },
      data: {
        ...buildDerivedPricing({
          listPriceNet: listPriceNet!,
          basePriceNet: basePriceNet!,
          vatRate,
          pricingStatus: existing.pricingStatus,
          effectiveFrom: input.effectiveFrom === null
            ? null
            : buildPrismaDate(input.effectiveFrom)?.toISOString() ?? existing.effectiveFrom?.toISOString() ?? null,
          effectiveTo: input.effectiveTo === null
            ? null
            : buildPrismaDate(input.effectiveTo)?.toISOString() ?? existing.effectiveTo?.toISOString() ?? null,
        }),
      },
    })

    return ok(mapPricingRecord(pricing))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się zaktualizować rekordu cenowego.')
  }
}

export async function publishSalesPricing(pricingId: string): Promise<CatalogAdminResult<SalesVersionPricingRecord>> {
  const unavailable = requireDb<SalesVersionPricingRecord>()

  if (unavailable) {
    return unavailable
  }

  const existing = await db!.salesVersionPricing.findUnique({ where: { id: pricingId } })

  if (!existing) {
    return fail('Nie znaleziono rekordu cenowego do publikacji.', 404)
  }

  try {
    const pricing = await db!.$transaction(async (transaction) => {
      await transaction.salesVersionPricing.updateMany({
        where: {
          versionId: existing.versionId,
          pricingStatus: SalesPricingStatus.PUBLISHED,
          NOT: { id: pricingId },
        },
        data: {
          pricingStatus: SalesPricingStatus.ARCHIVED,
        },
      })

      return transaction.salesVersionPricing.update({
        where: { id: pricingId },
        data: {
          pricingStatus: SalesPricingStatus.PUBLISHED,
        },
      })
    })

    return ok(mapPricingRecord(pricing))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się opublikować cen.')
  }
}

export async function archiveSalesPricing(pricingId: string): Promise<CatalogAdminResult<SalesVersionPricingRecord>> {
  const unavailable = requireDb<SalesVersionPricingRecord>()

  if (unavailable) {
    return unavailable
  }

  try {
    const pricing = await db!.salesVersionPricing.update({
      where: { id: pricingId },
      data: {
        pricingStatus: SalesPricingStatus.ARCHIVED,
      },
    })

    return ok(mapPricingRecord(pricing))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się zarchiwizować cen.')
  }
}

export async function createSalesModelColor(modelId: string, input: Record<string, unknown>): Promise<CatalogAdminResult<SalesModelColorRecord>> {
  const unavailable = requireDb<SalesModelColorRecord>()

  if (unavailable) {
    return unavailable
  }

  const model = await db!.salesModel.findUnique({ where: { id: modelId } })

  if (!model) {
    return fail('Wybrany model nie istnieje.', 404)
  }

  const name = requiredTextField(input, 'name', 'Podaj nazwę koloru.')

  if (typeof name !== 'string') {
    return fail(name)
  }

  const isBaseColor = Boolean(input.isBaseColor)
  const hasSurcharge = Boolean(input.hasSurcharge)
  const surchargeNet = hasSurcharge ? optionalNumber(input.surchargeNet) : null
  const colorError = validateColorInput({ hasSurcharge, surchargeNet })

  if (colorError) {
    return fail(colorError)
  }

  const sortOrder = optionalNumber(input.sortOrder) ?? await resolveNextSortOrder('color', modelId)
  const finishType = nullableString(input.finishType)

  try {
    const color = await db!.$transaction(async (transaction) => {
      if (isBaseColor) {
        await transaction.salesModelColor.updateMany({
          where: {
            modelId,
            isBaseColor: true,
          },
          data: {
            isBaseColor: false,
          },
        })
      }

      return transaction.salesModelColor.create({
        data: {
          modelId,
          code: buildStableCatalogCode(name),
          name,
          finishType,
          isBaseColor,
          hasSurcharge,
          surchargeNet,
          surchargeGross: hasSurcharge && surchargeNet !== null ? calculateGrossFromNet(surchargeNet) : null,
          sortOrder,
        },
      })
    })

    return ok(mapColorRecord(color))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się dodać koloru.')
  }
}

export async function updateSalesModelColor(colorId: string, input: Record<string, unknown>): Promise<CatalogAdminResult<SalesModelColorRecord>> {
  const unavailable = requireDb<SalesModelColorRecord>()

  if (unavailable) {
    return unavailable
  }

  const existing = await db!.salesModelColor.findUnique({ where: { id: colorId } })

  if (!existing) {
    return fail('Nie znaleziono koloru.', 404)
  }

  const name = nullableString(input.name) ?? existing.name
  const isBaseColor = input.isBaseColor === undefined ? existing.isBaseColor : Boolean(input.isBaseColor)
  const hasSurcharge = input.hasSurcharge === undefined ? existing.hasSurcharge : Boolean(input.hasSurcharge)
  const surchargeNet = hasSurcharge
    ? optionalNumber(input.surchargeNet) ?? toNumber(existing.surchargeNet)
    : null
  const colorError = validateColorInput({ hasSurcharge, surchargeNet })

  if (colorError) {
    return fail(colorError)
  }

  try {
    const color = await db!.$transaction(async (transaction) => {
      if (isBaseColor) {
        await transaction.salesModelColor.updateMany({
          where: {
            modelId: existing.modelId,
            isBaseColor: true,
            NOT: { id: colorId },
          },
          data: {
            isBaseColor: false,
          },
        })
      }

      return transaction.salesModelColor.update({
        where: { id: colorId },
        data: {
          code: buildStableCatalogCode(name),
          name,
          finishType: input.finishType === null ? null : nullableString(input.finishType) ?? existing.finishType,
          isBaseColor,
          hasSurcharge,
          surchargeNet,
          surchargeGross: hasSurcharge && surchargeNet !== null ? calculateGrossFromNet(surchargeNet) : null,
          sortOrder: optionalNumber(input.sortOrder) ?? existing.sortOrder,
        },
      })
    })

    return ok(mapColorRecord(color))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się zaktualizować koloru.')
  }
}

export async function deleteSalesModelColor(colorId: string): Promise<CatalogAdminResult<{ id: string }>> {
  const unavailable = requireDb<{ id: string }>()

  if (unavailable) {
    return unavailable
  }

  try {
    await db!.salesModelColor.delete({ where: { id: colorId } })
    return ok({ id: colorId })
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się usunąć koloru.')
  }
}

export async function getSalesModelAssets(modelId: string): Promise<CatalogAdminResult<SalesModelAssetBundleRecord | null>> {
  const unavailable = requireDb<SalesModelAssetBundleRecord | null>()

  if (unavailable) {
    return unavailable
  }

  const model = await db!.salesModel.findUnique({ where: { id: modelId } })

  if (!model) {
    return fail('Nie znaleziono modelu.', 404)
  }

  try {
    const bundle = await db!.salesModelAssetBundle.findUnique({
      where: { modelId },
      include: {
        files: {
          orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }, { fileName: 'asc' }],
        },
      },
    })

    return ok(bundle ? mapAssetBundleRecord(bundle) : null)
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się pobrać materiałów modelu.')
  }
}

export async function updateSalesModelAssets(modelId: string, input: Record<string, unknown>): Promise<CatalogAdminResult<SalesModelAssetBundleRecord>> {
  const unavailable = requireDb<SalesModelAssetBundleRecord>()

  if (unavailable) {
    return unavailable
  }

  const model = await db!.salesModel.findUnique({ where: { id: modelId } })

  if (!model) {
    return fail('Nie znaleziono modelu.', 404)
  }

  try {
    const bundle = await upsertAssetBundle(modelId, {
      assetsVersionTag: input.assetsVersionTag === null ? null : nullableString(input.assetsVersionTag),
      isActive: input.isActive === undefined ? undefined : Boolean(input.isActive),
    })

    return ok(mapAssetBundleRecord(bundle))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się zaktualizować pakietu materiałów.')
  }
}

export async function createSalesAssetFile(modelId: string, input: Record<string, unknown>): Promise<CatalogAdminResult<SalesModelAssetBundleRecord>> {
  const unavailable = requireDb<SalesModelAssetBundleRecord>()

  if (unavailable) {
    return unavailable
  }

  const model = await db!.salesModel.findUnique({ where: { id: modelId } })

  if (!model) {
    return fail('Nie znaleziono modelu.', 404)
  }

  const category = ensureEnumValue(input.category, SALES_ASSET_CATEGORIES)
  const fileName = requiredTextField(input, 'fileName', 'Podaj nazwę pliku.')
  const filePath = requiredTextField(input, 'filePath', 'Podaj ścieżkę pliku.')

  if (!category) {
    return fail('Wybierz poprawną kategorię pliku.')
  }

  if (typeof fileName !== 'string') {
    return fail(fileName)
  }

  if (typeof filePath !== 'string') {
    return fail(filePath)
  }

  const powertrainType = category === 'SPEC_PDF'
    ? ensureEnumValue(input.powertrainType, SALES_POWERTRAIN_TYPES, null)
    : null
  const fileDataBase64 = nullableString(input.fileDataBase64)

  if (category === 'SPEC_PDF' && input.powertrainType !== undefined && input.powertrainType !== null && !powertrainType) {
    return fail('Dla pliku specyfikacji wybierz poprawny typ napędu.')
  }

  try {
    const bundle = await upsertAssetBundle(modelId, {})
    const sortOrder = optionalNumber(input.sortOrder) ?? await resolveNextSortOrder('assetFile', bundle.id)

    await db!.salesAssetFile.create({
      data: {
        bundleId: bundle.id,
        category: category as AssetCategory,
        powertrainType: powertrainType as PowertrainType | null,
        fileName,
        filePath,
        fileDataBase64,
        mimeType: nullableString(input.mimeType),
        sortOrder,
      },
    })

    const refreshed = await db!.salesModelAssetBundle.findUnique({
      where: { id: bundle.id },
      include: {
        files: {
          orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }, { fileName: 'asc' }],
        },
      },
    })

    return ok(mapAssetBundleRecord(refreshed!))
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się dodać pliku do pakietu materiałów.')
  }
}

export async function deleteSalesAssetFile(fileId: string): Promise<CatalogAdminResult<{ id: string; bundleId: string }>> {
  const unavailable = requireDb<{ id: string; bundleId: string }>()

  if (unavailable) {
    return unavailable
  }

  const existing = await db!.salesAssetFile.findUnique({ where: { id: fileId } })

  if (!existing) {
    return fail('Nie znaleziono pliku do usunięcia.', 404)
  }

  try {
    await deleteBlobIfManaged(existing.filePath)
    await db!.salesAssetFile.delete({ where: { id: fileId } })
    return ok({ id: fileId, bundleId: existing.bundleId })
  } catch (error) {
    return handleCatalogAdminError(error, 'Nie udało się usunąć pliku.')
  }
}

export async function runLegacyCatalogSync(): Promise<CatalogAdminResult<SalesCatalogSyncSummary>> {
  return fail('Synchronizacja legacy została wyłączona. Katalog działa już wyłącznie na nowym modelu danych.', 410)
}

export async function getLegacyCatalogSyncStatus(): Promise<CatalogAdminResult<SalesCatalogSyncStatus>> {
  const workspace = await getSalesCatalogWorkspace()

  if (!workspace.ok) {
    return workspace
  }

  return ok({
    databaseReady: Boolean(db),
    stats: workspace.data.stats,
  })
}