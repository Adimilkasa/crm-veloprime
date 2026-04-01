import { jsonFromServiceResult, requireAdminApiSession } from '@/lib/api-route-helpers'
import { getLegacyCatalogSyncStatus } from '@/lib/catalog-admin'

export async function GET() {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const result = await getLegacyCatalogSyncStatus()
  return jsonFromServiceResult(result, (status) => ({ status }))
}