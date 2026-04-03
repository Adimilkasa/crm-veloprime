import type { ReactNode } from 'react'

import { notFound } from 'next/navigation'

import { PublicOfferGallery, type PublicOfferGallerySection } from '@/components/offers/PublicOfferGallery'
import { getPublicOfferDocumentSnapshot } from '@/lib/offer-management'

function parseCatalogKey(catalogKey: string | null | undefined) {
  if (!catalogKey) {
    return null
  }

  const [brand, model, version, year] = catalogKey.split('::')

  if (!brand || !model || !version) {
    return null
  }

  return {
    brand,
    model,
    version,
    year: year?.trim() || null,
  }
}

function formatDate(value: string | null) {
  if (!value) {
    return 'Nie określono'
  }

  return new Intl.DateTimeFormat('pl-PL', { dateStyle: 'medium' }).format(new Date(value))
}

function formatMoney(value: number | null | undefined) {
  if (value === null || value === undefined || Number.isNaN(value)) {
    return 'Do ustalenia z opiekunem'
  }

  return new Intl.NumberFormat('pl-PL', {
    style: 'currency',
    currency: 'PLN',
    maximumFractionDigits: 2,
  }).format(value)
}

function buildContactLine(email: string | null | undefined, phone: string | null | undefined) {
  return [email, phone].filter(Boolean).join(' • ') || 'Skontaktuj się z opiekunem VeloPrime.'
}

function buildModelLabel(modelName: string | null | undefined, fallback: string) {
  return modelName?.trim() || fallback
}

function isCompanyCustomer(customerType: string | null | undefined) {
  const normalized = customerType?.trim().toLowerCase() ?? ''
  return normalized.includes('firm') || normalized === 'b2b' || normalized === 'company'
}

function normalizeCommercialValue(value: string | null | undefined) {
  const normalized = value?.trim()

  if (!normalized || /do potwierdzenia|do ustalenia/i.test(normalized)) {
    return 'Do ustalenia z opiekunem'
  }

  return normalized
}

function formatPowertrainType(powertrainType: string | null | undefined) {
  const normalized = powertrainType?.trim().toLowerCase() ?? ''

  if (normalized.includes('electric') || normalized.includes('ev') || normalized.includes('elek')) {
    return 'Elektryczny'
  }

  if (normalized.includes('hybrid') || normalized.includes('phev') || normalized.includes('hev') || normalized.includes('hyb')) {
    return 'Hybrydowy'
  }

  if (normalized.includes('petrol') || normalized.includes('diesel') || normalized.includes('fuel') || normalized.includes('spalin')) {
    return 'Spalinowy'
  }

  return 'Do potwierdzenia'
}

function buildHeroNarrative(modelName: string, selectedColorName: string | null) {
  const selectedColor = selectedColorName?.trim()

  if (selectedColor) {
    return `${modelName} w kolorze ${selectedColor}. Oferta została przygotowana jako czytelna, spokojna prezentacja konfiguracji i warunków zakupu.`
  }

  return `${modelName}. Oferta została przygotowana jako czytelna, spokojna prezentacja konfiguracji i warunków zakupu.`
}

function buildGallerySections(images: {
  premium: string[]
  exterior: string[]
  interior: string[]
  details: string[]
  other: string[]
}): PublicOfferGallerySection[] {
  const sections = [
    {
      title: 'Zewnętrze',
      images: [...images.premium, ...images.exterior, ...images.other],
    },
    {
      title: 'Wnętrze',
      images: images.interior,
    },
    {
      title: 'Detale',
      images: images.details,
    },
  ]

  return sections
    .map((section) => ({
      ...section,
      images: section.images.filter((image, index, all) => all.indexOf(image) === index),
    }))
    .filter((section) => section.images.length > 0)
}

