import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { assignManagedOfferLead, createLeadForManagedOffer, getManagedOfferWithCalculation } from '@/lib/offer-management'

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
  const result = leadId
    ? await assignManagedOfferLead(session, {
        offerId,
        leadId,
      })
    : await createLeadForManagedOffer(session, {
        offerId,
        fullName: typeof payload.fullName === 'string' ? payload.fullName : undefined,
        email: typeof payload.email === 'string' ? payload.email : undefined,
        phone: typeof payload.phone === 'string' ? payload.phone : undefined,
        region: typeof payload.region === 'string' ? payload.region : undefined,
      })

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  const offer = await getManagedOfferWithCalculation(session, offerId)
  const responseOffer = offer
    ? {
        ...offer,
        leadId: offer.leadId ?? result.offer.leadId ?? null,
      }
    : result.offer

  return NextResponse.json({
    ok: true,
    offer: responseOffer,
  })
}