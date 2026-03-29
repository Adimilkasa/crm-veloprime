import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { compareClientVersions, type ClientVersionPayload, type UpdateArtifactType } from '@/lib/update-management'

const UPDATE_ARTIFACT_TYPES: UpdateArtifactType[] = ['DATA', 'ASSETS', 'APPLICATION']

function normalizeClientVersions(input: unknown) {
  if (!input || typeof input !== 'object') {
    return null
  }

  const payload = input as Record<string, unknown>
  const versions = payload.versions

  if (!versions || typeof versions !== 'object') {
    return null
  }

  const rawVersions = versions as Record<string, unknown>
  const normalized: ClientVersionPayload = {}

  for (const artifactType of UPDATE_ARTIFACT_TYPES) {
    const value = rawVersions[artifactType]
    normalized[artifactType] = typeof value === 'string' && value.trim().length > 0 ? value.trim() : null
  }

  return normalized
}

export async function POST(request: Request) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  let body: unknown

  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ ok: false, error: 'Niepoprawne dane wejściowe.' }, { status: 400 })
  }

  const clientVersions = normalizeClientVersions(body)

  if (!clientVersions) {
    return NextResponse.json(
      {
        ok: false,
        error: 'Przekaż obiekt versions z polami DATA, ASSETS i APPLICATION.',
      },
      { status: 400 }
    )
  }

  const comparison = await compareClientVersions(clientVersions)
  const requiresAnyUpdate = comparison.some((entry) => entry.requiresUpdate)
  const requiresCriticalUpdate = comparison.some((entry) => entry.requiresUpdate && entry.priority === 'CRITICAL')

  return NextResponse.json({
    ok: true,
    comparison,
    requiresAnyUpdate,
    requiresCriticalUpdate,
  })
}