import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'

export async function DELETE(
  _request: Request,
  _context: { params: Promise<{ stageId: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }
  void _request
  void _context
  void session

  return NextResponse.json(
    { ok: false, error: 'Etapy pipeline są sztywne i nie można ich usuwać.' },
    { status: 400 },
  )
}