import { readJsonRecord, jsonFromServiceResult, requireAdminApiSession } from '@/lib/api-route-helpers'
import { updateSalesBrand } from '@/lib/catalog-admin'

export async function PATCH(request: Request, context: { params: Promise<{ brandId: string }> }) {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const body = await readJsonRecord(request)

  if (!body.ok) {
    return body.response
  }

  const { brandId } = await context.params
  const result = await updateSalesBrand(brandId, body.body)
  return jsonFromServiceResult(result, (brand) => ({ brand }))
}