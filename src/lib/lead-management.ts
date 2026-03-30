import 'server-only'

import { mkdir, readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'

import type { AuthSession } from '@/lib/auth'
import { db, hasDatabaseUrl } from '@/lib/db'
import { listManagedUsers } from '@/lib/user-management'

export type LeadStageKind = 'OPEN' | 'WON' | 'LOST' | 'HOLD'

export type LeadStage = {
  id: string
  name: string
  color: string
  order: number
  kind: LeadStageKind
}

type LeadPipelineStageKey =
  | 'NEW_LEAD'
  | 'FIRST_CONTACT'
  | 'FOLLOW_UP'
  | 'MEETING_SCHEDULED'
  | 'OFFER_SHARED'
  | 'WON'
  | 'LOST'
  | 'ON_HOLD'

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
  afterStageId?: string
}

type DeleteLeadStageInput = {
  stageId: string
  fallbackStageId?: string
}

type ManagedUser = Awaited<ReturnType<typeof listManagedUsers>>[number]

type PersistedLeadRecord = {
  id: string
  source: string
  fullName: string
  email: string | null
  phone: string | null
  interestedModel: string | null
  region: string | null
  stageKey: LeadPipelineStageKey
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

type PersistedLeadStore = {
  leads: PersistedLeadRecord[]
}

const LEAD_DATA_DIR = path.join(process.cwd(), 'data')
const LEAD_STORE_PATH = path.join(LEAD_DATA_DIR, 'leads.json')

let inMemoryLeadStore: PersistedLeadStore | null = null

const FIXED_STAGES: Array<LeadStage & { stageKey: LeadPipelineStageKey }> = [
  { id: 'stage-new-lead', stageKey: 'NEW_LEAD', name: 'Nowy lead', color: '#5AA9E6', order: 0, kind: 'OPEN' },
  { id: 'stage-first-contact', stageKey: 'FIRST_CONTACT', name: 'Pierwszy kontakt', color: '#46B89A', order: 1, kind: 'OPEN' },
  { id: 'stage-follow-up', stageKey: 'FOLLOW_UP', name: 'Ponowny kontakt', color: '#3FB6C6', order: 2, kind: 'OPEN' },
  { id: 'stage-meeting-scheduled', stageKey: 'MEETING_SCHEDULED', name: 'Umowione spotkanie', color: '#C68D34', order: 3, kind: 'OPEN' },
  { id: 'stage-offer-shared', stageKey: 'OFFER_SHARED', name: 'Oferta przekazana', color: '#D4A84F', order: 4, kind: 'OPEN' },
  { id: 'stage-won', stageKey: 'WON', name: 'Wygrane', color: '#2F9B63', order: 5, kind: 'WON' },
  { id: 'stage-lost', stageKey: 'LOST', name: 'Stracone', color: '#C56A5A', order: 6, kind: 'LOST' },
  { id: 'stage-on-hold', stageKey: 'ON_HOLD', name: 'Wstrzymane', color: '#7A7F8E', order: 7, kind: 'HOLD' },
]

const STAGE_BY_ID = new Map(FIXED_STAGES.map((stage) => [stage.id, stage]))
const STAGE_BY_KEY = new Map(FIXED_STAGES.map((stage) => [stage.stageKey, stage]))

let forceFileLeadStorage = false

function isPrismaLeadStorageEnabled() {
  return !forceFileLeadStorage && hasDatabaseUrl() && Boolean(db)
}

function isPrismaSchemaMismatch(error: unknown) {
  return typeof error === 'object'
    && error !== null
    && 'code' in error
    && ['P2021', 'P2022'].includes((error as { code?: string }).code ?? '')
}

function canUseFileLeadStorageFallback(error: unknown) {
  return process.env.NODE_ENV !== 'production' && isPrismaSchemaMismatch(error)
}

function splitFullName(fullName: string) {
  const normalized = fullName.trim().replace(/\s+/g, ' ')
  const [firstName, ...lastNameParts] = normalized.split(' ')

  return {
    firstName: firstName || null,
    lastName: lastNameParts.join(' ').trim() || null,
  }
}

function joinFullName(firstName?: string | null, lastName?: string | null) {
  const value = [firstName?.trim(), lastName?.trim()].filter(Boolean).join(' ').trim()
  return value || 'Klient bez nazwy'
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

function buildActivityEntry(input: {
  kind: LeadDetailEntryKind
  label: string
  value: string
  authorName: string | null
  createdAt?: string
}) {
  return normalizeDetailEntry({
    id: `lead-detail-${crypto.randomUUID()}`,
    kind: input.kind,
    label: input.label,
    value: input.value,
    authorName: input.authorName,
    createdAt: input.createdAt,
  })
}

function mapStageKeyToId(stageKey?: string | null) {
  return STAGE_BY_KEY.get((stageKey ?? 'NEW_LEAD') as LeadPipelineStageKey)?.id ?? FIXED_STAGES[0].id
}

function mapPersistedLead(record: PersistedLeadRecord): ManagedLead {
  return {
    id: record.id,
    source: record.source,
    fullName: record.fullName,
    email: record.email,
    phone: record.phone,
    interestedModel: record.interestedModel,
    region: record.region,
    stageId: mapStageKeyToId(record.stageKey),
    message: record.message,
    managerId: record.managerId,
    managerName: record.managerName,
    salespersonId: record.salespersonId,
    salespersonName: record.salespersonName,
    nextActionAt: record.nextActionAt,
    details: Array.isArray(record.details) ? record.details.map((entry) => normalizeDetailEntry(entry)) : [],
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
  }
}

function mapDbLead(record: {
  id: string
  source: string
  firstName: string | null
  lastName: string | null
  email: string | null
  phone: string | null
  message: string | null
  interestedModel: string | null
  region: string | null
  pipelineStage: LeadPipelineStageKey
  managerId: string | null
  manager?: { fullName: string } | null
  salespersonId: string | null
  salesperson?: { fullName: string } | null
  nextActionAt: Date | null
  details: Array<{
    id: string
    kind: 'INFO' | 'COMMENT'
    label: string
    value: string
    createdAt: Date
    authorUser?: { fullName: string } | null
  }>
  createdAt: Date
  updatedAt: Date
}): ManagedLead {
  return {
    id: record.id,
    source: record.source,
    fullName: joinFullName(record.firstName, record.lastName),
    email: record.email,
    phone: record.phone,
    interestedModel: record.interestedModel,
    region: record.region,
    stageId: mapStageKeyToId(record.pipelineStage),
    message: record.message,
    managerId: record.managerId,
    managerName: record.manager?.fullName ?? null,
    salespersonId: record.salespersonId,
    salespersonName: record.salesperson?.fullName ?? null,
    nextActionAt: record.nextActionAt?.toISOString() ?? null,
    details: record.details.map((entry) => ({
      id: entry.id,
      kind: entry.kind,
      label: entry.label,
      value: entry.value,
      authorName: entry.authorUser?.fullName ?? null,
      createdAt: entry.createdAt.toISOString(),
    })),
    createdAt: record.createdAt.toISOString(),
    updatedAt: record.updatedAt.toISOString(),
  }
}

function buildUserMaps(users: ManagedUser[]) {
  const byId = new Map(users.map((user) => [user.id, user]))
  const children = new Map<string, ManagedUser[]>()

  for (const user of users) {
    const parentId = user.reportsToUserId ?? null
    if (!parentId) {
      continue
    }

    const bucket = children.get(parentId) ?? []
    bucket.push(user)
    children.set(parentId, bucket)
  }

  return { byId, children }
}

function getVisibleOwnerIds(session: AuthSession, users: ManagedUser[]) {
  if (session.role === 'ADMIN') {
    return new Set(users.map((user) => user.id))
  }

  const { children } = buildUserMaps(users)
  const visible = new Set<string>([session.sub])
  const queue = [session.sub]

  while (queue.length > 0) {
    const current = queue.shift()!
    const descendants = children.get(current) ?? []

    for (const descendant of descendants) {
      if (visible.has(descendant.id)) {
        continue
      }

      visible.add(descendant.id)
      queue.push(descendant.id)
    }
  }

  return visible
}

function canViewLead(session: AuthSession, lead: ManagedLead, users: ManagedUser[]) {
  if (session.role === 'ADMIN') {
    return true
  }

  const visibleOwnerIds = getVisibleOwnerIds(session, users)
  return Boolean(lead.salespersonId && visibleOwnerIds.has(lead.salespersonId))
}

function getAssignableLeadOwners(session: AuthSession, users: ManagedUser[]) {
  const visibleOwnerIds = getVisibleOwnerIds(session, users)

  if (session.role === 'SALES') {
    return users.filter((user) => user.id === session.sub && user.isActive)
  }

  return users
    .filter((user) => user.isActive && visibleOwnerIds.has(user.id))
    .sort((left, right) => left.fullName.localeCompare(right.fullName, 'pl'))
}

function getDirectSupervisor(userId: string | null | undefined, usersById: Map<string, ManagedUser>) {
  if (!userId) {
    return null
  }

  const owner = usersById.get(userId)
  if (!owner?.reportsToUserId) {
    return null
  }

  return usersById.get(owner.reportsToUserId) ?? null
}

function getOwnerForCreation(session: AuthSession, inputOwnerId: string | undefined, users: ManagedUser[]) {
  const assignable = getAssignableLeadOwners(session, users)
  const requestedOwnerId = inputOwnerId?.trim() || session.sub
  return assignable.find((user) => user.id === requestedOwnerId) ?? null
}

async function ensureStoreFile() {
  try {
    await mkdir(LEAD_DATA_DIR, { recursive: true })
    await readFile(LEAD_STORE_PATH, 'utf8')
  } catch {
    const seedStore = { leads: [] } satisfies PersistedLeadStore
    inMemoryLeadStore = seedStore

    try {
      await writeFile(LEAD_STORE_PATH, JSON.stringify(seedStore, null, 2), 'utf8')
    } catch {
      // Serverless environments may not allow writes to the application filesystem.
    }
  }
}

async function readStore() {
  await ensureStoreFile()

  try {
    const raw = await readFile(LEAD_STORE_PATH, 'utf8')
    const parsed = JSON.parse(raw) as Partial<PersistedLeadStore>

    return {
      leads: Array.isArray(parsed.leads)
        ? parsed.leads.filter(Boolean).map((entry) => {
            const record = entry as Partial<PersistedLeadRecord>
            return {
              id: record.id ?? `lead-${crypto.randomUUID()}`,
              source: record.source?.trim() || 'Manual',
              fullName: record.fullName?.trim() || 'Klient bez nazwy',
              email: record.email?.trim() || null,
              phone: record.phone?.trim() || null,
              interestedModel: record.interestedModel?.trim() || null,
              region: record.region?.trim() || null,
              stageKey: STAGE_BY_KEY.has((record.stageKey ?? '') as LeadPipelineStageKey)
                ? (record.stageKey as LeadPipelineStageKey)
                : FIXED_STAGES[0].stageKey,
              message: record.message?.trim() || null,
              managerId: record.managerId?.trim() || null,
              managerName: record.managerName?.trim() || null,
              salespersonId: record.salespersonId?.trim() || null,
              salespersonName: record.salespersonName?.trim() || null,
              nextActionAt: record.nextActionAt ?? null,
              details: Array.isArray(record.details) ? record.details.map((detail) => normalizeDetailEntry(detail)) : [],
              createdAt: record.createdAt ?? new Date().toISOString(),
              updatedAt: record.updatedAt ?? new Date().toISOString(),
            } satisfies PersistedLeadRecord
          })
        : [],
    } satisfies PersistedLeadStore
  } catch {
    if (!inMemoryLeadStore) {
      inMemoryLeadStore = { leads: [] } satisfies PersistedLeadStore
    }

    return inMemoryLeadStore
  }
}

async function writeStore(store: PersistedLeadStore) {
  inMemoryLeadStore = store

  try {
    await ensureStoreFile()
    await writeFile(LEAD_STORE_PATH, JSON.stringify(store, null, 2), 'utf8')
  } catch {
    // Ignore filesystem write failures in serverless hosting.
  }
}

async function buildSeedLeads(users: ManagedUser[]) {
  const owner = users.find((user) => user.isActive && user.role === 'SALES')
    ?? users.find((user) => user.isActive && user.role === 'MANAGER')
    ?? users.find((user) => user.isActive && user.role === 'DIRECTOR')
    ?? users.find((user) => user.isActive && user.role === 'ADMIN')
    ?? null
  const supervisor = owner?.reportsToUserId ? users.find((user) => user.id === owner.reportsToUserId) ?? null : null

  if (!owner) {
    return [] satisfies PersistedLeadRecord[]
  }

  return [
    {
      id: 'lead-seed-1',
      source: 'Landing page',
      fullName: 'Marek Witkowski',
      email: 'marek.w@example.com',
      phone: '+48 501 225 881',
      interestedModel: 'BYD Seal 6 DM-i',
      region: 'Warszawa',
      stageKey: 'NEW_LEAD',
      message: 'Prosi o leasing 36 miesięcy dla firmy.',
      managerId: supervisor?.id ?? null,
      managerName: supervisor?.fullName ?? null,
      salespersonId: owner.id,
      salespersonName: owner.fullName,
      nextActionAt: new Date('2026-03-24T09:00:00.000Z').toISOString(),
      details: [
        buildActivityEntry({
          kind: 'INFO',
          label: 'Lead utworzony',
          value: 'Lead został wprowadzony do pipeline i oczekuje na pierwszy kontakt.',
          authorName: 'Administrator VeloPrime',
          createdAt: new Date('2026-03-21T08:10:00.000Z').toISOString(),
        }),
        buildActivityEntry({
          kind: 'COMMENT',
          label: 'Komentarz',
          value: 'Klient chce potwierdzić harmonogram leasingu przed finalną decyzją.',
          authorName: owner.fullName,
          createdAt: new Date('2026-03-21T11:00:00.000Z').toISOString(),
        }),
      ],
      createdAt: new Date('2026-03-21T08:10:00.000Z').toISOString(),
      updatedAt: new Date('2026-03-21T11:00:00.000Z').toISOString(),
    },
    {
      id: 'lead-seed-2',
      source: 'Telefon',
      fullName: 'Anna Maj',
      email: 'anna.maj@example.com',
      phone: '+48 604 112 337',
      interestedModel: 'BYD Seal U',
      region: 'Krakow',
      stageKey: 'FIRST_CONTACT',
      message: 'Chce jazdę próbną w przyszłym tygodniu.',
      managerId: supervisor?.id ?? null,
      managerName: supervisor?.fullName ?? null,
      salespersonId: owner.id,
      salespersonName: owner.fullName,
      nextActionAt: new Date('2026-03-25T13:30:00.000Z').toISOString(),
      details: [
        buildActivityEntry({
          kind: 'INFO',
          label: 'Zmiana etapu',
          value: 'Lead został przesunięty do etapu Pierwszy kontakt.',
          authorName: owner.fullName,
          createdAt: new Date('2026-03-21T09:45:00.000Z').toISOString(),
        }),
      ],
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
      stageKey: 'OFFER_SHARED',
      message: 'Negocjuje pakiet serwisowy i termin odbioru.',
      managerId: supervisor?.id ?? null,
      managerName: supervisor?.fullName ?? null,
      salespersonId: owner.id,
      salespersonName: owner.fullName,
      nextActionAt: new Date('2026-03-23T15:00:00.000Z').toISOString(),
      details: [
        buildActivityEntry({
          kind: 'INFO',
          label: 'Zmiana etapu',
          value: 'Lead został przesunięty do etapu Oferta przekazana.',
          authorName: owner.fullName,
          createdAt: new Date('2026-03-21T11:20:00.000Z').toISOString(),
        }),
      ],
      createdAt: new Date('2026-03-18T15:15:00.000Z').toISOString(),
      updatedAt: new Date('2026-03-21T11:20:00.000Z').toISOString(),
    },
  ] satisfies PersistedLeadRecord[]
}

async function getFileStore(users: ManagedUser[]) {
  const store = await readStore()

  if (store.leads.length > 0) {
    return store
  }

  const seeded = { leads: await buildSeedLeads(users) } satisfies PersistedLeadStore
  await writeStore(seeded)
  return seeded
}

async function listDbLeads() {
  if (!db) {
    return []
  }

  return db.lead.findMany({
    include: {
      manager: true,
      salesperson: true,
      details: {
        include: { authorUser: true },
        orderBy: { createdAt: 'desc' },
      },
    },
    orderBy: { updatedAt: 'desc' },
  })
}

async function getManagedLeadByIdInternal(leadId: string, session: AuthSession) {
  const leads = await listManagedLeads(session)
  return leads.find((entry) => entry.id === leadId) ?? null
}

export async function listManagedLeadStages() {
  return FIXED_STAGES.map((stage) => ({
    id: stage.id,
    name: stage.name,
    color: stage.color,
    order: stage.order,
    kind: stage.kind,
  }))
}

export async function listAssignableLeadOwners(session: AuthSession) {
  const users = await listManagedUsers()

  return getAssignableLeadOwners(session, users).map((user) => ({
    id: user.id,
    fullName: user.fullName,
    email: user.email,
  }))
}

async function resolveStage(stageId?: string) {
  if (stageId) {
    return STAGE_BY_ID.get(stageId) ?? null
  }

  return FIXED_STAGES.find((stage) => stage.kind === 'OPEN') ?? FIXED_STAGES[0] ?? null
}

export async function listManagedLeads(session: AuthSession) {
  const users = await listManagedUsers()

  if (isPrismaLeadStorageEnabled() && db) {
    try {
      const leads = await listDbLeads()

      return leads
        .map((lead) => mapDbLead(lead))
        .filter((lead) => canViewLead(session, lead, users))
        .sort((left, right) => new Date(right.updatedAt).getTime() - new Date(left.updatedAt).getTime())
    } catch (error) {
      if (!canUseFileLeadStorageFallback(error)) {
        throw error
      }

      forceFileLeadStorage = true
    }
  }

  const store = await getFileStore(users)
  return store.leads
    .map((lead) => mapPersistedLead(lead))
    .filter((lead) => canViewLead(session, lead, users))
    .sort((left, right) => new Date(right.updatedAt).getTime() - new Date(left.updatedAt).getTime())
}

export async function createManagedLeadStage(_session: AuthSession, _input: CreateLeadStageInput) {
  void _session
  void _input
  return { ok: false as const, error: 'Etapy pipeline są sztywne i nie można ich dodawać.' }
}

export async function deleteManagedLeadStage(_session: AuthSession, _input: DeleteLeadStageInput) {
  void _session
  void _input
  return { ok: false as const, error: 'Etapy pipeline są sztywne i nie można ich usuwać.' }
}

export async function createManagedLead(session: AuthSession, input: CreateManagedLeadInput) {
  const fullName = input.fullName.trim()
  const email = input.email?.trim().toLowerCase() || null
  const phone = input.phone?.trim() || null
  const interestedModel = input.interestedModel?.trim() || null
  const source = input.source.trim() || 'Manual'

  if (!fullName) {
    return { ok: false as const, error: 'Podaj imię i nazwisko klienta.' }
  }

  if (!email && !phone) {
    return { ok: false as const, error: 'Podaj email lub telefon kontaktowy.' }
  }

  const [stage, users] = await Promise.all([resolveStage(input.stageId), listManagedUsers()])

  if (!stage) {
    return { ok: false as const, error: 'Nie udało się ustawić etapu startowego.' }
  }

  const owner = getOwnerForCreation(session, input.salespersonId, users)

  if (!owner) {
    return { ok: false as const, error: 'Możesz przypisać leada tylko do siebie albo do osoby z własnej struktury.' }
  }

  const { byId } = buildUserMaps(users)
  const supervisor = getDirectSupervisor(owner.id, byId)
  const createdAt = new Date().toISOString()
  const { firstName, lastName } = splitFullName(fullName)

  if (isPrismaLeadStorageEnabled() && db) {
    const created = await db.lead.create({
      data: {
        source,
        firstName,
        lastName,
        email,
        phone,
        message: input.message?.trim() || null,
        interestedModel,
        region: input.region?.trim() || null,
        pipelineStage: stage.stageKey,
        managerId: supervisor?.id ?? null,
        salespersonId: owner.id,
        nextActionAt: null,
        details: {
          create: {
            kind: 'INFO',
            label: 'Lead utworzony',
            value: `Lead został utworzony na etapie ${stage.name}.`,
            authorUserId: session.sub,
            createdAt: new Date(createdAt),
          },
        },
      },
      include: {
        manager: true,
        salesperson: true,
        details: {
          include: { authorUser: true },
          orderBy: { createdAt: 'desc' },
        },
      },
    })

    return { ok: true as const, lead: mapDbLead(created) }
  }

  const store = await getFileStore(users)
  const nextLead: PersistedLeadRecord = {
    id: `lead-${crypto.randomUUID()}`,
    source,
    fullName,
    email,
    phone,
    interestedModel,
    region: input.region?.trim() || null,
    stageKey: stage.stageKey,
    message: input.message?.trim() || null,
    managerId: supervisor?.id ?? null,
    managerName: supervisor?.fullName ?? null,
    salespersonId: owner.id,
    salespersonName: owner.fullName,
    nextActionAt: null,
    details: [
      buildActivityEntry({
        kind: 'INFO',
        label: 'Lead utworzony',
        value: `Lead został utworzony na etapie ${stage.name}.`,
        authorName: session.fullName,
        createdAt,
      }),
    ],
    createdAt,
    updatedAt: createdAt,
  }

  store.leads.push(nextLead)
  await writeStore(store)

  return { ok: true as const, lead: mapPersistedLead(nextLead) }
}

export async function moveManagedLeadToStage(session: AuthSession, leadId: string, stageId: string) {
  const [stage, users] = await Promise.all([resolveStage(stageId), listManagedUsers()])

  if (!stage) {
    return { ok: false as const, error: 'Nieprawidłowy etap leada.' }
  }

  const lead = await getManagedLeadByIdInternal(leadId, session)

  if (!lead) {
    return { ok: false as const, error: 'Nie znaleziono leada.' }
  }

  const updatedAt = new Date().toISOString()

  if (isPrismaLeadStorageEnabled() && db) {
    await db.$transaction([
      db.lead.update({
        where: { id: leadId },
        data: { pipelineStage: stage.stageKey },
      }),
      db.leadDetailEntry.create({
        data: {
          leadId,
          kind: 'INFO',
          label: 'Zmiana etapu',
          value: `Lead został przesunięty do etapu ${stage.name}.`,
          authorUserId: session.sub,
          createdAt: new Date(updatedAt),
        },
      }),
    ])

    const refreshed = await db.lead.findUnique({
      where: { id: leadId },
      include: {
        manager: true,
        salesperson: true,
        details: {
          include: { authorUser: true },
          orderBy: { createdAt: 'desc' },
        },
      },
    })

    if (!refreshed) {
      return { ok: false as const, error: 'Nie znaleziono leada po zapisaniu zmiany etapu.' }
    }

    return { ok: true as const, lead: mapDbLead(refreshed) }
  }

  const store = await getFileStore(users)
  const leadIndex = store.leads.findIndex((entry) => entry.id === leadId)

  if (leadIndex === -1) {
    return { ok: false as const, error: 'Nie znaleziono leada.' }
  }

  store.leads[leadIndex] = {
    ...store.leads[leadIndex],
    stageKey: stage.stageKey,
    updatedAt,
    details: [
      buildActivityEntry({
        kind: 'INFO',
        label: 'Zmiana etapu',
        value: `Lead został przesunięty do etapu ${stage.name}.`,
        authorName: session.fullName,
        createdAt: updatedAt,
      }),
      ...store.leads[leadIndex].details,
    ],
  }

  await writeStore(store)
  return { ok: true as const, lead: mapPersistedLead(store.leads[leadIndex]) }
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
  const users = await listManagedUsers()
  const lead = await getManagedLeadByIdInternal(input.leadId, session)

  if (!lead) {
    return { ok: false as const, error: 'Nie znaleziono leada.' }
  }

  const value = input.value.trim()
  const label = input.label?.trim() || ''

  if (!value) {
    return { ok: false as const, error: input.kind === 'COMMENT' ? 'Wpisz treść komentarza.' : 'Wpisz wartość informacji.' }
  }

  if (input.kind === 'INFO' && !label) {
    return { ok: false as const, error: 'Podaj nazwę informacji.' }
  }

  const createdAt = new Date().toISOString()

  if (isPrismaLeadStorageEnabled() && db) {
    const entry = await db.leadDetailEntry.create({
      data: {
        leadId: input.leadId,
        kind: input.kind,
        label: input.kind === 'COMMENT' ? 'Komentarz' : label,
        value,
        authorUserId: session.sub,
        createdAt: new Date(createdAt),
      },
      include: { authorUser: true },
    })

    await db.lead.update({
      where: { id: input.leadId },
      data: { updatedAt: new Date(createdAt) },
    })

    return {
      ok: true as const,
      entry: {
        id: entry.id,
        kind: entry.kind,
        label: entry.label,
        value: entry.value,
        authorName: entry.authorUser?.fullName ?? null,
        createdAt: entry.createdAt.toISOString(),
      } satisfies LeadDetailEntry,
    }
  }

  const store = await getFileStore(users)
  const leadIndex = store.leads.findIndex((entry) => entry.id === input.leadId)

  if (leadIndex === -1) {
    return { ok: false as const, error: 'Nie znaleziono leada.' }
  }

  const nextEntry = buildActivityEntry({
    kind: input.kind,
    label: input.kind === 'COMMENT' ? 'Komentarz' : label,
    value,
    authorName: session.fullName,
    createdAt,
  })

  store.leads[leadIndex] = {
    ...store.leads[leadIndex],
    updatedAt: createdAt,
    details: [nextEntry, ...store.leads[leadIndex].details],
  }

  await writeStore(store)
  return { ok: true as const, entry: nextEntry }
}

export async function logManagedLeadActivity(
  session: AuthSession,
  input: {
    leadId: string
    label: string
    value: string
  }
) {
  return addManagedLeadDetailEntry(session, {
    leadId: input.leadId,
    kind: 'INFO',
    label: input.label,
    value: input.value,
  })
}

export async function assignManagedLeadSalesperson(_session: AuthSession, _leadId: string, _salespersonId: string) {
  void _session
  void _leadId
  void _salespersonId
  return { ok: false as const, error: 'Zmiana opiekuna po utworzeniu leada jest zablokowana.' }
}