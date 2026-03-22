import 'server-only'

import { getDemoUsers } from '@/lib/auth'
import type { UserRoleKey } from '@/lib/rbac'

export type ManagedUser = {
  id: string
  fullName: string
  email: string
  role: UserRoleKey
  isActive: boolean
  region: string | null
  teamName: string | null
  reportsToUserId: string | null
  createdAt: string
  source: 'seed' | 'custom'
}

type CreateManagedUserInput = {
  fullName: string
  email: string
  role: UserRoleKey
  region?: string
  teamName?: string
  reportsToUserId?: string
}

const globalForUsers = globalThis as unknown as {
  crmUsers?: ManagedUser[]
}

function buildSeedUsers(): ManagedUser[] {
  return getDemoUsers().map((user) => ({
    id: user.sub,
    fullName: user.fullName,
    email: user.email,
    role: user.role,
    isActive: true,
    region: null,
    teamName: null,
    reportsToUserId: user.reportsToUserId ?? null,
    createdAt: new Date().toISOString(),
    source: 'seed',
  }))
}

function isSupervisorAllowed(role: UserRoleKey, supervisorRole: UserRoleKey) {
  if (role === 'MANAGER') {
    return supervisorRole === 'DIRECTOR'
  }

  if (role === 'SALES') {
    return supervisorRole === 'MANAGER' || supervisorRole === 'DIRECTOR'
  }

  return false
}

function normalizeSupervisorId(value?: string) {
  const normalized = value?.trim()
  return normalized ? normalized : null
}

function getStore() {
  if (!globalForUsers.crmUsers) {
    globalForUsers.crmUsers = buildSeedUsers()
  }

  return globalForUsers.crmUsers
}

export async function listManagedUsers() {
  return [...getStore()].sort((left, right) => left.fullName.localeCompare(right.fullName, 'pl'))
}

export async function listPotentialSupervisors(role: UserRoleKey) {
  if (role === 'ADMIN' || role === 'DIRECTOR') {
    return []
  }

  return (await listManagedUsers()).filter((user) => user.isActive && isSupervisorAllowed(role, user.role))
}

export async function createManagedUser(input: CreateManagedUserInput) {
  const users = getStore()
  const normalizedEmail = input.email.trim().toLowerCase()
  const reportsToUserId = normalizeSupervisorId(input.reportsToUserId)

  if (!input.fullName.trim()) {
    return { ok: false as const, error: 'Podaj imię i nazwisko użytkownika.' }
  }

  if (!normalizedEmail || !normalizedEmail.includes('@')) {
    return { ok: false as const, error: 'Podaj poprawny adres email.' }
  }

  if (users.some((user) => user.email === normalizedEmail)) {
    return { ok: false as const, error: 'Konto z takim emailem już istnieje.' }
  }

  if ((input.role === 'MANAGER' || input.role === 'SALES') && !reportsToUserId) {
    return { ok: false as const, error: 'Wybierz bezpośredniego przełożonego dla tego użytkownika.' }
  }

  if ((input.role === 'ADMIN' || input.role === 'DIRECTOR') && reportsToUserId) {
    return { ok: false as const, error: 'Ta rola nie powinna mieć przypisanego przełożonego.' }
  }

  if (reportsToUserId) {
    const supervisor = users.find((user) => user.id === reportsToUserId)

    if (!supervisor) {
      return { ok: false as const, error: 'Wybrany przełożony nie istnieje.' }
    }

    if (!isSupervisorAllowed(input.role, supervisor.role)) {
      return { ok: false as const, error: 'Wybrany przełożony nie pasuje do tej roli w strukturze sprzedaży.' }
    }
  }

  const nextUser: ManagedUser = {
    id: `custom-${crypto.randomUUID()}`,
    fullName: input.fullName.trim(),
    email: normalizedEmail,
    role: input.role,
    isActive: true,
    region: input.region?.trim() || null,
    teamName: input.teamName?.trim() || null,
    reportsToUserId,
    createdAt: new Date().toISOString(),
    source: 'custom',
  }

  users.push(nextUser)

  return { ok: true as const, user: nextUser }
}

export async function toggleManagedUserStatus(userId: string) {
  const users = getStore()
  const user = users.find((entry) => entry.id === userId)

  if (!user) {
    return { ok: false as const, error: 'Nie znaleziono użytkownika.' }
  }

  user.isActive = !user.isActive
  return { ok: true as const, user }
}