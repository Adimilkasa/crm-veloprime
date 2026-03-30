import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { sendManagedOfferEmail } from '@/lib/offer-management'

export async function POST(
  request: Request,
  context: { params: Promise<{ offerId: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const { offerId } = await context.params
  let body: unknown = null

  try {
    body = await request.json()
  } catch {
    body = null
  }

  const payload = (body ?? {}) as Record<string, unknown>
  const result = await sendManagedOfferEmail(
    session,
    {
      offerId,
      versionId: typeof payload.versionId === 'string' ? payload.versionId : null,
      toEmail: typeof payload.toEmail === 'string' ? payload.toEmail : null,
    },
    new URL(request.url).origin,
  )

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  return NextResponse.json({
    ok: true,
    email: result.email,
  })
}