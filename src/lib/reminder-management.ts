import 'server-only'

import { mkdir, readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'

import type { AuthSession } from '@/lib/auth'
import { db, hasDatabaseUrl, isDatabaseUnavailableError } from '@/lib/db'
import { listManagedLeads } from '@/lib/lead-management'
import { listManagedUsers } from '@/lib/user-management'

export type ManagedReminder = {
  id: string
  title: string
  note: string | null
  remindAt: string
  isCompleted: boolean
  completedAt: string | null
  leadId: string | null
  leadName: string | null
  ownerUserId: string | null
  ownerName: string | null
  createdByUserId: string | null
  createdByName: string | null
  createdAt: string
  updatedAt: string
}

type CreateManagedReminderInput = {
  title: string
  note?: string
  remindAt: string
  leadId?: string
}

type PersistedReminderRecord = ManagedReminder

type PersistedReminderStore = {
  reminders: PersistedReminderRecord[]
}

type ManagedUser = Awaited<ReturnType<typeof listManagedUsers>>[number]

const REMINDER_DATA_DIR = path.join(process.cwd(), 'data')
const REMINDER_STORE_PATH = path.join(REMINDER_DATA_DIR, 'reminders.json')

let inMemoryReminderStore: PersistedReminderStore | null = null
let forceFileReminderStorage = false

function isPrismaReminderStorageEnabled() {
  return !forceFileReminderStorage && hasDatabaseUrl() && Boolean(db)
}

function isPrismaSchemaMismatch(error: unknown) {
  return typeof error === 'object'
    && error !== null
    && 'code' in error
    && ['P2021', 'P2022'].includes((error as { code?: string }).code ?? '')
}

function canUseFileReminderStorageFallback(error: unknown) {
  return isDatabaseUnavailableError(error) || (process.env.NODE_ENV !== 'production' && isPrismaSchemaMismatch(error))
}

function normalizeReminder(entry: Partial<ManagedReminder>): ManagedReminder {
  const remindAt = entry.remindAt ?? new Date().toISOString()
  const createdAt = entry.createdAt ?? remindAt
  const updatedAt = entry.updatedAt ?? createdAt

  return {
    id: entry.id ?? `reminder-${crypto.randomUUID()}`,
    title: entry.title?.trim() || 'Przypomnienie',
    note: entry.note?.trim() || null,
    remindAt,
    isCompleted: entry.isCompleted ?? false,
    completedAt: entry.completedAt ?? null,
    leadId: entry.leadId?.trim() || null,
    leadName: entry.leadName?.trim() || null,
    ownerUserId: entry.ownerUserId?.trim() || null,
    ownerName: entry.ownerName?.trim() || null,
    createdByUserId: entry.createdByUserId?.trim() || null,
    createdByName: entry.createdByName?.trim() || null,
    createdAt,
    updatedAt,
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

function canViewReminder(session: AuthSession, reminder: ManagedReminder, users: ManagedUser[]) {
  if (session.role === 'ADMIN') {
    return true
  }

  const visibleOwnerIds = getVisibleOwnerIds(session, users)
  return Boolean(reminder.ownerUserId && visibleOwnerIds.has(reminder.ownerUserId)) || reminder.createdByUserId === session.sub
}

async function ensureStoreFile() {
  try {
    await mkdir(REMINDER_DATA_DIR, { recursive: true })
    await readFile(REMINDER_STORE_PATH, 'utf8')
  } catch {
    const seedStore = { reminders: [] } satisfies PersistedReminderStore
    inMemoryReminderStore = seedStore

    try {
      await writeFile(REMINDER_STORE_PATH, JSON.stringify(seedStore, null, 2), 'utf8')
    } catch {
      // Serverless environments may not allow writes to the application filesystem.
    }
  }
}

async function readStore() {
  await ensureStoreFile()

  try {
    const raw = await readFile(REMINDER_STORE_PATH, 'utf8')
    const parsed = JSON.parse(raw) as Partial<PersistedReminderStore>

    return {
      reminders: Array.isArray(parsed.reminders)
        ? parsed.reminders.filter(Boolean).map((entry) => normalizeReminder(entry))
        : [],
    } satisfies PersistedReminderStore
  } catch {
    if (!inMemoryReminderStore) {
      inMemoryReminderStore = { reminders: [] } satisfies PersistedReminderStore
    }

    return inMemoryReminderStore
  }
}

async function writeStore(store: PersistedReminderStore) {
  inMemoryReminderStore = store

  try {
    await ensureStoreFile()
    await writeFile(REMINDER_STORE_PATH, JSON.stringify(store, null, 2), 'utf8')
  } catch {
    // Ignore filesystem write failures in serverless hosting.
  }
}

function mapDbReminder(record: {
  id: string
  title: string
  note: string | null
  remindAt: Date
  isCompleted: boolean
  completedAt: Date | null
  leadId: string | null
  leadNameSnapshot: string | null
  ownerUserId: string | null
  ownerNameSnapshot: string | null
  createdByUserId: string | null
  createdByNameSnapshot: string | null
  lead?: { firstName: string | null; lastName: string | null } | null
  ownerUser?: { fullName: string } | null
  createdByUser?: { fullName: string } | null
  createdAt: Date
  updatedAt: Date
}): ManagedReminder {
  const leadName = [record.lead?.firstName?.trim(), record.lead?.lastName?.trim()].filter(Boolean).join(' ').trim()

  return {
    id: record.id,
    title: record.title,
    note: record.note,
    remindAt: record.remindAt.toISOString(),
    isCompleted: record.isCompleted,
    completedAt: record.completedAt?.toISOString() ?? null,
    leadId: record.leadId,
    leadName: leadName || record.leadNameSnapshot,
    ownerUserId: record.ownerUserId,
    ownerName: record.ownerUser?.fullName ?? record.ownerNameSnapshot,
    createdByUserId: record.createdByUserId,
    createdByName: record.createdByUser?.fullName ?? record.createdByNameSnapshot,
    createdAt: record.createdAt.toISOString(),
    updatedAt: record.updatedAt.toISOString(),
  }
}

async function listDbReminders() {
  if (!db) {
    return []
  }

  return db.reminder.findMany({
    include: {
      lead: {
        select: {
          firstName: true,
          lastName: true,
        },
      },
      ownerUser: {
        select: { fullName: true },
      },
      createdByUser: {
        select: { fullName: true },
      },
    },
    orderBy: [
      { isCompleted: 'asc' },
      { remindAt: 'asc' },
      { createdAt: 'desc' },
    ],
  })
}

export async function listManagedReminders(session: AuthSession, options?: { includeCompleted?: boolean }) {
  const users = await listManagedUsers()

  if (isPrismaReminderStorageEnabled() && db) {
    try {
      const reminders = await listDbReminders()

      return reminders
        .map((reminder) => mapDbReminder(reminder))
        .filter((reminder) => canViewReminder(session, reminder, users))
        .filter((reminder) => options?.includeCompleted ? true : !reminder.isCompleted)
    } catch (error) {
      if (!canUseFileReminderStorageFallback(error)) {
        throw error
      }

      forceFileReminderStorage = true
    }
  }

  const store = await readStore()
  return store.reminders
    .map((reminder) => normalizeReminder(reminder))
    .filter((reminder) => canViewReminder(session, reminder, users))
    .filter((reminder) => options?.includeCompleted ? true : !reminder.isCompleted)
    .sort((left, right) => new Date(left.remindAt).getTime() - new Date(right.remindAt).getTime())
}

export async function createManagedReminder(session: AuthSession, input: CreateManagedReminderInput) {
  const title = input.title.trim()
  const remindAt = new Date(input.remindAt)

  if (!title) {
    return { ok: false as const, error: 'Podaj tytuł przypomnienia.' }
  }

  if (Number.isNaN(remindAt.getTime())) {
    return { ok: false as const, error: 'Podaj poprawny termin przypomnienia.' }
  }

  const users = await listManagedUsers()
  const leads = await listManagedLeads(session)
  const lead = input.leadId?.trim() ? leads.find((entry) => entry.id === input.leadId?.trim()) ?? null : null

  if (input.leadId?.trim() && !lead) {
    return { ok: false as const, error: 'Nie znaleziono leada dla przypomnienia.' }
  }

  const ownerUserId = lead?.salespersonId ?? session.sub
  const ownerName = lead?.salespersonName ?? session.fullName
  const createdAt = new Date().toISOString()

  if (isPrismaReminderStorageEnabled() && db) {
    const created = await db.reminder.create({
      data: {
        title,
        note: input.note?.trim() || null,
        remindAt,
        leadId: lead?.id ?? null,
        leadNameSnapshot: lead?.fullName ?? null,
        ownerUserId,
        ownerNameSnapshot: ownerName,
        createdByUserId: session.sub,
        createdByNameSnapshot: session.fullName,
      },
      include: {
        lead: {
          select: {
            firstName: true,
            lastName: true,
          },
        },
        ownerUser: {
          select: { fullName: true },
        },
        createdByUser: {
          select: { fullName: true },
        },
      },
    })

    return { ok: true as const, reminder: mapDbReminder(created) }
  }

  const store = await readStore()
  const reminder = normalizeReminder({
    id: `reminder-${crypto.randomUUID()}`,
    title,
    note: input.note?.trim() || null,
    remindAt: remindAt.toISOString(),
    isCompleted: false,
    completedAt: null,
    leadId: lead?.id ?? null,
    leadName: lead?.fullName ?? null,
    ownerUserId,
    ownerName,
    createdByUserId: session.sub,
    createdByName: session.fullName,
    createdAt,
    updatedAt: createdAt,
  })

  store.reminders.unshift(reminder)
  await writeStore(store)
  return { ok: true as const, reminder }
}

export async function completeManagedReminder(session: AuthSession, reminderId: string) {
  const users = await listManagedUsers()
  const visibleReminders = await listManagedReminders(session, { includeCompleted: true })
  const existingReminder = visibleReminders.find((entry) => entry.id === reminderId) ?? null

  if (!existingReminder) {
    return { ok: false as const, error: 'Nie znaleziono przypomnienia.' }
  }

  if (existingReminder.isCompleted) {
    return { ok: true as const, reminder: existingReminder }
  }

  const completedAt = new Date().toISOString()

  if (isPrismaReminderStorageEnabled() && db) {
    const updated = await db.reminder.update({
      where: { id: reminderId },
      data: {
        isCompleted: true,
        completedAt: new Date(completedAt),
      },
      include: {
        lead: {
          select: {
            firstName: true,
            lastName: true,
          },
        },
        ownerUser: {
          select: { fullName: true },
        },
        createdByUser: {
          select: { fullName: true },
        },
      },
    })

    return { ok: true as const, reminder: mapDbReminder(updated) }
  }

  const store = await readStore()
  const reminderIndex = store.reminders.findIndex((entry) => entry.id === reminderId)

  if (reminderIndex === -1) {
    return { ok: false as const, error: 'Nie znaleziono przypomnienia.' }
  }

  const updatedReminder = normalizeReminder({
    ...store.reminders[reminderIndex],
    isCompleted: true,
    completedAt,
    updatedAt: completedAt,
  })

  if (!canViewReminder(session, updatedReminder, users)) {
    return { ok: false as const, error: 'Nie masz dostępu do tego przypomnienia.' }
  }

  store.reminders[reminderIndex] = updatedReminder
  await writeStore(store)
  return { ok: true as const, reminder: updatedReminder }
}