import { NextResponse } from 'next/server'

import { getAuthUserProfile, getSession } from '@/lib/auth'

export async function GET() {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const profile = await getAuthUserProfile(session.sub)

  if (!profile) {
    return NextResponse.json({ ok: false, error: 'Nie znaleziono profilu użytkownika.' }, { status: 404 })
  }

  return NextResponse.json({ ok: true, profile })
}