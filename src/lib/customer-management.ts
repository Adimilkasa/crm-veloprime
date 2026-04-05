import 'server-only'

import type { AuthSession } from '@/lib/auth'
import { db } from '@/lib/db'
import { listManagedUsers, type ManagedUser } from '@/lib/user-management'

export type ManagedCustomer = {
  id: string
  fullName: string
  email: string | null
  phone: string | null
  companyName: string | null
  taxId: string | null
  city: string | null
  notes: string | null
  ownerId: string | null
  ownerName: string | null
  leadCount: number
  offerCount: number
  createdAt: string
  updatedAt: string
}

export type ManagedCustomerOwnerOption = {
  id: string
  fullName: string
  role: string
}

export type ManagedCustomerLeadHistoryItem = {
  id: string
  fullName: string
  stageLabel: string
  salespersonName: string | null
  updatedAt: string
  acceptedAt: string | null
}

export type ManagedCustomerOfferHistoryItem = {
  id: string
  number: string
  title: string
  status: string
  ownerName: string | null
  updatedAt: string
}

export type ManagedCustomerWorkspace = {
  customer: ManagedCustomer
  ownerOptions: ManagedCustomerOwnerOption[]
  relatedLeads: ManagedCustomerLeadHistoryItem[]
  relatedOffers: ManagedCustomerOfferHistoryItem[]
}

const LEAD_STAGE_LABELS: Record<string, string> = {
  NEW_LEAD: 'Nowy lead',
  FIRST_CONTACT: 'Pierwszy kontakt',
  FOLLOW_UP: 'Ponowny kontakt',
  MEETING_SCHEDULED: 'Umówione spotkanie',
  OFFER_SHARED: 'Oferta przekazana',
  WON: 'Wygrane',
  LOST: 'Stracone',
  ON_HOLD: 'Wstrzymane',
}

function splitFullName(fullName: string) {
  const normalized = fullName.trim().replace(/\s+/g, ' ')
  const [firstName, ...lastNameParts] = normalized.split(' ')

  return {
    firstName: firstName || null,
    lastName: lastNameParts.join(' ').trim() || null,
  }
}

function mapManagedCustomer(record: {
  id: string
  fullName: string
  email: string | null
  phone: string | null
  companyName: string | null
  taxId: string | null
  city: string | null
  notes: string | null
  ownerId: string | null
  owner: { fullName: string } | null
  createdAt: Date
  updatedAt: Date
  _count: {
    leads: number
    offers: number
  }
}): ManagedCustomer {
  return {
    id: record.id,
    fullName: record.fullName,
    email: record.email,
    phone: record.phone,
    companyName: record.companyName,
    taxId: record.taxId,
    city: record.city,
    notes: record.notes,
    ownerId: record.ownerId,
    ownerName: record.owner?.fullName ?? null,
    leadCount: record._count.leads,
    offerCount: record._count.offers,
    createdAt: record.createdAt.toISOString(),
    updatedAt: record.updatedAt.toISOString(),
  }
}

function normalizeOptional(value: string | null | undefined) {
  const trimmed = value?.trim() ?? ''
  return trimmed ? trimmed : null
}

function buildUserHierarchyMaps(users: ManagedUser[]) {
  const children = new Map<string, ManagedUser[]>()

  for (const user of users) {
    const supervisorId = user.reportsToUserId ?? null

    if (!supervisorId) {
      continue
    }

    const bucket = children.get(supervisorId) ?? []
    bucket.push(user)
    children.set(supervisorId, bucket)
  }

  return { children }
}

function collectDescendantIds(rootUserId: string, children: Map<string, ManagedUser[]>) {
  const visible = new Set<string>([rootUserId])
  const queue = [rootUserId]

  while (queue.length > 0) {
    const current = queue.shift()

    if (!current) {
      continue
    }

    for (const child of children.get(current) ?? []) {
      if (visible.has(child.id)) {
        continue
      }

      visible.add(child.id)
      queue.push(child.id)
    }
  }

  return visible
}

