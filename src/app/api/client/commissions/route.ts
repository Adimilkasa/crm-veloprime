import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { getCommissionWorkspace, saveCommissionRules } from '@/lib/commission-management'

export async function GET(request: Request) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const { searchParams } = new URL(request.url)
  const result = await getCommissionWorkspace(session, searchParams.get('userId'))

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 403 })
  }

  return NextResponse.json({
    ok: true,
    workspace: result,
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
  const targetUserId = typeof payload.targetUserId === 'string' ? payload.targetUserId : ''
  const rules = Array.isArray(payload.rules)
    ? payload.rules.map((entry) => {
        const rule = entry as Record<string, unknown>
        const rawValue = rule.value
        return {
          id: typeof rule.id === 'string' ? rule.id : '',
          valueType: rule.valueType === 'PERCENT' ? 'PERCENT' as const : 'AMOUNT' as const,
          value: typeof rawValue === 'number' ? rawValue : rawValue === null ? null : Number.isFinite(Number(rawValue)) ? Number(rawValue) : null,
        }
      })
    : []

  const saveResult = await saveCommissionRules(session, {
    targetUserId,
    rules,
  })

  if (!saveResult.ok) {
    return NextResponse.json({ ok: false, error: saveResult.error }, { status: 400 })
  }

  const workspaceResult = await getCommissionWorkspace(session, targetUserId)

  if (!workspaceResult.ok) {
    return NextResponse.json({ ok: false, error: workspaceResult.error }, { status: 400 })
  }

  return NextResponse.json({
    ok: true,
    workspace: workspaceResult,
  })
}