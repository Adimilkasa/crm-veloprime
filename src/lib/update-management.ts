import 'server-only'

import { mkdir, readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'

import type { AuthSession } from '@/lib/auth'
import type { ModelColorPalette } from '@/lib/color-management'
import {
  getSalesCatalogBootstrap,
  type SalesCatalogBootstrapAssetSummary,
  type SalesCatalogBootstrapBrand,
  type SalesCatalogBootstrapModel,
  type SalesCatalogBootstrapPayload,
  type SalesCatalogBootstrapVersion,
  type SalesCatalogRuntimeItem,
} from '@/lib/sales-catalog-management'

export type UpdateArtifactType = 'DATA' | 'ASSETS' | 'APPLICATION'
export type UpdatePriority = 'CRITICAL' | 'STANDARD'

export type PublishedArtifactSnapshot = {
  source: 'DATABASE' | 'LEGACY' | 'MIXED' | 'STATIC'
  generatedAt: string
  stats: Record<string, number>
  notes: string[]
}

export type PublishedVersion = {
  artifactType: UpdateArtifactType
  version: string
  publishedAt: string | null
  publishedBy: string | null
  summary: string | null
  priority: UpdatePriority
  snapshot: PublishedArtifactSnapshot | null
}

export type UpdateManifest = {
  versions: PublishedVersion[]
}

export type ClientVersionPayload = Partial<Record<UpdateArtifactType, string | null>>

export type VersionComparisonResult = {
  artifactType: UpdateArtifactType
  currentVersion: string | null
  publishedVersion: string
  priority: UpdatePriority
  requiresUpdate: boolean
  snapshot: PublishedArtifactSnapshot | null
}

const UPDATE_DATA_DIR = path.join(process.cwd(), 'data')
const UPDATE_MANIFEST_PATH = path.join(UPDATE_DATA_DIR, 'update-manifest.json')
const PUBLISHED_CATALOG_DATA_PATH = path.join(UPDATE_DATA_DIR, 'published-sales-catalog-data.json')
const PUBLISHED_CATALOG_ASSETS_PATH = path.join(UPDATE_DATA_DIR, 'published-sales-catalog-assets.json')
const UPDATE_ARTIFACT_TYPES: UpdateArtifactType[] = ['DATA', 'ASSETS', 'APPLICATION']

type PublishedCatalogDataSnapshot = {
  generatedAt: string
  brands: SalesCatalogBootstrapBrand[]
  models: SalesCatalogBootstrapModel[]
  versions: SalesCatalogBootstrapVersion[]
  pricingRecords: SalesCatalogRuntimeItem[]
  colorPalettes: ModelColorPalette[]
}

type PublishedCatalogAssetsSnapshot = {
  generatedAt: string
  assetBundles: SalesCatalogBootstrapAssetSummary[]
}

let inMemoryManifest: UpdateManifest | null = null

function canPublishUpdates(role: AuthSession['role']) {
  return role === 'ADMIN' || role === 'DIRECTOR'
}

function buildSeedManifest(): UpdateManifest {
  return {
    versions: UPDATE_ARTIFACT_TYPES.map((artifactType) => ({
      artifactType,
      version: 'v1',
      publishedAt: null,
      publishedBy: null,
      summary: null,
      priority: artifactType === 'DATA' ? 'CRITICAL' : 'STANDARD',
      snapshot: null,
    })),
  }
}

async function ensureStoreFile() {
  try {
    await mkdir(UPDATE_DATA_DIR, { recursive: true })
    await readFile(UPDATE_MANIFEST_PATH, 'utf8')
  } catch {
    const seedManifest = buildSeedManifest()
    inMemoryManifest = seedManifest

    try {
      await writeFile(UPDATE_MANIFEST_PATH, JSON.stringify(seedManifest, null, 2), 'utf8')
    } catch {
      // Serverless environments may not allow writes to the application filesystem.
    }
  }
}

function normalizePublishedVersion(input: Partial<PublishedVersion>, artifactType: UpdateArtifactType): PublishedVersion {
  return {
    artifactType,
    version: typeof input.version === 'string' && input.version.trim().length > 0 ? input.version.trim() : 'v1',
    publishedAt: typeof input.publishedAt === 'string' ? input.publishedAt : null,
    publishedBy: typeof input.publishedBy === 'string' ? input.publishedBy : null,
    summary: typeof input.summary === 'string' ? input.summary : null,
    priority: input.priority === 'CRITICAL' ? 'CRITICAL' : 'STANDARD',
    snapshot: normalizePublishedArtifactSnapshot(input.snapshot),
  }
}

function normalizePublishedArtifactSnapshot(input: unknown): PublishedArtifactSnapshot | null {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    return null
  }

  const snapshot = input as Record<string, unknown>
  const source = snapshot.source
  const generatedAt = typeof snapshot.generatedAt === 'string' ? snapshot.generatedAt : null
  const statsInput = snapshot.stats

  if ((source !== 'DATABASE' && source !== 'LEGACY' && source !== 'MIXED' && source !== 'STATIC') || !generatedAt) {
    return null
  }

  const stats = statsInput && typeof statsInput === 'object' && !Array.isArray(statsInput)
    ? Object.entries(statsInput as Record<string, unknown>).reduce<Record<string, number>>((accumulator, [key, value]) => {
        const parsed = typeof value === 'number' ? value : Number(value)

        if (Number.isFinite(parsed)) {
          accumulator[key] = parsed
        }

        return accumulator
      }, {})
    : {}
  const notes = Array.isArray(snapshot.notes)
    ? snapshot.notes.filter((item): item is string => typeof item === 'string' && item.trim().length > 0)
    : []

  return {
    source,
    generatedAt,
    stats,
    notes,
  }
}