function canManageCustomers(session: AuthSession) {
  return session.role === 'ADMIN' || session.role === 'DIRECTOR' || session.role === 'MANAGER'
}

function getVisibleCustomerOwnerIds(session: AuthSession, users: ManagedUser[]) {
  if (session.role === 'ADMIN') {
    return new Set(users.filter((user) => user.isActive).map((user) => user.id))
  }

  const { children } = buildUserHierarchyMaps(users)
  return collectDescendantIds(session.sub, children)
}

async function listOwnerOptions(visibleOwnerIds: Set<string>) {
  if (!db || visibleOwnerIds.size === 0) {
    return [] satisfies ManagedCustomerOwnerOption[]
  }

  const users = await db.user.findMany({
    where: {
      isActive: true,
      id: {
        in: Array.from(visibleOwnerIds),
      },
    },
    orderBy: [
      { role: 'asc' },
      { fullName: 'asc' },
    ],
    select: {
      id: true,
      fullName: true,
      role: true,
    },
  })

  return users.map((user) => ({
    id: user.id,
    fullName: user.fullName,
    role: user.role,
  }))
}

function buildCustomerWorkspace(input: {
  customer: ManagedCustomer
  ownerOptions: ManagedCustomerOwnerOption[]
  relatedLeads: Array<{
    id: string
    firstName: string | null
    lastName: string | null
    pipelineStage: string
    acceptedAt: Date | null
    updatedAt: Date
    salespersonId: string | null
    salesperson: { fullName: string } | null
  }>
  relatedOffers: Array<{
    id: string
    number: string
    title: string
    status: string
    updatedAt: Date
    ownerId: string
    owner: { fullName: string } | null
  }>
}): ManagedCustomerWorkspace {
  return {
    customer: input.customer,
    ownerOptions: input.ownerOptions,
    relatedLeads: input.relatedLeads
      .map((lead) => ({
        id: lead.id,
        fullName: [lead.firstName?.trim(), lead.lastName?.trim()].filter(Boolean).join(' ').trim() || 'Klient bez nazwy',
        stageLabel: LEAD_STAGE_LABELS[lead.pipelineStage] ?? lead.pipelineStage,
        salespersonName: lead.salesperson?.fullName ?? null,
        updatedAt: lead.updatedAt.toISOString(),
        acceptedAt: lead.acceptedAt?.toISOString() ?? null,
      }))
      .sort((left, right) => right.updatedAt.localeCompare(left.updatedAt)),
    relatedOffers: input.relatedOffers
      .map((offer) => ({
        id: offer.id,
        number: offer.number,
        title: offer.title,
        status: offer.status,
        ownerName: offer.owner?.fullName ?? null,
        updatedAt: offer.updatedAt.toISOString(),
      }))
      .sort((left, right) => right.updatedAt.localeCompare(left.updatedAt)),
  }
}

function canViewCustomerRecord(input: {
  session: AuthSession
  visibleOwnerIds: Set<string>
  customerOwnerId: string | null
  leadSalespersonIds: Array<string | null>
  offerOwnerIds: string[]
}) {
  if (input.session.role === 'ADMIN') {
    return true
  }

  if (input.customerOwnerId && input.visibleOwnerIds.has(input.customerOwnerId)) {
    return true
  }

  if (input.leadSalespersonIds.some((salespersonId) => salespersonId && input.visibleOwnerIds.has(salespersonId))) {
    return true
  }

  return input.offerOwnerIds.some((ownerId) => input.visibleOwnerIds.has(ownerId))
}

