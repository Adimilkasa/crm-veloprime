'use client'

import Link from 'next/link'
import { useEffect, useMemo, useRef, useState } from 'react'
import { useRouter } from 'next/navigation'
import { ExternalLink, FileDown, FilePlus2, FileSpreadsheet, Palette, Search, Sparkles, X } from 'lucide-react'

import { calculateOfferSummary, type OfferCalculationSummary, type SharedCommissionRule, type SharedManagedUser } from '@/lib/offer-calculations-shared'
import { calculateOfferFinancing, type FinancingInputMode } from '@/lib/offer-financing-shared'

type OfferStatus = 'DRAFT' | 'SENT' | 'APPROVED' | 'REJECTED' | 'EXPIRED'
type OfferCustomerType = 'PRIVATE' | 'BUSINESS'

type ManagedOffer = {
  id: string
  number: string
  status: OfferStatus
  title: string
  leadId: string | null
  customerName: string
  customerEmail: string | null
  customerPhone: string | null
  modelName: string | null
  pricingCatalogKey: string | null
  selectedColorName: string | null
  customerType: OfferCustomerType
  discountValue: number | null
  ownerId: string
  ownerName: string
  validUntil: string | null
  totalGross: number | null
  totalNet: number | null
  financingVariant: string | null
  financingTermMonths: number | null
  financingInputMode: 'AMOUNT' | 'PERCENT'
  financingInputValue: number | null
  financingBuyoutPercent: number | null
  notes: string | null
  versions: Array<{
    id: string
    versionNumber: number
    summary: string
    createdAt: string
    pdfUrl: string | null
  }>
  createdAt: string
  updatedAt: string
  calculation: OfferCalculationSummary | null
}

type OfferLeadOption = {
  id: string
  label: string
  modelName: string | null
  contact: string | null
  ownerName: string | null
}

type OfferPricingOption = {
  key: string
  label: string
  brand: string
  model: string
  version: string
  year: string | null
  powertrain: string | null
  powerHp: string | null
  listPriceGross: number | null
  listPriceNet: number | null
  basePriceGross: number | null
  basePriceNet: number | null
  marginPoolGross: number | null
  marginPoolNet: number | null
}

type OfferColorPalette = {
  paletteKey: string
  brand: string
  model: string
  baseColorName: string
  optionalColorSurchargeGross: number | null
  optionalColorSurchargeNet: number | null
  colors: Array<{
    name: string
    isBase: boolean
    surchargeGross: number | null
    surchargeNet: number | null
    sortOrder: number
  }>
}

function buildPaletteKey(brand: string, model: string) {
  return `${brand.trim().toLowerCase()}::${model.trim().toLowerCase()}`
}

