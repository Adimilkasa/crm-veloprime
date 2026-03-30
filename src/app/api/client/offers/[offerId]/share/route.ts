import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { createManagedOfferShare } from '@/lib/offer-management'

export async function POST(
  request: Request,
  context: { params: Promise<{ offerId: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const { offerId } = await context.params
  let versionId: string | null = null

  try {
    const body = await request.json()
    versionId = typeof body?.versionId === 'string' ? body.versionId : null
  } catch {
    versionId = null
  }

  const result = await createManagedOfferShare(session, {
    offerId,
    versionId,
  })

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  const origin = new URL(request.url).origin

  return NextResponse.json({
    ok: true,
    share: {
      token: result.share.token,
      versionId: result.share.versionId,
      expiresAt: result.share.expiresAt,
      url: `${origin}/oferta/${result.share.token}`,
    },
  })
}