async function readStore() {
  await ensureStoreFile()

  try {
    const raw = await readFile(UPDATE_MANIFEST_PATH, 'utf8')
    const parsed = JSON.parse(raw) as Partial<UpdateManifest>
    const versionMap = new Map<UpdateArtifactType, PublishedVersion>()

    for (const artifactType of UPDATE_ARTIFACT_TYPES) {
      const existing = parsed.versions?.find((entry) => entry?.artifactType === artifactType)
      versionMap.set(artifactType, normalizePublishedVersion(existing ?? {}, artifactType))
    }

    return {
      versions: UPDATE_ARTIFACT_TYPES.map((artifactType) => versionMap.get(artifactType)!),
    } satisfies UpdateManifest
  } catch {
    if (!inMemoryManifest) {
      inMemoryManifest = buildSeedManifest()
    }

    return inMemoryManifest
  }
}

async function writeStore(manifest: UpdateManifest) {
  inMemoryManifest = manifest

  try {
    await ensureStoreFile()
    await writeFile(UPDATE_MANIFEST_PATH, JSON.stringify(manifest, null, 2), 'utf8')
  } catch {
    // Ignore filesystem write failures in serverless hosting.
  }
}

async function readPublishedCatalogDataStore() {
  try {
    const raw = await readFile(PUBLISHED_CATALOG_DATA_PATH, 'utf8')
    const parsed = JSON.parse(raw) as PublishedCatalogDataSnapshot

    if (!parsed || typeof parsed !== 'object') {
      return null
    }

    if (!Array.isArray(parsed.brands) || !Array.isArray(parsed.models) || !Array.isArray(parsed.versions) || !Array.isArray(parsed.pricingRecords) || !Array.isArray(parsed.colorPalettes)) {
      return null
    }

    return parsed
  } catch {
    return null
  }
}

async function readPublishedCatalogAssetsStore() {
  try {
    const raw = await readFile(PUBLISHED_CATALOG_ASSETS_PATH, 'utf8')
    const parsed = JSON.parse(raw) as PublishedCatalogAssetsSnapshot

    if (!parsed || typeof parsed !== 'object' || !Array.isArray(parsed.assetBundles)) {
      return null
    }

    return parsed
  } catch {
    return null
  }
}

async function writePublishedCatalogDataStore(catalog: SalesCatalogBootstrapPayload) {
  const snapshot: PublishedCatalogDataSnapshot = {
    generatedAt: new Date().toISOString(),
    brands: catalog.brands,
    models: catalog.models,
    versions: catalog.versions,
    pricingRecords: catalog.pricingRecords,
    colorPalettes: catalog.colorPalettes,
  }

  await mkdir(UPDATE_DATA_DIR, { recursive: true })
  await writeFile(PUBLISHED_CATALOG_DATA_PATH, JSON.stringify(snapshot, null, 2), 'utf8')
}

async function writePublishedCatalogAssetsStore(catalog: SalesCatalogBootstrapPayload) {
  const snapshot: PublishedCatalogAssetsSnapshot = {
    generatedAt: new Date().toISOString(),
    assetBundles: catalog.assetBundles,
  }

  await mkdir(UPDATE_DATA_DIR, { recursive: true })
  await writeFile(PUBLISHED_CATALOG_ASSETS_PATH, JSON.stringify(snapshot, null, 2), 'utf8')
}

