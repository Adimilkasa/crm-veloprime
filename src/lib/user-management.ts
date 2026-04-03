import 'server-only'

import { createAuthUser, listAuthUsers, resetAuthUserPassword, toggleAuthUserStatus } from '@/lib/auth'
import type { UserRoleKey } from '@/lib/rbac'

export type ManagedUser = {
  id: string
  fullName: string
  email: string
  phone: string | null
  avatarUrl: string | null
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
  phone?: string
  role: UserRoleKey
  password?: string
  region?: string
  teamName?: string
  reportsToUserId?: string
}

function isSupervisorAllowed(role: UserRoleKey, supervisorRole: UserRoleKey) {
  if (role === 'MANAGER') {
    return supervisorRole === 'ADMIN' || supervisorRole === 'DIRECTOR'
  }

  if (role === 'SALES') {
    return supervisorRole === 'ADMIN' || supervisorRole === 'MANAGER' || supervisorRole === 'DIRECTOR'
  }

  return false
}

function normalizeSupervisorId(value?: string) {
  const normalized = value?.trim()
  return normalized ? normalized : null
}

export async function listManagedUsers() {
  return [...(await listAuthUsers())]
    .map((user) => ({
      id: user.sub,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone ?? null,
      avatarUrl: user.avatarUrl ?? null,
      role: user.role,
      isActive: user.isActive,
      region: user.region,
      teamName: user.teamName,
      reportsToUserId: user.reportsToUserId ?? null,
      createdAt: user.createdAt,
      source: user.source,
    }))
    .sort((left, right) => left.fullName.localeCompare(right.fullName, 'pl'))
}

export async function listPotentialSupervisors(role: UserRoleKey) {
  if (role === 'ADMIN' || role === 'DIRECTOR') {
    return []
  }

  return (await listManagedUsers()).filter((user) => user.isActive && isSupervisorAllowed(role, user.role))
}

export async function createManagedUser(input: CreateManagedUserInput) {
  const normalizedEmail = input.email.trim().toLowerCase()
  const normalizedPhone = input.phone?.trim() ?? ''
  const reportsToUserId = normalizeSupervisorId(input.reportsToUserId)
  const users = await listManagedUsers()

  if (!input.fullName.trim()) {
    return { ok: false as const, error: 'Podaj imię i nazwisko użytkownika.' }
  }

  if (!normalizedEmail || !normalizedEmail.includes('@')) {
    return { ok: false as const, error: 'Podaj poprawny adres email.' }
  }

  if (!normalizedPhone) {
    return { ok: false as const, error: 'Podaj numer telefonu użytkownika.' }
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

  const result = await createAuthUser({
    fullName: input.fullName,
    email: normalizedEmail,
    phone: normalizedPhone,
    role: input.role,
    password: input.password,
    region: input.region,
    teamName: input.teamName,
    reportsToUserId,
  })

  return {
    ok: true as const,
    user: {
      id: result.user.sub,
      fullName: result.user.fullName,
      email: result.user.email,
      phone: result.user.phone ?? null,
      avatarUrl: result.user.avatarUrl ?? null,
      role: result.user.role,
      isActive: result.user.isActive,
      region: result.user.region,
      teamName: result.user.teamName,
      reportsToUserId: result.user.reportsToUserId ?? null,
      createdAt: result.user.createdAt,
      source: result.user.source,
    },
    temporaryPassword: result.temporaryPassword,
  }
}

export async function toggleManagedUserStatus(userId: string) {
  const user = await toggleAuthUserStatus(userId)

  if (!user) {
    return { ok: false as const, error: 'Nie znaleziono użytkownika.' }
  }

  return {
    ok: true as const,
    user: {
      id: user.sub,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone ?? null,
      avatarUrl: user.avatarUrl ?? null,
      role: user.role,
      isActive: user.isActive,
      region: user.region,
      teamName: user.teamName,
      reportsToUserId: user.reportsToUserId ?? null,
      createdAt: user.createdAt,
      source: user.source,
    },
  }
}

export async function resetManagedUserPassword(userId: string, newPassword?: string) {
  const result = await resetAuthUserPassword({ userId, newPassword })

  if (!result.ok) {
    return result
  }

  return {
    ok: true as const,
    temporaryPassword: result.temporaryPassword,
  }
}