async function getManagedCustomerWorkspaceInternal(session: AuthSession, customerId: string) {
  if (!db) {
    return { ok: false as const, error: 'Baza danych nie jest dostępna dla modułu klientów.', status: 503 }
  }

  if (!canManageCustomers(session)) {
    return { ok: false as const, error: 'Brak dostępu do kart klientów.', status: 403 }
  }

  const users = await listManagedUsers()
  const visibleOwnerIds = getVisibleCustomerOwnerIds(session, users)

  const customer = await db.customer.findUnique({
    where: { id: customerId },
    include: {
      owner: {
        select: { fullName: true },
      },
      _count: {
        select: {
          leads: true,
          offers: true,
        },
      },
      leads: {
        select: {
          id: true,
          firstName: true,
          lastName: true,
          pipelineStage: true,
          acceptedAt: true,
          updatedAt: true,
          salespersonId: true,
          salesperson: {
            select: { fullName: true },
          },
        },
      },
      offers: {
        select: {
          id: true,
          number: true,
          title: true,
          status: true,
          updatedAt: true,
          ownerId: true,
          owner: {
            select: { fullName: true },
          },
        },
      },
    },
  })

  if (!customer) {
    return { ok: false as const, error: 'Nie znaleziono karty klienta.', status: 404 }
  }

  if (!canViewCustomerRecord({
    session,
    visibleOwnerIds,
    customerOwnerId: customer.ownerId,
    leadSalespersonIds: customer.leads.map((lead) => lead.salespersonId),
    offerOwnerIds: customer.offers.map((offer) => offer.ownerId),
  })) {
    return { ok: false as const, error: 'Nie znaleziono karty klienta.', status: 404 }
  }

  const relatedLeads = session.role === 'ADMIN'
    ? customer.leads
    : customer.leads.filter((lead) => lead.salespersonId && visibleOwnerIds.has(lead.salespersonId))

  const relatedOffers = session.role === 'ADMIN'
    ? customer.offers
    : customer.offers.filter((offer) => visibleOwnerIds.has(offer.ownerId))

  const ownerOptions = await listOwnerOptions(visibleOwnerIds)

  return {
    ok: true as const,
    data: buildCustomerWorkspace({
      customer: mapManagedCustomer({
        ...customer,
        _count: {
          leads: relatedLeads.length,
          offers: relatedOffers.length,
        },
      }),
      ownerOptions,
      relatedLeads,
      relatedOffers,
    }),
  }
}

export async function getManagedCustomer(session: AuthSession, customerId: string) {
  const workspace = await getManagedCustomerWorkspaceInternal(session, customerId)

  if (!workspace.ok) {
    return workspace
  }

  return { ok: true as const, data: workspace.data.customer }
}

export async function getManagedCustomerWorkspaceForSession(session: AuthSession, customerId: string) {
  return getManagedCustomerWorkspaceInternal(session, customerId)
}

export async function updateManagedCustomer(session: AuthSession, customerId: string, input: {
  fullName: string
  email?: string | null
  phone?: string | null
  companyName?: string | null
  taxId?: string | null
  city?: string | null
  notes?: string | null
  ownerId?: string | null
}) {
  if (!db) {
    return { ok: false as const, error: 'Baza danych nie jest dostępna dla modułu klientów.', status: 503 }
  }

  if (!canManageCustomers(session)) {
    return { ok: false as const, error: 'Brak dostępu do kart klientów.', status: 403 }
  }

  const fullName = input.fullName.trim().replace(/\s+/g, ' ')

  if (!fullName) {
    return { ok: false as const, error: 'Podaj imię i nazwisko klienta.', status: 400 }
  }

  const email = normalizeOptional(input.email)?.toLowerCase() ?? null
  const phone = normalizeOptional(input.phone)
  const companyName = normalizeOptional(input.companyName)
  const taxId = normalizeOptional(input.taxId)
  const city = normalizeOptional(input.city)
  const notes = normalizeOptional(input.notes)
  const ownerId = normalizeOptional(input.ownerId)
  const { firstName, lastName } = splitFullName(fullName)

  const users = await listManagedUsers()
  const visibleOwnerIds = getVisibleCustomerOwnerIds(session, users)

  const existing = await db.customer.findUnique({
    where: { id: customerId },
    select: {
      id: true,
      ownerId: true,
      leads: {
        select: {
          salespersonId: true,
        },
      },
      offers: {
        select: {
          ownerId: true,
        },
      },
    },
  })

  if (!existing) {
    return { ok: false as const, error: 'Nie znaleziono karty klienta.', status: 404 }
  }

  if (!canViewCustomerRecord({
    session,
    visibleOwnerIds,
    customerOwnerId: existing.ownerId,
    leadSalespersonIds: existing.leads.map((lead) => lead.salespersonId),
    offerOwnerIds: existing.offers.map((offer) => offer.ownerId),
  })) {
    return { ok: false as const, error: 'Nie znaleziono karty klienta.', status: 404 }
  }

  if (ownerId && !visibleOwnerIds.has(ownerId)) {
    return { ok: false as const, error: 'Możesz przypisać klienta tylko do osoby z własnej struktury.', status: 403 }
  }

  const updated = await db.$transaction(async (transaction) => {
    const customer = await transaction.customer.update({
      where: { id: customerId },
      data: {
        fullName,
        email,
        phone,
        companyName,
        taxId,
        city,
        notes,
        ownerId,
      },
      include: {
        owner: {
          select: { fullName: true },
        },
        _count: {
          select: {
            leads: true,
            offers: true,
          },
        },
      },
    })

    await transaction.lead.updateMany({
      where: { customerId },
      data: {
        firstName,
        lastName,
        email,
        phone,
        region: city,
      },
    })

    return customer
  })

  return { ok: true as const, data: mapManagedCustomer(updated) }
}

