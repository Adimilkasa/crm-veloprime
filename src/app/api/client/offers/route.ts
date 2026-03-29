import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { createManagedOffer, getManagedOfferWithCalculation } from '@/lib/offer-management'

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
  const result = await createManagedOffer(session, {
    leadId: typeof payload.leadId === 'string' ? payload.leadId : undefined,
    customerName: typeof payload.customerName === 'string' ? payload.customerName : undefined,
    customerEmail: typeof payload.customerEmail === 'string' ? payload.customerEmail : undefined,
    customerPhone: typeof payload.customerPhone === 'string' ? payload.customerPhone : undefined,
    customerRegion: typeof payload.customerRegion === 'string' ? payload.customerRegion : undefined,
    title: typeof payload.title === 'string' ? payload.title : '',
    pricingCatalogKey: typeof payload.pricingCatalogKey === 'string' ? payload.pricingCatalogKey : undefined,
    selectedColorName: typeof payload.selectedColorName === 'string' ? payload.selectedColorName : undefined,
    customerType: payload.customerType === 'BUSINESS' ? 'BUSINESS' : 'PRIVATE',
    discountValue: typeof payload.discountValue === 'string' ? payload.discountValue : undefined,
    financingVariant: typeof payload.financingVariant === 'string' ? payload.financingVariant : undefined,
    financingTermMonths: typeof payload.financingTermMonths === 'string' ? payload.financingTermMonths : undefined,
    financingInputMode: 'AMOUNT',
    financingInputValue: typeof payload.financingInputValue === 'string' ? payload.financingInputValue : undefined,
    financingBuyoutPercent: typeof payload.financingBuyoutPercent === 'string' ? payload.financingBuyoutPercent : undefined,
    validUntil: typeof payload.validUntil === 'string' ? payload.validUntil : undefined,
    notes: typeof payload.notes === 'string' ? payload.notes : undefined,
  })

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  const offer = await getManagedOfferWithCalculation(session, result.offer.id)

  return NextResponse.json({
    ok: true,
    offer: offer ?? result.offer,
  })
}