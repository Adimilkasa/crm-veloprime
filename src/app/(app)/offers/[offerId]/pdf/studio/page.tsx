import Link from 'next/link'
import { notFound, redirect } from 'next/navigation'

import { OfferPdfA4Document } from '@/components/offers/OfferPdfA4Document'
import { PrintPdfButton } from '@/components/offers/PrintPdfButton'
import { getSession } from '@/lib/auth'
import { getOfferAssetBundle } from '@/lib/offer-assets'
import { getOfferDocumentSnapshot } from '@/lib/offer-management'

export default async function OfferPdfStudioPage({
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
  const document = await getOfferDocumentSnapshot(session, offerId, versionId)

  if (!document) {
    notFound()
  }

  const payload = document.payload
  const assets = await getOfferAssetBundle(payload.customer.modelName)

  return (
    <main className="min-h-screen bg-[linear-gradient(180deg,#f3efe6_0%,#ece7db_100%)] px-4 py-8 text-[#17191c]">
      <div className="mx-auto mb-5 flex max-w-[1400px] flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <Link href={`/offers/${offerId}/pdf${versionId ? `?versionId=${versionId}` : ''}`} className="inline-flex w-fit items-center rounded-2xl border border-[#d8cfbf] bg-white px-4 py-2.5 text-sm font-medium text-[#4d4d4d] transition hover:border-[rgba(201,161,59,0.26)] hover:text-[#1f1f1f]">
            Wróć do widoku PDF
          </Link>
          <Link href="/offers" className="inline-flex w-fit items-center rounded-2xl border border-[#d8cfbf] bg-white px-4 py-2.5 text-sm font-medium text-[#4d4d4d] transition hover:border-[rgba(201,161,59,0.26)] hover:text-[#1f1f1f]">
            Wróć do ofert
          </Link>
        </div>

        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <div className="rounded-[20px] border border-[#dccfaf] bg-[rgba(255,248,234,0.92)] px-4 py-3 text-sm leading-6 text-[#6b5a33]">
            Widok techniczny dokumentu pozwalający zweryfikować układ stron przed eksportem PDF.
          </div>
          <PrintPdfButton />
        </div>
      </div>

      <div className="mx-auto mb-5 grid max-w-[1400px] gap-3 lg:grid-cols-4">
        <div className="rounded-[20px] border border-[#d8cfbf] bg-white px-4 py-3 text-sm text-[#4d4d4d] shadow-[0_10px_24px_rgba(31,31,31,0.04)]">Strona 1: okładka oferty</div>
        <div className="rounded-[20px] border border-[#d8cfbf] bg-white px-4 py-3 text-sm text-[#4d4d4d] shadow-[0_10px_24px_rgba(31,31,31,0.04)]">Strona 2: podsumowanie i finansowanie</div>
        <div className="rounded-[20px] border border-[#d8cfbf] bg-white px-4 py-3 text-sm text-[#4d4d4d] shadow-[0_10px_24px_rgba(31,31,31,0.04)]">Strona 3: galeria modelu</div>
        <div className="rounded-[20px] border border-[#d8cfbf] bg-white px-4 py-3 text-sm text-[#4d4d4d] shadow-[0_10px_24px_rgba(31,31,31,0.04)]">Strona 4: rezerwa układu</div>
      </div>

      <div className="mx-auto max-w-[1400px] overflow-x-auto rounded-[30px] border border-[#d8cfbf] bg-[rgba(255,255,255,0.42)] p-5 shadow-[0_24px_70px_rgba(31,31,31,0.08)]">
        <OfferPdfA4Document payload={payload} assets={assets} studio />
      </div>
    </main>
  )
}
