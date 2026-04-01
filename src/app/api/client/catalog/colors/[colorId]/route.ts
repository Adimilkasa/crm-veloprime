import { readJsonRecord, jsonFromServiceResult, requireAdminApiSession } from '@/lib/api-route-helpers'
import { deleteSalesModelColor, updateSalesModelColor } from '@/lib/catalog-admin'

export async function PATCH(request: Request, context: { params: Promise<{ colorId: string }> }) {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const body = await readJsonRecord(request)

  if (!body.ok) {
    return body.response
  }

  const { colorId } = await context.params
  const result = await updateSalesModelColor(colorId, body.body)
  return jsonFromServiceResult(result, (color) => ({ color }))
}

export async function DELETE(_request: Request, context: { params: Promise<{ colorId: string }> }) {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const { colorId } = await context.params
  const result = await deleteSalesModelColor(colorId)
  return jsonFromServiceResult(result, (deleted) => ({ deleted }))
}