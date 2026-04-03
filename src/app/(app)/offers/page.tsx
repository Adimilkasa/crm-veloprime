import { redirect } from 'next/navigation'

import { assignOfferLeadAction, createOfferAction, createOfferVersionAction, updateOfferAction } from '@/app/(app)/offers/actions'
import { OffersWorkspace } from '@/components/offers/OffersWorkspace'
import { getSession } from '@/lib/auth'
import { listManagedOffers, listOfferLeadOptions, listOfferPricingOptions, offerStatusOptions } from '@/lib/offer-management'

export default async function OffersPage({
  searchParams,
}: {
  searchParams: Promise<{ leadId?: string; offerId?: string }>
}) {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  const { leadId, offerId } = await searchParams

  const [offers, leadOptions, pricingOptions] = await Promise.all([
    listManagedOffers(session),
    listOfferLeadOptions(session),
    listOfferPricingOptions(),
  ])

  return (
    <OffersWorkspace
      offers={offers}
      leadOptions={leadOptions}
      initialLeadId={leadId ?? null}
      initialOfferId={offerId ?? null}
      pricingOptions={pricingOptions}
      statusOptions={offerStatusOptions}
      createOfferAction={createOfferAction}
      assignOfferLeadAction={assignOfferLeadAction}
      updateOfferAction={updateOfferAction}
      createOfferVersionAction={createOfferVersionAction}
    />
  )
}