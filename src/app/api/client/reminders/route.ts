import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { createManagedReminder, listManagedReminders } from '@/lib/reminder-management'

export async function GET() {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const reminders = await listManagedReminders(session)
  return NextResponse.json({ ok: true, reminders })
}

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
  const result = await createManagedReminder(session, {
    title: typeof payload.title === 'string' ? payload.title : '',
    note: typeof payload.note === 'string' ? payload.note : '',
    remindAt: typeof payload.remindAt === 'string' ? payload.remindAt : '',
    leadId: typeof payload.leadId === 'string' ? payload.leadId : '',
  })

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  return NextResponse.json({ ok: true, reminder: result.reminder }, { status: 201 })
}