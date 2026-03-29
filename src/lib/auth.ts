import 'server-only'

import { randomUUID, scryptSync, timingSafeEqual } from 'node:crypto'

import { cookies } from 'next/headers'
import { UserRole } from '@prisma/client'
import { SignJWT, jwtVerify } from 'jose'

import { db } from '@/lib/db'
import type { UserRoleKey } from '@/lib/rbac'

export type AuthSession = {
  sub: string
  email: string
  fullName: string
  role: UserRoleKey
}

export type DemoUser = AuthSession & {
  reportsToUserId?: string | null
  password: string
}

type AuthBackedUser = DemoUser & {
  isActive: boolean
  region: string | null
  teamName: string | null
  createdAt: string
  source: 'seed' | 'custom'
}

const SESSION_COOKIE = 'crmvp_session'

const seedUsers: DemoUser[] = [
  {
    sub: 'demo-admin',
    email: 'admin@veloprime.pl',
    fullName: 'Administrator VeloPrime',
    role: 'ADMIN',
    reportsToUserId: null,
    password: 'Admin123!'
  },
  {
    sub: 'demo-director',
    email: 'dyrektor@veloprime.pl',
    fullName: 'Dyrektor Sprzedazy',
    role: 'DIRECTOR',
    reportsToUserId: null,
    password: 'Director123!'
  },
  {
    sub: 'demo-manager',
    email: 'manager@veloprime.pl',
    fullName: 'Manager Regionu',
    role: 'MANAGER',
    reportsToUserId: 'demo-director',
    password: 'Manager123!'
  },
  {
    sub: 'demo-sales',
    email: 'handlowiec@veloprime.pl',
    fullName: 'Handlowiec VeloPrime',
    role: 'SALES',
    reportsToUserId: 'demo-manager',
    password: 'Sales123!'
  },
]

const globalForAuth = globalThis as unknown as {
  crmAuthUsers?: AuthBackedUser[]
}

const PASSWORD_HASH_PREFIX = 'scrypt:'

function mapSeedUser(user: DemoUser): AuthBackedUser {
  return {
    ...user,
    isActive: true,
    region: null,
    teamName: null,
    createdAt: new Date().toISOString(),
    source: 'seed',
  }
}

function getUserStore() {
  if (!globalForAuth.crmAuthUsers) {
    globalForAuth.crmAuthUsers = seedUsers.map(mapSeedUser)
  }

  return globalForAuth.crmAuthUsers
}

function sanitizeAuthUser(user: AuthBackedUser) {
  return {
    sub: user.sub,
    email: user.email,
    fullName: user.fullName,
    role: user.role,
    reportsToUserId: user.reportsToUserId ?? null,
    isActive: user.isActive,
    region: user.region,
    teamName: user.teamName,
    createdAt: user.createdAt,
    source: user.source,
  }
}

function generateTemporaryPassword() {
  const suffix = randomUUID().slice(0, 8)
  return `Start!${suffix}`
}

function hashPassword(password: string) {
  const salt = randomUUID().replace(/-/g, '')
  const hash = scryptSync(password, salt, 64).toString('hex')
  return `${PASSWORD_HASH_PREFIX}${salt}:${hash}`
}

function verifyPassword(password: string, passwordHash: string | null | undefined) {
  if (!passwordHash) {
    return false
  }

  if (!passwordHash.startsWith(PASSWORD_HASH_PREFIX)) {
    return passwordHash === password
  }

  const [salt, storedHash] = passwordHash.slice(PASSWORD_HASH_PREFIX.length).split(':')

  if (!salt || !storedHash) {
    return false
  }

  const computed = scryptSync(password, salt, 64)
  const stored = Buffer.from(storedHash, 'hex')

  if (computed.length !== stored.length) {
    return false
  }

  return timingSafeEqual(computed, stored)
}

function mapDbRole(role: UserRole): UserRoleKey {
  return role as UserRoleKey
}

function mapDbUser(user: {
  id: string
  email: string
  fullName: string
  role: UserRole
  isActive: boolean
  region: string | null
  teamName: string | null
  reportsToUserId: string | null
  createdAt: Date
  passwordHash?: string | null
}): AuthBackedUser {
  return {
    sub: user.id,
    email: user.email,
    fullName: user.fullName,
    role: mapDbRole(user.role),
    reportsToUserId: user.reportsToUserId ?? null,
    password: user.passwordHash ?? '',
    isActive: user.isActive,
    region: user.region,
    teamName: user.teamName,
    createdAt: user.createdAt.toISOString(),
    source: user.id.startsWith('demo-') ? 'seed' : 'custom',
  }
}

