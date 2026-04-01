import { readJsonRecord, jsonFromServiceResult, requireAdminApiSession } from '@/lib/api-route-helpers'
import { createSalesPricing } from '@/lib/catalog-admin'

export async function POST(request: Request, context: { params: Promise<{ versionId: string }> }) {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const body = await readJsonRecord(request)

  if (!body.ok) {
    return body.response
  }

  const { versionId } = await context.params
  const result = await createSalesPricing(versionId, body.body)
  return jsonFromServiceResult(result, (pricing) => ({ pricing }), 201)
}