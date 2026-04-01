import { readJsonRecord, jsonFromServiceResult, requireAdminApiSession } from '@/lib/api-route-helpers'
import { getSalesModelAssets, updateSalesModelAssets } from '@/lib/catalog-admin'

export async function GET(_request: Request, context: { params: Promise<{ modelId: string }> }) {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const { modelId } = await context.params
  const result = await getSalesModelAssets(modelId)
  return jsonFromServiceResult(result, (assetBundle) => ({ assetBundle }))
}

export async function PATCH(request: Request, context: { params: Promise<{ modelId: string }> }) {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const body = await readJsonRecord(request)

  if (!body.ok) {
    return body.response
  }

  const { modelId } = await context.params
  const result = await updateSalesModelAssets(modelId, body.body)
  return jsonFromServiceResult(result, (assetBundle) => ({ assetBundle }))
}