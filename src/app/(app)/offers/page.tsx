import { redirect } from 'next/navigation'

import { createOfferAction, createOfferVersionAction, updateOfferAction } from '@/app/(app)/offers/actions'
import { OffersWorkspace } from '@/components/offers/OffersWorkspace'
import { getSession } from '@/lib/auth'
import { listManagedOffersWithCalculation, listOfferLeadOptions, listOfferPricingOptions, offerStatusOptions } from '@/lib/offer-management'
import { getActivePricingSheet } from '@/lib/pricing-management'
import { getRoleDefinition } from '@/lib/rbac'

export default async function OffersPage() {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  const [offers, leadOptions, pricingOptions, pricingSheet] = await Promise.all([
    listManagedOffersWithCalculation(session),
    listOfferLeadOptions(session),
    listOfferPricingOptions(),
    getActivePricingSheet(),
  ])

  const roleDefinition = getRoleDefinition(session.role)

  return (
    <OffersWorkspace
      offers={offers}
      leadOptions={leadOptions}
      pricingOptions={pricingOptions}
      pricingSnapshot={{
        headersCount: pricingSheet.headers.length,
        rowsCount: pricingSheet.rows.length,
        updatedAt: pricingSheet.updatedAt,
        updatedBy: pricingSheet.updatedBy,
      }}
      roleLabel={roleDefinition.label}
      statusOptions={offerStatusOptions}
      createOfferAction={createOfferAction}
      updateOfferAction={updateOfferAction}
      createOfferVersionAction={createOfferVersionAction}
    />
  )
}