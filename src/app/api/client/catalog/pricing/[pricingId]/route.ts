import { readJsonRecord, jsonFromServiceResult, requireAdminApiSession } from '@/lib/api-route-helpers'
import { updateSalesPricing } from '@/lib/catalog-admin'

export async function PATCH(request: Request, context: { params: Promise<{ pricingId: string }> }) {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const body = await readJsonRecord(request)

  if (!body.ok) {
    return body.response
  }

  const { pricingId } = await context.params
  const result = await updateSalesPricing(pricingId, body.body)
  return jsonFromServiceResult(result, (pricing) => ({ pricing }))
}