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

function buildContactLine(customer: OfferPdfPayload['customer']) {
  const parts = [customer.customerEmail, customer.customerPhone].filter(Boolean)

  if (parts.length === 0) {
    return 'Dane kontaktowe zostaną potwierdzone na etapie rozmowy handlowej.'
  }

  return parts.join(' • ')
}

function buildOfferNarrative(payload: OfferPdfPayload) {
  const financingSummary = payload.customer.financingSummary ?? payload.customer.financingVariant ?? 'warunki ustalane indywidualnie'
  const modelName = payload.customer.modelName ?? payload.customer.title ?? 'tej konfiguracji'

  return `Konfiguracja ${modelName} została przygotowana dla ${payload.customer.customerName}. Punkt wyjścia do rozmowy stanowi cena końcowa ${payload.customer.finalGrossLabel} brutto oraz scenariusz finansowania: ${financingSummary}.`
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
  const offerHeadline = payload.customer.modelName ?? payload.customer.title ?? 'Oferta VeloPrime'
  const financingSummary = payload.customer.financingSummary ?? payload.customer.financingVariant ?? 'Warunki ustalane indywidualnie'
  const contactLine = buildContactLine(payload.customer)
  const coverBriefItems = [
    { label: 'Dla klienta', value: payload.customer.customerName },
    { label: 'Kontakt', value: contactLine },
    { label: 'Konfiguracja', value: payload.customer.selectedColorName ?? 'Kolor bazowy' },
    { label: 'Finansowanie', value: financingSummary },
  ]
  const galleryImageCount = detailImages.length + interiorImages.length + exteriorImages.length

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
            <div className="pdf-a4-offer-kicker">Dokument handlowy • konfiguracja gotowa do rozmowy</div>
            <div className="pdf-a4-eyebrow">{payload.customer.offerNumber}</div>
            <h1 className="pdf-a4-hero-title">{offerHeadline}</h1>
            <p className="pdf-a4-hero-description">
              Oferta przygotowana dla {payload.customer.customerName} z wybraną konfiguracją, finansowaniem i zestawem materiałów produktowych VeloPrime.
            </p>

            <div className="pdf-a4-chip-row">
              <span className="pdf-a4-chip">Klient: {payload.customer.customerName}</span>
              <span className="pdf-a4-chip">Kolor: {payload.customer.selectedColorName ?? 'Bazowy'}</span>
              <span className="pdf-a4-chip">Finansowanie: {payload.customer.financingVariant ?? 'Indywidualnie ustalane'}</span>
            </div>

            <div className="pdf-a4-cover-brief-grid">
              {coverBriefItems.map((item) => (
                <article key={item.label} className="pdf-a4-brief-card">
                  <div className="pdf-a4-brief-label">{item.label}</div>
                  <div className="pdf-a4-brief-value">{item.value}</div>
                </article>
              ))}
            </div>
          </div>

          <div className="pdf-a4-hero-stage">
            <div className="pdf-a4-hero-panel">
              {heroImage ? (
                /* eslint-disable-next-line @next/next/no-img-element -- html2pdf wymaga prostego img w klonowanym dokumencie */
                <img src={heroImage} alt={payload.customer.modelName ?? 'Oferta samochodu'} className="pdf-a4-hero-image" />
              ) : (
                <div className="pdf-a4-hero-image pdf-a4-hero-image--placeholder">
                  Grafika modelu będzie dostępna po przypisaniu kompletu materiałów do tej konfiguracji.
                </div>
              )}

              <div className="pdf-a4-hero-caption">
                <div className="pdf-a4-card-label pdf-a4-card-label--gold">Wybrana konfiguracja</div>
                <div className="pdf-a4-hero-caption-title">{payload.customer.selectedColorName ?? offerHeadline}</div>
                <div className="pdf-a4-hero-caption-copy">{financingSummary}</div>
              </div>
            </div>
          </div>
        </div>

        <div className="pdf-a4-cover-prices">
          <div className="pdf-a4-price-card pdf-a4-price-card--gross">
            <div className="pdf-a4-card-label">Cena końcowa brutto</div>
            <div className="pdf-a4-price-value">{payload.customer.finalGrossLabel}</div>
            <div className="pdf-a4-price-subtext">Po uwzględnieniu rabatu {payload.customer.discountLabel} ({payload.customer.discountPercentLabel}).</div>
          </div>
          <div className="pdf-a4-price-card pdf-a4-price-card--net">
            <div className="pdf-a4-card-label">Cena końcowa netto</div>
            <div className="pdf-a4-price-value">{payload.customer.finalNetLabel}</div>
            <div className="pdf-a4-price-subtext">Oferta pozostawia przestrzeń do omówienia finansowania i warunków finalnych.</div>
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
              <div><span>Model:</span> {offerHeadline}</div>
              <div><span>Kolor:</span> {payload.customer.selectedColorName ?? 'Bazowy'}</div>
              <div><span>Finansowanie:</span> {payload.customer.financingSummary ?? payload.customer.financingVariant ?? 'Warunki ustalane indywidualnie'}</div>
              <div><span>Ważność oferty:</span> {formatDate(payload.customer.validUntil)}</div>
            </div>
          </article>

          <article className="pdf-a4-info-card pdf-a4-info-card--cover pdf-a4-info-card--bronze">
            <div className="pdf-a4-card-label pdf-a4-card-label--gold">Oferta i terminy</div>
            <div className="pdf-a4-info-list">
              <div><span>Numer:</span> {payload.customer.offerNumber}</div>
              <div><span>Wersja:</span> {payload.versionNumber}</div>
              <div><span>Wygenerowano:</span> {formatDate(payload.createdAt)}</div>
              <div><span>Kontakt:</span> {contactLine}</div>
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

        <div className="pdf-a4-summary-grid pdf-a4-summary-grid--deal">
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

          <article className="pdf-a4-info-card pdf-a4-info-card--bronze pdf-a4-story-card">
            <div className="pdf-a4-card-label pdf-a4-card-label--gold">Narracja oferty</div>
            <h3 className="pdf-a4-story-title">Konfiguracja przygotowana do rozmowy z klientem</h3>
            <p className="pdf-a4-story-copy">{buildOfferNarrative(payload)}</p>
            <div className="pdf-a4-story-tags">
              <span className="pdf-a4-chip">Model: {offerHeadline}</span>
              <span className="pdf-a4-chip">Kolor: {payload.customer.selectedColorName ?? 'Bazowy'}</span>
              <span className="pdf-a4-chip">Ważność: {formatDate(payload.customer.validUntil)}</span>
            </div>
          </article>
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

          <div className="pdf-a4-note-grid">
            <div className="pdf-a4-notes-box">
              <div className="pdf-a4-card-label pdf-a4-card-label--gold">Uwagi do oferty</div>
              <p>{notes || 'Ta wersja dokumentu jest gotowym punktem wyjścia do rozmowy, doprecyzowania warunków i finalizacji decyzji zakupowej.'}</p>
            </div>
            <div className="pdf-a4-notes-box pdf-a4-notes-box--soft">
              <div className="pdf-a4-card-label pdf-a4-card-label--green">Zakres rozmowy z klientem</div>
              <p>Dokument zbiera konfigurację, poziom ceny końcowej i proponowany scenariusz finansowania. Finalne warunki mogą zostać doprecyzowane w trakcie spotkania lub dalszych uzgodnień.</p>
            </div>
          </div>
        </div>
      </Page>

      <Page>
        <SectionHeading
          eyebrow="Materiały sprzedażowe"
          title={`Galeria modelu ${offerHeadline}`}
          description="Zestaw materiałów produktowych do rozmowy z klientem, prezentacji samochodu i domknięcia decyzji zakupowej."
        />

        {galleryImageCount === 0 ? (
          <div className="pdf-a4-gallery-empty">
            Materiały modelu nie są jeszcze przypisane do tej konfiguracji. Dokument zachowuje układ PDF, ale galeria zostanie uzupełniona po dodaniu assetów produktowych.
          </div>
        ) : null}

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
