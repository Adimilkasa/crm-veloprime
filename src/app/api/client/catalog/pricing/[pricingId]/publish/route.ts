import { jsonFromServiceResult, requireAdminApiSession } from '@/lib/api-route-helpers'
import { publishSalesPricing } from '@/lib/catalog-admin'

export async function POST(_request: Request, context: { params: Promise<{ pricingId: string }> }) {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const { pricingId } = await context.params
  const result = await publishSalesPricing(pricingId)
  return jsonFromServiceResult(result, (pricing) => ({ pricing }))
}