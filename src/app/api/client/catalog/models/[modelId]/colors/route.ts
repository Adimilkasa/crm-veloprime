import { readJsonRecord, jsonFromServiceResult, requireAdminApiSession } from '@/lib/api-route-helpers'
import { createSalesModelColor } from '@/lib/catalog-admin'

export async function POST(request: Request, context: { params: Promise<{ modelId: string }> }) {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const body = await readJsonRecord(request)

  if (!body.ok) {
    return body.response
  }

  const { modelId } = await context.params
  const result = await createSalesModelColor(modelId, body.body)
  return jsonFromServiceResult(result, (color) => ({ color }), 201)
}