import Link from 'next/link'
import { notFound } from 'next/navigation'

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

function buildOfferNarrative(input: {
  modelName: string
  customerName: string
  finalGrossLabel: string
  financingSummary: string | null
  financingVariant: string | null
}) {
  const financing = input.financingSummary ?? input.financingVariant ?? 'warunki ustalane indywidualnie'

  return `Konfiguracja ${input.modelName} została przygotowana indywidualnie dla ${input.customerName}. Punktem wyjścia do rozmowy jest cena końcowa ${input.finalGrossLabel} brutto oraz scenariusz finansowania: ${financing}.`
}

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
    return (
      <main className="min-h-screen bg-[radial-gradient(circle_at_top,rgba(26,87,152,0.2),transparent_35%),linear-gradient(180deg,#f6f8fc_0%,#edf2f8_100%)] px-4 py-10 text-[#172033]">
        <div className="mx-auto max-w-3xl rounded-[32px] border border-[rgba(27,58,112,0.12)] bg-white/90 p-8 shadow-[0_24px_80px_rgba(17,32,67,0.14)]">
          <div className="text-xs font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">Oferta VeloPrime</div>
          <h1 className="mt-4 text-3xl font-semibold text-[#172033]">Ta oferta nie jest już aktywna.</h1>
          <p className="mt-4 max-w-2xl text-base leading-8 text-[#52607a]">
            Link wygasł wraz z okresem ważności dokumentu. Skontaktuj się bezpośrednio z opiekunem oferty, aby otrzymać aktualną wersję.
          </p>
          <div className="mt-8 rounded-[24px] border border-[rgba(27,58,112,0.1)] bg-[#f8fbff] p-6">
            <div className="text-sm font-semibold text-[#172033]">{document.advisorName ?? 'Opiekun VeloPrime'}</div>
            <div className="mt-2 text-sm text-[#52607a]">{buildContactLine(document.advisorEmail, document.advisorPhone)}</div>
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
  const offerNarrative = buildOfferNarrative({
    modelName: modelLabel,
    customerName: payload.customer.customerName,
    finalGrossLabel: payload.customer.finalGrossLabel,
    financingSummary: payload.customer.financingSummary,
    financingVariant: payload.customer.financingVariant,
  })
  const advisorName = payload.advisor.fullName || payload.internal.ownerName || 'Opiekun VeloPrime'
  const advisorRole = payload.advisor.role || payload.internal.ownerRole || 'Handlowiec'
  const customerContactLine = buildContactLine(payload.customer.customerEmail, payload.customer.customerPhone)
  const advisorContactLine = buildContactLine(payload.advisor.email, payload.advisor.phone)
  const accentGallery = gallery.slice(0, 5)

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,rgba(212,168,79,0.12),transparent_28%),radial-gradient(circle_at_85%_14%,rgba(31,82,147,0.16),transparent_24%),linear-gradient(180deg,#fcfcfb_0%,#f1f5f8_100%)] px-4 py-5 text-[#172033] sm:px-6 lg:px-8 lg:py-8">
      <div className="mx-auto max-w-7xl">
        <section className="relative overflow-hidden rounded-[38px] border border-[rgba(20,33,61,0.08)] bg-[linear-gradient(135deg,rgba(255,255,255,0.9),rgba(247,250,255,0.88))] shadow-[0_34px_110px_rgba(17,32,67,0.14)]">
          <div className="absolute inset-x-0 top-0 h-px bg-[linear-gradient(90deg,transparent,rgba(212,168,79,0.48),transparent)]" />
          <div className="absolute -left-16 top-12 h-44 w-44 rounded-full bg-[rgba(212,168,79,0.12)] blur-3xl" />
          <div className="absolute right-0 top-0 h-64 w-64 rounded-full bg-[rgba(32,83,149,0.12)] blur-3xl" />

          <div className="relative px-6 py-6 lg:px-10 lg:py-8">
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
                <InfoPill label="Numer" value={payload.customer.offerNumber} />
                <InfoPill label="Ważność" value={formatDate(payload.customer.validUntil ?? document.shareExpiresAt)} />
                <InfoPill label="Wersja" value={String(document.version.versionNumber)} />
              </div>
            </div>

            <div className="mt-8 grid gap-8 lg:grid-cols-[1.05fr_0.95fr] xl:gap-10">
              <div className="relative z-10">
                <div className="text-[11px] font-semibold uppercase tracking-[0.28em] text-[#9d7b27]">Konfiguracja dopasowana do rozmowy handlowej</div>
                <h1 className="mt-4 max-w-4xl text-[40px] font-semibold leading-[1.04] tracking-[-0.03em] text-[#172033] sm:text-[54px] lg:text-[64px]">
                  {modelLabel}
                </h1>
                <p className="mt-5 max-w-2xl text-[16px] leading-8 text-[#58657f]">
                  {offerNarrative}
                </p>

                <div className="mt-7 flex flex-wrap gap-3">
                  <InfoPill label="Dla klienta" value={payload.customer.customerName} />
                  <InfoPill label="Kolor" value={payload.customer.selectedColorName ?? 'Bazowy'} />
                  <InfoPill label="Kontakt" value={customerContactLine} />
                </div>

                <div className="mt-8 grid gap-4 sm:grid-cols-3">
                  <MetricCard
                    eyebrow="Cena końcowa"
                    value={payload.customer.finalGrossLabel}
                    detail="Brutto dla przygotowanej konfiguracji, po uwzględnieniu warunków oferty."
                    accent
                  />
                  <MetricCard
                    eyebrow="Cena netto"
                    value={payload.customer.finalNetLabel}
                    detail={`Cena katalogowa ${payload.customer.listPriceLabel} z rabatem ${payload.customer.discountLabel}.`}
                  />
                  <MetricCard
                    eyebrow="Finansowanie"
                    value={payload.customer.financingVariant ?? 'Ustalane'}
                    detail={payload.customer.financingSummary ?? 'Szczegóły finansowania są gotowe do omówienia z opiekunem oferty.'}
                  />
                </div>

                <div className="mt-8 flex flex-wrap gap-3">
                  {payload.advisor.email ? (
                    <a href={`mailto:${payload.advisor.email}`} className="inline-flex items-center rounded-full bg-[linear-gradient(180deg,#e3c986_0%,#d6ad56_100%)] px-5 py-3 text-sm font-semibold text-[#1c1711] shadow-[0_14px_34px_rgba(212,168,79,0.2)] transition hover:translate-y-[-1px] hover:brightness-[1.02]">
                      Wyślij wiadomość do opiekuna
                    </a>
                  ) : null}
                  {payload.advisor.phone ? (
                    <a href={`tel:${payload.advisor.phone.replace(/\s+/g, '')}`} className="inline-flex items-center rounded-full border border-[rgba(20,33,61,0.1)] bg-white/88 px-5 py-3 text-sm font-medium text-[#172033] shadow-[0_12px_30px_rgba(17,32,67,0.06)] transition hover:translate-y-[-1px] hover:border-[rgba(157,123,39,0.24)]">
                      Zadzwoń: {payload.advisor.phone}
                    </a>
                  ) : null}
                  {assets.specPdfUrl ? (
                    <Link href={assets.specPdfUrl} target="_blank" className="inline-flex items-center rounded-full border border-[rgba(20,33,61,0.1)] bg-[#f8fbff] px-5 py-3 text-sm font-medium text-[#244167] shadow-[0_12px_30px_rgba(17,32,67,0.05)] transition hover:translate-y-[-1px] hover:border-[rgba(36,65,103,0.22)]">
                      Otwórz specyfikację PDF
                    </Link>
                  ) : null}
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
                      <div className="mt-2 max-w-xl text-sm leading-7 text-white/78">{payload.customer.financingSummary ?? 'Wariant finansowania oraz detale zakupu są gotowe do omówienia z opiekunem oferty.'}</div>
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
                      <div className="mt-3 text-[22px] font-semibold">{advisorName}</div>
                      <div className="mt-2 text-sm text-white/72">{advisorRole}</div>
                      <div className="mt-4 text-sm leading-7 text-white/78">{advisorContactLine}</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section className="mt-6 grid gap-6 xl:grid-cols-[1.08fr_0.92fr]">
          <SectionCard
            eyebrow="Podsumowanie handlowe"
            title="Najważniejsze parametry przygotowane dla tej wersji oferty"
            description="Kluczowe liczby i ustalenia zebrane tak, aby klient od razu rozumiał punkt wyjścia do rozmowy oraz zakres oferty."
          >
            <div className="grid gap-4 sm:grid-cols-2">
              <DetailTile label="Model" value={modelLabel} />
              <DetailTile label="Kolor" value={payload.customer.selectedColorName ?? 'Bazowy'} />
              <DetailTile label="Cena katalogowa" value={payload.customer.listPriceLabel} />
              <DetailTile label="Rabat" value={`${payload.customer.discountLabel} (${payload.customer.discountPercentLabel})`} />
            </div>

            <div className="mt-5 rounded-[26px] border border-[rgba(20,33,61,0.08)] bg-[linear-gradient(180deg,#f9fbfe_0%,#f4f7fb_100%)] p-5">
              <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">Narracja oferty</div>
              <p className="mt-4 text-[15px] leading-8 text-[#55627d]">{offerNarrative}</p>
            </div>

            <div className="mt-5 grid gap-4 sm:grid-cols-2">
              <div className="rounded-[26px] border border-[rgba(20,33,61,0.08)] bg-white p-5">
                <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">Finansowanie</div>
                <div className="mt-3 text-[22px] font-semibold leading-tight text-[#172033]">
                  {payload.customer.financingVariant ?? 'Warunki ustalane indywidualnie'}
                </div>
                <p className="mt-3 text-sm leading-7 text-[#5b6881]">
                  {payload.customer.financingSummary ?? 'W tej wersji dokumentu scenariusz finansowania pozostaje gotowy do doprecyzowania z opiekunem oferty.'}
                </p>
              </div>
              <div className="rounded-[26px] border border-[rgba(20,33,61,0.08)] bg-white p-5">
                <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">Uwagi</div>
                <p className="mt-3 text-sm leading-7 text-[#5b6881]">
                  {payload.customer.notes?.trim() || 'Dokument stanowi gotowy punkt wyjścia do rozmowy handlowej, porównania wariantów oraz finalizacji konfiguracji.'}
                </p>
              </div>
            </div>

            {payload.customer.financingDisclaimer ? (
              <div className="mt-5 rounded-[24px] border border-[rgba(157,123,39,0.16)] bg-[linear-gradient(180deg,#fff9ee_0%,#fffdf8_100%)] px-5 py-4 text-sm leading-7 text-[#6b654d]">
                {payload.customer.financingDisclaimer}
              </div>
            ) : null}
          </SectionCard>

          <div className="grid gap-6">
            <SectionCard
              eyebrow="Kontakt"
              title="Osoba odpowiedzialna za ofertę"
              description="W przypadku pytań, potrzeby korekty konfiguracji lub chęci zamówienia jazdy próbnej, kontakt odbywa się bezpośrednio z opiekunem dokumentu."
            >
              <div className="rounded-[28px] bg-[linear-gradient(145deg,#18325f_0%,#214b87_100%)] p-6 text-white shadow-[0_22px_60px_rgba(23,45,87,0.28)]">
                <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-white/62">{advisorRole}</div>
                <div className="mt-3 text-[30px] font-semibold leading-tight">{advisorName}</div>
                <div className="mt-4 text-sm leading-8 text-white/76">{advisorContactLine}</div>
              </div>

              <div className="mt-5 grid gap-3">
                <DetailTile label="Numer oferty" value={payload.customer.offerNumber} />
                <DetailTile label="Wersja dokumentu" value={String(document.version.versionNumber)} />
                <DetailTile label="Wygenerowano" value={formatDate(payload.createdAt)} />
                <DetailTile label="Ważna do" value={formatDate(payload.customer.validUntil ?? document.shareExpiresAt)} />
              </div>
            </SectionCard>

            <SectionCard
              eyebrow="Następny krok"
              title="Jak korzystać z tej oferty"
              description="To jest aktywny podgląd online. Link może służyć do spokojnego przejrzenia konfiguracji, porównania warunków i powrotu do rozmowy z doradcą."
            >
              <div className="grid gap-3">
                <div className="rounded-[22px] border border-[rgba(20,33,61,0.07)] bg-white/90 px-5 py-4 text-sm leading-7 text-[#56627a]">
                  1. Sprawdź model, cenę końcową i wariant finansowania.
                </div>
                <div className="rounded-[22px] border border-[rgba(20,33,61,0.07)] bg-white/90 px-5 py-4 text-sm leading-7 text-[#56627a]">
                  2. Obejrzyj galerię i otwórz specyfikację PDF, jeśli chcesz przejść do szczegółów technicznych.
                </div>
                <div className="rounded-[22px] border border-[rgba(20,33,61,0.07)] bg-white/90 px-5 py-4 text-sm leading-7 text-[#56627a]">
                  3. Skontaktuj się z opiekunem oferty, aby dopracować finansowanie lub finalny wariant zamówienia.
                </div>
              </div>
            </SectionCard>
          </div>
        </section>

        <SectionCard
          eyebrow="Galeria modelu"
          title={`Materiały dla konfiguracji ${modelLabel}`}
          description="Zestaw materiałów wizualnych wspierających ocenę finalnego wyglądu samochodu. Ta sekcja ma sprzedawać auto, a nie przypominać panel administracyjny."
        >
          {accentGallery.length > 0 ? (
            <div className="grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
              <div className="overflow-hidden rounded-[28px] border border-[rgba(20,33,61,0.08)] bg-[#eef3f9] shadow-[0_18px_50px_rgba(17,32,67,0.08)]">
                {/* eslint-disable-next-line @next/next/no-img-element -- product gallery uses static asset URLs */}
                <img src={accentGallery[0]} alt={modelLabel} className="h-[420px] w-full object-cover" />
              </div>
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-1">
                {accentGallery.slice(1).map((imageUrl) => (
                  <div key={imageUrl} className="overflow-hidden rounded-[24px] border border-[rgba(20,33,61,0.08)] bg-[#eef3f9] shadow-[0_16px_40px_rgba(17,32,67,0.07)]">
                    {/* eslint-disable-next-line @next/next/no-img-element -- product gallery uses static asset URLs */}
                    <img src={imageUrl} alt={modelLabel} className="h-[198px] w-full object-cover" />
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <div className="rounded-[26px] border border-dashed border-[rgba(20,33,61,0.14)] bg-[linear-gradient(180deg,#f8fbfe_0%,#f5f8fc_100%)] px-6 py-10 text-sm leading-8 text-[#5f6d87]">
              Ta oferta nie ma jeszcze kompletnej galerii. Sam link pozostaje aktywny, a opiekun może uzupełnić materiały lub dosłać dodatkową prezentację produktu.
            </div>
          )}
        </SectionCard>
      </div>
    </main>
  )
}