import { jsonFromServiceResult, requireAdminApiSession } from '@/lib/api-route-helpers'
import { runLegacyCatalogSync } from '@/lib/catalog-admin'
import { syncCommissionRules } from '@/lib/commission-management'

export async function POST() {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const result = await runLegacyCatalogSync()

  if (result.ok) {
    await syncCommissionRules(session.session.fullName)
  }

  return jsonFromServiceResult(result, (summary) => ({ summary }))
}