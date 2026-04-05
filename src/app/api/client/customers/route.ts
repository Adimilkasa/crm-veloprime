import { jsonFromServiceResult, readJsonRecord, requireAdminApiSession } from '@/lib/api-route-helpers'
import { createManagedCustomerFromLead } from '@/lib/customer-management'

export async function POST(request: Request) {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const payload = await readJsonRecord(request)

  if (!payload.ok) {
    return payload.response
  }

  const result = await createManagedCustomerFromLead(
    session.session,
    typeof payload.body.leadId === 'string' ? payload.body.leadId : '',
  )

  return jsonFromServiceResult(result, (workspace) => ({
    customer: workspace.customer,
    ownerOptions: workspace.ownerOptions,
    relatedLeads: workspace.relatedLeads,
    relatedOffers: workspace.relatedOffers,
  }), 201)
}