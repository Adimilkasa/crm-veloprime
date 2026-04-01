import { jsonFromServiceResult, requireAdminApiSession } from '@/lib/api-route-helpers'
import { getSalesCatalogWorkspace } from '@/lib/catalog-admin'

export async function GET() {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const result = await getSalesCatalogWorkspace()
  return jsonFromServiceResult(result, (workspace) => ({ workspace }))
}