function buildCatalogStats(input: {
  brands: SalesCatalogBootstrapBrand[]
  models: SalesCatalogBootstrapModel[]
  versions: SalesCatalogBootstrapVersion[]
  pricingRecords: SalesCatalogRuntimeItem[]
  colorPalettes: ModelColorPalette[]
  assetBundles: SalesCatalogBootstrapAssetSummary[]
}) {
  return {
    brands: input.brands.length,
    models: input.models.length,
    versions: input.versions.length,
    pricingRecords: input.pricingRecords.length,
    colorPalettes: input.colorPalettes.length,
    colors: input.colorPalettes.reduce((sum, palette) => sum + palette.colors.length, 0),
    assetBundles: input.assetBundles.length,
    assetFiles: input.assetBundles.reduce((sum, bundle) => sum + bundle.totalFiles, 0),
  }
}

export async function getPublishedSalesCatalogBootstrap() {
  const [manifest, liveCatalog, dataSnapshot, assetsSnapshot] = await Promise.all([
    readStore(),
    getSalesCatalogBootstrap(),
    readPublishedCatalogDataStore(),
    readPublishedCatalogAssetsStore(),
  ])

  const publishedDataEntry = manifest.versions.find((entry) => entry.artifactType === 'DATA')
  const publishedAssetsEntry = manifest.versions.find((entry) => entry.artifactType === 'ASSETS')
  const canUsePublishedData = publishedDataEntry?.snapshot?.source === 'DATABASE'
  const canUsePublishedAssets = publishedAssetsEntry?.snapshot?.source === 'DATABASE'

  const brands = canUsePublishedData ? (dataSnapshot?.brands ?? liveCatalog.brands) : liveCatalog.brands
  const models = canUsePublishedData ? (dataSnapshot?.models ?? liveCatalog.models) : liveCatalog.models
  const versions = canUsePublishedData ? (dataSnapshot?.versions ?? liveCatalog.versions) : liveCatalog.versions
  const pricingRecords = canUsePublishedData ? (dataSnapshot?.pricingRecords ?? liveCatalog.pricingRecords) : liveCatalog.pricingRecords
  const colorPalettes = canUsePublishedData ? (dataSnapshot?.colorPalettes ?? liveCatalog.colorPalettes) : liveCatalog.colorPalettes
  const assetBundles = canUsePublishedAssets ? (assetsSnapshot?.assetBundles ?? liveCatalog.assetBundles) : liveCatalog.assetBundles

  return {
    brands,
    models,
    versions,
    pricingRecords,
    colorPalettes,
    assetBundles,
    stats: buildCatalogStats({
      brands,
      models,
      versions,
      pricingRecords,
      colorPalettes,
      assetBundles,
    }),
  } satisfies SalesCatalogBootstrapPayload
}

export async function listPublishedSalesCatalogItems() {
  const catalog = await getPublishedSalesCatalogBootstrap()
  return catalog.pricingRecords
}

export async function findPublishedSalesCatalogItemByKey(key: string) {
  const items = await listPublishedSalesCatalogItems()
  return items.find((item) => item.key === key) ?? null
}

export async function findPublishedSalesCatalogVersionByKey(catalogKey: string) {
  const normalizedKey = catalogKey.trim().toLowerCase()

  if (!normalizedKey) {
    return null
  }

  const catalog = await getPublishedSalesCatalogBootstrap()
  return catalog.versions.find((version) => version.catalogKey === normalizedKey) ?? null
}

export async function listPublishedSalesModelColorPalettes() {
  const catalog = await getPublishedSalesCatalogBootstrap()
  return catalog.colorPalettes
}

function nextVersion(currentVersion: string) {
  const numericPart = Number.parseInt(currentVersion.replace(/^v/i, ''), 10)

  if (Number.isNaN(numericPart) || numericPart < 1) {
    return 'v1'
  }

  return `v${numericPart + 1}`
}

