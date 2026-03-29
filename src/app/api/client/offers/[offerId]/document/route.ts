import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { getOfferAssetBundle } from '@/lib/offer-assets'
import { getOfferDocumentSnapshot } from '@/lib/offer-management'

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
  const document = await getOfferDocumentSnapshot(session, offerId, versionId)

  if (!document) {
    return NextResponse.json({ ok: false, error: 'Nie znaleziono dokumentu oferty.' }, { status: 404 })
  }

  const assets = await getOfferAssetBundle(document.payload.customer.modelName)

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
            pdfUrl: document.version.pdfUrl,
          }
        : null,
      payload: document.payload,
      assets,
    },
  })
}