import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { toggleManagedUserStatus } from '@/lib/user-management'

export async function PATCH(
  _request: Request,
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
  const result = await toggleManagedUserStatus(userId)

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  return NextResponse.json({ ok: true, user: result.user })
}