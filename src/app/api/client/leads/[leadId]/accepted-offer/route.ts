import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { updateManagedLeadAcceptedOffer } from '@/lib/lead-management'

export async function PATCH(
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
  const result = await updateManagedLeadAcceptedOffer(
    session,
    leadId,
    typeof payload.acceptedOfferId === 'string' ? payload.acceptedOfferId : '',
  )

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  return NextResponse.json({ ok: true, lead: result.lead })
}