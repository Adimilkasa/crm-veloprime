import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { getManagedOfferWithCalculation } from '@/lib/offer-management'
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

  const payload = body as Record<string, unknown>
  const offerId = typeof payload.offerId === 'string' ? payload.offerId.trim() : ''
  const clientVersions = normalizeClientVersions(body)

  if (!offerId) {
    return NextResponse.json({ ok: false, error: 'offerId jest wymagane.' }, { status: 400 })
  }

  if (!clientVersions) {
    return NextResponse.json(
      {
        ok: false,
        error: 'Przekaz obiekt versions z polami DATA, ASSETS i APPLICATION.',
      },
      { status: 400 }
    )
  }

  const comparison = await compareClientVersions(clientVersions)
  const requiresCriticalUpdate = comparison.some((entry) => entry.requiresUpdate && entry.priority === 'CRITICAL')

  if (requiresCriticalUpdate) {
    return NextResponse.json(
      {
        ok: false,
        code: 'UPDATE_REQUIRED',
        error: 'Oferta nie moze zostac sfinalizowana na nieaktualnej wersji danych krytycznych.',
        comparison,
      },
      { status: 409 }
    )
  }

  const offer = await getManagedOfferWithCalculation(session, offerId)

  if (!offer) {
    return NextResponse.json({ ok: false, error: 'Nie znaleziono oferty.' }, { status: 404 })
  }

  if (offer.pricingCatalogKey && !offer.calculation) {
    return NextResponse.json(
      {
        ok: false,
        code: 'RECALCULATION_REQUIRED',
        error: 'Oferta wymaga ponownego przeliczenia przed finalizacja.',
      },
      { status: 409 }
    )
  }

  if (offer.totalGross === null || offer.totalNet === null) {
    return NextResponse.json(
      {
        ok: false,
        code: 'INCOMPLETE_OFFER',
        error: 'Oferta nie ma kompletnej wartosci koncowej i nie moze zostac sfinalizowana.',
      },
      { status: 409 }
    )
  }

  const approvalId = `approval-${crypto.randomUUID()}`
  const approvedAt = new Date().toISOString()

  return NextResponse.json({
    ok: true,
    approval: {
      approvalId,
      approvedAt,
      offerId: offer.id,
      offerNumber: offer.number,
      title: offer.title,
      totalGross: offer.totalGross,
      totalNet: offer.totalNet,
      customerName: offer.customerName,
    },
    comparison,
  })
}