import { redirect } from 'next/navigation'

import { assignOfferLeadAction, createOfferAction, createOfferLeadAction, createOfferVersionAction, updateOfferAction } from '@/app/(app)/offers/actions'
import { OffersWorkspace } from '@/components/offers/OffersWorkspace'
import { getSession } from '@/lib/auth'
import { listActiveCommissionRules } from '@/lib/commission-management'
import { listManagedOffersWithCalculation, listOfferColorPalettes, listOfferLeadOptions, listOfferPricingOptions, offerStatusOptions } from '@/lib/offer-management'
import { listManagedUsers } from '@/lib/user-management'

export default async function OffersPage({
  searchParams,
}: {
  searchParams: Promise<{ leadId?: string }>
}) {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  const { leadId } = await searchParams

  const [offers, leadOptions, pricingOptions, colorPalettes, salesUsers, commissionRules] = await Promise.all([
    listManagedOffersWithCalculation(session),
    listOfferLeadOptions(session),
    listOfferPricingOptions(),
    listOfferColorPalettes(),
    listManagedUsers(),
    listActiveCommissionRules(),
  ])

  return (
    <OffersWorkspace
      offers={offers}
      leadOptions={leadOptions}
      initialLeadId={leadId ?? null}
      pricingOptions={pricingOptions}
      colorPalettes={colorPalettes}
      salesUsers={salesUsers.map((user) => ({ id: user.id, fullName: user.fullName, role: user.role, reportsToUserId: user.reportsToUserId }))}
      commissionRules={commissionRules.map((rule) => ({ userId: rule.userId, catalogKey: rule.catalogKey, valueType: rule.valueType, value: rule.value, isArchived: rule.isArchived }))}
      statusOptions={offerStatusOptions}
      createOfferAction={createOfferAction}
      assignOfferLeadAction={assignOfferLeadAction}
      createOfferLeadAction={createOfferLeadAction}
      updateOfferAction={updateOfferAction}
      createOfferVersionAction={createOfferVersionAction}
    />
  )
}