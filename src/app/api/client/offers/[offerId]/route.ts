import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { getManagedOfferWithCalculation, updateManagedOffer } from '@/lib/offer-management'

export async function GET(
  _request: Request,
  context: { params: Promise<{ offerId: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const { offerId } = await context.params
  const offer = await getManagedOfferWithCalculation(session, offerId)

  if (!offer) {
    return NextResponse.json({ ok: false, error: 'Nie znaleziono oferty.' }, { status: 404 })
  }

  return NextResponse.json({
    ok: true,
    offer,
  })
}

export async function PATCH(
  request: Request,
  context: { params: Promise<{ offerId: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const { offerId } = await context.params
  const currentOffer = await getManagedOfferWithCalculation(session, offerId)

  if (!currentOffer) {
    return NextResponse.json({ ok: false, error: 'Nie znaleziono oferty.' }, { status: 404 })
  }

  let body: unknown

  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ ok: false, error: 'Niepoprawne dane wejściowe.' }, { status: 400 })
  }

  const payload = body as Record<string, unknown>

  const result = await updateManagedOffer(session, {
    offerId,
    title: typeof payload.title === 'string' ? payload.title : currentOffer.title,
    status: typeof payload.status === 'string' ? (payload.status as typeof currentOffer.status) : currentOffer.status,
    customerName: typeof payload.customerName === 'string' ? payload.customerName : currentOffer.customerName,
    customerEmail: typeof payload.customerEmail === 'string' ? payload.customerEmail : currentOffer.customerEmail ?? '',
    customerPhone: typeof payload.customerPhone === 'string' ? payload.customerPhone : currentOffer.customerPhone ?? '',
    customerRegion: typeof payload.customerRegion === 'string' ? payload.customerRegion : '',
    pricingCatalogKey: typeof payload.pricingCatalogKey === 'string' ? payload.pricingCatalogKey : currentOffer.pricingCatalogKey ?? '',
    selectedColorName: typeof payload.selectedColorName === 'string' ? payload.selectedColorName : currentOffer.selectedColorName ?? '',
    customerType: payload.customerType === 'BUSINESS' ? 'BUSINESS' : payload.customerType === 'PRIVATE' ? 'PRIVATE' : currentOffer.customerType,
    discountValue: typeof payload.discountValue === 'string' ? payload.discountValue : currentOffer.discountValue?.toString() ?? '',
    financingVariant: typeof payload.financingVariant === 'string' ? payload.financingVariant : currentOffer.financingVariant ?? '',
    financingTermMonths: typeof payload.financingTermMonths === 'string'
      ? payload.financingTermMonths
      : currentOffer.financingTermMonths?.toString() ?? '',
    financingInputMode: 'AMOUNT',
    financingInputValue: typeof payload.financingInputValue === 'string'
      ? payload.financingInputValue
      : currentOffer.financingInputValue?.toString() ?? '',
    financingBuyoutPercent: typeof payload.financingBuyoutPercent === 'string'
      ? payload.financingBuyoutPercent
      : currentOffer.financingBuyoutPercent?.toString() ?? '',
    validUntil: typeof payload.validUntil === 'string'
      ? payload.validUntil
      : currentOffer.validUntil ? currentOffer.validUntil.slice(0, 10) : '',
    notes: typeof payload.notes === 'string' ? payload.notes : currentOffer.notes ?? '',
  })

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  const updatedOffer = await getManagedOfferWithCalculation(session, offerId)

  return NextResponse.json({
    ok: true,
    offer: updatedOffer ?? result.offer,
  })
}