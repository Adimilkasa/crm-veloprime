import Link from 'next/link'
import { notFound } from 'next/navigation'

import { PublicOfferGallery } from '@/components/offers/PublicOfferGallery'
import { getPublicOfferDocumentSnapshot } from '@/lib/offer-management'

function formatDate(value: string | null) {
  if (!value) {
    return 'Nie określono'
  }

  return new Intl.DateTimeFormat('pl-PL', { dateStyle: 'medium' }).format(new Date(value))
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

function buildHeroNarrative(input: {
  modelName: string
  customerName: string
  selectedColorName: string | null
  powertrainType: string | null | undefined
}) {
  const color = input.selectedColorName?.trim() || 'kolor bazowy'
  const powertrain = input.powertrainType?.trim() || 'napęd zgodny z konfiguracją'

  return `Konfiguracja ${input.modelName} została przygotowana indywidualnie dla ${input.customerName}. Hero pokazuje sam pojazd i jego główne cechy: kolor ${color} oraz ${powertrain}.`
}

function formatMoney(value: number | null | undefined) {
  if (value === null || value === undefined || Number.isNaN(value)) {
    return 'Do potwierdzenia'
  }

  return new Intl.NumberFormat('pl-PL', {
    style: 'currency',
    currency: 'PLN',
    maximumFractionDigits: 2,
  }).format(value)
}

const defaultFinancingDisclaimer =
  'Prezentowane raty są orientacyjne i obliczone na podstawie parametrów wprowadzonych do kalkulatora. Ostateczna decyzja finansowa, wysokość rat oraz warunki umowy są ustalane przez instytucję finansującą po pełnej analizie zdolności kredytowej klienta. Oferta nie stanowi wiążącej oferty finansowania zgodnie z Kodeksem cywilnym.'

function InfoPill({ label, value }: { label: string; value: string }) {
  return (
    <span className="inline-flex items-center rounded-full border border-white/55 bg-white/72 px-4 py-2 text-sm font-medium text-[#24324f] backdrop-blur-sm">
      <span className="mr-2 text-[10px] font-semibold uppercase tracking-[0.22em] text-[#8b7746]">{label}</span>
      <span>{value}</span>
    </span>
  )
}

function MetricCard({
  eyebrow,
  value,
  detail,
  accent = false,
}: {
  eyebrow: string
  value: string
  detail: string
  accent?: boolean
}) {
  return (
    <article
      className={[
        'rounded-[26px] border p-5 shadow-[0_20px_60px_rgba(17,32,67,0.08)]',
        accent
          ? 'border-[rgba(157,123,39,0.18)] bg-[linear-gradient(180deg,#fff8ea_0%,#fffdf7_100%)]'
          : 'border-[rgba(20,33,61,0.08)] bg-white/92',
      ].join(' ')}
    >
      <div className="text-[11px] font-semibold uppercase tracking-[0.22em] text-[#8b7746]">{eyebrow}</div>
      <div className="mt-3 text-[28px] font-semibold leading-tight text-[#172033]">{value}</div>
      <div className="mt-3 text-sm leading-7 text-[#5c6881]">{detail}</div>
    </article>
  )
}

function SectionCard({
  eyebrow,
  title,
  description,
  children,
}: {
  eyebrow: string
  title: string
  description?: string
  children: React.ReactNode
}) {
  return (
    <section className="rounded-[30px] border border-[rgba(20,33,61,0.08)] bg-white/94 p-6 shadow-[0_20px_60px_rgba(17,32,67,0.08)] lg:p-8">
      <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">{eyebrow}</div>
      <h2 className="mt-3 text-[28px] font-semibold leading-tight text-[#172033]">{title}</h2>
      {description ? <p className="mt-3 max-w-3xl text-[15px] leading-8 text-[#58657f]">{description}</p> : null}
      <div className="mt-6">{children}</div>
    </section>
  )
}

function DetailTile({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-[22px] border border-[rgba(20,33,61,0.07)] bg-[linear-gradient(180deg,#ffffff_0%,#f7f9fc_100%)] p-4">
      <div className="text-sm text-[#7a879f]">{label}</div>
      <div className="mt-2 text-[18px] font-semibold leading-7 text-[#172033]">{value}</div>
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
      <main className="min-h-screen bg-[radial-gradient(circle_at_top,rgba(26,87,152,0.2),transparent_35%),linear-gradient(180deg,#f6f8fc_0%,#edf2f8_100%)] px-4 py-10 text-[#172033]">
        <div className="mx-auto max-w-3xl rounded-[32px] border border-[rgba(27,58,112,0.12)] bg-white/90 p-8 shadow-[0_24px_80px_rgba(17,32,67,0.14)]">
          <div className="text-xs font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">Oferta VeloPrime</div>
          <h1 className="mt-4 text-3xl font-semibold text-[#172033]">Oferta wygasła.</h1>
          <p className="mt-4 max-w-2xl text-base leading-8 text-[#52607a]">
            Ten link nie jest już aktywny. W sprawie aktualnej oferty skontaktuj się z osobą odpowiedzialną za klienta.
          </p>
          <div className="mt-8 rounded-[24px] border border-[rgba(27,58,112,0.1)] bg-[#f8fbff] p-6">
            <div className="text-[11px] font-semibold uppercase tracking-[0.22em] text-[#9d7b27]">Osoba odpowiedzialna za klienta</div>
            <div className="mt-3 text-lg font-semibold text-[#172033]">{expiredAdvisorName}</div>
            <div className="mt-2 text-sm text-[#52607a]">{expiredAdvisorContact}</div>
            <div className="mt-5 flex flex-wrap gap-3">
              {document.advisorEmail ? (
                <a href={`mailto:${document.advisorEmail}`} className="inline-flex items-center rounded-full bg-[linear-gradient(180deg,#e3c986_0%,#d6ad56_100%)] px-5 py-3 text-sm font-semibold text-[#1c1711] shadow-[0_14px_34px_rgba(212,168,79,0.2)] transition hover:translate-y-[-1px] hover:brightness-[1.02]">
                  Napisz wiadomość
                </a>
              ) : null}
              {document.advisorPhone ? (
                <a href={`tel:${document.advisorPhone.replace(/\s+/g, '')}`} className="inline-flex items-center rounded-full border border-[rgba(20,33,61,0.1)] bg-white px-5 py-3 text-sm font-medium text-[#172033] shadow-[0_12px_30px_rgba(17,32,67,0.06)] transition hover:translate-y-[-1px] hover:border-[rgba(157,123,39,0.24)]">
                  Zadzwoń
                </a>
              ) : null}
            </div>
          </div>
        </div>
      </main>
    )
  }

  const payload = document.payload
  const assets = document.assets
  const heroImage = assets.images.premium[0] ?? assets.images.exterior[0] ?? assets.images.other[0] ?? null
  const gallery = [
    ...assets.images.premium,
    ...assets.images.exterior,
    ...assets.images.interior,
    ...assets.images.details,
  ].filter((image, index, all) => all.indexOf(image) === index)
  const modelLabel = buildModelLabel(payload.customer.modelName, document.title)
  const pricingDisplayMode = isCompanyCustomer(payload.internal.customerType) ? 'netto' : 'brutto'
  const effectivePriceLabel = pricingDisplayMode === 'netto' ? payload.customer.finalNetLabel : payload.customer.finalGrossLabel
  const secondaryPriceLabel = pricingDisplayMode === 'netto' ? payload.customer.finalGrossLabel : payload.customer.finalNetLabel
  const effectivePriceTitle = pricingDisplayMode === 'netto' ? 'Cena końcowa netto' : 'Cena końcowa brutto'
  const secondaryPriceTitle = pricingDisplayMode === 'netto' ? 'Cena końcowa brutto' : 'Cena końcowa netto'
  const heroNarrative = buildHeroNarrative({
    modelName: modelLabel,
    customerName: payload.customer.customerName,
    selectedColorName: payload.customer.selectedColorName,
    powertrainType: payload.internal.powertrainType,
  })
  const advisorName = payload.advisor.fullName || payload.internal.ownerName || 'Opiekun VeloPrime'
  const advisorRole = payload.advisor.role || payload.internal.ownerRole || 'Handlowiec'
  const advisorAvatarUrl = payload.advisor.avatarUrl?.trim() || null
  const customerContactLine = buildContactLine(payload.customer.customerEmail, payload.customer.customerPhone)
  const advisorContactLine = buildContactLine(payload.advisor.email, payload.advisor.phone)
  const validUntilLabel = formatDate(payload.customer.validUntil ?? document.shareExpiresAt)
  const generatedAtLabel = formatDate(payload.createdAt)
  const onlineStatusSummary = `To jest aktywna wersja oferty online. Link prowadzi do tej samej konfiguracji przygotowanej przez opiekuna i pozostaje ważny do ${validUntilLabel}.`
  const formalNotice = payload.customer.financingDisclaimer ?? defaultFinancingDisclaimer
  const baseColorName = payload.internal.baseColorName?.trim() || null
  const technicalItems = [
    { label: 'Model', value: modelLabel },
    { label: 'Kolor konfiguracji', value: payload.customer.selectedColorName ?? 'Bazowy' },
    { label: 'Typ napędu', value: payload.internal.powertrainType?.trim() || 'Do potwierdzenia' },
    ...(baseColorName ? [{ label: 'Kolor bazowy modelu', value: baseColorName }] : []),
  ]
  const notesText = payload.customer.notes?.trim() || 'Brak dodatkowych uwag do oferty.'
  const financingSummary = payload.internal.financing
  const financingFacts = financingSummary
    ? [
        { label: 'Szacowana rata', value: formatMoney(financingSummary.estimatedInstallment) },
        { label: 'Okres', value: `${financingSummary.termMonths} mies.` },
        { label: 'Wpłata własna', value: formatMoney(financingSummary.downPaymentAmount) },
        { label: 'Wykup', value: `${financingSummary.buyoutPercent}%` },
      ]
    : []

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,rgba(212,168,79,0.12),transparent_28%),radial-gradient(circle_at_85%_14%,rgba(31,82,147,0.16),transparent_24%),linear-gradient(180deg,#fcfcfb_0%,#f1f5f8_100%)] px-4 py-6 text-[#172033] sm:px-6 lg:px-8 lg:py-10">
      <div className="mx-auto max-w-7xl">
        <section className="relative overflow-hidden rounded-[40px] border border-[rgba(20,33,61,0.08)] bg-[linear-gradient(135deg,rgba(255,255,255,0.9),rgba(247,250,255,0.88))] shadow-[0_34px_110px_rgba(17,32,67,0.14)]">
          <div className="absolute inset-x-0 top-0 h-px bg-[linear-gradient(90deg,transparent,rgba(212,168,79,0.48),transparent)]" />
          <div className="absolute -left-16 top-12 h-44 w-44 rounded-full bg-[rgba(212,168,79,0.12)] blur-3xl" />
          <div className="absolute right-0 top-0 h-64 w-64 rounded-full bg-[rgba(32,83,149,0.12)] blur-3xl" />

          <div className="relative px-6 py-7 lg:px-10 lg:py-9">
            <div className="flex flex-col gap-4 border-b border-[rgba(20,33,61,0.07)] pb-6 lg:flex-row lg:items-center lg:justify-between">
              <div className="flex items-center gap-4">
                <div className="rounded-[22px] border border-white/70 bg-white/78 px-4 py-3 shadow-[0_14px_34px_rgba(17,32,67,0.08)] backdrop-blur-sm">
                  {/* eslint-disable-next-line @next/next/no-img-element -- share page uses static asset logo */}
                  <img src={assets.logoUrl} alt="VeloPrime" className="h-8 w-auto" />
                </div>
                <div>
                  <div className="text-[11px] font-semibold uppercase tracking-[0.28em] text-[#9d7b27]">Oferta online</div>
                  <div className="mt-1 text-sm text-[#62708a]">Dokument przygotowany indywidualnie dla klienta</div>
                </div>
              </div>

              <div className="flex flex-wrap gap-3">
                <InfoPill label="Dla klienta" value={payload.customer.customerName} />
                <InfoPill label="Kolor" value={payload.customer.selectedColorName ?? 'Bazowy'} />
                <InfoPill label="Napęd" value={payload.internal.powertrainType?.trim() || 'Do potwierdzenia'} />
              </div>
            </div>

            <div className="mt-8 grid gap-8 lg:grid-cols-[1.05fr_0.95fr] xl:gap-10">
              <div className="relative z-10">
                <div className="text-[11px] font-semibold uppercase tracking-[0.28em] text-[#9d7b27]">Konfiguracja dopasowana do rozmowy handlowej</div>
                <h1 className="mt-4 max-w-4xl text-[40px] font-semibold leading-[1.04] tracking-[-0.03em] text-[#172033] sm:text-[54px] lg:text-[64px]">
                  {modelLabel}
                </h1>
                <p className="mt-5 max-w-2xl text-[16px] leading-8 text-[#58657f]">
                  {heroNarrative}
                </p>

                <div className="mt-7 flex flex-wrap gap-3">
                  <InfoPill label="Kontakt" value={customerContactLine} />
                  <InfoPill label="Opiekun" value={advisorName} />
                </div>

                <div className="mt-8 max-w-xl rounded-[28px] border border-white/70 bg-white/74 p-5 shadow-[0_20px_60px_rgba(17,32,67,0.08)] backdrop-blur-md lg:p-6">
                  <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">Gotowe do prezentacji</div>
                  <p className="mt-3 text-[15px] leading-8 text-[#56627a]">
                    Poniżej znajdziesz PDF specyfikacji, galerię modelu, wycenę oraz finansowanie w kolejności zgodnej z finalnym układem oferty.
                  </p>
                </div>
              </div>

              <div className="relative lg:pl-4">
                <div className="overflow-hidden rounded-[32px] border border-[rgba(20,33,61,0.08)] bg-[linear-gradient(180deg,#ffffff_0%,#f7f9fc_100%)] shadow-[0_30px_90px_rgba(17,32,67,0.14)]">
                  <div className="relative">
                    {heroImage ? (
                      // eslint-disable-next-line @next/next/no-img-element -- share page uses direct product assets
                      <img src={heroImage} alt={modelLabel} className="h-[320px] w-full object-cover sm:h-[420px]" />
                    ) : (
                      <div className="flex h-[320px] items-center justify-center bg-[linear-gradient(135deg,#edf3fb,#dde7f5)] px-8 text-center text-sm leading-7 text-[#5f6d87] sm:h-[420px]">
                        Materiały modelu są kompletowane. Ta oferta pozostaje aktywna i może zostać uzupełniona dodatkowymi wizualizacjami.
                      </div>
                    )}

                    <div className="absolute inset-x-0 bottom-0 bg-[linear-gradient(180deg,transparent_0%,rgba(8,17,35,0.75)_100%)] p-6 text-white sm:p-7">
                      <div className="text-[11px] font-semibold uppercase tracking-[0.28em] text-white/68">Wybrana konfiguracja</div>
                      <div className="mt-3 text-[28px] font-semibold leading-tight">{payload.customer.selectedColorName ?? modelLabel}</div>
                      <div className="mt-2 max-w-xl text-sm leading-7 text-white/78">Hero pozostaje czysty: skupia się na samochodzie, kolorze i materiale wizualnym, bez sekcji cenowej i metadanych dokumentu.</div>
                    </div>
                  </div>

                  <div className="grid gap-4 px-6 py-6 sm:grid-cols-2">
                    <div className="rounded-[24px] border border-[rgba(20,33,61,0.07)] bg-white/90 p-5">
                      <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">Klient</div>
                      <div className="mt-3 text-[22px] font-semibold text-[#172033]">{payload.customer.customerName}</div>
                      <div className="mt-3 text-sm leading-7 text-[#5f6d87]">{customerContactLine}</div>
                    </div>
                    <div className="rounded-[24px] border border-[rgba(20,33,61,0.07)] bg-[linear-gradient(135deg,#18325f_0%,#23477f_100%)] p-5 text-white shadow-[0_18px_50px_rgba(23,45,87,0.28)]">
                      <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-white/62">Opiekun oferty</div>
                      <div className="mt-4 flex items-center gap-4">
                        <AdvisorAvatar avatarUrl={advisorAvatarUrl} fullName={advisorName} size="h-16 w-16" textClassName="text-lg" />
                        <div>
                          <div className="text-[22px] font-semibold">{advisorName}</div>
                          <div className="mt-2 text-sm text-white/72">{advisorRole}</div>
                        </div>
                      </div>
                      <div className="mt-4 text-sm leading-7 text-white/78">{advisorContactLine}</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {assets.specPdfUrl ? (
          <section className="mt-8 rounded-[30px] border border-[rgba(20,33,61,0.08)] bg-white/94 p-6 shadow-[0_20px_60px_rgba(17,32,67,0.08)] lg:p-8">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
              <div>
                <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">PDF</div>
                <h2 className="mt-3 text-[28px] font-semibold leading-tight text-[#172033]">Specyfikacja pojazdu dostępna do pobrania</h2>
                <p className="mt-3 max-w-3xl text-[15px] leading-8 text-[#58657f]">
                  PDF pozostaje tuż pod hero, zanim użytkownik przejdzie do sekcji technicznej, galerii, wyceny i finansowania.
                </p>
              </div>
              <Link href={assets.specPdfUrl} target="_blank" className="inline-flex items-center rounded-full bg-[linear-gradient(180deg,#e3c986_0%,#d6ad56_100%)] px-5 py-3 text-sm font-semibold text-[#1c1711] shadow-[0_14px_34px_rgba(212,168,79,0.2)] transition hover:translate-y-[-1px] hover:brightness-[1.02]">
                Otwórz specyfikację PDF
              </Link>
            </div>
          </section>
        ) : null}

        <section className="mt-8 grid gap-6 xl:grid-cols-[1.08fr_0.92fr]">
          <SectionCard
            eyebrow="Konfiguracja techniczna"
            title="Dane pojazdu i wybranej konfiguracji"
            description="Ta sekcja zawiera wyłącznie parametry samochodu. Metadane dokumentu i formalności pozostają przeniesione na sam dół oferty."
          >
            <div className="grid gap-4 sm:grid-cols-2">
              {technicalItems.map((item) => (
                <DetailTile key={item.label} label={item.label} value={item.value} />
              ))}
            </div>

            <div className="mt-5 rounded-[26px] border border-[rgba(20,33,61,0.08)] bg-[linear-gradient(180deg,#f9fbfe_0%,#f4f7fb_100%)] p-5">
              <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">Opis konfiguracji</div>
              <p className="mt-4 text-[15px] leading-8 text-[#55627d]">
                Sekcja techniczna pozostaje czysta: pokazuje model, kolor i napęd, zanim użytkownik przejdzie do materiałów wizualnych oraz części handlowej oferty.
              </p>
            </div>
          </SectionCard>

          <div className="grid gap-6">
            <SectionCard
              eyebrow="Materiały modelu"
              title={`Galeria dla konfiguracji ${modelLabel}`}
              description="Galeria jest celowo pokazana przed sekcją wartości i finansowania, żeby najpierw sprzedawać sam samochód i jego wygląd."
            >
              <PublicOfferGallery modelLabel={modelLabel} gallery={gallery} />
            </SectionCard>

            <SectionCard
              eyebrow="Wartość pojazdu"
              title="Cena i rabat dla tej konfiguracji"
              description="Wycena pozostaje oddzielona od finansowania. Najpierw pokazujemy wartość pojazdu i pełny kontekst cenowy, a dopiero potem scenariusz finansowania."
            >
              <div className="grid gap-4 sm:grid-cols-3">
                <MetricCard
                  eyebrow={effectivePriceTitle}
                  value={effectivePriceLabel}
                  detail={`Cena prezentowana w trybie ${pricingDisplayMode} dla przygotowanej konfiguracji, po uwzględnieniu warunków oferty.`}
                  accent
                />
                <MetricCard
                  eyebrow={secondaryPriceTitle}
                  value={secondaryPriceLabel}
                  detail={`Cena alternatywna względem trybu ${pricingDisplayMode} dla tej samej konfiguracji.`}
                />
                <MetricCard
                  eyebrow="Rabat"
                  value={payload.customer.discountLabel}
                  detail={`Cena katalogowa ${payload.customer.listPriceLabel} oraz rabat procentowy ${payload.customer.discountPercentLabel}.`}
                />
              </div>
            </SectionCard>
          </div>
        </section>

        <section className="mt-8 grid gap-6 xl:grid-cols-[1.08fr_0.92fr]">
          <SectionCard
            eyebrow="Finansowanie"
            title="Osobna sekcja warunków finansowania"
            description="Finansowanie nie miesza się z wartością pojazdu. Tu trafiają wyłącznie wariant, parametry kalkulacji oraz zastrzeżenie formalne."
          >
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="rounded-[26px] border border-[rgba(20,33,61,0.08)] bg-white p-5">
                <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">Wariant finansowania</div>
                <div className="mt-3 text-[22px] font-semibold leading-tight text-[#172033]">
                  {payload.customer.financingVariant ?? 'Warunki ustalane indywidualnie'}
                </div>
                <p className="mt-3 text-sm leading-7 text-[#5b6881]">
                  {payload.customer.financingSummary ?? 'W tej wersji dokumentu scenariusz finansowania pozostaje gotowy do doprecyzowania z opiekunem oferty.'}
                </p>
              </div>
              <div className="rounded-[26px] border border-[rgba(20,33,61,0.08)] bg-[linear-gradient(145deg,#18325f_0%,#214b87_100%)] p-5 text-white shadow-[0_22px_60px_rgba(23,45,87,0.28)]">
                <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-white/62">Podstawa kalkulacji</div>
                <div className="mt-3 text-[22px] font-semibold leading-tight">
                  {financingSummary?.calculationBaseLabel ? `Wartości ${financingSummary.calculationBaseLabel}` : 'Wartości do potwierdzenia'}
                </div>
                <p className="mt-3 text-sm leading-7 text-white/76">
                  {financingSummary
                    ? `Kalkulacja obejmuje okres ${financingSummary.termMonths} mies., wpłatę własną ${formatMoney(financingSummary.downPaymentAmount)} i wykup ${financingSummary.buyoutPercent}%.`
                    : 'Szczegółowa kalkulacja finansowania zostanie przedstawiona po pełnym potwierdzeniu parametrów.'}
                </p>
              </div>
            </div>

            {financingFacts.length > 0 ? (
              <div className="mt-5 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                {financingFacts.map((item) => (
                  <DetailTile key={item.label} label={item.label} value={item.value} />
                ))}
              </div>
            ) : null}

            <div className="mt-5 rounded-[24px] border border-[rgba(157,123,39,0.16)] bg-[linear-gradient(180deg,#fff9ee_0%,#fffdf8_100%)] px-5 py-4 text-sm leading-7 text-[#6b654d]">
              {formalNotice}
            </div>
          </SectionCard>

          <SectionCard
            eyebrow="Opiekun"
            title="Osoba odpowiedzialna za ofertę"
            description="Sekcja kontaktowa pozostaje oddzielona od danych systemowych dokumentu. Tu klient widzi wyłącznie opiekuna i ewentualne uwagi do rozmowy."
          >
            <div className="rounded-[28px] bg-[linear-gradient(145deg,#18325f_0%,#214b87_100%)] p-6 text-white shadow-[0_22px_60px_rgba(23,45,87,0.28)]">
              <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-white/62">{advisorRole}</div>
              <div className="mt-4 flex items-center gap-4">
                <AdvisorAvatar avatarUrl={advisorAvatarUrl} fullName={advisorName} size="h-20 w-20" textClassName="text-xl" />
                <div>
                  <div className="text-[30px] font-semibold leading-tight">{advisorName}</div>
                  <div className="mt-3 text-sm leading-8 text-white/76">{advisorContactLine}</div>
                </div>
              </div>
              <div className="mt-5 flex flex-wrap gap-3">
                {payload.advisor.email ? (
                  <a href={`mailto:${payload.advisor.email}`} className="inline-flex items-center rounded-full bg-[linear-gradient(180deg,#e3c986_0%,#d6ad56_100%)] px-5 py-3 text-sm font-semibold text-[#1c1711] shadow-[0_14px_34px_rgba(212,168,79,0.2)] transition hover:translate-y-[-1px] hover:brightness-[1.02]">
                    Wyślij wiadomość do opiekuna
                  </a>
                ) : null}
                {payload.advisor.phone ? (
                  <a href={`tel:${payload.advisor.phone.replace(/\s+/g, '')}`} className="inline-flex items-center rounded-full border border-white/20 bg-white/10 px-5 py-3 text-sm font-medium text-white transition hover:translate-y-[-1px] hover:border-white/35">
                    Zadzwoń: {payload.advisor.phone}
                  </a>
                ) : null}
              </div>
            </div>

            <div className="mt-5 rounded-[24px] border border-[rgba(20,33,61,0.08)] bg-[linear-gradient(180deg,#f9fbfe_0%,#f4f7fb_100%)] p-5 text-sm leading-8 text-[#55627d]">
              <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">Uwagi do oferty</div>
              <p className="mt-3">{notesText}</p>
            </div>
          </SectionCard>
        </section>

        <section className="mt-8 rounded-[30px] border border-[rgba(20,33,61,0.08)] bg-[linear-gradient(180deg,rgba(255,255,255,0.96),rgba(246,249,252,0.96))] p-6 shadow-[0_20px_60px_rgba(17,32,67,0.08)] lg:p-8">
          <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">Finalizacja</div>
          <h2 className="mt-3 text-[28px] font-semibold leading-tight text-[#172033]">Oficjalny status tej wersji oferty</h2>
          <p className="mt-3 max-w-3xl text-[15px] leading-8 text-[#58657f]">
            Końcowa sekcja porządkuje status dokumentu, termin ważności i formalne zastrzeżenia przed finalnym potwierdzeniem konfiguracji lub finansowania.
          </p>

          <div className="mt-6 grid gap-6 xl:grid-cols-[1.05fr_0.95fr]">
            <div className="grid gap-4">
              <div className="rounded-[26px] border border-[rgba(36,65,103,0.12)] bg-[linear-gradient(180deg,#f7fbff_0%,#edf4fb_100%)] p-5">
                <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-[#31557f]">Status wersji online</div>
                <p className="mt-3 text-sm leading-8 text-[#4d5f79]">{onlineStatusSummary}</p>
              </div>

              <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
                <DetailTile label="Numer oferty" value={payload.customer.offerNumber} />
                <DetailTile label="Wersja dokumentu" value={String(document.version.versionNumber)} />
                <DetailTile label="Wygenerowano" value={generatedAtLabel} />
                <DetailTile label="Ważna do" value={validUntilLabel} />
                <DetailTile label="Specyfikacja" value={assets.specPdfUrl ? 'PDF dostępny' : 'Brak osobnego PDF'} />
                <DetailTile label="Typ klienta" value={isCompanyCustomer(payload.internal.customerType) ? 'Firma' : 'Klient prywatny'} />
              </div>
            </div>

            <div className="rounded-[26px] border border-[rgba(157,123,39,0.16)] bg-[linear-gradient(180deg,#fff9ee_0%,#fffdf8_100%)] p-5">
              <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">Zastrzeżenie formalne</div>
              <p className="mt-3 text-sm leading-8 text-[#6b654d]">{formalNotice}</p>
            </div>
          </div>
        </section>
      </div>
    </main>
  )
}

function AdvisorAvatar({
  avatarUrl,
  fullName,
  size,
  textClassName,
}: {
  avatarUrl: string | null
  fullName: string
  size: string
  textClassName: string
}) {
  const initials = buildAdvisorInitials(fullName)

  if (avatarUrl) {
    return (
      <div className={`overflow-hidden rounded-full border border-white/25 bg-white/10 ${size}`}>
        {/* eslint-disable-next-line @next/next/no-img-element -- direct avatar url can be blob or data uri */}
        <img src={avatarUrl} alt={fullName} className="h-full w-full object-cover" />
      </div>
    )
  }

  return (
    <div className={`flex items-center justify-center rounded-full border border-white/18 bg-[linear-gradient(135deg,rgba(255,255,255,0.18),rgba(255,255,255,0.08))] font-semibold text-white ${size} ${textClassName}`}>
      {initials}
    </div>
  )
}

function buildAdvisorInitials(value: string) {
  const parts = value.trim().split(/\s+/).filter(Boolean).slice(0, 2)

  if (parts.length === 0) {
    return 'VP'
  }

  return parts.map((part) => part[0]?.toUpperCase() ?? '').join('')
}