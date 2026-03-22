import 'server-only'

import type { AuthSession } from '@/lib/auth'
import { listManagedUsers } from '@/lib/user-management'

export type LeadStageKind = 'OPEN' | 'WON' | 'LOST'

export type LeadStage = {
  id: string
  name: string
  color: string
  order: number
  kind: LeadStageKind
}

export type LeadDetailEntryKind = 'INFO' | 'COMMENT'

export type LeadDetailEntry = {
  id: string
  kind: LeadDetailEntryKind
  label: string
  value: string
  authorName: string | null
  createdAt: string
}

export type ManagedLead = {
  id: string
  source: string
  fullName: string
  email: string | null
  phone: string | null
  interestedModel: string | null
  region: string | null
  stageId: string
  message: string | null
  managerId: string | null
  managerName: string | null
  salespersonId: string | null
  salespersonName: string | null
  nextActionAt: string | null
  details: LeadDetailEntry[]
  createdAt: string
  updatedAt: string
}

type CreateManagedLeadInput = {
  source: string
  fullName: string
  email?: string
  phone?: string
  interestedModel?: string
  region?: string
  message?: string
  stageId?: string
  salespersonId?: string
}

type CreateLeadStageInput = {
  name: string
  color: string
  kind: LeadStageKind
}

const globalForLeads = globalThis as unknown as {
  crmLeadStages?: LeadStage[]
  crmLeads?: ManagedLead[]
}

function normalizeDetailEntry(entry: Partial<LeadDetailEntry>): LeadDetailEntry {
  return {
    id: entry.id ?? `lead-detail-${crypto.randomUUID()}`,
    kind: entry.kind === 'COMMENT' ? 'COMMENT' : 'INFO',
    label: entry.label?.trim() || (entry.kind === 'COMMENT' ? 'Komentarz' : 'Informacja'),
    value: entry.value?.trim() || '',
    authorName: entry.authorName?.trim() || null,
    createdAt: entry.createdAt ?? new Date().toISOString(),
  }
}

function normalizeManagedLead(lead: ManagedLead): ManagedLead {
  return {
    ...lead,
    details: Array.isArray(lead.details) ? lead.details.map((entry) => normalizeDetailEntry(entry)) : [],
  }
}

function buildSeedStages(): LeadStage[] {
  return [
    { id: 'stage-new', name: 'Nowy lead', color: '#5aa9e6', order: 0, kind: 'OPEN' },
    { id: 'stage-contact', name: 'Pierwszy kontakt', color: '#44c4a1', order: 1, kind: 'OPEN' },
    { id: 'stage-test-drive', name: 'Jazda probna', color: '#2ec4b6', order: 2, kind: 'OPEN' },
    { id: 'stage-offer', name: 'Oferta', color: '#d8b45a', order: 3, kind: 'OPEN' },
    { id: 'stage-negotiation', name: 'Negocjacje', color: '#f59e0b', order: 4, kind: 'OPEN' },
    { id: 'stage-won', name: 'Wygrany', color: '#22c55e', order: 5, kind: 'WON' },
    { id: 'stage-lost', name: 'Utracony', color: '#ef4444', order: 6, kind: 'LOST' },
  ]
}

async function getStageStore() {
  if (!globalForLeads.crmLeadStages) {
    globalForLeads.crmLeadStages = buildSeedStages()
  }

  return globalForLeads.crmLeadStages
}

export async function listManagedLeadStages() {
  const stages = await getStageStore()
  return [...stages].sort((left, right) => left.order - right.order)
}

async function resolveStage(stageId?: string) {
  const stages = await getStageStore()

  if (stageId) {
    return stages.find((stage) => stage.id === stageId) ?? null
  }

  return [...stages].sort((left, right) => left.order - right.order).find((stage) => stage.kind === 'OPEN') ?? stages[0] ?? null
}

function isLeadership(role: AuthSession['role']) {
  return role === 'ADMIN' || role === 'DIRECTOR' || role === 'MANAGER'
}

function canViewLead(session: AuthSession, lead: ManagedLead) {
  if (session.role === 'ADMIN' || session.role === 'DIRECTOR') {
    return true
  }

  if (session.role === 'MANAGER') {
    return lead.managerId === session.sub || lead.salespersonId === session.sub
  }

  return lead.salespersonId === session.sub
}

