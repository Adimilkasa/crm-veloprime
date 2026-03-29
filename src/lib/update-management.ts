import 'server-only'

import { mkdir, readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'

import type { AuthSession } from '@/lib/auth'

export type UpdateArtifactType = 'DATA' | 'ASSETS' | 'APPLICATION'
export type UpdatePriority = 'CRITICAL' | 'STANDARD'

export type PublishedVersion = {
  artifactType: UpdateArtifactType
  version: string
  publishedAt: string | null
  publishedBy: string | null
  summary: string | null
  priority: UpdatePriority
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
}

const UPDATE_DATA_DIR = path.join(process.cwd(), 'data')
const UPDATE_MANIFEST_PATH = path.join(UPDATE_DATA_DIR, 'update-manifest.json')
const UPDATE_ARTIFACT_TYPES: UpdateArtifactType[] = ['DATA', 'ASSETS', 'APPLICATION']

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

function nextVersion(currentVersion: string) {
  const numericPart = Number.parseInt(currentVersion.replace(/^v/i, ''), 10)

  if (Number.isNaN(numericPart) || numericPart < 1) {
    return 'v1'
  }

  return `v${numericPart + 1}`
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
    }
  })

  const nextManifest = { versions: nextVersions } satisfies UpdateManifest
  await writeStore(nextManifest)

  return { ok: true as const, manifest: nextManifest }
}