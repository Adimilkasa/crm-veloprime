import { redirect } from 'next/navigation'

import { clearPricingSheetAction, importPricingSheetAction, savePricingSheetAction } from '@/app/(app)/pricing/actions'
import { PricingWorkspace } from '@/components/pricing/PricingWorkspace'
import { getSession } from '@/lib/auth'
import { getPricingSheet } from '@/lib/pricing-management'
import { getRoleDefinition } from '@/lib/rbac'

export default async function PricingPage() {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  const result = await getPricingSheet(session)

  if (!result.ok) {
    redirect('/dashboard')
  }

  const roleDefinition = getRoleDefinition(session.role)

  return (
    <PricingWorkspace
      roleLabel={roleDefinition.label}
      sheet={result.sheet}
      importPricingSheetAction={importPricingSheetAction}
      savePricingSheetAction={savePricingSheetAction}
      clearPricingSheetAction={clearPricingSheetAction}
    />
  )
}