async function buildSeedLeads(): Promise<ManagedLead[]> {
  const users = await listManagedUsers()
  const manager = users.find((user) => user.role === 'MANAGER' && user.isActive)
  const sales = users.find((user) => user.role === 'SALES' && user.isActive)
  const stages = await listManagedLeadStages()
  const newStage = stages.find((stage) => stage.id === 'stage-new') ?? stages[0]
  const contactStage = stages.find((stage) => stage.id === 'stage-contact') ?? stages[1] ?? stages[0]
  const negotiationStage = stages.find((stage) => stage.id === 'stage-negotiation') ?? stages[2] ?? stages[0]

  return [
    {
      id: 'lead-seed-1',
      source: 'Landing page',
      fullName: 'Marek Witkowski',
      email: 'marek.w@example.com',
      phone: '+48 501 225 881',
      interestedModel: 'BYD Seal 6 DM-i',
      region: 'Warszawa',
      stageId: newStage.id,
      message: 'Prosi o leasing 36 miesięcy dla firmy.',
      managerId: manager?.id ?? null,
      managerName: manager?.fullName ?? null,
      salespersonId: sales?.id ?? null,
      salespersonName: sales?.fullName ?? null,
      nextActionAt: new Date('2026-03-24T09:00:00.000Z').toISOString(),
      details: [
        {
          id: 'lead-seed-1-info-1',
          kind: 'INFO',
          label: 'Data wydania samochodu',
          value: '02.04.2026',
          authorName: 'Administrator VeloPrime',
          createdAt: new Date('2026-03-21T10:15:00.000Z').toISOString(),
        },
        {
          id: 'lead-seed-1-comment-1',
          kind: 'COMMENT',
          label: 'Komentarz',
          value: 'Klient chce potwierdzić harmonogram leasingu przed finalną decyzją.',
          authorName: 'Manager Regionu',
          createdAt: new Date('2026-03-21T11:00:00.000Z').toISOString(),
        },
      ],
      createdAt: new Date('2026-03-21T08:10:00.000Z').toISOString(),
      updatedAt: new Date('2026-03-21T08:10:00.000Z').toISOString(),
    },
    {
      id: 'lead-seed-2',
      source: 'Telefon',
      fullName: 'Anna Maj',
      email: 'anna.maj@example.com',
      phone: '+48 604 112 337',
      interestedModel: 'BYD Seal U',
      region: 'Krakow',
      stageId: contactStage.id,
      message: 'Chce jazdę próbną w przyszłym tygodniu.',
      managerId: manager?.id ?? null,
      managerName: manager?.fullName ?? null,
      salespersonId: sales?.id ?? null,
      salespersonName: sales?.fullName ?? null,
      nextActionAt: new Date('2026-03-25T13:30:00.000Z').toISOString(),
      details: [],
      createdAt: new Date('2026-03-20T12:30:00.000Z').toISOString(),
      updatedAt: new Date('2026-03-21T09:45:00.000Z').toISOString(),
    },
    {
      id: 'lead-seed-3',
      source: 'Partner',
      fullName: 'Piotr Bielski',
      email: 'piotr.b@example.com',
      phone: '+48 602 778 190',
      interestedModel: 'BYD Dolphin Surf',
      region: 'Poznan',
      stageId: negotiationStage.id,
      message: 'Negocjuje pakiet serwisowy i termin odbioru.',
      managerId: manager?.id ?? null,
      managerName: manager?.fullName ?? null,
      salespersonId: sales?.id ?? null,
      salespersonName: sales?.fullName ?? null,
      nextActionAt: new Date('2026-03-23T15:00:00.000Z').toISOString(),
      details: [],
      createdAt: new Date('2026-03-18T15:15:00.000Z').toISOString(),
      updatedAt: new Date('2026-03-21T11:20:00.000Z').toISOString(),
    },
  ]
}

async function getStore() {
  if (!globalForLeads.crmLeads) {
    globalForLeads.crmLeads = await buildSeedLeads()
  }

  globalForLeads.crmLeads = globalForLeads.crmLeads.map((lead) => normalizeManagedLead(lead))

  return globalForLeads.crmLeads
}

async function resolveSalesperson(salespersonId?: string) {
  if (!salespersonId) {
    return null
  }

  const users = await listManagedUsers()
  return users.find((user) => user.id === salespersonId && user.isActive && user.role === 'SALES') ?? null
}

export async function listManagedLeads(session: AuthSession) {
  const leads = await getStore()

  return [...leads]
    .filter((lead) => canViewLead(session, lead))
    .sort((left, right) => new Date(right.updatedAt).getTime() - new Date(left.updatedAt).getTime())
}

export async function createManagedLeadStage(session: AuthSession, input: CreateLeadStageInput) {
  if (!isLeadership(session.role)) {
    return { ok: false as const, error: 'Tylko kadra zarządzająca może tworzyć etapy.' }
  }

  const name = input.name.trim()

  if (!name) {
    return { ok: false as const, error: 'Podaj nazwę etapu.' }
  }

  const stages = await getStageStore()

  if (stages.some((stage) => stage.name.toLowerCase() === name.toLowerCase())) {
    return { ok: false as const, error: 'Etap o takiej nazwie już istnieje.' }
  }

  const nextStage: LeadStage = {
    id: `stage-${crypto.randomUUID()}`,
    name,
    color: input.color.trim() || '#5aa9e6',
    kind: input.kind,
    order: stages.length,
  }

  stages.push(nextStage)

  return { ok: true as const, stage: nextStage }
}

