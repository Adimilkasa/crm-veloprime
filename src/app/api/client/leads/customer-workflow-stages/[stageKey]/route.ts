import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { updateCustomerWorkflowStageDefinition } from '@/lib/lead-management'

export async function PATCH(
  request: Request,
  context: { params: Promise<{ stageKey: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const { stageKey } = await context.params

  let body: unknown

  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ ok: false, error: 'Niepoprawne dane wejściowe.' }, { status: 400 })
  }

  const payload = body as Record<string, unknown>
  const result = await updateCustomerWorkflowStageDefinition(session, stageKey, {
    label: typeof payload.label === 'string' ? payload.label : '',
  })

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  return NextResponse.json({ ok: true, stage: result.stage })
}