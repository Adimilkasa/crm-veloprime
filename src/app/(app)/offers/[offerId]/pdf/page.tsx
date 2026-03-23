import Link from 'next/link'
import { notFound, redirect } from 'next/navigation'

import { PrintPdfButton } from '@/components/offers/PrintPdfButton'
import { getSession } from '@/lib/auth'
import { getOfferDocumentSnapshot } from '@/lib/offer-management'

function formatDate(value: string | null) {
  if (!value) {
    return 'Do ustalenia'
  }

  return new Intl.DateTimeFormat('pl-PL', { dateStyle: 'medium' }).format(new Date(value))
}

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
  const document = await getOfferDocumentSnapshot(session, offerId, versionId)

  if (!document) {
    notFound()
  }

  const payload = document.payload
  const financing = payload.internal.financing

  return (
    <main className="min-h-screen bg-[#ece7dc] px-4 py-8 text-[#17191c]">
      <div className="mx-auto mb-4 flex max-w-5xl items-center justify-between print:hidden">
        <Link href="/offers" className="rounded-full border border-[#d2c19d] bg-white px-4 py-2 text-sm font-medium text-[#252a31] transition hover:bg-[#f8f2e7]">
          Wróć do ofert
        </Link>
        <div className="flex items-center gap-3">
          <div className="text-sm text-[#5a6068]">Kliknij przycisk obok, aby pobrać PDF z przeglądarki.</div>
          <PrintPdfButton />
        </div>
      </div>

      <div className="mx-auto mb-4 max-w-5xl rounded-[24px] border border-[#dccfb5] bg-[#fff8ea] px-5 py-4 text-sm leading-6 text-[#6b5a33] print:hidden">
        Ten ekran jest gotowym dokumentem oferty. Aby pobrać plik PDF, kliknij "Drukuj / zapisz jako PDF" i wybierz zapis do PDF w systemowym oknie drukowania.
      </div>

      <section className="mx-auto max-w-5xl overflow-hidden rounded-[32px] bg-white shadow-[0_30px_80px_rgba(0,0,0,0.16)] print:rounded-none print:shadow-none">
        <div className="bg-[linear-gradient(135deg,#171d23,#242d36)] px-8 py-8 text-white">
          <div className="text-xs font-semibold uppercase tracking-[0.22em] text-[#d8bb79]">VeloPrime</div>
          <div className="mt-4 flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <h1 className="text-3xl font-semibold">{payload.customer.title}</h1>
              <div className="mt-2 text-sm text-[#ccd4dc]">Oferta nr {payload.customer.offerNumber}</div>
            </div>
            <div className="rounded-[24px] border border-white/10 bg-white/5 px-5 py-4 text-sm text-[#d7dee6]">
              <div>Wersja: {payload.versionNumber}</div>
              <div>Wygenerowano: {formatDate(payload.createdAt)}</div>
              <div>Wazna do: {formatDate(payload.customer.validUntil)}</div>
            </div>
          </div>
        </div>

        <div className="grid gap-8 px-8 py-8 lg:grid-cols-[1.2fr_0.8fr]">
          <div className="grid gap-8">
            <section>
              <div className="text-xs font-semibold uppercase tracking-[0.22em] text-[#9c7d31]">Klient</div>
              <div className="mt-4 grid gap-2 text-sm leading-7 text-[#37404a]">
                <div><span className="font-semibold text-[#171d23]">Nazwa:</span> {payload.customer.customerName}</div>
                <div><span className="font-semibold text-[#171d23]">E-mail:</span> {payload.customer.customerEmail ?? 'Do uzupelnienia'}</div>
                <div><span className="font-semibold text-[#171d23]">Telefon:</span> {payload.customer.customerPhone ?? 'Do uzupelnienia'}</div>
              </div>
            </section>

            <section>
              <div className="text-xs font-semibold uppercase tracking-[0.22em] text-[#9c7d31]">Konfiguracja</div>
              <div className="mt-4 rounded-[24px] border border-[#ece5d7] bg-[#faf7f0] p-5 text-sm leading-7 text-[#37404a]">
                <div><span className="font-semibold text-[#171d23]">Model:</span> {payload.customer.modelName ?? 'Do ustalenia'}</div>
                <div><span className="font-semibold text-[#171d23]">Kolor:</span> {payload.customer.selectedColorName ?? 'Bazowy'}</div>
                <div><span className="font-semibold text-[#171d23]">Finansowanie:</span> {payload.customer.financingSummary ?? payload.customer.financingVariant ?? 'Wariant gotowkowy / do ustalenia'}</div>
                {financing ? (
                  <>
                    <div><span className="font-semibold text-[#171d23]">Szacowana rata:</span> {new Intl.NumberFormat('pl-PL', { style: 'currency', currency: 'PLN', maximumFractionDigits: 2 }).format(financing.estimatedInstallment)}</div>
                    <div><span className="font-semibold text-[#171d23]">Wpłata własna:</span> {new Intl.NumberFormat('pl-PL', { style: 'currency', currency: 'PLN', maximumFractionDigits: 2 }).format(financing.downPaymentAmount)} ({financing.downPaymentPercent.toFixed(2).replace('.', ',')}%)</div>
                    <div><span className="font-semibold text-[#171d23]">Wykup:</span> {new Intl.NumberFormat('pl-PL', { style: 'currency', currency: 'PLN', maximumFractionDigits: 2 }).format(financing.buyoutAmount)} ({financing.buyoutPercent.toFixed(2).replace('.', ',')}%)</div>
                    <div><span className="font-semibold text-[#171d23]">Okres:</span> {financing.termMonths} mies.</div>
                  </>
                ) : null}
              </div>
            </section>

            <section>
              <div className="text-xs font-semibold uppercase tracking-[0.22em] text-[#9c7d31]">Uwagi</div>
              <div className="mt-4 rounded-[24px] border border-[#ece5d7] bg-[#faf7f0] p-5 text-sm leading-7 text-[#37404a]">
                {payload.customer.notes ?? 'Brak dodatkowych uwag do dokumentu.'}
              </div>
            </section>
          </div>

          <aside className="grid gap-3 self-start rounded-[28px] border border-[#ece5d7] bg-[#fffdfa] p-6">
            <div className="text-xs font-semibold uppercase tracking-[0.22em] text-[#9c7d31]">Podsumowanie ceny</div>
            <div className="flex items-center justify-between gap-4 text-sm text-[#37404a]">
              <span>Cena katalogowa</span>
              <span className="font-semibold text-[#171d23]">{payload.customer.listPriceLabel}</span>
            </div>
            <div className="flex items-center justify-between gap-4 text-sm text-[#37404a]">
              <span>Rabat</span>
              <span className="font-semibold text-[#171d23]">{payload.customer.discountLabel}</span>
            </div>
            <div className="flex items-center justify-between gap-4 text-sm text-[#37404a]">
              <span>Rabat %</span>
              <span className="font-semibold text-[#171d23]">{payload.customer.discountPercentLabel}</span>
            </div>
            <div className="border-t border-[#ece5d7] pt-3">
              <div className="flex items-center justify-between gap-4 text-base">
                <span className="font-semibold text-[#171d23]">Cena koncowa brutto</span>
                <span className="font-semibold text-[#171d23]">{payload.customer.finalGrossLabel}</span>
              </div>
              <div className="mt-2 flex items-center justify-between gap-4 text-sm text-[#5b646d]">
                <span>Cena koncowa netto</span>
                <span>{payload.customer.finalNetLabel}</span>
              </div>
            </div>

            {payload.customer.financingDisclaimer ? (
              <div className="rounded-[20px] border border-[#efe3c2] bg-[#fff7e7] px-4 py-3 text-sm leading-6 text-[#62522f]">
                {payload.customer.financingDisclaimer}
              </div>
            ) : null}
          </aside>
        </div>
      </section>
    </main>
  )
}