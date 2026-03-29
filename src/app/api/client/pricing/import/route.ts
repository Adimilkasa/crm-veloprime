import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { syncCommissionRules } from '@/lib/commission-management'
import { importPricingSheet } from '@/lib/pricing-management'

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
  const result = await importPricingSheet(session, typeof payload.sheetInput === 'string' ? payload.sheetInput : '')

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  await syncCommissionRules(session.fullName)

  return NextResponse.json({
    ok: true,
    sheet: result.sheet,
  })
}