import { readJsonRecord, jsonFromServiceResult, requireAdminApiSession } from '@/lib/api-route-helpers'
import { createSalesModel } from '@/lib/catalog-admin'

export async function POST(request: Request) {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const body = await readJsonRecord(request)

  if (!body.ok) {
    return body.response
  }

  const result = await createSalesModel(body.body)
  return jsonFromServiceResult(result, (model) => ({ model }), 201)
}