async function ensureSeedUsersInDb() {
  if (!db) {
    return null
  }

  for (const user of seedUsers) {
    await db.user.upsert({
      where: { id: user.sub },
      update: {
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        isActive: true,
        reportsToUserId: user.reportsToUserId ?? null,
        passwordHash: hashPassword(user.password),
      },
      create: {
        id: user.sub,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        isActive: true,
        reportsToUserId: user.reportsToUserId ?? null,
        passwordHash: hashPassword(user.password),
      },
    })
  }

  return db.user.findMany({
    orderBy: { fullName: 'asc' },
  })
}

async function listDbUsers() {
  if (!db) {
    return null
  }

  const users = await ensureSeedUsersInDb()
  return users?.map(mapDbUser) ?? []
}

function getSecret() {
  return new TextEncoder().encode(process.env.AUTH_SECRET || 'crm-veloprime-dev-secret-change-me')
}

function getSessionCookieOptions() {
  return {
    httpOnly: true,
    sameSite: 'lax' as const,
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    maxAge: 60 * 60 * 12,
  }
}

export function getCookieName() {
  return SESSION_COOKIE
}

export function getDemoUsers() {
  return getUserStore().filter((user) => user.source === 'seed').map(sanitizeAuthUser)
}

export async function validateDemoCredentials(email: string, password: string) {
  const normalizedEmail = email.trim().toLowerCase()

  const dbUsers = await listDbUsers()
  if (dbUsers) {
    return dbUsers.find(
      (user) => user.isActive && user.email === normalizedEmail && verifyPassword(password, user.password),
    ) ?? null
  }

  return getUserStore().find(
    (user) => user.isActive && user.email === normalizedEmail && user.password === password,
  ) ?? null
}

export async function listAuthUsers() {
  const dbUsers = await listDbUsers()
  if (dbUsers) {
    return dbUsers.map(sanitizeAuthUser)
  }

  return getUserStore().map(sanitizeAuthUser)
}

export async function createAuthUser(input: {
  fullName: string
  email: string
  role: UserRoleKey
  region?: string
  teamName?: string
  reportsToUserId?: string | null
  password?: string
}) {
  const normalizedEmail = input.email.trim().toLowerCase()
  const password = input.password?.trim() || generateTemporaryPassword()

  if (db) {
    await ensureSeedUsersInDb()

    const created = await db.user.create({
      data: {
        id: `custom-${randomUUID()}`,
        email: normalizedEmail,
        fullName: input.fullName.trim(),
        role: input.role,
        isActive: true,
        region: input.region?.trim() || null,
        teamName: input.teamName?.trim() || null,
        reportsToUserId: input.reportsToUserId ?? null,
        passwordHash: hashPassword(password),
      },
    })

    return {
      user: sanitizeAuthUser(mapDbUser(created)),
      temporaryPassword: input.password?.trim() ? null : password,
    }
  }

  const users = getUserStore()

  const nextUser: AuthBackedUser = {
    sub: `custom-${randomUUID()}`,
    email: normalizedEmail,
    fullName: input.fullName.trim(),
    role: input.role,
    reportsToUserId: input.reportsToUserId ?? null,
    password,
    isActive: true,
    region: input.region?.trim() || null,
    teamName: input.teamName?.trim() || null,
    createdAt: new Date().toISOString(),
    source: 'custom',
  }

  users.push(nextUser)

  return {
    user: sanitizeAuthUser(nextUser),
    temporaryPassword: input.password?.trim() ? null : password,
  }
}

export async function toggleAuthUserStatus(userId: string) {
  if (db) {
    await ensureSeedUsersInDb()
    const current = await db.user.findUnique({ where: { id: userId } })

    if (!current) {
      return null
    }

    const updated = await db.user.update({
      where: { id: userId },
      data: { isActive: !current.isActive },
    })

    return sanitizeAuthUser(mapDbUser(updated))
  }

  const users = getUserStore()
  const user = users.find((entry) => entry.sub === userId)

  if (!user) {
    return null
  }

  user.isActive = !user.isActive
  return sanitizeAuthUser(user)
}

