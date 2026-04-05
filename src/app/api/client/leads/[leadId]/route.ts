import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import {
  listAssignableLeadOwners,
  listCustomerWorkflowStages,
  listManagedLeads,
  listManagedLeadStages,
} from '@/lib/lead-management'
import { listManagedOffers } from '@/lib/offer-management'

export async function GET(
  _request: Request,
  context: { params: Promise<{ leadId: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const { leadId } = await context.params
  const [leads, stages, customerWorkflowStages, offers, salespeople] = await Promise.all([
    listManagedLeads(session),
    listManagedLeadStages(),
    listCustomerWorkflowStages(),
    listManagedOffers(session),
    listAssignableLeadOwners(session),
  ])

  const lead = leads.find((entry) => entry.id === leadId) ?? null

  if (!lead) {
    return NextResponse.json({ ok: false, error: 'Nie znaleziono leada.' }, { status: 404 })
  }

  const linkedOffers = offers
    .filter((offer) => offer.leadId === leadId)
    .map((offer) => ({
      id: offer.id,
      number: offer.number,
      title: offer.title,
      status: offer.status,
      updatedAt: offer.updatedAt,
      versionCount: offer.versions.length,
    }))

  return NextResponse.json({
    ok: true,
    lead,
    stages,
    customerWorkflowStages,
    linkedOffers,
    salespeople,
  })
}