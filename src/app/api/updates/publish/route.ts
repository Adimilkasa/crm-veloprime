import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { publishUpdate, type UpdateArtifactType, type UpdatePriority } from '@/lib/update-management'

const UPDATE_ARTIFACT_TYPES: UpdateArtifactType[] = ['DATA', 'ASSETS', 'APPLICATION']
const UPDATE_PRIORITIES: UpdatePriority[] = ['CRITICAL', 'STANDARD']

function isArtifactType(value: unknown): value is UpdateArtifactType {
  return typeof value === 'string' && UPDATE_ARTIFACT_TYPES.includes(value as UpdateArtifactType)
}

function isPriority(value: unknown): value is UpdatePriority {
  return typeof value === 'string' && UPDATE_PRIORITIES.includes(value as UpdatePriority)
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

  const payload = body as Record<string, unknown>
  const artifactType = payload.artifactType
  const priority = payload.priority
  const summary = payload.summary

  if (!isArtifactType(artifactType)) {
    return NextResponse.json(
      { ok: false, error: 'artifactType musi byc jednym z: DATA, ASSETS, APPLICATION.' },
      { status: 400 }
    )
  }

  if (priority !== undefined && !isPriority(priority)) {
    return NextResponse.json(
      { ok: false, error: 'priority musi byc jednym z: CRITICAL, STANDARD.' },
      { status: 400 }
    )
  }

  if (summary !== undefined && summary !== null && typeof summary !== 'string') {
    return NextResponse.json({ ok: false, error: 'summary musi byc tekstem.' }, { status: 400 })
  }

  const result = await publishUpdate(session, {
    artifactType,
    priority,
    summary: typeof summary === 'string' ? summary : null,
  })

  if (!result.ok) {
    const status = 'status' in result && typeof result.status === 'number' ? result.status : 403
    return NextResponse.json(result, { status })
  }

  return NextResponse.json(result)
}