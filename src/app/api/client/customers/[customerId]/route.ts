import { jsonFromServiceResult, readJsonRecord, requireCustomerWorkspaceApiSession } from '@/lib/api-route-helpers'
import { getManagedCustomerWorkspaceForSession, updateManagedCustomer } from '@/lib/customer-management'

export async function GET(
  _request: Request,
  context: { params: Promise<{ customerId: string }> },
) {
  const session = await requireCustomerWorkspaceApiSession()

  if (!session.ok) {
    return session.response
  }

  const { customerId } = await context.params
  const result = await getManagedCustomerWorkspaceForSession(session.session, customerId)
  return jsonFromServiceResult(result, (workspace) => ({
    customer: workspace.customer,
    ownerOptions: workspace.ownerOptions,
    relatedLeads: workspace.relatedLeads,
    relatedOffers: workspace.relatedOffers,
  }))
}

export async function PATCH(
  request: Request,
  context: { params: Promise<{ customerId: string }> },
) {
  const session = await requireCustomerWorkspaceApiSession()

  if (!session.ok) {
    return session.response
  }

  const payload = await readJsonRecord(request)

  if (!payload.ok) {
    return payload.response
  }

  const { customerId } = await context.params
  const result = await updateManagedCustomer(session.session, customerId, {
    fullName: typeof payload.body.fullName === 'string' ? payload.body.fullName : '',
    email: typeof payload.body.email === 'string' ? payload.body.email : '',
    phone: typeof payload.body.phone === 'string' ? payload.body.phone : '',
    companyName: typeof payload.body.companyName === 'string' ? payload.body.companyName : '',
    taxId: typeof payload.body.taxId === 'string' ? payload.body.taxId : '',
    city: typeof payload.body.city === 'string' ? payload.body.city : '',
    notes: typeof payload.body.notes === 'string' ? payload.body.notes : '',
    ownerId: typeof payload.body.ownerId === 'string' ? payload.body.ownerId : '',
  })

  return jsonFromServiceResult(result, (customer) => ({ customer }))
}