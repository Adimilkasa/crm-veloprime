import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import {
  createManagedLead,
  listAssignableLeadOwners,
  listCustomerWorkflowStages,
  listManagedLeads,
  listManagedLeadStages,
} from '@/lib/lead-management'
import { listManagedOffers } from '@/lib/offer-management'

export async function GET() {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const [leads, stages, customerWorkflowStages, offers, salespeople] = await Promise.all([
    listManagedLeads(session),
    listManagedLeadStages(),
    listCustomerWorkflowStages(),
    listManagedOffers(session),
    listAssignableLeadOwners(session),
  ])

  const leadOffersByLeadId = offers.reduce<Record<string, Array<{
    id: string
    number: string
    title: string
    status: string
    updatedAt: string
    versionCount: number
  }>>>((accumulator, offer) => {
    if (!offer.leadId) {
      return accumulator
    }

    if (!accumulator[offer.leadId]) {
      accumulator[offer.leadId] = []
    }

    accumulator[offer.leadId].push({
      id: offer.id,
      number: offer.number,
      title: offer.title,
      status: offer.status,
      updatedAt: offer.updatedAt,
      versionCount: offer.versions.length,
    })

    return accumulator
  }, {})

  return NextResponse.json({
    ok: true,
    leads,
    stages,
    customerWorkflowStages,
    leadOffersByLeadId,
    salespeople,
  })
}

export async function POST(request: Request) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  let body: unknown

  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ ok: false, error: 'Niepoprawne dane wejściowe.' }, { status: 400 })
  }

  const payload = body as Record<string, unknown>
  const result = await createManagedLead(session, {
    source: typeof payload.source === 'string' ? payload.source : '',
    fullName: typeof payload.fullName === 'string' ? payload.fullName : '',
    email: typeof payload.email === 'string' ? payload.email : '',
    phone: typeof payload.phone === 'string' ? payload.phone : '',
    interestedModel: typeof payload.interestedModel === 'string' ? payload.interestedModel : '',
    region: typeof payload.region === 'string' ? payload.region : '',
    message: typeof payload.message === 'string' ? payload.message : '',
    stageId: typeof payload.stageId === 'string' ? payload.stageId : '',
    salespersonId: typeof payload.salespersonId === 'string' ? payload.salespersonId : '',
  })

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  return NextResponse.json({
    ok: true,
    lead: result.lead,
  })
}