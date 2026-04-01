import Link from 'next/link'
import { headers } from 'next/headers'
import { notFound, redirect } from 'next/navigation'

import { OfferPdfA4Document } from '@/components/offers/OfferPdfA4Document'
import { PrintPdfButton } from '@/components/offers/PrintPdfButton'
import { getSession } from '@/lib/auth'
import { getOfferAssetBundle } from '@/lib/offer-assets'
import { createManagedOfferShare, getOfferDocumentSnapshot } from '@/lib/offer-management'

export default async function OfferPdfPage({
  params,
  searchParams,
}: {
  params: Promise<{ offerId: string }>
  searchParams: Promise<{ versionId?: string }>
}) {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  const { offerId } = await params
  const { versionId } = await searchParams
  const requestHeaders = await headers()
  const document = await getOfferDocumentSnapshot(session, offerId, versionId)

  if (!document) {
    notFound()
  }

  const payload = document.payload
  const assets = await getOfferAssetBundle({
    modelName: payload.customer.modelName,
    catalogKey: payload.internal.catalogKey,
    powertrainType: payload.internal.powertrainType,
  })
  const host = requestHeaders.get('x-forwarded-host') ?? requestHeaders.get('host') ?? process.env.VERCEL_PROJECT_PRODUCTION_URL ?? process.env.VERCEL_URL ?? 'localhost:3000'
  const protocol = requestHeaders.get('x-forwarded-proto') ?? (host.startsWith('localhost') ? 'http' : 'https')
  const origin = `${protocol}://${host}`
  const shareResult = await createManagedOfferShare(session, {
    offerId,
    versionId: document.version?.id ?? versionId ?? null,
  })
  const publicOfferUrl = shareResult.ok ? `${origin}/oferta/${shareResult.share.token}` : null
  const publicOfferExpiresAt = shareResult.ok ? shareResult.share.expiresAt : null

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,rgba(201,161,59,0.14),transparent_28%),linear-gradient(180deg,#fafaf9_0%,#f5f1e8_100%)] px-4 py-8 text-[#17191c] print:bg-white print:px-0 print:py-0">
      <div className="mx-auto mb-4 flex max-w-5xl flex-col gap-3 sm:flex-row sm:items-center sm:justify-between print:hidden">
        <Link href="/offers" className="inline-flex w-fit items-center rounded-2xl border border-[#e5dfd1] bg-white px-4 py-2.5 text-sm font-medium text-[#4d4d4d] shadow-[0_10px_24px_rgba(31,31,31,0.04)] transition hover:border-[rgba(201,161,59,0.26)] hover:text-[#1f1f1f]">
          Wróć do ofert
        </Link>
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <div className="text-sm text-[#6b6b6b]">PDF jest skróconym eksportem tej wersji. Główny widok dla klienta pozostaje aktywny online.</div>
          {publicOfferUrl ? (
            <a
              href={publicOfferUrl}
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center rounded-2xl border border-[#dbe4ef] bg-[#f8fbff] px-4 py-2.5 text-sm font-medium text-[#23477f] transition hover:border-[rgba(35,71,127,0.26)] hover:text-[#172f56]"
            >
              Otwórz ofertę online
            </a>
          ) : null}
          {assets.specPdfUrl ? (
            <a
              href={assets.specPdfUrl}
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center rounded-2xl border border-[#e5dfd1] bg-white px-4 py-2.5 text-sm font-medium text-[#4d4d4d] transition hover:border-[rgba(201,161,59,0.26)] hover:text-[#1f1f1f]"
            >
              Otwórz specyfikację
            </a>
          ) : null}
          <PrintPdfButton />
        </div>
      </div>

      <div className="mx-auto flex max-w-full justify-center overflow-x-auto pb-2 print:block print:overflow-visible">
        <OfferPdfA4Document
          payload={payload}
          assets={assets}
          publicOfferUrl={publicOfferUrl}
          publicOfferExpiresAt={publicOfferExpiresAt}
        />
      </div>
    </main>
  )
}