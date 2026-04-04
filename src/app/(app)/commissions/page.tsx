import { redirect } from 'next/navigation'

import { saveCommissionRulesAction, syncCommissionRulesAction } from '@/app/(app)/commissions/actions'
import { CommissionsWorkspace } from '@/components/commissions/CommissionsWorkspace'
import { getSession } from '@/lib/auth'
import { getCommissionWorkspace } from '@/lib/commission-management'
import { getRoleDefinition } from '@/lib/rbac'

export default async function CommissionsPage({
  searchParams,
}: {
  searchParams: Promise<{ userId?: string }>
}) {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  const { userId } = await searchParams
  const result = await getCommissionWorkspace(session, userId)

  if (!result.ok) {
    redirect('/dashboard')
  }

  const roleDefinition = getRoleDefinition(session.role)

  return (
    <CommissionsWorkspace
      role={session.role}
      roleLabel={roleDefinition.label}
      targetUserId={result.targetUserId}
      editable={result.editable}
      users={result.users}
      rules={result.rules}
      summary={result.summary}
      updatedAt={result.updatedAt}
      updatedBy={result.updatedBy}
      saveCommissionRulesAction={saveCommissionRulesAction}
      syncCommissionRulesAction={syncCommissionRulesAction}
    />
  )
}