function Panel({
  children,
  variant = 'default',
  className = '',
  id,
}: {
  children: ReactNode
  variant?: 'default' | 'highlight' | 'accent'
  className?: string
  id?: string
}) {
  const variants = {
    default: 'bg-white/72 shadow-[0_20px_60px_rgba(15,23,42,0.08)] ring-1 ring-white/50 backdrop-blur-xl',
    highlight: 'bg-white/78 shadow-[0_20px_60px_rgba(15,23,42,0.1)] ring-1 ring-white/60 backdrop-blur-xl',
    accent: 'bg-[linear-gradient(135deg,rgba(190,147,62,0.96),rgba(212,168,79,0.92))] text-white shadow-[0_24px_64px_rgba(190,147,62,0.26)]',
  }

  return (
    <section id={id} className={`rounded-[36px] px-6 py-7 sm:px-8 sm:py-8 lg:px-10 lg:py-10 ${variants[variant]} ${className}`.trim()}>
      {children}
    </section>
  )
}

function SectionHeader({ title, description }: { title: string; description: string }) {
  return (
    <div className="max-w-3xl">
      <p className="text-[12px] font-semibold uppercase tracking-[0.22em] text-[#6e6e73]">Premium offer</p>
      <h2 className="mt-4 text-[32px] font-semibold leading-[1.02] tracking-[-0.04em] text-[#1d1d1f] sm:text-[40px] lg:text-[46px]">{title}</h2>
      <p className="mt-4 text-[16px] leading-8 text-[#4e4e56]">{description}</p>
    </div>
  )
}

function SpecTile({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-[24px] bg-white/68 px-5 py-4 shadow-[0_10px_28px_rgba(15,23,42,0.05)] ring-1 ring-white/70 backdrop-blur-sm">
      <div className="text-[13px] font-medium text-[#6e6e73]">{label}</div>
      <div className="mt-2 text-[18px] font-semibold leading-tight text-[#1d1d1f]">{value}</div>
    </div>
  )
}

function FinanceRow({ label, value, emphasize = false }: { label: string; value: string; emphasize?: boolean }) {
  return (
    <div className="flex items-start justify-between gap-4 border-b border-[#d9d9de] py-4 last:border-b-0 last:pb-0 first:pt-0">
      <div className="text-[14px] leading-7 text-[#6e6e73]">{label}</div>
      <div className={`text-right text-[16px] font-semibold leading-7 ${emphasize ? 'text-[#1d1d1f]' : 'text-[#3a3a40]'}`}>{value}</div>
    </div>
  )
}

