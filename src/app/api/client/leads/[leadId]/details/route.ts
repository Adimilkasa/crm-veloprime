import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { addManagedLeadDetailEntry } from '@/lib/lead-management'

export async function POST(
  request: Request,
  context: { params: Promise<{ leadId: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const { leadId } = await context.params

  let body: unknown

  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ ok: false, error: 'Niepoprawne dane wejściowe.' }, { status: 400 })
  }

  const payload = body as Record<string, unknown>
  const result = await addManagedLeadDetailEntry(session, {
    leadId,
    kind: payload.kind === 'COMMENT' ? 'COMMENT' : 'INFO',
    label: typeof payload.label === 'string' ? payload.label : undefined,
    value: typeof payload.value === 'string' ? payload.value : '',
  })

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  return NextResponse.json({ ok: true, entry: result.entry })
}