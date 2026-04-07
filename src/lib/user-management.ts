import 'server-only'

import { createAuthUser, listAuthUsers, resetAuthUserPassword, toggleAuthUserStatus, type AuthSession } from '@/lib/auth'
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

const manageableRolesByActor: Record<UserRoleKey, UserRoleKey[]> = {
  ADMIN: ['ADMIN', 'DIRECTOR', 'MANAGER', 'SALES'],
  DIRECTOR: ['MANAGER', 'SALES'],
  MANAGER: ['SALES'],
  SALES: [],
}

export function canAccessUserAdministration(role: UserRoleKey) {
  return role === 'ADMIN' || role === 'DIRECTOR' || role === 'MANAGER'
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

function buildUsersById(users: ManagedUser[]) {
  return new Map(users.map((user) => [user.id, user] as const))
}

function isDescendantOf(user: ManagedUser, ancestorId: string, usersById: Map<string, ManagedUser>) {
  const visited = new Set<string>()
  let currentUser = user

  while (currentUser.reportsToUserId) {
    const nextId = currentUser.reportsToUserId
    if (!visited.add(nextId)) {
      return false
    }

    if (nextId === ancestorId) {
      return true
    }

    const nextUser = usersById.get(nextId)
    if (!nextUser) {
      return false
    }

    currentUser = nextUser
  }

  return false
}

function canManageExistingUser(session: AuthSession, targetUser: ManagedUser, users: ManagedUser[]) {
  if (targetUser.id === session.sub) {
    return false
  }

  if (session.role === 'ADMIN') {
    return true
  }

  if (!canAccessUserAdministration(session.role)) {
    return false
  }

  const usersById = buildUsersById(users)
  if (!isDescendantOf(targetUser, session.sub, usersById)) {
    return false
  }

  return manageableRolesByActor[session.role].includes(targetUser.role)
}

function assignableRolesForSession(role: UserRoleKey) {
  return manageableRolesByActor[role]
}

function listDirectManagerSubordinates(session: AuthSession, users: ManagedUser[]) {
  return users.filter(
    (user) => user.isActive && user.role === 'MANAGER' && user.reportsToUserId === session.sub,
  )
}

function listSupervisorOptionsForSession(session: AuthSession, users: ManagedUser[]) {
  if (session.role === 'ADMIN') {
    return users.filter((user) => user.isActive && (user.role === 'ADMIN' || user.role === 'DIRECTOR' || user.role === 'MANAGER'))
  }

  if (session.role === 'DIRECTOR') {
    const currentUser = users.find((user) => user.id === session.sub && user.isActive) ?? null
    return [
      ...(currentUser == null ? [] : [currentUser]),
      ...listDirectManagerSubordinates(session, users),
    ]
  }

  if (session.role === 'MANAGER') {
    const currentUser = users.find((user) => user.id === session.sub && user.isActive) ?? null
    return currentUser == null ? [] : [currentUser]
  }

  return []
}

function canAssignSupervisorForSession(
  session: AuthSession,
  targetRole: UserRoleKey,
  supervisorId: string | null,
  users: ManagedUser[],
) {
  if (!supervisorId) {
    return targetRole === 'ADMIN' || targetRole === 'DIRECTOR'
  }

  const allowedSupervisorIds = new Set(listSupervisorOptionsForSession(session, users).map((user) => user.id))
  if (!allowedSupervisorIds.has(supervisorId)) {
    return false
  }

  const supervisor = users.find((user) => user.id === supervisorId)
  return supervisor != null && isSupervisorAllowed(targetRole, supervisor.role)
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

export async function listManagedUsersForSession(session: AuthSession) {
  const users = await listManagedUsers()

  if (session.role === 'ADMIN') {
    return users
  }

  if (!canAccessUserAdministration(session.role)) {
    return []
  }

  return users.filter((user) => canManageExistingUser(session, user, users))
}

export async function listSupervisorOptionsForManagedUser(session: AuthSession) {
  const users = await listManagedUsers()
  return listSupervisorOptionsForSession(session, users)
}

export async function createManagedUserForSession(session: AuthSession, input: CreateManagedUserInput) {
  if (!canAccessUserAdministration(session.role)) {
    return { ok: false as const, error: 'Brak dostępu do administracji kontami.' }
  }

  const allowedRoles = assignableRolesForSession(session.role)
  if (!allowedRoles.includes(input.role)) {
    return { ok: false as const, error: 'Nie możesz utworzyć konta o tej roli.' }
  }

  const users = await listManagedUsers()
  let reportsToUserId = normalizeSupervisorId(input.reportsToUserId)

  if (session.role === 'DIRECTOR' && input.role === 'MANAGER') {
    reportsToUserId ??= session.sub
  }

  if ((session.role === 'DIRECTOR' || session.role === 'MANAGER') && input.role === 'SALES') {
    reportsToUserId ??= session.sub
  }

  if (!canAssignSupervisorForSession(session, input.role, reportsToUserId, users)) {
    return { ok: false as const, error: 'Wybrany przełożony nie należy do Twojej struktury lub nie pasuje do tej roli.' }
  }

  return createManagedUser({
    ...input,
    reportsToUserId: reportsToUserId ?? undefined,
  })
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

export async function toggleManagedUserStatusForSession(session: AuthSession, userId: string) {
  const users = await listManagedUsers()
  const targetUser = users.find((user) => user.id === userId)

  if (!targetUser) {
    return { ok: false as const, error: 'Nie znaleziono użytkownika.' }
  }

  if (!canManageExistingUser(session, targetUser, users)) {
    return { ok: false as const, error: 'Możesz blokować i odblokowywać tylko konta swoich podwładnych.' }
  }

  return toggleManagedUserStatus(userId)
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

export async function resetManagedUserPasswordForSession(session: AuthSession, userId: string, newPassword?: string) {
  const users = await listManagedUsers()
  const targetUser = users.find((user) => user.id === userId)

  if (!targetUser) {
    return { ok: false as const, error: 'Nie znaleziono użytkownika.' }
  }

  if (!canManageExistingUser(session, targetUser, users)) {
    return { ok: false as const, error: 'Możesz resetować hasła tylko kont swoich podwładnych.' }
  }

  return resetManagedUserPassword(userId, newPassword)
}