export async function createManagedCustomerFromLead(session: AuthSession, leadId: string) {
  if (!db) {
    return { ok: false as const, error: 'Baza danych nie jest dostępna dla modułu klientów.', status: 503 }
  }

  if (!canManageCustomers(session)) {
    return { ok: false as const, error: 'Brak dostępu do kart klientów.', status: 403 }
  }

  const users = await listManagedUsers()
  const visibleOwnerIds = getVisibleCustomerOwnerIds(session, users)

  const lead = await db.lead.findUnique({
    where: { id: leadId },
    include: {
      salesperson: {
        select: { id: true, fullName: true },
      },
    },
  })

  if (!lead) {
    return { ok: false as const, error: 'Nie znaleziono leada do utworzenia klienta.', status: 404 }
  }

  if (lead.salespersonId && !visibleOwnerIds.has(lead.salespersonId) && session.role !== 'ADMIN') {
    return { ok: false as const, error: 'Nie znaleziono leada do utworzenia klienta.', status: 404 }
  }

  const offerCustomerId = lead.acceptedOfferId
    ? (await db.offer.findUnique({
        where: { id: lead.acceptedOfferId },
        select: { customerId: true },
      }))?.customerId ?? null
    : null

  const fullName = [lead.firstName?.trim(), lead.lastName?.trim()].filter(Boolean).join(' ').trim() || 'Klient bez nazwy'
  const ownerId = lead.salespersonId ?? session.sub

  const resolvedCustomer = await db.$transaction(async (transaction) => {
    if (lead.customerId) {
      await transaction.lead.update({
        where: { id: lead.id },
        data: { customerId: lead.customerId },
      })
      return transaction.customer.findUnique({ where: { id: lead.customerId } })
    }

    if (offerCustomerId) {
      await transaction.lead.update({
        where: { id: lead.id },
        data: { customerId: offerCustomerId },
      })
      return transaction.customer.findUnique({ where: { id: offerCustomerId } })
    }

    const contactFilters = [
      lead.email ? { email: lead.email } : undefined,
      lead.phone ? { phone: lead.phone } : undefined,
    ].filter(Boolean) as Array<{ email?: string | null; phone?: string | null }>

    const existing = contactFilters.length > 0
      ? await transaction.customer.findFirst({
          where: {
            fullName,
            OR: contactFilters,
          },
        })
      : null

    const customer = existing ?? await transaction.customer.create({
      data: {
        fullName,
        email: lead.email,
        phone: lead.phone,
        city: lead.region,
        notes: lead.message,
        ownerId,
      },
    })

    await transaction.lead.update({
      where: { id: lead.id },
      data: { customerId: customer.id },
    })

    return customer
  })

  if (!resolvedCustomer) {
    return { ok: false as const, error: 'Nie udało się przygotować karty klienta.', status: 500 }
  }

  return getManagedCustomerWorkspaceInternal(session, resolvedCustomer.id)
}