import { jsonFromServiceResult, requireAdminApiSession } from '@/lib/api-route-helpers'
import { archiveSalesModel } from '@/lib/catalog-admin'

export async function POST(_request: Request, context: { params: Promise<{ modelId: string }> }) {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const { modelId } = await context.params
  const result = await archiveSalesModel(modelId)
  return jsonFromServiceResult(result, (model) => ({ model }))
}