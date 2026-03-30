import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import type { UserRoleKey } from '@/lib/rbac'
import { listManagedUsers, createManagedUser } from '@/lib/user-management'

function isAdmin(role: string) {
  return role === 'ADMIN'
}

export async function GET() {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  if (!isAdmin(session.role)) {
    return NextResponse.json({ ok: false, error: 'Brak dostępu do administracji kontami.' }, { status: 403 })
  }

  const users = await listManagedUsers()
  const supervisorOptions = users.filter((user) => user.isActive && (user.role === 'DIRECTOR' || user.role === 'MANAGER'))

  return NextResponse.json({ ok: true, users, supervisorOptions })
}

export async function POST(request: Request) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  if (!isAdmin(session.role)) {
    return NextResponse.json({ ok: false, error: 'Brak dostępu do administracji kontami.' }, { status: 403 })
  }

  let body: unknown

  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ ok: false, error: 'Niepoprawne dane wejściowe.' }, { status: 400 })
  }

  const payload = body as Record<string, unknown>
  const result = await createManagedUser({
    fullName: typeof payload.fullName === 'string' ? payload.fullName : '',
    email: typeof payload.email === 'string' ? payload.email : '',
    phone: typeof payload.phone === 'string' ? payload.phone : '',
    role: (typeof payload.role === 'string' ? payload.role : 'SALES') as UserRoleKey,
    password: typeof payload.password === 'string' ? payload.password : '',
    region: typeof payload.region === 'string' ? payload.region : '',
    teamName: typeof payload.teamName === 'string' ? payload.teamName : '',
    reportsToUserId: typeof payload.reportsToUserId === 'string' ? payload.reportsToUserId : '',
  })

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  return NextResponse.json({
    ok: true,
    user: result.user,
    temporaryPassword: result.temporaryPassword ?? null,
  })
}