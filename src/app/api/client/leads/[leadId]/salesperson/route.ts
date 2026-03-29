import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'

export async function PATCH(
  _request: Request,
  _context: { params: Promise<{ leadId: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }
  void _request
  void _context
  void session

  return NextResponse.json(
    { ok: false, error: 'Zmiana opiekuna po utworzeniu leada jest zablokowana.' },
    { status: 400 },
  )
}