function formatDate(value: string | null) {
  if (!value) {
    return 'Brak'
  }

  return new Intl.DateTimeFormat('pl-PL', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

function formatMoney(value: number | null) {
  if (value === null) {
    return 'Do ustalenia'
  }

  return new Intl.NumberFormat('pl-PL', {
    style: 'currency',
    currency: 'PLN',
    maximumFractionDigits: 2,
  }).format(value)
}

function formatPercentValue(value: number | null) {
  if (value === null) {
    return 'Do ustalenia'
  }

  return `${value.toFixed(2).replace('.', ',')}%`
}

function Overlay({ title, onClose, children }: { title: string; onClose: () => void; children: React.ReactNode }) {
  return (
    <div className="fixed inset-0 z-50 bg-[rgba(3,6,10,0.68)] p-4 backdrop-blur-sm lg:p-8">
      <div className="mx-auto flex h-full w-full max-w-3xl flex-col overflow-hidden rounded-[28px] border border-white/8 bg-[#0f151d] shadow-[0_30px_80px_rgba(0,0,0,0.34)]">
        <div className="flex items-center justify-between gap-4 border-b border-white/8 px-5 py-4">
          <div>
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Oferty PDF</div>
            <h2 className="mt-1 text-xl font-semibold text-white">{title}</h2>
          </div>
          <button type="button" onClick={onClose} className="inline-flex h-10 w-10 items-center justify-center rounded-2xl border border-white/8 bg-white/[0.03] text-[#d5dce5] transition hover:bg-white/[0.08]">
            <X className="h-4 w-4" />
          </button>
        </div>
        <div className="overflow-y-auto px-5 py-5">{children}</div>
      </div>
    </div>
  )
}

function getStatusTone(status: OfferStatus) {
  switch (status) {
    case 'APPROVED':
      return 'border-emerald-400/20 bg-emerald-500/10 text-emerald-200'
    case 'SENT':
      return 'border-sky-400/20 bg-sky-500/10 text-sky-100'
    case 'REJECTED':
      return 'border-red-400/20 bg-red-500/10 text-red-200'
    case 'EXPIRED':
      return 'border-white/10 bg-white/[0.04] text-[#c2cad4]'
    default:
      return 'border-amber-400/20 bg-amber-500/10 text-amber-100'
  }
}

function CalculationCard({ offer }: { offer: ManagedOffer }) {
  if (!offer.calculation) {
    return (
      <section className="rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:p-5">
        <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Kalkulacja marży</div>
        <div className="mt-4 rounded-[24px] border border-dashed border-white/10 bg-white/[0.03] px-4 py-12 text-center text-sm text-[#7f8a97]">
          Wybierz konfigurację z polityki cenowej, aby system policzył pulę, udział dyrektora, managera i prowizję handlowca.
        </div>
      </section>
    )
  }

  const calc = offer.calculation

  return (
    <section className="rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:p-5">
      <div className="flex items-center justify-between gap-3">
        <div>
          <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Kalkulacja marży</div>
          <div className="mt-1 text-sm text-[#9ba6b2]">{calc.catalogLabel}</div>
        </div>
        <div className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#aeb7c2]">
          {calc.customerType === 'BUSINESS' ? 'Firma / netto' : 'Klient prywatny / brutto'}
        </div>
      </div>

      <div className="mt-4 grid gap-3 md:grid-cols-2">
        <div className="rounded-[22px] border border-white/8 bg-white/[0.03] p-4">
          <div className="text-xs uppercase tracking-[0.16em] text-[#8b96a3]">Cena katalogowa</div>
          <div className="mt-2 text-lg font-semibold text-white">{formatMoney(calc.customerType === 'BUSINESS' ? calc.listPriceNet : calc.listPriceGross)}</div>
        </div>
        <div className="rounded-[22px] border border-white/8 bg-white/[0.03] p-4">
          <div className="text-xs uppercase tracking-[0.16em] text-[#8b96a3]">Cena bazowa</div>
          <div className="mt-2 text-lg font-semibold text-white">{formatMoney(calc.customerType === 'BUSINESS' ? calc.basePriceNet : calc.basePriceGross)}</div>
        </div>
        <div className="rounded-[22px] border border-amber-400/20 bg-amber-500/10 p-4">
          <div className="text-xs uppercase tracking-[0.16em] text-amber-100">Pula całkowita</div>
          <div className="mt-2 text-lg font-semibold text-white">{formatMoney(calc.customerType === 'BUSINESS' ? calc.marginPoolNet : calc.marginPoolGross)}</div>
        </div>
        <div className="rounded-[22px] border border-emerald-400/20 bg-emerald-500/10 p-4">
          <div className="text-xs uppercase tracking-[0.16em] text-emerald-100">Dostępny rabat / prowizja handlowca</div>
          <div className="mt-2 text-lg font-semibold text-white">{formatMoney(calc.availableDiscount)}</div>
        </div>
      </div>

      <div className="mt-3 rounded-[22px] border border-sky-400/20 bg-sky-500/10 p-4">
        <div className="flex items-center justify-between gap-3 text-xs uppercase tracking-[0.16em] text-sky-100">
          <span>Lakier</span>
          <span>{calc.selectedColorName ?? calc.baseColorName ?? 'Brak palety'}</span>
        </div>
        <div className="mt-2 text-lg font-semibold text-white">
          {formatMoney(calc.customerType === 'BUSINESS' ? calc.colorSurchargeNet : calc.colorSurchargeGross)}
        </div>
      </div>

      <div className="mt-4 grid gap-3 rounded-[24px] border border-white/8 bg-[#10161d] p-4 text-sm text-[#d5dce5]">
        <div className="flex items-center justify-between gap-3">
          <span>Dyrektor {calc.directorName ? `(${calc.directorName})` : ''}</span>
          <span>{formatMoney(calc.directorShare)}</span>
        </div>
        <div className="flex items-center justify-between gap-3">
          <span>Manager {calc.managerName ? `(${calc.managerName})` : ''}</span>
          <span>{formatMoney(calc.managerShare)}</span>
        </div>
        <div className="flex items-center justify-between gap-3">
          <span>Rabat klienta</span>
          <span>{formatMoney(calc.appliedDiscount)}</span>
        </div>
        <div className="flex items-center justify-between gap-3 border-t border-white/8 pt-3 font-semibold text-white">
          <span>Prowizja handlowca</span>
          <span>{formatMoney(calc.salespersonCommission)}</span>
        </div>
      </div>
    </section>
  )
}

function FinancingPreviewCard({
  customerType,
  finalPriceGross,
  finalPriceNet,
  termMonths,
  inputMode,
  inputValue,
  buyoutPercent,
}: {
  customerType: OfferCustomerType
  finalPriceGross: number | null
  finalPriceNet: number | null
  termMonths: number | null
  inputMode: FinancingInputMode
  inputValue: number | null
  buyoutPercent: number | null
}) {
  const financing = calculateOfferFinancing({
    customerType,
    finalPriceGross,
    finalPriceNet,
    termMonths,
    downPaymentInputMode: inputMode,
    downPaymentInputValue: inputValue,
    buyoutPercent,
  })

  return (
    <section className="rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:p-5">
      <div className="flex items-center justify-between gap-3">
        <div>
          <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Podgląd finansowania</div>
          <div className="mt-1 text-sm text-[#9ba6b2]">Podgląd liczy się od aktualnej ceny oferty widocznej po prawej stronie.</div>
        </div>
        <div className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#aeb7c2]">
          {customerType === 'BUSINESS' ? 'Podstawa netto' : 'Podstawa brutto'}
        </div>
      </div>

      {!termMonths || inputValue === null || buyoutPercent === null ? (
        <div className="mt-4 rounded-[22px] border border-dashed border-white/10 bg-white/[0.03] px-4 py-8 text-center text-sm text-[#7f8a97]">
          Uzupełnij okres, wpłatę własną i wykup, aby zobaczyć szacowaną ratę.
        </div>
      ) : financing && !financing.ok ? (
        <div className="mt-4 rounded-[22px] border border-red-400/20 bg-red-500/10 px-4 py-4 text-sm text-red-200">
          {financing.error}
        </div>
      ) : financing && financing.ok ? (
        <div className="mt-4 grid gap-3 md:grid-cols-2">
          <div className="rounded-[22px] border border-emerald-400/20 bg-emerald-500/10 p-4">
            <div className="text-xs uppercase tracking-[0.16em] text-emerald-100">Szacowana rata</div>
            <div className="mt-2 text-lg font-semibold text-white">{formatMoney(financing.summary.estimatedInstallment)}</div>
          </div>
          <div className="rounded-[22px] border border-white/8 bg-white/[0.03] p-4">
            <div className="text-xs uppercase tracking-[0.16em] text-[#8b96a3]">Okres</div>
            <div className="mt-2 text-lg font-semibold text-white">{financing.summary.termMonths} mies.</div>
          </div>
          <div className="rounded-[22px] border border-white/8 bg-white/[0.03] p-4">
            <div className="text-xs uppercase tracking-[0.16em] text-[#8b96a3]">Wpłata własna</div>
            <div className="mt-2 text-lg font-semibold text-white">{formatMoney(financing.summary.downPaymentAmount)}</div>
            <div className="mt-1 text-sm text-[#9ba6b2]">{formatPercentValue(financing.summary.downPaymentPercent)}</div>
          </div>
          <div className="rounded-[22px] border border-white/8 bg-white/[0.03] p-4">
            <div className="text-xs uppercase tracking-[0.16em] text-[#8b96a3]">Wykup</div>
            <div className="mt-2 text-lg font-semibold text-white">{formatMoney(financing.summary.buyoutAmount)}</div>
            <div className="mt-1 text-sm text-[#9ba6b2]">{formatPercentValue(financing.summary.buyoutPercent)}</div>
          </div>
        </div>
      ) : (
        <div className="mt-4 rounded-[22px] border border-dashed border-white/10 bg-white/[0.03] px-4 py-8 text-center text-sm text-[#7f8a97]">
          Nie można policzyć finansowania dla bieżącej oferty.
        </div>
      )}
    </section>
  )
}

export function OffersWorkspace({
  offers,
  leadOptions,
  pricingOptions,
  colorPalettes,
  salesUsers,
  commissionRules,
  pricingSnapshot,
  roleLabel,
  statusOptions,
  createOfferAction,
  updateOfferAction,
  createOfferVersionAction,
}: {
  offers: ManagedOffer[]
  leadOptions: OfferLeadOption[]
  pricingOptions: OfferPricingOption[]
  colorPalettes: OfferColorPalette[]
  salesUsers: SharedManagedUser[]
  commissionRules: SharedCommissionRule[]
  pricingSnapshot: {
    headersCount: number
    rowsCount: number
    updatedAt: string | null
    updatedBy: string | null
  }
  roleLabel: string
  statusOptions: Array<{ value: OfferStatus; label: string }>
  createOfferAction: (formData: FormData) => Promise<{ ok: boolean; error?: string; offerId?: string }>
  updateOfferAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
  createOfferVersionAction: (formData: FormData) => Promise<{ ok: boolean; error?: string; versionId?: string; pdfUrl?: string }>
}) {
  const router = useRouter()
  const [selectedOfferId, setSelectedOfferId] = useState<string | null>(offers[0]?.id ?? null)
  const [isCreateOpen, setCreateOpen] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState<OfferStatus | 'ALL'>('ALL')
  const [createFeedback, setCreateFeedback] = useState<string | null>(null)
  const [editorFeedback, setEditorFeedback] = useState<string | null>(null)
  const [createPricingCatalogKey, setCreatePricingCatalogKey] = useState('')
  const [createSelectedColorName, setCreateSelectedColorName] = useState('')
  const [editorPricingCatalogKey, setEditorPricingCatalogKey] = useState(offers[0]?.pricingCatalogKey ?? '')
  const [editorSelectedColorName, setEditorSelectedColorName] = useState(offers[0]?.selectedColorName ?? '')
  const [editorCustomerType, setEditorCustomerType] = useState<OfferCustomerType>(offers[0]?.customerType ?? 'PRIVATE')
  const [editorFinancingInputMode, setEditorFinancingInputMode] = useState<FinancingInputMode>(offers[0]?.financingInputMode ?? 'PERCENT')
  const [editorFinancingTermMonths, setEditorFinancingTermMonths] = useState<string>(offers[0]?.financingTermMonths ? String(offers[0].financingTermMonths) : '')
  const [editorFinancingInputValue, setEditorFinancingInputValue] = useState<string>(offers[0]?.financingInputValue !== null && offers[0]?.financingInputValue !== undefined ? String(offers[0].financingInputValue) : '')
  const [editorFinancingBuyoutPercent, setEditorFinancingBuyoutPercent] = useState<string>(offers[0]?.financingBuyoutPercent !== null && offers[0]?.financingBuyoutPercent !== undefined ? String(offers[0].financingBuyoutPercent) : '')
  const [editorTitle, setEditorTitle] = useState(offers[0]?.title ?? '')
  const [editorValidUntil, setEditorValidUntil] = useState(offers[0]?.validUntil ? offers[0].validUntil.slice(0, 10) : '')
  const [editorDiscountValue, setEditorDiscountValue] = useState(offers[0]?.discountValue !== null && offers[0]?.discountValue !== undefined ? String(offers[0].discountValue) : '')
  const [editorFinancingVariant, setEditorFinancingVariant] = useState(offers[0]?.financingVariant ?? '')
  const [editorNotes, setEditorNotes] = useState(offers[0]?.notes ?? '')
  const createFormRef = useRef<HTMLFormElement>(null)

  const pricingOptionsByKey = useMemo(() => new Map(pricingOptions.map((option) => [option.key, option])), [pricingOptions])
  const colorPalettesByKey = useMemo(() => new Map(colorPalettes.map((palette) => [palette.paletteKey, palette])), [colorPalettes])

  const filteredOffers = useMemo(() => {
    const normalizedQuery = searchQuery.trim().toLowerCase()

    return offers.filter((offer) => {
      const matchesStatus = statusFilter === 'ALL' || offer.status === statusFilter
      const matchesQuery = !normalizedQuery || [
        offer.number,
        offer.title,
        offer.customerName,
        offer.customerEmail,
        offer.customerPhone,
        offer.modelName,
        offer.ownerName,
      ].some((value) => value?.toLowerCase().includes(normalizedQuery))

      return matchesStatus && matchesQuery
    })
  }, [offers, searchQuery, statusFilter])

  const selectedOffer = filteredOffers.find((offer) => offer.id === selectedOfferId) ?? offers.find((offer) => offer.id === selectedOfferId) ?? null
  const selectedEditorPalette = editorPricingCatalogKey
    ? (() => {
        const option = pricingOptionsByKey.get(editorPricingCatalogKey)
        return option ? colorPalettesByKey.get(buildPaletteKey(option.brand, option.model)) ?? null : null
      })()
    : null
  const selectedCreatePalette = createPricingCatalogKey
    ? (() => {
        const option = pricingOptionsByKey.get(createPricingCatalogKey)
        return option ? colorPalettesByKey.get(buildPaletteKey(option.brand, option.model)) ?? null : null
      })()
    : null
  const offerStats = {
    all: offers.length,
    draft: offers.filter((offer) => offer.status === 'DRAFT').length,
    sent: offers.filter((offer) => offer.status === 'SENT').length,
    approved: offers.filter((offer) => offer.status === 'APPROVED').length,
  }

  useEffect(() => {
    setEditorPricingCatalogKey(selectedOffer?.pricingCatalogKey ?? '')
    setEditorSelectedColorName(selectedOffer?.selectedColorName ?? '')
    setEditorCustomerType(selectedOffer?.customerType ?? 'PRIVATE')
    setEditorFinancingInputMode(selectedOffer?.financingInputMode ?? 'PERCENT')
    setEditorFinancingTermMonths(selectedOffer?.financingTermMonths ? String(selectedOffer.financingTermMonths) : '')
    setEditorFinancingInputValue(selectedOffer?.financingInputValue !== null && selectedOffer?.financingInputValue !== undefined ? String(selectedOffer.financingInputValue) : '')
    setEditorFinancingBuyoutPercent(selectedOffer?.financingBuyoutPercent !== null && selectedOffer?.financingBuyoutPercent !== undefined ? String(selectedOffer.financingBuyoutPercent) : '')
    setEditorTitle(selectedOffer?.title ?? '')
    setEditorValidUntil(selectedOffer?.validUntil ? selectedOffer.validUntil.slice(0, 10) : '')
    setEditorDiscountValue(selectedOffer?.discountValue !== null && selectedOffer?.discountValue !== undefined ? String(selectedOffer.discountValue) : '')
    setEditorFinancingVariant(selectedOffer?.financingVariant ?? '')
    setEditorNotes(selectedOffer?.notes ?? '')
  }, [selectedOffer?.id, selectedOffer?.pricingCatalogKey, selectedOffer?.selectedColorName])

  const liveFinancingTermMonths = editorFinancingTermMonths.trim() ? Number(editorFinancingTermMonths) : null
  const liveFinancingInputValue = editorFinancingInputValue.trim() ? Number(editorFinancingInputValue) : null
  const liveFinancingBuyoutPercent = editorFinancingBuyoutPercent.trim() ? Number(editorFinancingBuyoutPercent) : null
  const liveDiscountValue = editorDiscountValue.trim() ? Number(editorDiscountValue) : null
  const selectedEditorPricingOption = editorPricingCatalogKey ? pricingOptionsByKey.get(editorPricingCatalogKey) ?? null : null
  const liveCalculation = useMemo(() => {
    if (!selectedOffer || !selectedEditorPricingOption) {
      return null
    }

    return calculateOfferSummary({
      catalogItem: selectedEditorPricingOption,
      ownerId: selectedOffer.ownerId,
      users: salesUsers,
      commissionRules,
      customerType: editorCustomerType,
      discountValue: liveDiscountValue !== null && !Number.isNaN(liveDiscountValue) ? liveDiscountValue : null,
      colorPalette: selectedEditorPalette,
      selectedColorName: editorSelectedColorName,
    })
  }, [commissionRules, editorCustomerType, editorSelectedColorName, liveDiscountValue, salesUsers, selectedEditorPalette, selectedEditorPricingOption, selectedOffer])
  const previewOffer = selectedOffer
    ? {
        ...selectedOffer,
        title: editorTitle,
        modelName: selectedEditorPricingOption ? `${selectedEditorPricingOption.brand} ${selectedEditorPricingOption.model} ${selectedEditorPricingOption.version}` : selectedOffer.modelName,
        selectedColorName: editorSelectedColorName || selectedOffer.selectedColorName,
        customerType: editorCustomerType,
        discountValue: liveDiscountValue !== null && !Number.isNaN(liveDiscountValue) ? liveDiscountValue : null,
        validUntil: editorValidUntil || null,
        financingVariant: editorFinancingVariant || null,
        financingTermMonths: liveFinancingTermMonths !== null && !Number.isNaN(liveFinancingTermMonths) ? liveFinancingTermMonths : null,
        financingInputMode: editorFinancingInputMode,
        financingInputValue: liveFinancingInputValue !== null && !Number.isNaN(liveFinancingInputValue) ? liveFinancingInputValue : null,
        financingBuyoutPercent: liveFinancingBuyoutPercent !== null && !Number.isNaN(liveFinancingBuyoutPercent) ? liveFinancingBuyoutPercent : null,
        notes: editorNotes || null,
        totalGross: liveCalculation?.finalPriceGross ?? selectedOffer.totalGross,
        totalNet: liveCalculation?.finalPriceNet ?? selectedOffer.totalNet,
        calculation: liveCalculation ?? selectedOffer.calculation,
      }
    : null

  async function handleCreateOffer(formData: FormData) {
    setCreateFeedback(null)
    setEditorFeedback(null)
    const result = await createOfferAction(formData)

    if (!result.ok) {
      setCreateFeedback(result.error || 'Nie udało się utworzyć oferty.')
      return
    }

    createFormRef.current?.reset()
    setCreateOpen(false)
    setCreatePricingCatalogKey('')
    setCreateSelectedColorName('')
    setSelectedOfferId(result.offerId ?? null)
    setEditorFeedback('Oferta została utworzona. Teraz kliknij "Zapisz i otwórz dokument PDF".')
    router.refresh()
  }

  async function handleUpdateOffer(formData: FormData) {
    setEditorFeedback(null)
    const result = await updateOfferAction(formData)

    if (!result.ok) {
      setEditorFeedback(result.error || 'Nie udało się zapisać zmian.')
      return
    }

    setEditorFeedback('Zmiany zapisane. Kalkulacja została przeliczona na nowo.')
    router.refresh()
  }

  async function handleCreateVersion(formData: FormData) {
    setEditorFeedback(null)
    const result = await createOfferVersionAction(formData)

    if (!result.ok) {
      setEditorFeedback(result.error || 'Nie udało się zapisać wersji oferty.')
      return
    }

    if (result.pdfUrl) {
      window.open(result.pdfUrl, '_blank', 'noopener,noreferrer')
      setEditorFeedback('Wersja dokumentu została zapisana i otwarta w nowej karcie. Użyj przycisku "Drukuj / zapisz jako PDF", aby pobrać plik.')
    } else {
      setEditorFeedback('Wersja dokumentu została zapisana.')
    }

    router.refresh()
  }

  function handleCreatePricingChange(nextKey: string) {
    setCreatePricingCatalogKey(nextKey)

    const option = pricingOptionsByKey.get(nextKey)
    const palette = option ? colorPalettesByKey.get(buildPaletteKey(option.brand, option.model)) ?? null : null
    setCreateSelectedColorName(palette?.baseColorName ?? '')
  }

  function handleEditorPricingChange(nextKey: string) {
    setEditorPricingCatalogKey(nextKey)

    const option = pricingOptionsByKey.get(nextKey)
    const palette = option ? colorPalettesByKey.get(buildPaletteKey(option.brand, option.model)) ?? null : null
    setEditorSelectedColorName(palette?.baseColorName ?? '')
  }

  return (
    <main className="grid gap-4">
      <section className="rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] px-4 py-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:px-5">
        <div className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
          <div className="min-w-0">
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Oferty PDF</div>
            <div className="mt-2 flex flex-col gap-2 xl:flex-row xl:items-center xl:gap-4">
              <h2 className="text-2xl font-semibold text-white">Generator ofert handlowych</h2>
              <span className="inline-flex w-fit rounded-full border border-white/8 bg-white/[0.03] px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#aeb7c2]">
                Rola: {roleLabel}
              </span>
            </div>
            <div className="mt-3 flex flex-wrap gap-2 text-xs uppercase tracking-[0.16em] text-[#aeb7c2]">
              <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Wszystkie: {offerStats.all}</span>
              <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Szkice: {offerStats.draft}</span>
              <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Wysłane: {offerStats.sent}</span>
              <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Zaakceptowane: {offerStats.approved}</span>
            </div>
          </div>

          <button type="button" onClick={() => setCreateOpen(true)} className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl border border-[rgba(216,180,90,0.4)] bg-[linear-gradient(135deg,#d8b45a,#b98b1d)] px-4 text-sm font-semibold text-[#111827] transition hover:brightness-105">
            <FilePlus2 className="h-4 w-4" />
            <span>Nowa oferta z leada</span>
          </button>
        </div>

        <div className="mt-4 rounded-[22px] border border-white/8 bg-white/[0.03] px-4 py-3 text-sm text-[#c2cad4]">
          Generator ofert czyta tylko ostatnio zapisaną bazę z polityki cenowej.
          <span className="ml-2 text-[#f3d998]">Kolumny: {pricingSnapshot.headersCount}, rekordy: {pricingSnapshot.rowsCount}.</span>
          <span className="ml-2 text-[#8b96a3]">Ostatni zapis: {formatDate(pricingSnapshot.updatedAt)} / {pricingSnapshot.updatedBy ?? 'brak autora'}.</span>
        </div>

        <div className="mt-4 grid gap-3 lg:grid-cols-3">
          <div className="rounded-[22px] border border-white/8 bg-white/[0.03] px-4 py-4">
            <div className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Krok 1</div>
            <div className="mt-2 text-sm font-semibold text-white">Utwórz ofertę</div>
            <div className="mt-2 text-sm leading-6 text-[#aeb7c2]">Kliknij "Nowa oferta z leada", wybierz konfigurację i zapisz szkic.</div>
          </div>
          <div className="rounded-[22px] border border-white/8 bg-white/[0.03] px-4 py-4">
            <div className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Krok 2</div>
            <div className="mt-2 text-sm font-semibold text-white">Zapisz i otwórz dokument</div>
            <div className="mt-2 text-sm leading-6 text-[#aeb7c2]">Po wybraniu oferty kliknij przycisk "Zapisz i otwórz dokument PDF" w prawym panelu.</div>
          </div>
          <div className="rounded-[22px] border border-white/8 bg-white/[0.03] px-4 py-4">
            <div className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Krok 3</div>
            <div className="mt-2 text-sm font-semibold text-white">Pobierz PDF</div>
            <div className="mt-2 text-sm leading-6 text-[#aeb7c2]">Na otwartym dokumencie kliknij "Drukuj / zapisz jako PDF". To jest właściwy moment pobrania pliku.</div>
          </div>
        </div>
      </section>

      <section className="grid gap-4 xl:grid-cols-[380px_minmax(0,1fr)]">
        <div className="grid gap-4">
          <div className="grid gap-3 rounded-[24px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-3 shadow-[0_18px_48px_rgba(0,0,0,0.16)]">
            <label className="flex h-12 items-center gap-3 rounded-2xl border border-white/10 bg-[#111821] px-4 text-sm text-[#d5dce5]">
              <Search className="h-4 w-4 text-[#7f8a97]" />
              <input value={searchQuery} onChange={(event) => setSearchQuery(event.target.value)} className="h-full w-full bg-transparent text-sm text-white outline-none placeholder:text-[#64707d]" placeholder="Szukaj po numerze, kliencie, modelu..." />
            </label>
            <select value={statusFilter} onChange={(event) => setStatusFilter(event.target.value as OfferStatus | 'ALL')} className="h-12 rounded-2xl border border-white/10 bg-[#111821] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
              <option value="ALL">Wszystkie statusy</option>
              {statusOptions.map((status) => (
                <option key={status.value} value={status.value}>{status.label}</option>
              ))}
            </select>
          </div>

          <div className="grid gap-3">
            {filteredOffers.map((offer) => (
              <button key={offer.id} type="button" onClick={() => setSelectedOfferId(offer.id)} className={[
                'rounded-[22px] border px-4 py-4 text-left transition',
                selectedOfferId === offer.id
                  ? 'border-[rgba(216,180,90,0.35)] bg-[rgba(216,180,90,0.08)] shadow-[0_12px_32px_rgba(0,0,0,0.18)]'
                  : 'border-white/8 bg-[rgba(18,24,33,0.78)] hover:border-white/16 hover:bg-[rgba(21,28,38,0.88)]',
              ].join(' ')}>
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <div className="text-[11px] uppercase tracking-[0.16em] text-[#8b96a3]">{offer.number}</div>
                    <div className="mt-2 text-sm font-semibold text-white">{offer.title}</div>
                  </div>
                  <span className={['inline-flex rounded-full border px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.16em]', getStatusTone(offer.status)].join(' ')}>
                    {statusOptions.find((status) => status.value === offer.status)?.label ?? offer.status}
                  </span>
                </div>
                <div className="mt-3 grid gap-1 text-sm text-[#c2cad4]">
                  <div>{offer.customerName}</div>
                  <div>{offer.modelName ?? 'Konfiguracja do uzupełnienia'}</div>
                </div>
                <div className="mt-3 flex flex-wrap gap-2 text-[10px] uppercase tracking-[0.14em] text-[#aeb7c2]">
                  <span className="rounded-full border border-white/8 bg-white/[0.03] px-2.5 py-1">Opiekun: {offer.ownerName}</span>
                  <span className="rounded-full border border-white/8 bg-white/[0.03] px-2.5 py-1">Rabat: {formatMoney(offer.discountValue)}</span>
                </div>
                <div className="mt-3 rounded-2xl border border-white/8 bg-white/[0.03] px-3 py-2 text-[11px] uppercase tracking-[0.14em] text-[#d5dce5]">
                  Cena końcowa: {formatMoney(offer.totalGross)}
                </div>
              </button>
            ))}

            {filteredOffers.length === 0 ? (
              <div className="rounded-[22px] border border-dashed border-white/10 bg-white/[0.03] px-4 py-10 text-center text-sm text-[#7f8a97]">
                Brak ofert dla wybranych filtrów.
              </div>
            ) : null}
          </div>
        </div>

        {selectedOffer ? (
          <div className="grid gap-4">
            <section className="rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:p-5">
              <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                <div>
                  <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Generator</div>
                  <h3 className="mt-2 text-2xl font-semibold text-white">{selectedOffer.title}</h3>
                  <div className="mt-2 flex flex-wrap gap-2 text-[11px] uppercase tracking-[0.16em] text-[#aeb7c2]">
                    <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">{selectedOffer.number}</span>
                    <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Klient: {selectedOffer.customerName}</span>
                    <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Opiekun: {selectedOffer.ownerName}</span>
                  </div>
                  <div className="mt-3 text-sm text-[#aeb7c2]">Po zapisaniu wersji dokument otworzy się automatycznie w nowej karcie.</div>
                </div>
                <form action={handleCreateVersion} className="flex flex-wrap gap-3">
                  <input type="hidden" name="offerId" value={selectedOffer.id} />
                  <Link href={`/offers/${selectedOffer.id}/pdf`} target="_blank" className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm font-medium text-white transition hover:bg-white/[0.08]">
                    <ExternalLink className="h-4 w-4" />
                    <span>Otwórz podgląd dokumentu</span>
                  </Link>
                  <button type="submit" className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl border border-[rgba(216,180,90,0.35)] bg-[rgba(216,180,90,0.12)] px-4 text-sm font-medium text-[#f3d998] transition hover:bg-[rgba(216,180,90,0.18)]">
                    <FileDown className="h-4 w-4" />
                    <span>Zapisz i otwórz dokument PDF</span>
                  </button>
                </form>
              </div>
            </section>

            <div className="grid gap-4 2xl:grid-cols-[minmax(0,1.1fr)_380px]">
              <form action={handleUpdateOffer} className="grid gap-4 rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:p-5">
                <input type="hidden" name="offerId" value={selectedOffer.id} />
                <div className="grid gap-4 md:grid-cols-2">
                  <label className="block">
                    <span className="text-sm font-medium text-white">Tytuł oferty</span>
                    <input name="title" value={editorTitle} onChange={(event) => setEditorTitle(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" />
                  </label>
                  <label className="block">
                    <span className="text-sm font-medium text-white">Status</span>
                    <select name="status" defaultValue={selectedOffer.status} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                      {statusOptions.map((status) => (
                        <option key={status.value} value={status.value}>{status.label}</option>
                      ))}
                    </select>
                  </label>
                </div>

                <div className="grid gap-4 md:grid-cols-2">
                  <label className="block">
                    <span className="text-sm font-medium text-white">Typ klienta</span>
                    <select name="customerType" value={editorCustomerType} onChange={(event) => setEditorCustomerType(event.target.value as OfferCustomerType)} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                      <option value="PRIVATE">Klient prywatny</option>
                      <option value="BUSINESS">Firma</option>
                    </select>
                  </label>
                  <label className="block">
                    <span className="text-sm font-medium text-white">Ważna do</span>
                    <input type="date" name="validUntil" value={editorValidUntil} onChange={(event) => setEditorValidUntil(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" />
                  </label>
                </div>

                <label className="block">
                  <span className="text-sm font-medium text-white">Konfiguracja z polityki cenowej</span>
                  <select name="pricingCatalogKey" value={editorPricingCatalogKey} onChange={(event) => handleEditorPricingChange(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                    <option value="">Wybierz konfigurację</option>
                    {pricingOptions.map((option) => (
                      <option key={option.key} value={option.key}>{option.label}</option>
                    ))}
                  </select>
                </label>

                <label className="block">
                  <span className="text-sm font-medium text-white">Kolor</span>
                  <div className="relative mt-2">
                    <Palette className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-[#7f8a97]" />
                    <select name="selectedColorName" value={editorSelectedColorName} onChange={(event) => setEditorSelectedColorName(event.target.value)} disabled={!selectedEditorPalette} className="h-11 w-full rounded-2xl border border-white/10 bg-[#131922] pl-10 pr-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)] disabled:cursor-not-allowed disabled:opacity-60">
                      {!selectedEditorPalette ? <option value="">Najpierw wybierz konfigurację</option> : null}
                      {selectedEditorPalette?.colors.map((color) => (
                        <option key={color.name} value={color.name}>
                          {color.name}{color.isBase ? ' / bazowy' : color.surchargeGross ? ` / +${formatMoney(color.surchargeGross)}` : ''}
                        </option>
                      ))}
                    </select>
                  </div>
                </label>

                <div className="grid gap-4 md:grid-cols-2">
                  <label className="block">
                    <span className="text-sm font-medium text-white">Rabat klienta (kwota PLN, nie %)</span>
                    <input type="number" step="0.01" name="discountValue" value={editorDiscountValue} onChange={(event) => setEditorDiscountValue(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="np. 3000 PLN" />
                    <div className="mt-2 text-xs text-[#8b96a3]">Obecnie to pole oznacza kwotę rabatu. Jeśli chcesz rabat procentowy, dodamy osobny tryb.</div>
                  </label>
                  <label className="block">
                    <span className="text-sm font-medium text-white">Wariant finansowania</span>
                    <input name="financingVariant" value={editorFinancingVariant} onChange={(event) => setEditorFinancingVariant(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Np. Leasing operacyjny" />
                  </label>
                </div>

                <div className="grid gap-4 md:grid-cols-4">
                  <label className="block">
                    <span className="text-sm font-medium text-white">Okres finansowania</span>
                    <select name="financingTermMonths" value={editorFinancingTermMonths} onChange={(event) => setEditorFinancingTermMonths(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                      <option value="">Brak</option>
                      <option value="24">24 mies.</option>
                      <option value="36">36 mies.</option>
                      <option value="48">48 mies.</option>
                      <option value="60">60 mies.</option>
                      <option value="71">71 mies.</option>
                    </select>
                  </label>
                  <label className="block">
                    <span className="text-sm font-medium text-white">Tryb wpłaty własnej</span>
                    <select name="financingInputMode" value={editorFinancingInputMode} onChange={(event) => setEditorFinancingInputMode(event.target.value as FinancingInputMode)} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                      <option value="PERCENT">%</option>
                      <option value="AMOUNT">Kwota</option>
                    </select>
                  </label>
                  <label className="block">
                    <span className="text-sm font-medium text-white">Wpłata własna</span>
                    <input type="number" step="0.01" name="financingInputValue" value={editorFinancingInputValue} onChange={(event) => setEditorFinancingInputValue(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="np. 10 lub 20000" />
                  </label>
                  <label className="block">
                    <span className="text-sm font-medium text-white">Wykup (%)</span>
                    <input type="number" step="0.01" name="financingBuyoutPercent" value={editorFinancingBuyoutPercent} onChange={(event) => setEditorFinancingBuyoutPercent(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="np. 20" />
                  </label>
                </div>

                <label className="block">
                  <span className="text-sm font-medium text-white">Uwagi do dokumentu</span>
                  <textarea name="notes" rows={6} value={editorNotes} onChange={(event) => setEditorNotes(event.target.value)} className="mt-2 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 py-3 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Co ma się znaleźć w ofercie, jakie ustalenia ma zawierać dokument, jakie dodatki i warunki?" />
                </label>

                {editorFeedback ? (
                  <div className="rounded-2xl border border-white/10 bg-white/[0.04] px-4 py-3 text-sm text-[#d5dce5]">{editorFeedback}</div>
                ) : null}

                <button type="submit" className="inline-flex h-11 items-center justify-center rounded-2xl border border-[rgba(216,180,90,0.35)] bg-[rgba(216,180,90,0.12)] px-4 text-sm font-medium text-[#f3d998] transition hover:bg-[rgba(216,180,90,0.18)]">
                  Zapisz generator oferty
                </button>
              </form>

              <div className="grid gap-4">
                <CalculationCard offer={previewOffer ?? selectedOffer} />
                <FinancingPreviewCard
                  customerType={editorCustomerType}
                  finalPriceGross={previewOffer?.calculation?.finalPriceGross ?? previewOffer?.totalGross ?? selectedOffer.calculation?.finalPriceGross ?? selectedOffer.totalGross}
                  finalPriceNet={previewOffer?.calculation?.finalPriceNet ?? previewOffer?.totalNet ?? selectedOffer.calculation?.finalPriceNet ?? selectedOffer.totalNet}
                  termMonths={liveFinancingTermMonths !== null && !Number.isNaN(liveFinancingTermMonths) ? liveFinancingTermMonths : null}
                  inputMode={editorFinancingInputMode}
                  inputValue={liveFinancingInputValue !== null && !Number.isNaN(liveFinancingInputValue) ? liveFinancingInputValue : null}
                  buyoutPercent={liveFinancingBuyoutPercent !== null && !Number.isNaN(liveFinancingBuyoutPercent) ? liveFinancingBuyoutPercent : null}
                />

                <section className="rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:p-5">
                  <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Podgląd PDF</div>
                  <div className="mt-1 text-sm text-[#9ba6b2]">To jest podgląd treści dokumentu. Pobranie pliku następuje po kliknięciu "Zapisz i otwórz dokument PDF".</div>
                  <div className="mt-4 rounded-[24px] border border-white/8 bg-[linear-gradient(180deg,rgba(255,255,255,0.05),rgba(255,255,255,0.02))] p-5">
                    <div className="text-[11px] uppercase tracking-[0.16em] text-[#8b96a3]">Dokument handlowy</div>
                    <div className="mt-2 text-2xl font-semibold text-white">{previewOffer?.title ?? selectedOffer.title}</div>
                    <div className="mt-4 grid gap-2 text-sm text-[#d5dce5]">
                      <div>Klient: {selectedOffer.customerName}</div>
                      <div>Kontakt: {selectedOffer.customerEmail ?? selectedOffer.customerPhone ?? 'Do uzupełnienia'}</div>
                      <div>Model: {previewOffer?.modelName ?? selectedOffer.modelName ?? 'Do uzupełnienia'}</div>
                      <div>Kolor: {previewOffer?.calculation?.selectedColorName ?? previewOffer?.selectedColorName ?? 'Bazowy / do ustalenia'}</div>
                      <div>Wariant: {previewOffer?.financingVariant ?? 'Do ustalenia'}</div>
                      <div>Okres finansowania: {previewOffer?.financingTermMonths ? `${previewOffer.financingTermMonths} mies.` : 'Brak'}</div>
                      <div>Typ klienta: {previewOffer?.customerType === 'BUSINESS' ? 'Firma' : 'Klient prywatny'}</div>
                      <div>Dopłata za lakier: {formatMoney((previewOffer?.customerType === 'BUSINESS' ? previewOffer?.calculation?.colorSurchargeNet : previewOffer?.calculation?.colorSurchargeGross) ?? 0)}</div>
                      <div>Cena końcowa brutto: {formatMoney(previewOffer?.totalGross ?? selectedOffer.totalGross)}</div>
                      <div>Cena końcowa netto: {formatMoney(previewOffer?.totalNet ?? selectedOffer.totalNet)}</div>
                      <div>Ważna do: {formatDate(previewOffer?.validUntil ?? selectedOffer.validUntil)}</div>
                    </div>
                    <div className="mt-5 rounded-[18px] border border-white/8 bg-[#10161d] p-4 text-sm leading-6 text-[#c2cad4]">
                      {previewOffer?.notes ?? 'Dodaj uwagi do oferty, aby przygotować treść dokumentu dla klienta.'}
                    </div>
                  </div>
                </section>

                <section className="rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:p-5">
                  <div className="flex items-center justify-between gap-3">
                    <div>
                      <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Historia wersji</div>
                      <div className="mt-1 text-sm text-[#9ba6b2]">Snapshoty gotowe pod kolejne PDF-y dla klienta.</div>
                    </div>
                    <div className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#aeb7c2]">
                      {selectedOffer.versions.length} wersji
                    </div>
                  </div>

                  <div className="mt-4 grid gap-3">
                    {selectedOffer.versions.length > 0 ? selectedOffer.versions.map((version) => (
                      <article key={version.id} className="rounded-[20px] border border-white/8 bg-[#10161d] p-4">
                        <div className="flex items-center justify-between gap-3">
                          <div className="text-sm font-semibold text-white">Wersja {version.versionNumber}</div>
                          <div className="text-[11px] uppercase tracking-[0.16em] text-[#7f8a97]">{formatDate(version.createdAt)}</div>
                        </div>
                        <div className="mt-2 text-sm leading-6 text-[#c2cad4]">{version.summary}</div>
                        {version.pdfUrl ? (
                          <div className="mt-3">
                            <Link href={version.pdfUrl} target="_blank" className="inline-flex items-center gap-2 text-sm font-medium text-[#f3d998] transition hover:text-white">
                              <ExternalLink className="h-4 w-4" />
                              <span>Otwórz tę wersję i zapisz PDF</span>
                            </Link>
                          </div>
                        ) : null}
                      </article>
                    )) : (
                      <div className="rounded-[20px] border border-dashed border-white/10 bg-white/[0.03] px-4 py-8 text-center text-sm text-[#7f8a97]">
                        Brak zapisanych wersji. Kliknij "Zapisz i otwórz dokument PDF", aby utworzyć pierwszą wersję do pobrania.
                      </div>
                    )}
                  </div>
                </section>
              </div>
            </div>
          </div>
        ) : (
          <div className="rounded-[28px] border border-dashed border-white/10 bg-white/[0.03] px-4 py-20 text-center text-sm text-[#7f8a97]">
            Zacznij od kliknięcia "Nowa oferta z leada". Po utworzeniu oferty wybierz ją z listy i użyj przycisku "Zapisz i otwórz dokument PDF".
          </div>
        )}
      </section>

      {isCreateOpen ? (
        <Overlay title="Utwórz ofertę z leada" onClose={() => setCreateOpen(false)}>
          <form ref={createFormRef} action={handleCreateOffer} className="grid gap-4">
            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-white">Lead</span>
                <select name="leadId" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                  <option value="">Wybierz leada</option>
                  {leadOptions.map((lead) => (
                    <option key={lead.id} value={lead.id}>{lead.label}</option>
                  ))}
                </select>
              </label>

              <label className="block">
                <span className="text-sm font-medium text-white">Typ klienta</span>
                <select name="customerType" defaultValue="PRIVATE" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                  <option value="PRIVATE">Klient prywatny</option>
                  <option value="BUSINESS">Firma</option>
                </select>
              </label>
            </div>

            <label className="block">
              <span className="text-sm font-medium text-white">Tytuł oferty</span>
              <input name="title" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Np. Oferta BYD Seal 6 DM-i dla klienta" />
            </label>

            <label className="block">
              <span className="text-sm font-medium text-white">Konfiguracja z polityki cenowej</span>
              <select name="pricingCatalogKey" value={createPricingCatalogKey} onChange={(event) => handleCreatePricingChange(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                <option value="">Wybierz konfigurację</option>
                {pricingOptions.map((option) => (
                  <option key={option.key} value={option.key}>{option.label}</option>
                ))}
              </select>
            </label>

            <label className="block">
              <span className="text-sm font-medium text-white">Kolor</span>
              <div className="relative mt-2">
                <Palette className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-[#7f8a97]" />
                <select name="selectedColorName" value={createSelectedColorName} onChange={(event) => setCreateSelectedColorName(event.target.value)} disabled={!selectedCreatePalette} className="h-11 w-full rounded-2xl border border-white/10 bg-[#131922] pl-10 pr-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)] disabled:cursor-not-allowed disabled:opacity-60">
                  {!selectedCreatePalette ? <option value="">Najpierw wybierz konfigurację</option> : null}
                  {selectedCreatePalette?.colors.map((color) => (
                    <option key={color.name} value={color.name}>
                      {color.name}{color.isBase ? ' / bazowy' : color.surchargeGross ? ` / +${formatMoney(color.surchargeGross)}` : ''}
                    </option>
                  ))}
                </select>
              </div>
            </label>

            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-white">Rabat klienta</span>
                <input type="number" step="0.01" name="discountValue" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="np. 3000" />
              </label>
              <label className="block">
                <span className="text-sm font-medium text-white">Wariant finansowania</span>
                <input name="financingVariant" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Leasing / wynajem / gotówka" />
              </label>
            </div>

            <div className="grid gap-4 md:grid-cols-4">
              <label className="block">
                <span className="text-sm font-medium text-white">Okres</span>
                <select name="financingTermMonths" defaultValue="" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                  <option value="">Brak</option>
                  <option value="24">24 mies.</option>
                  <option value="36">36 mies.</option>
                  <option value="48">48 mies.</option>
                  <option value="60">60 mies.</option>
                  <option value="71">71 mies.</option>
                </select>
              </label>
              <label className="block">
                <span className="text-sm font-medium text-white">Tryb wpłaty</span>
                <select name="financingInputMode" defaultValue="PERCENT" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                  <option value="PERCENT">%</option>
                  <option value="AMOUNT">Kwota</option>
                </select>
              </label>
              <label className="block">
                <span className="text-sm font-medium text-white">Wpłata własna</span>
                <input type="number" step="0.01" name="financingInputValue" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="np. 10 lub 20000" />
              </label>
              <label className="block">
                <span className="text-sm font-medium text-white">Wykup %</span>
                <input type="number" step="0.01" name="financingBuyoutPercent" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="np. 20" />
              </label>
            </div>

            <label className="block">
              <span className="text-sm font-medium text-white">Ważna do</span>
              <input type="date" name="validUntil" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" />
            </label>

            <label className="block">
              <span className="text-sm font-medium text-white">Uwagi startowe</span>
              <textarea name="notes" rows={4} className="mt-2 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 py-3 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Co powinno wejść do pierwszej wersji oferty?" />
            </label>

            {leadOptions.length > 0 ? (
              <div className="rounded-2xl border border-white/10 bg-white/[0.04] p-4 text-sm text-[#c2cad4]">
                <div className="flex items-center gap-2 text-[#f3d998]">
                  <Sparkles className="h-4 w-4" />
                  <span>Oferty dziedziczą dane klienta z leada, a kwota końcowa wynika z polityki cenowej, rabatu i struktury prowizyjnej.</span>
                </div>
              </div>
            ) : null}

            {createFeedback ? (
              <div className="rounded-2xl border border-red-400/20 bg-red-500/10 px-4 py-3 text-sm text-red-200">{createFeedback}</div>
            ) : null}

            <button type="submit" className="inline-flex h-11 items-center justify-center rounded-2xl border border-[rgba(216,180,90,0.4)] bg-[linear-gradient(135deg,#d8b45a,#b98b1d)] px-4 text-sm font-semibold text-[#111827] transition hover:brightness-105">
              Utwórz ofertę
            </button>
          </form>
        </Overlay>
      ) : null}
    </main>
  )
}