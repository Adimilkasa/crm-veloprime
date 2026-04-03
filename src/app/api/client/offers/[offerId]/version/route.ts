import { NextResponse } from 'next/server'

import { getSession } from '@/lib/auth'
import { createManagedOfferVersion } from '@/lib/offer-management'

export async function POST(
  _request: Request,
  context: { params: Promise<{ offerId: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const { offerId } = await context.params
  const result = await createManagedOfferVersion(session, offerId)

  if (!result.ok) {
    return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
  }

  return NextResponse.json({
    ok: true,
    version: {
      id: result.version.id,
      versionNumber: result.version.versionNumber,
      summary: result.version.summary,
      createdAt: result.version.createdAt,
    },
  })
}