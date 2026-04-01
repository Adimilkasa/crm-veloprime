import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { listManagedLeadStages, listManagedLeads, type ManagedLead } from '@/lib/lead-management'
import { listManagedOffers, listOfferLeadOptions, listOfferPricingOptions, offerStatusOptions } from '@/lib/offer-management'
import { getSalesCatalogBootstrap } from '@/lib/sales-catalog-management'
import { getPublishedUpdateManifest } from '@/lib/update-management'

function normalizeComparable(value: string | null | undefined) {
  return value?.trim().toLowerCase() ?? ''
}

function attachLeadId<T extends { leadId: string | null; customerName: string; customerEmail: string | null; customerPhone: string | null }>(offer: T, leads: ManagedLead[]) {
  if (offer.leadId) {
    return offer
  }

  const normalizedName = normalizeComparable(offer.customerName)
  const normalizedEmail = normalizeComparable(offer.customerEmail)
  const normalizedPhone = normalizeComparable(offer.customerPhone)
  const matchedLead = leads.find((lead) => {
    const sameEmail = normalizedEmail && normalizeComparable(lead.email) === normalizedEmail
    const samePhone = normalizedPhone && normalizeComparable(lead.phone) === normalizedPhone
    const sameName = normalizedName && normalizeComparable(lead.fullName) === normalizedName

    return Boolean(sameEmail || samePhone || (sameName && (!normalizedEmail || !normalizedPhone)))
  })

  return matchedLead ? { ...offer, leadId: matchedLead.id } : offer
}

export async function GET() {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const [manifest, catalog, offers, leads, leadOptions, pricingOptions, leadStages] = await Promise.all([
    getPublishedUpdateManifest(),
    getSalesCatalogBootstrap(),
    listManagedOffers(session),
    listManagedLeads(session),
    listOfferLeadOptions(session),
    listOfferPricingOptions(),
    listManagedLeadStages(),
  ])

  const offersWithLeadIds = offers.map((offer) => attachLeadId(offer, leads))

  return NextResponse.json({
    ok: true,
    session: {
      sub: session.sub,
      email: session.email,
      fullName: session.fullName,
      role: session.role,
    },
    manifest,
    catalog,
    offers: offersWithLeadIds,
    leadOptions,
    pricingOptions,
    leadStages,
    offerStatusOptions,
  })
}