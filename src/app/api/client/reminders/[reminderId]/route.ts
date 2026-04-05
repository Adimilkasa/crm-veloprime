import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { completeManagedReminder } from '@/lib/reminder-management'

export async function PATCH(
  _request: Request,
  context: { params: Promise<{ reminderId: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const { reminderId } = await context.params
  const result = await completeManagedReminder(session, reminderId)

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  return NextResponse.json({ ok: true, reminder: result.reminder })
}