import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { getOfferAssetBundle } from '@/lib/offer-assets'
import { getOfferDocumentSnapshot } from '@/lib/offer-management'

function describeOfferDocumentError(error: unknown) {
  const details = error instanceof Error ? error.message.trim() : String(error ?? '').trim()
  return details
    ? `Nie udało się pobrać dokumentu oferty. Szczegóły: ${details}`
    : 'Nie udało się pobrać dokumentu oferty.'
}

export async function GET(
  request: Request,
  context: { params: Promise<{ offerId: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const { offerId } = await context.params
  const { searchParams } = new URL(request.url)
  const versionId = searchParams.get('versionId')
  try {
    const document = await getOfferDocumentSnapshot(session, offerId, versionId)

    if (!document) {
      return NextResponse.json({ ok: false, error: 'Nie znaleziono dokumentu oferty.' }, { status: 404 })
    }

    const assets = await getOfferAssetBundle({
      modelName: document.payload.customer.modelName,
      catalogKey: document.payload.internal.catalogKey,
      powertrainType: document.payload.internal.powertrainType,
    })

    return NextResponse.json({
      ok: true,
      document: {
        offerId: document.offer.id,
        offerNumber: document.offer.number,
        title: document.offer.title,
        version: document.version
          ? {
              id: document.version.id,
              versionNumber: document.version.versionNumber,
              summary: document.version.summary,
              createdAt: document.version.createdAt,
            }
          : null,
        payload: document.payload,
        assets,
      },
    })
  } catch (error) {
    return NextResponse.json({ ok: false, error: describeOfferDocumentError(error) }, { status: 500 })
  }
}