import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { syncCommissionRules } from '@/lib/commission-management'
import { clearPricingSheet, getPricingSheet, savePricingSheet } from '@/lib/pricing-management'

export async function GET() {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const result = await getPricingSheet(session)

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 403 })
  }

  return NextResponse.json({
    ok: true,
    sheet: result.sheet,
  })
}

export async function PATCH(request: Request) {
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
  const headers = Array.isArray(payload.headers) ? payload.headers.map((value) => String(value ?? '')) : []
  const rows = Array.isArray(payload.rows)
    ? payload.rows.map((row) => Array.isArray(row) ? row.map((value) => String(value ?? '')) : [])
    : []

  const result = await savePricingSheet(session, { headers, rows })

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  await syncCommissionRules(session.fullName)

  return NextResponse.json({
    ok: true,
    sheet: result.sheet,
  })
}

export async function DELETE() {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const result = await clearPricingSheet(session)

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  await syncCommissionRules(session.fullName)

  return NextResponse.json({
    ok: true,
    sheet: {
      headers: [],
      rows: [],
      updatedAt: new Date().toISOString(),
      updatedBy: session.fullName,
    },
  })
}