import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { getPublishedUpdateManifest } from '@/lib/update-management'

export async function GET() {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const manifest = await getPublishedUpdateManifest()

  return NextResponse.json({
    ok: true,
    manifest,
    session: {
      sub: session.sub,
      role: session.role,
      fullName: session.fullName,
    },
  })
}