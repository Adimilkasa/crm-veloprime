import { jsonFromServiceResult, requireAdminApiSession } from '@/lib/api-route-helpers'
import { deleteSalesAssetFile } from '@/lib/catalog-admin'

export async function DELETE(_request: Request, context: { params: Promise<{ fileId: string }> }) {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const { fileId } = await context.params
  const result = await deleteSalesAssetFile(fileId)
  return jsonFromServiceResult(result, (deleted) => ({ deleted }))
}