export async function createManagedLead(session: AuthSession, input: CreateManagedLeadInput) {
  const fullName = input.fullName.trim()
  const email = input.email?.trim().toLowerCase() || null
  const phone = input.phone?.trim() || null
  const source = input.source.trim() || 'Manual'

  if (!fullName) {
    return { ok: false as const, error: 'Podaj imię i nazwisko klienta.' }
  }

  if (!email && !phone) {
    return { ok: false as const, error: 'Podaj email lub telefon kontaktowy.' }
  }

  const stage = await resolveStage(input.stageId)

  if (!stage) {
    return { ok: false as const, error: 'Nie udało się ustawić etapu startowego.' }
  }

  let salespersonId: string | null = null
  let salespersonName: string | null = null
  let managerId: string | null = null
  let managerName: string | null = null

  if (session.role === 'SALES') {
    salespersonId = session.sub
    salespersonName = session.fullName
  } else {
    const salesperson = await resolveSalesperson(input.salespersonId)

    if (input.salespersonId && !salesperson) {
      return { ok: false as const, error: 'Wybrany handlowiec nie istnieje lub jest nieaktywny.' }
    }

    salespersonId = salesperson?.id ?? null
    salespersonName = salesperson?.fullName ?? null
  }

  if (session.role === 'MANAGER') {
    managerId = session.sub
    managerName = session.fullName
  }

  const nextLead: ManagedLead = {
    id: `lead-${crypto.randomUUID()}`,
    source,
    fullName,
    email,
    phone,
    interestedModel: input.interestedModel?.trim() || null,
    region: input.region?.trim() || null,
    stageId: stage.id,
    message: input.message?.trim() || null,
    managerId,
    managerName,
    salespersonId,
    salespersonName,
    nextActionAt: null,
    details: [],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  }

  const leads = await getStore()
  leads.push(nextLead)

  return { ok: true as const, lead: nextLead }
}

export async function moveManagedLeadToStage(session: AuthSession, leadId: string, stageId: string) {
  const stage = await resolveStage(stageId)

  if (!stage) {
    return { ok: false as const, error: 'Nieprawidłowy etap leada.' }
  }

  const leads = await getStore()
  const lead = leads.find((entry) => entry.id === leadId)

  if (!lead) {
    return { ok: false as const, error: 'Nie znaleziono leada.' }
  }

  if (!canViewLead(session, lead)) {
    return { ok: false as const, error: 'Nie masz dostępu do tego leada.' }
  }

  lead.stageId = stage.id
  lead.updatedAt = new Date().toISOString()

  return { ok: true as const, lead }
}

export async function addManagedLeadDetailEntry(
  session: AuthSession,
  input: {
    leadId: string
    kind: LeadDetailEntryKind
    label?: string
    value: string
  }
) {
  const leads = await getStore()
  const lead = leads.find((entry) => entry.id === input.leadId)

  if (!lead) {
    return { ok: false as const, error: 'Nie znaleziono leada.' }
  }

  if (!canViewLead(session, lead)) {
    return { ok: false as const, error: 'Nie masz dostępu do tego leada.' }
  }

  const value = input.value.trim()
  const label = input.label?.trim() || ''

  if (!value) {
    return { ok: false as const, error: input.kind === 'COMMENT' ? 'Wpisz treść komentarza.' : 'Wpisz wartość informacji.' }
  }

  if (input.kind === 'INFO' && !label) {
    return { ok: false as const, error: 'Podaj nazwę informacji.' }
  }

  const nextEntry: LeadDetailEntry = {
    id: `lead-detail-${crypto.randomUUID()}`,
    kind: input.kind,
    label: input.kind === 'COMMENT' ? 'Komentarz' : label,
    value,
    authorName: session.fullName,
    createdAt: new Date().toISOString(),
  }

  if (!Array.isArray(lead.details)) {
    lead.details = []
  }

  lead.details.unshift(nextEntry)
  lead.updatedAt = new Date().toISOString()

  return { ok: true as const, entry: nextEntry }
}

export async function assignManagedLeadSalesperson(session: AuthSession, leadId: string, salespersonId: string) {
  if (!isLeadership(session.role)) {
    return { ok: false as const, error: 'Tylko administrator, dyrektor lub manager mogą przypisywać leady.' }
  }

  const leads = await getStore()
  const lead = leads.find((entry) => entry.id === leadId)

  if (!lead) {
    return { ok: false as const, error: 'Nie znaleziono leada.' }
  }

  if (!canViewLead(session, lead)) {
    return { ok: false as const, error: 'Nie masz dostępu do tego leada.' }
  }

  if (!salespersonId) {
    lead.salespersonId = null
    lead.salespersonName = null
  } else {
    const salesperson = await resolveSalesperson(salespersonId)

    if (!salesperson) {
      return { ok: false as const, error: 'Wybrany handlowiec nie istnieje lub jest nieaktywny.' }
    }

    lead.salespersonId = salesperson.id
    lead.salespersonName = salesperson.fullName
  }

  if (session.role === 'MANAGER') {
    lead.managerId = session.sub
    lead.managerName = session.fullName
  }

  lead.updatedAt = new Date().toISOString()
  return { ok: true as const, lead }
}