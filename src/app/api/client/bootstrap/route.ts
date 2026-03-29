import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { listManagedLeadStages } from '@/lib/lead-management'
import { listManagedOffers, listOfferLeadOptions, listOfferPricingOptions, offerStatusOptions } from '@/lib/offer-management'
import { getPublishedUpdateManifest } from '@/lib/update-management'

export async function GET() {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const [manifest, offers, leadOptions, pricingOptions, leadStages] = await Promise.all([
    getPublishedUpdateManifest(),
    listManagedOffers(session),
    listOfferLeadOptions(session),
    listOfferPricingOptions(),
    listManagedLeadStages(),
  ])

  return NextResponse.json({
    ok: true,
    session: {
      sub: session.sub,
      email: session.email,
      fullName: session.fullName,
      role: session.role,
    },
    manifest,
    offers,
    leadOptions,
    pricingOptions,
    leadStages,
    offerStatusOptions,
  })
}