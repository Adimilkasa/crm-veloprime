import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { assignManagedOfferLead, getManagedOfferWithCalculation } from '@/lib/offer-management'

export async function POST(
  request: Request,
  context: { params: Promise<{ offerId: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const { offerId } = await context.params

  let body: unknown

  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ ok: false, error: 'Niepoprawne dane wejściowe.' }, { status: 400 })
  }

  const payload = body as Record<string, unknown>
  const leadId = typeof payload.leadId === 'string' ? payload.leadId.trim() : ''

  if (!leadId) {
    return NextResponse.json({ ok: false, error: 'leadId jest wymagane.' }, { status: 400 })
  }

  const result = await assignManagedOfferLead(session, {
    offerId,
    leadId,
  })

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  const offer = await getManagedOfferWithCalculation(session, offerId)

  return NextResponse.json({
    ok: true,
    offer: offer ?? result.offer,
  })
}