import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { resetManagedUserPassword } from '@/lib/user-management'

export async function POST(
  request: Request,
  context: { params: Promise<{ userId: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  if (session.role !== 'ADMIN') {
    return NextResponse.json({ ok: false, error: 'Brak dostępu do administracji kontami.' }, { status: 403 })
  }

  const { userId } = await context.params

  let body: unknown = {}

  try {
    body = await request.json()
  } catch {
    body = {}
  }

  const payload = body as Record<string, unknown>
  const result = await resetManagedUserPassword(
    userId,
    typeof payload.newPassword === 'string' ? payload.newPassword : undefined,
  )

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  return NextResponse.json({ ok: true, temporaryPassword: result.temporaryPassword })
}