import 'server-only'

import { mkdir, readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'

import type { AuthSession } from '@/lib/auth'
import { getActivePricingSheet } from '@/lib/pricing-management'
import { buildPricingCatalog } from '@/lib/pricing-catalog'
import { listManagedUsers } from '@/lib/user-management'

export type CommissionValueType = 'AMOUNT' | 'PERCENT'

export type CommissionRule = {
  id: string
  userId: string
  userName: string
  userRole: 'DIRECTOR' | 'MANAGER'
  catalogKey: string
  brand: string
  model: string
  version: string
  year: string | null
  valueType: CommissionValueType
  value: number | null
  isArchived: boolean
  createdAt: string
  updatedAt: string
}

type CommissionOwner = {
  id: string
  fullName: string
  role: 'DIRECTOR' | 'MANAGER'
}

function isCommissionOwner(user: Awaited<ReturnType<typeof listManagedUsers>>[number]): user is Awaited<ReturnType<typeof listManagedUsers>>[number] & CommissionOwner {
  return user.role === 'DIRECTOR' || user.role === 'MANAGER'
}

type CommissionStore = {
  rules: CommissionRule[]
  updatedAt: string | null
  updatedBy: string | null
}

const COMMISSION_DATA_DIR = path.join(process.cwd(), 'data')
const COMMISSION_STORE_PATH = path.join(COMMISSION_DATA_DIR, 'commission-rules.json')

function canAccessCommissionModule(role: AuthSession['role']) {
  return role === 'ADMIN' || role === 'DIRECTOR' || role === 'MANAGER'
}

function canEditRule(session: AuthSession, targetUserId: string) {
  if (session.role === 'ADMIN') {
    return true
  }

  return session.sub === targetUserId
}

function buildRuleId(userId: string, catalogKey: string) {
  return `${userId}::${catalogKey}`
}

function buildSeedStore(): CommissionStore {
  return {
    rules: [],
    updatedAt: null,
    updatedBy: null,
  }
}

async function ensureStoreFile() {
  await mkdir(COMMISSION_DATA_DIR, { recursive: true })

  try {
    await readFile(COMMISSION_STORE_PATH, 'utf8')
  } catch {
    await writeFile(COMMISSION_STORE_PATH, JSON.stringify(buildSeedStore(), null, 2), 'utf8')
  }
}

async function writeStore(store: CommissionStore) {
  await ensureStoreFile()
  await writeFile(COMMISSION_STORE_PATH, JSON.stringify(store, null, 2), 'utf8')
}

async function readStore() {
  await ensureStoreFile()

  try {
    const raw = await readFile(COMMISSION_STORE_PATH, 'utf8')
    const parsed = JSON.parse(raw) as Partial<CommissionStore>

    return {
      rules: Array.isArray(parsed.rules) ? parsed.rules.filter(Boolean) as CommissionRule[] : [],
      updatedAt: typeof parsed.updatedAt === 'string' ? parsed.updatedAt : null,
      updatedBy: typeof parsed.updatedBy === 'string' ? parsed.updatedBy : null,
    } satisfies CommissionStore
  } catch {
    const seed = buildSeedStore()
    await writeStore(seed)
    return seed
  }
}

export async function syncCommissionRules(systemActor = 'System') {
  const [store, pricingSheet, users] = await Promise.all([
    readStore(),
    getActivePricingSheet(),
    listManagedUsers(),
  ])

  const catalog = buildPricingCatalog(pricingSheet)
  const eligibleUsers: CommissionOwner[] = users
    .filter(isCommissionOwner)
    .map((user) => ({
      id: user.id,
      fullName: user.fullName,
      role: user.role,
    }))
  const nextRules = new Map(store.rules.map((rule) => [rule.id, rule]))
  const activeRuleIds = new Set<string>()

  for (const user of eligibleUsers) {
    for (const item of catalog) {
      const id = buildRuleId(user.id, item.key)
      const existing = nextRules.get(id)

      activeRuleIds.add(id)

      if (existing) {
        existing.userName = user.fullName
        existing.userRole = user.role
        existing.brand = item.brand
        existing.model = item.model
        existing.version = item.version
        existing.year = item.year
        existing.catalogKey = item.key
        existing.isArchived = false
        continue
      }

      const timestamp = new Date().toISOString()

      nextRules.set(id, {
        id,
        userId: user.id,
        userName: user.fullName,
        userRole: user.role,
        catalogKey: item.key,
        brand: item.brand,
        model: item.model,
        version: item.version,
        year: item.year,
        valueType: 'AMOUNT',
        value: null,
        isArchived: false,
        createdAt: timestamp,
        updatedAt: timestamp,
      })
    }
  }

  for (const rule of nextRules.values()) {
    const userStillEligible = eligibleUsers.some((user) => user.id === rule.userId)
    rule.isArchived = !userStillEligible || !activeRuleIds.has(rule.id)
  }

  const nextStore: CommissionStore = {
    rules: [...nextRules.values()].sort((left, right) => left.userName.localeCompare(right.userName, 'pl') || left.brand.localeCompare(right.brand, 'pl') || left.model.localeCompare(right.model, 'pl') || left.version.localeCompare(right.version, 'pl')),
    updatedAt: new Date().toISOString(),
    updatedBy: systemActor,
  }

  await writeStore(nextStore)
  return nextStore
}

export async function getCommissionWorkspace(session: AuthSession, targetUserId?: string | null) {
  if (!canAccessCommissionModule(session.role)) {
    return { ok: false as const, error: 'Nie masz dostępu do modułu prowizji.' }
  }

  const [store, users] = await Promise.all([
    syncCommissionRules(session.fullName),
    listManagedUsers(),
  ])

  const eligibleUsers: CommissionOwner[] = users
    .filter(isCommissionOwner)
    .map((user) => ({
      id: user.id,
      fullName: user.fullName,
      role: user.role,
    }))

  if (eligibleUsers.length === 0) {
    return {
      ok: true as const,
      targetUserId: null,
      editable: false,
      users: [],
      rules: [],
      summary: { total: 0, configured: 0, missing: 0, archived: 0 },
      updatedAt: store.updatedAt,
      updatedBy: store.updatedBy,
    }
  }

  const resolvedTargetUserId = session.role === 'ADMIN'
    ? targetUserId && eligibleUsers.some((user) => user.id === targetUserId)
      ? targetUserId
      : eligibleUsers[0].id
    : session.sub

  const targetUser = eligibleUsers.find((user) => user.id === resolvedTargetUserId)

  if (!targetUser) {
    return { ok: false as const, error: 'Nie znaleziono użytkownika do konfiguracji prowizji.' }
  }

  const visibleRules = store.rules.filter((rule) => rule.userId === resolvedTargetUserId)
  const activeRules = visibleRules.filter((rule) => !rule.isArchived)

  return {
    ok: true as const,
    targetUserId: resolvedTargetUserId,
    editable: canEditRule(session, resolvedTargetUserId),
    users: eligibleUsers,
    rules: activeRules,
    summary: {
      total: activeRules.length,
      configured: activeRules.filter((rule) => rule.value !== null).length,
      missing: activeRules.filter((rule) => rule.value === null).length,
      archived: visibleRules.filter((rule) => rule.isArchived).length,
    },
    updatedAt: store.updatedAt,
    updatedBy: store.updatedBy,
  }
}

export async function saveCommissionRules(
  session: AuthSession,
  input: {
    targetUserId: string
    rules: Array<{
      id: string
      valueType: CommissionValueType
      value: number | null
    }>
  }
) {
  if (!canAccessCommissionModule(session.role)) {
    return { ok: false as const, error: 'Nie masz dostępu do zapisu prowizji.' }
  }

  if (!canEditRule(session, input.targetUserId)) {
    return { ok: false as const, error: 'Nie możesz edytować prowizji tego użytkownika.' }
  }

  const store = await syncCommissionRules(session.fullName)
  const rulesById = new Map(store.rules.map((rule) => [rule.id, rule]))

  for (const payload of input.rules) {
    const rule = rulesById.get(payload.id)

    if (!rule || rule.userId !== input.targetUserId || rule.isArchived) {
      return { ok: false as const, error: 'Jedna z pozycji prowizyjnych jest nieaktualna. Odśwież widok i spróbuj ponownie.' }
    }

    if (payload.value !== null && payload.value < 0) {
      return { ok: false as const, error: 'Prowizja nie może być wartością ujemną.' }
    }

    if (payload.valueType === 'PERCENT' && payload.value !== null && payload.value > 100) {
      return { ok: false as const, error: 'Prowizja procentowa nie może być większa niż 100%.' }
    }

    rule.valueType = payload.valueType
    rule.value = payload.value
    rule.updatedAt = new Date().toISOString()
  }

  const nextStore: CommissionStore = {
    rules: [...rulesById.values()],
    updatedAt: new Date().toISOString(),
    updatedBy: session.fullName,
  }

  await writeStore(nextStore)

  return { ok: true as const }
}

export async function listActiveCommissionRules() {
  const store = await syncCommissionRules('System')
  return store.rules.filter((rule) => !rule.isArchived)
}