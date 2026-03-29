import type { ReactNode } from 'react'

export type OfferPdfPayload = {
  createdAt: string
  versionNumber: number
  customer: {
    offerNumber: string
    validUntil: string | null
    modelName: string | null
    title: string | null
    customerName: string
    customerEmail: string | null
    customerPhone: string | null
    selectedColorName: string | null
    financingVariant: string | null
    financingSummary: string | null
    financingDisclaimer: string | null
    listPriceLabel: string
    discountLabel: string
    discountPercentLabel: string
    finalGrossLabel: string
    finalNetLabel: string
    notes: string | null
  }
  internal: {
    financing: {
      estimatedInstallment: number
      downPaymentAmount: number
      downPaymentPercent: number
      buyoutAmount: number
      buyoutPercent: number
      termMonths: number
    } | null
  }
}

export type OfferPdfAssets = {
  logoUrl: string
  specPdfUrl: string | null
  images: {
    premium: string[]
    details: string[]
    interior: string[]
    exterior: string[]
    other: string[]
  }
}

function formatDate(value: string | null) {
  if (!value) {
    return 'Nie określono'
  }

  return new Intl.DateTimeFormat('pl-PL', { dateStyle: 'medium' }).format(new Date(value))
}

function formatMoney(value: number) {
  return new Intl.NumberFormat('pl-PL', {
    style: 'currency',
    currency: 'PLN',
    maximumFractionDigits: 2,
  }).format(value)
}

function buildGalleryTitle(modelName: string | null, variant: 'details' | 'interior' | 'exterior') {
  if (variant === 'details') {
    return `Akcenty modelu ${modelName ?? 'BYD'}`
  }

  if (variant === 'interior') {
    return `Kabina i wykończenie ${modelName ?? 'pojazdu'}`
  }

  return `Sylwetka i linia ${modelName ?? 'pojazdu'}`
}

function buildGalleryDescription(variant: 'details' | 'interior' | 'exterior') {
  if (variant === 'details') {
    return 'Wybrane ujęcia podkreślające materiały, światła i dopracowane detale samochodu.'
  }

  if (variant === 'interior') {
    return 'Wnętrze pokazane z perspektywy użytkownika: układ kokpitu, komfort i jakość wykończenia.'
  }

  return 'Zewnętrzne ujęcia nadwozia z różnych perspektyw, budujące finalne wrażenie modelu.'
}

function Page({ children }: { children: ReactNode }) {
  return <section className="pdf-a4-page">{children}</section>
}

function SectionHeading({ eyebrow, title, description }: { eyebrow: string; title: string; description?: string }) {
  return (
    <div className="pdf-a4-section-heading">
      <div className="pdf-a4-eyebrow">{eyebrow}</div>
      <h2 className="pdf-a4-title">{title}</h2>
      {description ? <p className="pdf-a4-description">{description}</p> : null}
    </div>
  )
}

function GallerySection({
  title,
  description,
  images,
}: {
  title: string
  description: string
  images: string[]
}) {
  if (images.length === 0) {
    return null
  }

  return (
    <section className="pdf-a4-gallery-section">
      <SectionHeading eyebrow="Galeria modelu" title={title} description={description} />
      <div className="pdf-a4-gallery-grid">
        {images.slice(0, 3).map((imageUrl, index) => (
          <figure key={imageUrl} className="pdf-a4-gallery-card">
            {/* eslint-disable-next-line @next/next/no-img-element -- html2pdf wymaga prostego img w klonowanym dokumencie */}
            <img src={imageUrl} alt={`${title} ${index + 1}`} className="pdf-a4-gallery-image" />
          </figure>
        ))}
      </div>
    </section>
  )
}

