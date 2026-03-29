import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'

export async function POST(_request: Request) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }
  void _request
  void session

  return NextResponse.json(
    { ok: false, error: 'Etapy pipeline są sztywne i nie można ich dodawać.' },
    { status: 400 },
  )
}