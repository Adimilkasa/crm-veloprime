import { NextResponse } from 'next/server'

import { getSession, type AuthSession } from '@/lib/auth'

export async function requireAdminApiSession() {
  const session = await getSession()

  if (!session) {
    return {
      ok: false as const,
      response: NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 }),
    }
  }

  if (session.role !== 'ADMIN') {
    return {
      ok: false as const,
      response: NextResponse.json({ ok: false, error: 'Brak dostępu do administracji katalogiem.' }, { status: 403 }),
    }
  }

  return {
    ok: true as const,
    session,
  }
}

export async function readJsonRecord(request: Request) {
  let body: unknown

  try {
    body = await request.json()
  } catch {
    return {
      ok: false as const,
      response: NextResponse.json({ ok: false, error: 'Niepoprawne dane wejściowe.' }, { status: 400 }),
    }
  }

  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return {
      ok: false as const,
      response: NextResponse.json({ ok: false, error: 'Niepoprawne dane wejściowe.' }, { status: 400 }),
    }
  }

  return {
    ok: true as const,
    body: body as Record<string, unknown>,
  }
}

export function jsonFromServiceResult<T>(result: { ok: true; data: T } | { ok: false; error: string; status: number }, successBody: (data: T) => Record<string, unknown>, successStatus = 200) {
  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: result.status })
  }

  return NextResponse.json({ ok: true, ...successBody(result.data) }, { status: successStatus })
}

export type AdminApiSession = AuthSession