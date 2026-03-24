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
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,rgba(201,161,59,0.12),transparent_28%),linear-gradient(180deg,#fafaf9_0%,#f5f1e8_100%)] px-4 py-8 text-[#17191c] print:bg-white print:px-0 print:py-0">
      <div className="mx-auto mb-4 flex max-w-5xl flex-col gap-3 sm:flex-row sm:items-center sm:justify-between print:hidden">
        <Link href="/offers" className="inline-flex w-fit items-center rounded-2xl border border-[#e5dfd1] bg-white px-4 py-2.5 text-sm font-medium text-[#4d4d4d] shadow-[0_10px_24px_rgba(31,31,31,0.04)] transition hover:border-[rgba(201,161,59,0.26)] hover:text-[#1f1f1f]">
          Wróć do ofert
        </Link>
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <div className="text-sm text-[#6b6b6b]">Kliknij przycisk obok, aby pobrać PDF z przeglądarki.</div>
          <PrintPdfButton />
        </div>
      </div>

      <div className="mx-auto mb-4 max-w-5xl rounded-[24px] border border-[#ece2c8] bg-[#fff8ea] px-5 py-4 text-sm leading-6 text-[#6b5a33] shadow-[0_12px_30px_rgba(31,31,31,0.03)] print:hidden">
        Ten ekran jest gotowym dokumentem oferty. Aby pobrać plik PDF, kliknij "Drukuj / zapisz jako PDF" i wybierz zapis do PDF w systemowym oknie drukowania.
      </div>

      <section className="mx-auto max-w-5xl overflow-hidden rounded-[32px] border border-[#e8e2d3] bg-white shadow-[0_24px_70px_rgba(31,31,31,0.06)] print:max-w-none print:rounded-none print:border-0 print:shadow-none">
        <div className="border-b border-[#ebe5d8] bg-[linear-gradient(135deg,#ffffff_0%,#fbf8f1_52%,#f7f3e8_100%)] px-8 py-8 text-[#1f1f1f] print:bg-white">
          <div className="text-xs font-semibold uppercase tracking-[0.22em] text-[#9d7b27]">VeloPrime</div>
          <div className="mt-4 flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <h1 className="text-3xl font-semibold">{payload.customer.title}</h1>
              <div className="mt-2 text-sm text-[#6b6b6b]">Oferta nr {payload.customer.offerNumber}</div>
            </div>
            <div className="rounded-[24px] border border-[#ece6d9] bg-white/90 px-5 py-4 text-sm text-[#5f5a4f] shadow-[0_12px_28px_rgba(31,31,31,0.04)] print:shadow-none">
              <div>Wersja: {payload.versionNumber}</div>
              <div>Wygenerowano: {formatDate(payload.createdAt)}</div>
              <div>Wazna do: {formatDate(payload.customer.validUntil)}</div>
            </div>
          </div>
        </div>

        <div className="grid gap-8 px-8 py-8 lg:grid-cols-[1.2fr_0.8fr]">
          <div className="grid gap-8">
            <section>
              <div className="text-xs font-semibold uppercase tracking-[0.22em] text-[#9d7b27]">Klient</div>
              <div className="mt-4 grid gap-2 text-sm leading-7 text-[#37404a]">
                <div><span className="font-semibold text-[#171d23]">Nazwa:</span> {payload.customer.customerName}</div>
                <div><span className="font-semibold text-[#171d23]">E-mail:</span> {payload.customer.customerEmail ?? 'Do uzupelnienia'}</div>
                <div><span className="font-semibold text-[#171d23]">Telefon:</span> {payload.customer.customerPhone ?? 'Do uzupelnienia'}</div>
              </div>
            </section>

            <section>
              <div className="text-xs font-semibold uppercase tracking-[0.22em] text-[#9d7b27]">Konfiguracja</div>
              <div className="mt-4 rounded-[24px] border border-[#ece5d7] bg-[#fcfbf8] p-5 text-sm leading-7 text-[#37404a]">
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
              <div className="text-xs font-semibold uppercase tracking-[0.22em] text-[#9d7b27]">Uwagi</div>
              <div className="mt-4 rounded-[24px] border border-[#ece5d7] bg-[#fcfbf8] p-5 text-sm leading-7 text-[#37404a]">
                {payload.customer.notes ?? 'Brak dodatkowych uwag do dokumentu.'}
              </div>
            </section>
          </div>

          <aside className="grid gap-3 self-start rounded-[28px] border border-[#ece5d7] bg-[linear-gradient(180deg,#ffffff_0%,#fcfbf8_100%)] p-6 shadow-[0_14px_30px_rgba(31,31,31,0.04)] print:shadow-none">
            <div className="text-xs font-semibold uppercase tracking-[0.22em] text-[#9d7b27]">Podsumowanie ceny</div>
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