async function buildArtifactSnapshot(artifactType: UpdateArtifactType): Promise<{ ok: true; snapshot: PublishedArtifactSnapshot } | { ok: false; error: string }> {
  if (artifactType === 'APPLICATION') {
    return {
      ok: true,
      snapshot: {
        source: 'STATIC',
        generatedAt: new Date().toISOString(),
        stats: {},
        notes: ['Publikacja APPLICATION nie buduje snapshotu katalogu ani assetów.'],
      },
    }
  }

  const catalog = await getSalesCatalogBootstrap()

  if (artifactType === 'DATA') {
    if (catalog.stats.pricingRecords === 0) {
      return { ok: false, error: 'Nie można opublikować DATA bez aktywnego katalogu i cen.' }
    }

    const bundleSources = new Set(catalog.assetBundles.map((bundle) => bundle.source))
    const dataSource = bundleSources.size === 0
      ? 'DATABASE'
      : bundleSources.size > 1
        ? 'MIXED'
        : (catalog.assetBundles[0]?.source ?? 'DATABASE')

    return {
      ok: true,
      snapshot: {
        source: dataSource,
        generatedAt: new Date().toISOString(),
        stats: {
          brands: catalog.stats.brands,
          models: catalog.stats.models,
          versions: catalog.stats.versions,
          pricingRecords: catalog.stats.pricingRecords,
          colorPalettes: catalog.stats.colorPalettes,
          colors: catalog.stats.colors,
        },
        notes: [
          dataSource == 'MIXED' || dataSource == 'LEGACY'
            ? 'Bootstrap katalogu nadal korzysta częściowo z fallbacku legacy.'
            : 'Bootstrap katalogu korzysta z nowego modelu danych.',
        ],
      },
    }
  }

  if (catalog.stats.assetBundles === 0) {
    return { ok: false, error: 'Nie można opublikować ASSETS bez dostępnych pakietów materiałów.' }
  }

  const categoryTotals = catalog.assetBundles.reduce<Record<string, number>>((accumulator, bundle) => {
    for (const [category, count] of Object.entries(bundle.categories)) {
      accumulator[category] = (accumulator[category] ?? 0) + count
    }

    return accumulator
  }, {})
  const bundleSources = new Set(catalog.assetBundles.map((bundle) => bundle.source))

  return {
    ok: true,
    snapshot: {
      source: bundleSources.size > 1 ? 'MIXED' : (catalog.assetBundles[0]?.source ?? 'STATIC'),
      generatedAt: new Date().toISOString(),
      stats: {
        assetBundles: catalog.stats.assetBundles,
        assetFiles: catalog.stats.assetFiles,
        primaryImages: categoryTotals.PRIMARY ?? 0,
        exteriorImages: categoryTotals.EXTERIOR ?? 0,
        interiorImages: categoryTotals.INTERIOR ?? 0,
        detailImages: categoryTotals.DETAILS ?? 0,
        premiumImages: categoryTotals.PREMIUM ?? 0,
        specPdfFiles: categoryTotals.SPEC_PDF ?? 0,
        genericSpecBundles: catalog.assetBundles.filter((bundle) => bundle.hasGenericSpecPdf).length,
        electricSpecBundles: catalog.assetBundles.filter((bundle) => bundle.specPowertrains.includes('ELECTRIC')).length,
        hybridSpecBundles: catalog.assetBundles.filter((bundle) => bundle.specPowertrains.includes('HYBRID')).length,
      },
      notes: [
        bundleSources.size > 1
          ? 'Pakiety assetów pochodzą z więcej niż jednego źródła.'
          : `Pakiety assetów pochodzą z: ${catalog.assetBundles[0]?.source ?? 'STATIC'}.`,
      ],
    },
  }
}

export async function getPublishedUpdateManifest() {
  return readStore()
}

export async function compareClientVersions(clientVersions: ClientVersionPayload) {
  const manifest = await readStore()

  return manifest.versions.map((entry) => ({
    artifactType: entry.artifactType,
    currentVersion: clientVersions[entry.artifactType] ?? null,
    publishedVersion: entry.version,
    priority: entry.priority,
    requiresUpdate: clientVersions[entry.artifactType] !== entry.version,
    snapshot: entry.snapshot,
  })) satisfies VersionComparisonResult[]
}

export async function publishUpdate(
  session: AuthSession,
  input: {
    artifactType: UpdateArtifactType
    summary?: string | null
    priority?: UpdatePriority
  }
) {
  if (!canPublishUpdates(session.role)) {
    return { ok: false as const, error: 'Tylko administrator lub dyrektor moga publikowac aktualizacje.' }
  }

  const artifactSnapshot = await buildArtifactSnapshot(input.artifactType)

  if (!artifactSnapshot.ok) {
    return { ok: false as const, error: artifactSnapshot.error, status: 400 }
  }

  if (input.artifactType === 'DATA' || input.artifactType === 'ASSETS') {
    const catalog = await getSalesCatalogBootstrap()

    if (input.artifactType === 'DATA') {
      await writePublishedCatalogDataStore(catalog)
    }

    if (input.artifactType === 'ASSETS') {
      await writePublishedCatalogAssetsStore(catalog)
    }
  }

  const manifest = await readStore()
  const nextVersions = manifest.versions.map((entry) => {
    if (entry.artifactType !== input.artifactType) {
      return entry
    }

    return {
      ...entry,
      version: nextVersion(entry.version),
      publishedAt: new Date().toISOString(),
      publishedBy: session.fullName,
      summary: input.summary?.trim() || null,
      priority: input.priority ?? entry.priority,
      snapshot: artifactSnapshot.snapshot,
    }
  })

  const nextManifest = { versions: nextVersions } satisfies UpdateManifest
  await writeStore(nextManifest)

  return { ok: true as const, manifest: nextManifest }
}