export default async function PublicOfferPage({
  params,
}: {
  params: Promise<{ token: string }>
}) {
  const { token } = await params
  const document = await getPublicOfferDocumentSnapshot(token)

  if (!document.ok && document.status === 'not-found') {
    notFound()
  }

  if (!document.ok) {
    const expiredAdvisorName = document.advisorName ?? 'Opiekun VeloPrime'
    const expiredAdvisorContact = buildContactLine(document.advisorEmail, document.advisorPhone)

    return (
      <main className="min-h-screen bg-transparent px-4 py-12 text-[#1d1d1f] sm:px-6 lg:px-8">
        <div className="mx-auto max-w-3xl">
          <Panel>
            <h1 className="text-[42px] font-semibold tracking-[-0.04em]">Oferta wygasła</h1>
            <p className="mt-4 text-[16px] leading-8 text-[#4e4e56]">Ten link nie jest już aktywny. W sprawie aktualnej oferty skontaktuj się z osobą odpowiedzialną za klienta.</p>
            <div className="mt-8 rounded-[28px] bg-white/70 p-6 ring-1 ring-white/70">
              <div className="text-[13px] font-medium uppercase tracking-[0.16em] text-[#6e6e73]">Kontakt</div>
              <div className="mt-3 text-[24px] font-semibold text-[#1d1d1f]">{expiredAdvisorName}</div>
              <div className="mt-3 text-[15px] leading-7 text-[#4e4e56]">{expiredAdvisorContact}</div>
            </div>
          </Panel>
        </div>
      </main>
    )
  }

  const payload = document.payload
  const assets = document.assets
  const gallerySections = buildGallerySections(assets.images)
  const heroImage = gallerySections[0]?.images[0] ?? assets.images.premium[0] ?? assets.images.exterior[0] ?? assets.images.other[0] ?? null
  const modelLabel = buildModelLabel(payload.customer.modelName, document.title)
  const parsedCatalogKey = parseCatalogKey(payload.internal.catalogKey)
  const pricingDisplayMode = isCompanyCustomer(payload.internal.customerType) ? 'netto' : 'brutto'
  const effectivePriceLabel = pricingDisplayMode === 'netto' ? payload.customer.finalNetLabel : payload.customer.finalGrossLabel
  const effectivePriceTitle = pricingDisplayMode === 'netto' ? 'Cena końcowa netto' : 'Cena końcowa brutto'
  const advisorName = payload.advisor.fullName || payload.internal.ownerName || 'Opiekun VeloPrime'
  const advisorContactLine = buildContactLine(payload.advisor.email, payload.advisor.phone)
  const validUntilLabel = formatDate(payload.customer.validUntil ?? document.shareExpiresAt)
  const heroNarrative = buildHeroNarrative(modelLabel, payload.customer.selectedColorName)
  const formalNotice = payload.customer.financingDisclaimer ?? 'Prezentowane warunki mają charakter orientacyjny i wymagają końcowego potwierdzenia po weryfikacji finansowej.'
  const financingSummary = payload.internal.financing
  const estimatedInstallmentLabel = financingSummary?.estimatedInstallment ? formatMoney(financingSummary.estimatedInstallment) : null
  const priceFallbackText = normalizeCommercialValue(effectivePriceLabel)
  const heroPrimaryValue = estimatedInstallmentLabel ? `${estimatedInstallmentLabel} / mies.` : priceFallbackText
  const heroPrimaryLabel = estimatedInstallmentLabel ? 'Szacowana rata miesięczna' : effectivePriceTitle
  const powertrainLabel = formatPowertrainType(payload.internal.powertrainType)
  const technicalTiles = [
    ...(parsedCatalogKey?.brand ? [{ label: 'Marka', value: parsedCatalogKey.brand }] : []),
    { label: 'Model', value: modelLabel },
    ...(parsedCatalogKey?.version ? [{ label: 'Wersja', value: parsedCatalogKey.version }] : []),
    { label: 'Napęd', value: powertrainLabel },
    ...(payload.internal.driveType?.trim() ? [{ label: 'Napęd osi', value: payload.internal.driveType.trim() }] : []),
    { label: 'Kolor', value: payload.customer.selectedColorName ?? 'Bazowy' },
    ...(payload.internal.year ? [{ label: 'Rocznik', value: String(payload.internal.year) }] : []),
    ...(payload.internal.powerHp?.trim() ? [{ label: 'Moc', value: payload.internal.powerHp.trim() }] : []),
    ...(payload.internal.systemPowerHp?.trim() ? [{ label: 'Moc układu', value: payload.internal.systemPowerHp.trim() }] : []),
    ...(payload.internal.batteryCapacityKwh?.trim() ? [{ label: 'Pojemność baterii', value: payload.internal.batteryCapacityKwh.trim() }] : []),
    ...(payload.internal.rangeKm?.trim() ? [{ label: 'Zasięg', value: payload.internal.rangeKm.trim() }] : []),
    ...(payload.internal.combustionEnginePowerHp?.trim() ? [{ label: 'Moc silnika spalinowego', value: payload.internal.combustionEnginePowerHp.trim() }] : []),
    ...(payload.internal.engineDisplacementCc?.trim() ? [{ label: 'Pojemność silnika', value: payload.internal.engineDisplacementCc.trim() }] : []),
    ...(payload.internal.baseColorName?.trim() ? [{ label: 'Kolor bazowy', value: payload.internal.baseColorName.trim() }] : []),
  ].filter((item, index, all) => all.findIndex((candidate) => candidate.label === item.label && candidate.value === item.value) === index)
  const customerData = [payload.customer.customerName, payload.customer.customerEmail, payload.customer.customerPhone].filter(Boolean)
  const primaryCtaHref = payload.advisor.email
    ? `mailto:${payload.advisor.email}`
    : payload.advisor.phone
      ? `tel:${payload.advisor.phone.replace(/\s+/g, '')}`
      : null
  const phoneCtaHref = payload.advisor.phone ? `tel:${payload.advisor.phone.replace(/\s+/g, '')}` : null
  const primaryFinalPrice = pricingDisplayMode === 'netto' ? payload.customer.finalNetLabel : payload.customer.finalGrossLabel
  const secondaryFinalPrice = pricingDisplayMode === 'netto' ? payload.customer.finalGrossLabel : payload.customer.finalNetLabel
  const primaryFinalPriceLabel = pricingDisplayMode === 'netto' ? 'Cena końcowa netto' : 'Cena końcowa brutto'
  const secondaryFinalPriceLabel = pricingDisplayMode === 'netto' ? 'Cena końcowa brutto' : 'Cena końcowa netto'
  const financeRows = [
    { label: 'Cena auta', value: payload.customer.listPriceLabel },
    { label: 'Rabat', value: `${payload.customer.discountLabel} (${payload.customer.discountPercentLabel})` },
    { label: 'Cena końcowa', value: priceFallbackText, emphasize: true },
    { label: 'Wpłata własna', value: financingSummary?.downPaymentAmount ? formatMoney(financingSummary.downPaymentAmount) : 'Do ustalenia' },
    { label: 'Okres', value: financingSummary?.termMonths ? `${financingSummary.termMonths} mies.` : 'Do ustalenia' },
    { label: 'Wykup', value: financingSummary?.buyoutPercent ? `${financingSummary.buyoutPercent}%` : 'Do ustalenia' },
  ]

  return (
    <main className="min-h-screen bg-transparent text-[#1d1d1f]">
      <section className="relative left-1/2 right-1/2 w-screen -translate-x-1/2 overflow-hidden">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_top,rgba(255,255,255,0.14),transparent_48%)]" />
        {heroImage ? (
          // eslint-disable-next-line @next/next/no-img-element -- direct product assets are required in the public offer hero
          <img src={heroImage} alt={modelLabel} className="absolute inset-0 h-full w-full object-cover" />
        ) : (
          <div className="absolute inset-0 bg-[linear-gradient(135deg,#c7d2e3_0%,#8b9bb4_100%)]" />
        )}
        <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(10,16,24,0.28)_0%,rgba(10,16,24,0.18)_24%,rgba(10,16,24,0.52)_78%,rgba(245,245,247,1)_100%)]" />
        <div className="absolute inset-0 bg-[linear-gradient(90deg,rgba(10,16,24,0.72)_0%,rgba(10,16,24,0.44)_34%,rgba(10,16,24,0.12)_68%,rgba(10,16,24,0.04)_100%)]" />

        <div className="relative z-10 mx-auto flex min-h-[92svh] max-w-7xl items-end px-4 pb-16 pt-28 sm:px-6 lg:px-8 lg:pb-24">
          <div className="max-w-3xl">
            <div className="inline-flex rounded-full bg-white/12 px-4 py-2 text-[12px] font-semibold uppercase tracking-[0.22em] text-white backdrop-blur-md ring-1 ring-white/18">
              Oferta przygotowana dla {payload.customer.customerName}
            </div>
            <h1 className="mt-6 text-[52px] font-semibold leading-[0.92] tracking-[-0.06em] text-white sm:text-[72px] lg:text-[104px]">{modelLabel}</h1>
            <p className="mt-6 max-w-2xl text-[18px] leading-8 text-white/82 sm:text-[19px]">{heroNarrative}</p>
            <p className="mt-4 max-w-xl text-[15px] leading-7 text-white/72">To produkcyjna wersja oferty przygotowana dla klienta, z prezentacją modelu, konfiguracji, specyfikacji i warunków finansowych.</p>

            <div className="mt-10">
              <div className="text-[13px] font-semibold uppercase tracking-[0.18em] text-white/68">{heroPrimaryLabel}</div>
              <div className="mt-3 text-[42px] font-semibold leading-[0.98] tracking-[-0.05em] text-white sm:text-[56px] lg:text-[72px]">{heroPrimaryValue}</div>
            </div>

            <div className="mt-10 rounded-[26px] bg-white/10 px-5 py-4 backdrop-blur-md ring-1 ring-white/18 sm:px-6">
              <div className="text-[12px] font-semibold uppercase tracking-[0.18em] text-white/64">Dane klienta</div>
              <div className="mt-3 flex flex-wrap gap-x-5 gap-y-2 text-[14px] leading-7 text-white/82">
                {customerData.map((item) => (
                  <span key={item}>{item}</span>
                ))}
              </div>
            </div>

            <div className="mt-8 flex flex-wrap gap-x-6 gap-y-2 text-[14px] leading-7 text-white/72">
              <span>Opiekun: {advisorName}</span>
              <span>Ważna do: {validUntilLabel}</span>
              <span>{advisorContactLine}</span>
            </div>
          </div>
        </div>
      </section>

      <div className="relative z-10 mx-auto -mt-10 max-w-7xl px-4 pb-24 sm:px-6 lg:px-8">
        <div className="space-y-8 sm:space-y-10 lg:space-y-12">
          <Panel>
            <div className="grid gap-8 lg:grid-cols-[0.9fr_1.1fr] lg:items-start">
              <SectionHeader
                title="Najważniejsze dane"
                description="Zestaw najważniejszych informacji o konfiguracji, generowany z danych dostępnych dla tej polityki cenowej i publicznego snapshotu oferty."
              />

              <div className="grid gap-4 [grid-template-columns:repeat(auto-fit,minmax(180px,1fr))]">
                  {technicalTiles.map((item) => (
                    <SpecTile key={item.label} label={item.label} value={item.value} />
                  ))}
              </div>
            </div>
          </Panel>

          <Panel>
            <div className="flex items-center justify-between gap-4">
              <h2 className="text-[28px] font-semibold leading-[1.02] tracking-[-0.04em] text-[#1d1d1f] sm:text-[34px]">Galeria</h2>
            </div>
            <div className="mt-6">
              <PublicOfferGallery modelLabel={modelLabel} sections={gallerySections} />
            </div>
          </Panel>

          <Panel id="specyfikacja-pojazdu" className="scroll-mt-24 overflow-hidden">
            <div className="relative rounded-[28px] bg-[#f2ede2]">
              {heroImage ? (
                // eslint-disable-next-line @next/next/no-img-element -- direct product assets are required in the public offer specification block
                <img src={heroImage} alt={modelLabel} className="absolute inset-0 h-full w-full object-cover opacity-28" />
              ) : null}
              <div className="absolute inset-0 bg-[linear-gradient(90deg,rgba(255,255,255,0.92)_0%,rgba(255,255,255,0.84)_48%,rgba(255,255,255,0.76)_100%)]" />
              <div className="relative grid gap-5 px-6 py-6 sm:px-7 lg:grid-cols-[1.05fr_0.95fr] lg:items-center">
                <div>
                  <div className="text-[12px] font-semibold uppercase tracking-[0.18em] text-[#6e6e73]">Specyfikacja pojazdu</div>
                  <h2 className="mt-3 text-[28px] font-semibold leading-[1.04] tracking-[-0.04em] text-[#1d1d1f]">PDF z kartą modelu i wyposażenia</h2>
                  <p className="mt-3 max-w-2xl text-[15px] leading-7 text-[#4e4e56]">Krótki dokument z techniczną specyfikacją i szczegółami konfiguracji przygotowanej dla klienta.</p>
                </div>

                <div className="flex flex-wrap gap-3 lg:justify-end">
                  {assets.specPdfUrl ? (
                    <a href={assets.specPdfUrl} target="_blank" rel="noreferrer" className="inline-flex items-center justify-center rounded-full bg-[#BE933E] px-6 py-3 text-[15px] font-semibold text-white transition hover:brightness-[1.03]">
                      Pobierz PDF
                    </a>
                  ) : (
                    <div className="text-[14px] leading-7 text-[#6e6e73]">PDF specyfikacji nie został jeszcze dołączony.</div>
                  )}
                </div>
              </div>
            </div>
          </Panel>

          <Panel variant="highlight">
            <div className="grid gap-8 lg:grid-cols-[1.05fr_0.95fr] lg:gap-10">
              <div className="rounded-[32px] bg-[#1d1d1f] px-7 py-8 text-white shadow-[0_18px_48px_rgba(29,29,31,0.2)] sm:px-8 sm:py-9">
                <div className="text-[12px] font-semibold uppercase tracking-[0.22em] text-white/58">Finanse</div>
                <h2 className="mt-4 text-[32px] font-semibold leading-[1.02] tracking-[-0.04em] text-white sm:text-[40px]">Najważniejsza liczba tej oferty</h2>
                <div className="mt-8 text-[16px] font-medium text-white/68">Rata miesięczna</div>
                <div className="mt-3 text-[44px] font-semibold leading-[0.98] tracking-[-0.05em] text-white sm:text-[56px]">{heroPrimaryValue}</div>
                <p className="mt-5 max-w-xl text-[15px] leading-8 text-white/74">
                  {estimatedInstallmentLabel
                    ? 'To punkt wyjścia do rozmowy o finansowaniu. Ostateczna rata i warunki zostaną potwierdzone po weryfikacji klienta i finalnej konfiguracji.'
                    : 'Jeżeli klient nie ma jeszcze gotowego wariantu finansowania, opiekun przygotuje dokładną propozycję po krótkiej rozmowie.'}
                </p>
                <div className="mt-8 rounded-[24px] bg-white/8 p-5 ring-1 ring-white/10">
                  <div className="text-[13px] font-medium text-white/58">{primaryFinalPriceLabel}</div>
                  <div className="mt-2 text-[28px] font-semibold tracking-[-0.04em] text-white">{primaryFinalPrice}</div>
                  <div className="mt-4 text-[13px] font-medium text-white/52">{secondaryFinalPriceLabel}</div>
                  <div className="mt-1 text-[18px] font-semibold text-white/82">{secondaryFinalPrice}</div>
                </div>
              </div>

              <div className="rounded-[32px] bg-white/72 px-6 py-6 ring-1 ring-white/70 backdrop-blur-md sm:px-7 sm:py-7">
                <div className="text-[12px] font-semibold uppercase tracking-[0.22em] text-[#6e6e73]">Podsumowanie</div>
                <div className="mt-6">
                  {financeRows.map((row) => (
                    <FinanceRow key={row.label} label={row.label} value={row.value} emphasize={row.emphasize} />
                  ))}
                </div>
              </div>
            </div>

            <div className="mt-6 border-t border-white/40 pt-5 text-[12px] leading-7 text-[#5e6168]">
              {formalNotice} Szczegółowe wyliczenie finansowania jest przygotowywane po weryfikacji zdolności finansowej klienta oraz po potwierdzeniu długości finansowania, wysokości wpłaty własnej i wykupu.
            </div>
          </Panel>

          <Panel variant="accent">
            <div className="grid gap-8 lg:grid-cols-[0.95fr_1.05fr] lg:items-center">
              <div>
                <div className="text-[12px] font-semibold uppercase tracking-[0.22em] text-white/70">Kontakt</div>
                <h2 className="mt-4 text-[34px] font-semibold leading-[1.02] tracking-[-0.04em] text-white sm:text-[44px]">Finalny krok to rozmowa z opiekunem</h2>
                <p className="mt-4 max-w-2xl text-[16px] leading-8 text-white/82">Ta oferta została zbudowana po to, by klient szybko przeszedł od pierwszego wrażenia do kontaktu. {advisorName} dopracuje konfigurację, finansowanie i kolejne kroki zakupu.</p>
              </div>

              <div className="rounded-[30px] bg-white/12 p-6 ring-1 ring-white/14 backdrop-blur-md sm:p-7">
                <div className="text-[13px] font-semibold uppercase tracking-[0.18em] text-white/62">Opiekun oferty</div>
                <div className="mt-4 text-[30px] font-semibold tracking-[-0.04em] text-white">{advisorName}</div>
                <div className="mt-4 space-y-2 text-[16px] leading-7 text-white/82">
                  {payload.advisor.phone ? <div>{payload.advisor.phone}</div> : null}
                  {payload.advisor.email ? <div>{payload.advisor.email}</div> : null}
                </div>

                <div className="mt-8 flex flex-wrap gap-3">
                  {primaryCtaHref ? (
                    <a href={primaryCtaHref} className="inline-flex items-center rounded-full bg-white px-6 py-3 text-[15px] font-semibold text-[#BE933E] transition hover:bg-white/90">
                      Skontaktuj się
                    </a>
                  ) : null}
                  {phoneCtaHref ? (
                    <a href={phoneCtaHref} className="inline-flex items-center rounded-full bg-white/10 px-6 py-3 text-[15px] font-semibold text-white ring-1 ring-white/18 transition hover:bg-white/16">
                      Zadzwoń
                    </a>
                  ) : null}
                </div>
              </div>
            </div>
          </Panel>
        </div>
      </div>
    </main>
  )
}