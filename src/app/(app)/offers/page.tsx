import { redirect } from 'next/navigation'

import { createOfferAction, createOfferVersionAction, updateOfferAction } from '@/app/(app)/offers/actions'
import { OffersWorkspace } from '@/components/offers/OffersWorkspace'
import { getSession } from '@/lib/auth'
import { listActiveCommissionRules } from '@/lib/commission-management'
import { listManagedOffersWithCalculation, listOfferColorPalettes, listOfferLeadOptions, listOfferPricingOptions, offerStatusOptions } from '@/lib/offer-management'
import { getActivePricingSheet } from '@/lib/pricing-management'
import { getRoleDefinition } from '@/lib/rbac'
import { listManagedUsers } from '@/lib/user-management'

export default async function OffersPage() {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  const [offers, leadOptions, pricingOptions, colorPalettes, pricingSheet, salesUsers, commissionRules] = await Promise.all([
    listManagedOffersWithCalculation(session),
    listOfferLeadOptions(session),
    listOfferPricingOptions(),
    listOfferColorPalettes(),
    getActivePricingSheet(),
    listManagedUsers(),
    listActiveCommissionRules(),
  ])

  const roleDefinition = getRoleDefinition(session.role)

  return (
    <OffersWorkspace
      offers={offers}
      leadOptions={leadOptions}
      pricingOptions={pricingOptions}
      colorPalettes={colorPalettes}
      salesUsers={salesUsers.map((user) => ({ id: user.id, fullName: user.fullName, role: user.role, reportsToUserId: user.reportsToUserId }))}
      commissionRules={commissionRules.map((rule) => ({ userId: rule.userId, catalogKey: rule.catalogKey, valueType: rule.valueType, value: rule.value, isArchived: rule.isArchived }))}
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