export function OfferPdfA4Document({
  payload,
  assets,
  studio = false,
}: {
  payload: OfferPdfPayload
  assets: OfferPdfAssets
  studio?: boolean
}) {
  const financing = payload.internal.financing
  const heroImage = assets.images.premium[0] ?? assets.images.exterior[0] ?? assets.images.other[0] ?? null
  const detailImages = assets.images.details.slice(0, 3)
  const interiorImages = assets.images.interior.slice(0, 3)
  const exteriorImages = assets.images.exterior.slice(0, 3)
  const notes = payload.customer.notes?.trim() ?? ''

  return (
    <section
      id="offer-pdf-document"
      data-offer-number={payload.customer.offerNumber}
      data-pdf-layout="a4"
      className={`pdf-a4-document-shell${studio ? ' pdf-a4-document-shell--studio' : ''}`}
    >
      <Page>
        <div className="pdf-a4-cover-glow" />
        <div className="pdf-a4-header-row">
          <div className="pdf-a4-brand-row">
            {/* eslint-disable-next-line @next/next/no-img-element -- html2pdf wymaga prostego img w klonowanym dokumencie */}
            <img src={assets.logoUrl} alt="VeloPrime" className="pdf-a4-logo" />
            <div className="pdf-a4-brand-copy">
              <div className="pdf-a4-eyebrow">VeloPrime</div>
              <div className="pdf-a4-subtitle">Oferta indywidualna dla klienta</div>
            </div>
          </div>

          <div className="pdf-a4-meta-box">
            <div>Wersja: {payload.versionNumber}</div>
            <div>Wygenerowano: {formatDate(payload.createdAt)}</div>
            <div>Ważna do: {formatDate(payload.customer.validUntil)}</div>
          </div>
        </div>

        <div className="pdf-a4-cover-layout">
          <div className="pdf-a4-cover-copy">
            <div className="pdf-a4-eyebrow">{payload.customer.offerNumber}</div>
            <h1 className="pdf-a4-hero-title">{payload.customer.modelName ?? payload.customer.title}</h1>
            <p className="pdf-a4-hero-description">
              Oferta przygotowana dla {payload.customer.customerName} z wybraną konfiguracją, finansowaniem i zestawem materiałów produktowych VeloPrime.
            </p>

            <div className="pdf-a4-chip-row">
              <span className="pdf-a4-chip">Klient: {payload.customer.customerName}</span>
              <span className="pdf-a4-chip">Kolor: {payload.customer.selectedColorName ?? 'Bazowy'}</span>
              <span className="pdf-a4-chip">Finansowanie: {payload.customer.financingVariant ?? 'Indywidualnie ustalane'}</span>
            </div>
          </div>

          <div className="pdf-a4-hero-stage">
            {heroImage ? (
              /* eslint-disable-next-line @next/next/no-img-element -- html2pdf wymaga prostego img w klonowanym dokumencie */
              <img src={heroImage} alt={payload.customer.modelName ?? 'Oferta samochodu'} className="pdf-a4-hero-image" />
            ) : (
              <div className="pdf-a4-hero-image pdf-a4-hero-image--placeholder">
                Grafika modelu będzie dostępna po przypisaniu kompletu materiałów do tej konfiguracji.
              </div>
            )}
          </div>
        </div>

        <div className="pdf-a4-cover-prices">
          <div className="pdf-a4-price-card pdf-a4-price-card--gross">
            <div className="pdf-a4-card-label">Cena końcowa brutto</div>
            <div className="pdf-a4-price-value">{payload.customer.finalGrossLabel}</div>
          </div>
          <div className="pdf-a4-price-card pdf-a4-price-card--net">
            <div className="pdf-a4-card-label">Cena końcowa netto</div>
            <div className="pdf-a4-price-value">{payload.customer.finalNetLabel}</div>
          </div>
        </div>

        <div className="pdf-a4-cover-bottom-grid">
          <article className="pdf-a4-info-card pdf-a4-info-card--cover">
            <div className="pdf-a4-card-label pdf-a4-card-label--gold">Klient</div>
            <div className="pdf-a4-info-list">
              <div><span>Nazwa:</span> {payload.customer.customerName}</div>
              <div><span>E-mail:</span> {payload.customer.customerEmail ?? 'Nie podano'}</div>
              <div><span>Telefon:</span> {payload.customer.customerPhone ?? 'Nie podano'}</div>
            </div>
          </article>

          <article className="pdf-a4-info-card pdf-a4-info-card--cover pdf-a4-info-card--green">
            <div className="pdf-a4-card-label pdf-a4-card-label--green">Konfiguracja</div>
            <div className="pdf-a4-info-list">
              <div><span>Model:</span> {payload.customer.modelName ?? 'Nie określono'}</div>
              <div><span>Kolor:</span> {payload.customer.selectedColorName ?? 'Bazowy'}</div>
              <div><span>Finansowanie:</span> {payload.customer.financingSummary ?? payload.customer.financingVariant ?? 'Warunki ustalane indywidualnie'}</div>
              <div><span>Ważność oferty:</span> {formatDate(payload.customer.validUntil)}</div>
            </div>
          </article>
        </div>
      </Page>

      <Page>
        <SectionHeading
          eyebrow="Oferta"
          title="Podsumowanie oferty"
          description="Najważniejsze parametry handlowe przygotowane dla tej wersji dokumentu, wraz z prezentacją warunków finansowych."
        />

        <div className="pdf-a4-summary-grid pdf-a4-summary-grid--single">
          <aside className="pdf-a4-info-card pdf-a4-info-card--summary pdf-a4-info-card--summary-wide">
            <div className="pdf-a4-card-label pdf-a4-card-label--gold">Podsumowanie ceny</div>
            <div className="pdf-a4-info-list pdf-a4-info-list--tight">
              <div><span>Cena katalogowa</span><strong>{payload.customer.listPriceLabel}</strong></div>
              <div><span>Rabat</span><strong>{payload.customer.discountLabel}</strong></div>
              <div><span>Rabat %</span><strong>{payload.customer.discountPercentLabel}</strong></div>
            </div>
            <div className="pdf-a4-summary-footer">
              <div><span>Cena końcowa brutto</span><strong>{payload.customer.finalGrossLabel}</strong></div>
              <div><span>Cena końcowa netto</span><strong>{payload.customer.finalNetLabel}</strong></div>
            </div>
          </aside>
        </div>

        <div className="pdf-a4-financing-block">
          <SectionHeading
            eyebrow="Finansowanie"
            title="Przedstawione warunki finansowe"
            description="Orientacyjne warunki finansowania dla wybranej konfiguracji. Ostateczne parametry są potwierdzane indywidualnie na etapie finalizacji oferty."
          />

          <div className="pdf-a4-financing-grid">
            <article className="pdf-a4-info-card pdf-a4-info-card--violet">
              <div className="pdf-a4-card-label pdf-a4-card-label--violet">Wariant</div>
              <div className="pdf-a4-financing-value">{payload.customer.financingVariant ?? 'Brak'}</div>
            </article>
            <article className="pdf-a4-info-card pdf-a4-info-card--violet">
              <div className="pdf-a4-card-label pdf-a4-card-label--violet">Szacowana rata</div>
              <div className="pdf-a4-financing-value">{financing ? formatMoney(financing.estimatedInstallment) : 'Indywidualnie ustalana'}</div>
            </article>
            <article className="pdf-a4-info-card pdf-a4-info-card--violet">
              <div className="pdf-a4-card-label pdf-a4-card-label--violet">Wpłata własna</div>
              <div className="pdf-a4-financing-value">{financing ? formatMoney(financing.downPaymentAmount) : 'Indywidualnie ustalana'}</div>
              <div className="pdf-a4-financing-meta">{financing ? `${financing.downPaymentPercent.toFixed(2).replace('.', ',')}%` : ''}</div>
            </article>
            <article className="pdf-a4-info-card pdf-a4-info-card--violet">
              <div className="pdf-a4-card-label pdf-a4-card-label--violet">Wykup i okres</div>
              <div className="pdf-a4-financing-value">{financing ? formatMoney(financing.buyoutAmount) : 'Indywidualnie ustalane'}</div>
              <div className="pdf-a4-financing-meta">{financing ? `${financing.buyoutPercent.toFixed(2).replace('.', ',')}% • ${financing.termMonths} mies.` : ''}</div>
            </article>
          </div>

          {payload.customer.financingDisclaimer ? (
            <div className="pdf-a4-disclaimer">{payload.customer.financingDisclaimer}</div>
          ) : null}

          {notes ? (
            <div className="pdf-a4-notes-box">
              <div className="pdf-a4-card-label pdf-a4-card-label--gold">Uwagi do oferty</div>
              <p>{notes}</p>
            </div>
          ) : null}
        </div>
      </Page>

      <Page>
        <GallerySection
          title={buildGalleryTitle(payload.customer.modelName, 'details')}
          description={buildGalleryDescription('details')}
          images={detailImages}
        />
        <GallerySection
          title={buildGalleryTitle(payload.customer.modelName, 'interior')}
          description={buildGalleryDescription('interior')}
          images={interiorImages}
        />
        <GallerySection
          title={buildGalleryTitle(payload.customer.modelName, 'exterior')}
          description={buildGalleryDescription('exterior')}
          images={exteriorImages}
        />
      </Page>
    </section>
  )
}
