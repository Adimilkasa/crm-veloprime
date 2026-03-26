import 'server-only'

import { cookies } from 'next/headers'
import { SignJWT, jwtVerify } from 'jose'

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

const SESSION_COOKIE = 'crmvp_session'

const demoUsers: DemoUser[] = [
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
  return demoUsers.map(({ password, ...user }) => user)
}

export function validateDemoCredentials(email: string, password: string) {
  const normalizedEmail = email.trim().toLowerCase()
  return demoUsers.find((user) => user.email === normalizedEmail && user.password === password) ?? null
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