export async function changeAuthUserPassword(input: {
  userId: string
  currentPassword: string
  newPassword: string
}) {
  if (db) {
    await ensureSeedUsersInDb()
    const user = await db.user.findUnique({ where: { id: input.userId } })

    if (!user) {
      return { ok: false as const, error: 'Nie znaleziono użytkownika.' }
    }

    if (!user.isActive) {
      return { ok: false as const, error: 'Konto użytkownika jest zablokowane.' }
    }

    if (!verifyPassword(input.currentPassword, user.passwordHash)) {
      return { ok: false as const, error: 'Obecne hasło jest nieprawidłowe.' }
    }

    const nextPassword = input.newPassword.trim()

    if (nextPassword.length < 8) {
      return { ok: false as const, error: 'Nowe hasło musi mieć co najmniej 8 znaków.' }
    }

    await db.user.update({
      where: { id: input.userId },
      data: { passwordHash: hashPassword(nextPassword) },
    })

    return { ok: true as const }
  }

  const users = getUserStore()
  const user = users.find((entry) => entry.sub === input.userId)

  if (!user) {
    return { ok: false as const, error: 'Nie znaleziono użytkownika.' }
  }

  if (!user.isActive) {
    return { ok: false as const, error: 'Konto użytkownika jest zablokowane.' }
  }

  if (user.password !== input.currentPassword) {
    return { ok: false as const, error: 'Obecne hasło jest nieprawidłowe.' }
  }

  const nextPassword = input.newPassword.trim()

  if (nextPassword.length < 8) {
    return { ok: false as const, error: 'Nowe hasło musi mieć co najmniej 8 znaków.' }
  }

  user.password = nextPassword

  return { ok: true as const }
}

export async function resetAuthUserPassword(input: { userId: string; newPassword?: string }) {
  if (db) {
    await ensureSeedUsersInDb()
    const user = await db.user.findUnique({ where: { id: input.userId } })

    if (!user) {
      return { ok: false as const, error: 'Nie znaleziono użytkownika.' }
    }

    const nextPassword = input.newPassword?.trim() || generateTemporaryPassword()

    if (nextPassword.length < 8) {
      return { ok: false as const, error: 'Hasło tymczasowe musi mieć co najmniej 8 znaków.' }
    }

    await db.user.update({
      where: { id: input.userId },
      data: { passwordHash: hashPassword(nextPassword) },
    })

    return {
      ok: true as const,
      temporaryPassword: nextPassword,
    }
  }

  const users = getUserStore()
  const user = users.find((entry) => entry.sub === input.userId)

  if (!user) {
    return { ok: false as const, error: 'Nie znaleziono użytkownika.' }
  }

  const nextPassword = input.newPassword?.trim() || generateTemporaryPassword()

  if (nextPassword.length < 8) {
    return { ok: false as const, error: 'Hasło tymczasowe musi mieć co najmniej 8 znaków.' }
  }

  user.password = nextPassword

  return {
    ok: true as const,
    temporaryPassword: nextPassword,
  }
}

export async function createSessionToken(session: AuthSession) {
  return new SignJWT({
    email: session.email,
    fullName: session.fullName,
    role: session.role,
  })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(session.sub)
    .setIssuedAt()
    .setExpirationTime('12h')
    .sign(getSecret())
}

export function getSessionCookieSettings() {
  return getSessionCookieOptions()
}

export async function createSession(session: AuthSession) {
  const token = await createSessionToken(session)

  const cookieStore = await cookies()
  cookieStore.set(SESSION_COOKIE, token, getSessionCookieOptions())
}

export async function clearSession() {
  const cookieStore = await cookies()
  cookieStore.delete(SESSION_COOKIE)
}

export async function getSession() {
  const cookieStore = await cookies()
  const token = cookieStore.get(SESSION_COOKIE)?.value

  if (!token) {
    return null
  }

  try {
    const { payload } = await jwtVerify(token, getSecret())

    return {
      sub: payload.sub || '',
      email: String(payload.email || ''),
      fullName: String(payload.fullName || ''),
      role: payload.role as UserRoleKey,
    } satisfies AuthSession
  } catch {
    return null
  }
}