import { NextResponse } from 'next/server'

import { changeAuthUserPassword, getSession } from '@/lib/auth'

export async function POST(request: Request) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  let body: unknown

  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ ok: false, error: 'Niepoprawne dane wejściowe.' }, { status: 400 })
  }

  const payload = body as Record<string, unknown>
  const result = await changeAuthUserPassword({
    userId: session.sub,
    currentPassword: typeof payload.currentPassword === 'string' ? payload.currentPassword : '',
    newPassword: typeof payload.newPassword === 'string' ? payload.newPassword : '',
  })

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  return NextResponse.json({ ok: true })
}