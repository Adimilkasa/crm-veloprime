'use client'

import Link from 'next/link'
import { useEffect, useMemo, useRef, useState } from 'react'
import { useRouter } from 'next/navigation'
import { ExternalLink, FileDown, FilePlus2, Palette, Search, X } from 'lucide-react'

import { calculateOfferSummary, type OfferCalculationSummary, type SharedCommissionRule, type SharedManagedUser } from '@/lib/offer-calculations-shared'
import { calculateOfferFinancing, getBuyoutLimit } from '@/lib/offer-financing-shared'

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

const FINANCING_VARIANT_OPTIONS: Record<OfferCustomerType, string[]> = {
  BUSINESS: ['leasing operacyjny', 'wynajem długoterminowy'],
  PRIVATE: ['kredyt', 'leasing konsumencki', 'wynajem'],
}

function getFinancingVariantOptions(customerType: OfferCustomerType) {
  return FINANCING_VARIANT_OPTIONS[customerType]
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

function getOfferPoolAmount(summary: OfferCalculationSummary | null) {
  if (!summary) {
    return null
  }

  return summary.customerType === 'BUSINESS' ? summary.marginPoolNet : summary.marginPoolGross
}

function getStatusTone(status: OfferStatus) {
  switch (status) {
    case 'APPROVED':
      return 'border-[#d9ece4] bg-[#f4fbf8] text-[#3f7d64]'
    case 'SENT':
      return 'border-[#dbe7f6] bg-[#f8fbff] text-[#4a90e2]'
    case 'REJECTED':
      return 'border-[#f1d4d2] bg-[#fff5f4] text-[#a64b45]'
    case 'EXPIRED':
      return 'border-[#e8e1d4] bg-[#fcfbf8] text-[#7a7262]'
    default:
      return 'border-[#efe0ba] bg-[#fffaf0] text-[#9d7b27]'
  }
}

function CalculationCard({ offer }: { offer: ManagedOffer }) {
  if (!offer.calculation) {
    return (
      <section className="rounded-[28px] border border-[#e8e1d4] bg-white p-4 shadow-[0_18px_42px_rgba(31,31,31,0.05)] lg:p-5">
        <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Kalkulacja marży</div>
        <div className="mt-4 rounded-[24px] border border-dashed border-[#e7dfd0] bg-[#fcfbf8] px-4 py-12 text-center text-sm text-[#8a826f]">
          Wybierz konfigurację z polityki cenowej, aby system policzył pulę, udział dyrektora, managera i prowizję handlowca.
        </div>
      </section>
    )
  }

  const calc = offer.calculation

  return (
    <section className="rounded-[28px] border border-[#e8e1d4] bg-white p-4 shadow-[0_18px_42px_rgba(31,31,31,0.05)] lg:p-5">
      <div className="flex items-center justify-between gap-3">
        <div>
          <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Kalkulacja marży</div>
          <div className="mt-1 text-sm text-[#6b6b6b]">{calc.catalogLabel}</div>
        </div>
        <div className="rounded-full border border-[#e7dfd0] bg-[#fcfbf8] px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#7a7262]">
          {calc.customerType === 'BUSINESS' ? 'Firma / netto' : 'Klient prywatny / brutto'}
        </div>
      </div>

      <div className="mt-4 grid gap-3 md:grid-cols-2">
        <div className="rounded-[22px] border border-[#e8e1d4] bg-[#fcfbf8] p-4">
          <div className="text-xs uppercase tracking-[0.16em] text-[#8a826f]">Cena katalogowa</div>
          <div className="mt-2 text-lg font-semibold text-[#1f1f1f]">{formatMoney(calc.customerType === 'BUSINESS' ? calc.listPriceNet : calc.listPriceGross)}</div>
        </div>
        <div className="rounded-[22px] border border-[#e8e1d4] bg-[#fcfbf8] p-4">
          <div className="text-xs uppercase tracking-[0.16em] text-[#8a826f]">Cena bazowa</div>
          <div className="mt-2 text-lg font-semibold text-[#1f1f1f]">{formatMoney(calc.customerType === 'BUSINESS' ? calc.basePriceNet : calc.basePriceGross)}</div>
        </div>
        <div className="rounded-[22px] border border-[#efe0ba] bg-[#fffaf0] p-4">
          <div className="text-xs uppercase tracking-[0.16em] text-[#9d7b27]">Pula całkowita</div>
          <div className="mt-2 text-lg font-semibold text-[#1f1f1f]">{formatMoney(calc.customerType === 'BUSINESS' ? calc.marginPoolNet : calc.marginPoolGross)}</div>
        </div>
        <div className="rounded-[22px] border border-[#d9ece4] bg-[#f4fbf8] p-4">
          <div className="text-xs uppercase tracking-[0.16em] text-[#3f7d64]">Dostępna pula oferty</div>
          <div className="mt-2 text-lg font-semibold text-[#1f1f1f]">{formatMoney(calc.availableDiscount)}</div>
        </div>
      </div>

      <div className="mt-3 rounded-[22px] border border-[#dbe7f6] bg-[#f8fbff] p-4">
        <div className="flex items-center justify-between gap-3 text-xs uppercase tracking-[0.16em] text-[#4a90e2]">
          <span>Lakier</span>
          <span>{calc.selectedColorName ?? calc.baseColorName ?? 'Brak palety'}</span>
        </div>
        <div className="mt-2 text-lg font-semibold text-[#1f1f1f]">
          {formatMoney(calc.customerType === 'BUSINESS' ? calc.colorSurchargeNet : calc.colorSurchargeGross)}
        </div>
      </div>

      <div className="mt-4 grid gap-3 rounded-[24px] border border-[#eee6d9] bg-[#fcfbf8] p-4 text-sm text-[#555555]">
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
        <div className="flex items-center justify-between gap-3 border-t border-[#e7dfd0] pt-3 font-semibold text-[#1f1f1f]">
          <span>Pozostaje w puli</span>
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
  inputValue,
  buyoutPercent,
}: {
  customerType: OfferCustomerType
  finalPriceGross: number | null
  finalPriceNet: number | null
  termMonths: number | null
  inputValue: number | null
  buyoutPercent: number | null
}) {
  const financing = calculateOfferFinancing({
    customerType,
    finalPriceGross,
    finalPriceNet,
    termMonths,
    downPaymentInputMode: 'AMOUNT',
    downPaymentInputValue: inputValue,
    buyoutPercent,
  })

  return (
    <section className="rounded-[28px] border border-[#e8e1d4] bg-white p-4 shadow-[0_18px_42px_rgba(31,31,31,0.05)] lg:p-5">
      <div className="flex items-center justify-between gap-3">
        <div>
          <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Podgląd finansowania</div>
          <div className="mt-1 text-sm text-[#6b6b6b]">Podgląd liczy się od aktualnej ceny oferty widocznej po prawej stronie.</div>
        </div>
        <div className="rounded-full border border-[#e7dfd0] bg-[#fcfbf8] px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#7a7262]">
          {customerType === 'BUSINESS' ? 'Podstawa netto' : 'Podstawa brutto'}
        </div>
      </div>

      {!termMonths || inputValue === null || buyoutPercent === null ? (
        <div className="mt-4 rounded-[22px] border border-dashed border-[#e7dfd0] bg-[#fcfbf8] px-4 py-8 text-center text-sm text-[#8a826f]">
          Uzupełnij okres, wpłatę własną i wykup, aby zobaczyć szacowaną ratę.
        </div>
      ) : financing && !financing.ok ? (
        <div className="mt-4 rounded-[22px] border border-[#f1d4d2] bg-[#fff5f4] px-4 py-4 text-sm text-[#a64b45]">
          {financing.error}
        </div>
      ) : financing && financing.ok ? (
        <div className="mt-4 grid gap-3 md:grid-cols-2">
          <div className="rounded-[22px] border border-[#d9ece4] bg-[#f4fbf8] p-4">
            <div className="text-xs uppercase tracking-[0.16em] text-[#3f7d64]">Szacowana rata</div>
            <div className="mt-2 text-lg font-semibold text-[#1f1f1f]">{formatMoney(financing.summary.estimatedInstallment)}</div>
          </div>
          <div className="rounded-[22px] border border-[#e8e1d4] bg-[#fcfbf8] p-4">
            <div className="text-xs uppercase tracking-[0.16em] text-[#8a826f]">Okres</div>
            <div className="mt-2 text-lg font-semibold text-[#1f1f1f]">{financing.summary.termMonths} mies.</div>
          </div>
          <div className="rounded-[22px] border border-[#e8e1d4] bg-[#fcfbf8] p-4">
            <div className="text-xs uppercase tracking-[0.16em] text-[#8a826f]">Wpłata własna</div>
            <div className="mt-2 text-lg font-semibold text-[#1f1f1f]">{formatMoney(financing.summary.downPaymentAmount)}</div>
            <div className="mt-1 text-sm text-[#6b6b6b]">{formatPercentValue(financing.summary.downPaymentPercent)}</div>
          </div>
          <div className="rounded-[22px] border border-[#e8e1d4] bg-[#fcfbf8] p-4">
            <div className="text-xs uppercase tracking-[0.16em] text-[#8a826f]">Wykup</div>
            <div className="mt-2 text-lg font-semibold text-[#1f1f1f]">{formatMoney(financing.summary.buyoutAmount)}</div>
            <div className="mt-1 text-sm text-[#6b6b6b]">{formatPercentValue(financing.summary.buyoutPercent)}</div>
          </div>
        </div>
      ) : (
        <div className="mt-4 rounded-[22px] border border-dashed border-[#e7dfd0] bg-[#fcfbf8] px-4 py-8 text-center text-sm text-[#8a826f]">
          Nie można policzyć finansowania dla bieżącej oferty.
        </div>
      )}
    </section>
  )
}

export function OffersWorkspace({
  offers,
  leadOptions,
  initialLeadId,
  pricingOptions,
  colorPalettes,
  salesUsers,
  commissionRules,
  statusOptions,
  createOfferAction,
  assignOfferLeadAction,
  createOfferLeadAction,
  updateOfferAction,
  createOfferVersionAction,
}: {
  offers: ManagedOffer[]
  leadOptions: OfferLeadOption[]
  initialLeadId: string | null
  pricingOptions: OfferPricingOption[]
  colorPalettes: OfferColorPalette[]
  salesUsers: SharedManagedUser[]
  commissionRules: SharedCommissionRule[]
  statusOptions: Array<{ value: OfferStatus; label: string }>
  createOfferAction: (formData: FormData) => Promise<{ ok: boolean; error?: string; offerId?: string }>
  assignOfferLeadAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
  createOfferLeadAction: (formData: FormData) => Promise<{ ok: boolean; error?: string; leadId?: string }>
  updateOfferAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
  createOfferVersionAction: (formData: FormData) => Promise<{ ok: boolean; error?: string; versionId?: string; pdfUrl?: string }>
}) {
  const router = useRouter()
  const [selectedOfferId, setSelectedOfferId] = useState<string | null>(null)
  const [isCreateOpen, setCreateOpen] = useState(false)
  const [createFeedback, setCreateFeedback] = useState<string | null>(null)
  const [editorFeedback, setEditorFeedback] = useState<string | null>(null)
  const [leadBindingFeedback, setLeadBindingFeedback] = useState<string | null>(null)
  const [createSelectedLeadId, setCreateSelectedLeadId] = useState(initialLeadId ?? '')
  const [createLeadSearchQuery, setCreateLeadSearchQuery] = useState('')
  const [editorPricingCatalogKey, setEditorPricingCatalogKey] = useState(offers[0]?.pricingCatalogKey ?? '')
  const [editorSelectedColorName, setEditorSelectedColorName] = useState(offers[0]?.selectedColorName ?? '')
  const [editorCustomerType, setEditorCustomerType] = useState<OfferCustomerType>(offers[0]?.customerType ?? 'PRIVATE')
  const [editorFinancingTermMonths, setEditorFinancingTermMonths] = useState<string>(offers[0]?.financingTermMonths ? String(offers[0].financingTermMonths) : '')
  const [editorFinancingInputValue, setEditorFinancingInputValue] = useState<string>(offers[0]?.financingInputValue !== null && offers[0]?.financingInputValue !== undefined ? String(offers[0].financingInputValue) : '')
  const [editorFinancingBuyoutPercent, setEditorFinancingBuyoutPercent] = useState<string>(offers[0]?.financingBuyoutPercent !== null && offers[0]?.financingBuyoutPercent !== undefined ? String(offers[0].financingBuyoutPercent) : '')
  const [editorTitle, setEditorTitle] = useState(offers[0]?.title ?? '')
  const [editorValidUntil, setEditorValidUntil] = useState(offers[0]?.validUntil ? offers[0].validUntil.slice(0, 10) : '')
  const [editorDiscountValue, setEditorDiscountValue] = useState(offers[0]?.discountValue !== null && offers[0]?.discountValue !== undefined ? String(offers[0].discountValue) : '')
  const [editorFinancingVariant, setEditorFinancingVariant] = useState(offers[0]?.financingVariant ?? '')
  const [editorNotes, setEditorNotes] = useState(offers[0]?.notes ?? '')
  const [assignLeadId, setAssignLeadId] = useState(initialLeadId ?? '')
  const [assignLeadSearchQuery, setAssignLeadSearchQuery] = useState('')
  const [newLeadFullName, setNewLeadFullName] = useState('')
  const [newLeadEmail, setNewLeadEmail] = useState('')
  const [newLeadPhone, setNewLeadPhone] = useState('')
  const [newLeadRegion, setNewLeadRegion] = useState('')
  const hasHandledInitialLeadRef = useRef(false)

  const pricingOptionsByKey = useMemo(() => new Map(pricingOptions.map((option) => [option.key, option])), [pricingOptions])
  const colorPalettesByKey = useMemo(() => new Map(colorPalettes.map((palette) => [palette.paletteKey, palette])), [colorPalettes])

  const selectedOffer = offers.find((offer) => offer.id === selectedOfferId) ?? null
  const selectedEditorPalette = editorPricingCatalogKey
    ? (() => {
        const option = pricingOptionsByKey.get(editorPricingCatalogKey)
        return option ? colorPalettesByKey.get(buildPaletteKey(option.brand, option.model)) ?? null : null
      })()
    : null
  const filteredCreateLeadOptions = useMemo(() => {
    const normalizedQuery = createLeadSearchQuery.trim().toLowerCase()

    return leadOptions.filter((lead) => {
      if (!normalizedQuery) {
        return true
      }

      return [lead.label, lead.modelName, lead.contact, lead.ownerName].some((value) => value?.toLowerCase().includes(normalizedQuery))
    })
  }, [createLeadSearchQuery, leadOptions])
  const filteredAssignLeadOptions = useMemo(() => {
    const normalizedQuery = assignLeadSearchQuery.trim().toLowerCase()

    return leadOptions.filter((lead) => {
      if (!normalizedQuery) {
        return true
      }

      return [lead.label, lead.modelName, lead.contact, lead.ownerName].some((value) => value?.toLowerCase().includes(normalizedQuery))
    })
  }, [assignLeadSearchQuery, leadOptions])

  useEffect(() => {
    if (!initialLeadId || hasHandledInitialLeadRef.current) {
      return
    }

    hasHandledInitialLeadRef.current = true
    const existingOffer = offers.find((offer) => offer.leadId === initialLeadId)

    if (existingOffer) {
      setSelectedOfferId(existingOffer.id)
      return
    }

    setCreateSelectedLeadId(initialLeadId)
    setCreateOpen(true)
  }, [initialLeadId, offers])

  useEffect(() => {
    setEditorPricingCatalogKey(selectedOffer?.pricingCatalogKey ?? '')
    setEditorSelectedColorName(selectedOffer?.selectedColorName ?? '')
    setEditorCustomerType(selectedOffer?.customerType ?? 'PRIVATE')
    setEditorFinancingTermMonths(selectedOffer?.financingTermMonths ? String(selectedOffer.financingTermMonths) : '')
    setEditorFinancingInputValue(selectedOffer?.financingInputValue !== null && selectedOffer?.financingInputValue !== undefined ? String(selectedOffer.financingInputValue) : '')
    setEditorFinancingBuyoutPercent(selectedOffer?.financingBuyoutPercent !== null && selectedOffer?.financingBuyoutPercent !== undefined ? String(selectedOffer.financingBuyoutPercent) : '')
    setEditorTitle(selectedOffer?.title ?? '')
    setEditorValidUntil(selectedOffer?.validUntil ? selectedOffer.validUntil.slice(0, 10) : '')
    setEditorDiscountValue(selectedOffer?.discountValue !== null && selectedOffer?.discountValue !== undefined ? String(selectedOffer.discountValue) : '')
    setEditorFinancingVariant(selectedOffer?.financingVariant ?? '')
    setEditorNotes(selectedOffer?.notes ?? '')
    setAssignLeadId(selectedOffer?.leadId ?? initialLeadId ?? '')
    setNewLeadFullName(selectedOffer?.customerName ?? '')
    setNewLeadEmail(selectedOffer?.customerEmail ?? '')
    setNewLeadPhone(selectedOffer?.customerPhone ?? '')
    setNewLeadRegion('')
  }, [selectedOffer?.id, selectedOffer?.pricingCatalogKey, selectedOffer?.selectedColorName, selectedOffer?.customerType, selectedOffer?.financingTermMonths, selectedOffer?.financingInputValue, selectedOffer?.financingBuyoutPercent, selectedOffer?.title, selectedOffer?.validUntil, selectedOffer?.discountValue, selectedOffer?.financingVariant, selectedOffer?.notes])

  useEffect(() => {
    if (!getFinancingVariantOptions(editorCustomerType).includes(editorFinancingVariant)) {
      setEditorFinancingVariant('')
    }
  }, [editorCustomerType, editorFinancingVariant])

  function openCreateFlow(leadId?: string | null) {
    setCreateFeedback(null)
    setCreateLeadSearchQuery('')
    setCreateSelectedLeadId(leadId ?? initialLeadId ?? '')
    setCreateOpen(true)
  }

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
  const editorPoolAmount = getOfferPoolAmount(liveCalculation)
  const editorRemainingPoolAmount = editorPoolAmount !== null && liveCalculation ? editorPoolAmount - liveCalculation.appliedDiscount : null
  const editorBuyoutLimit = getBuyoutLimit(liveFinancingTermMonths)
  const editorBuyoutError = editorBuyoutLimit !== null && liveFinancingBuyoutPercent !== null && liveFinancingBuyoutPercent > editorBuyoutLimit
    ? `Dla ${liveFinancingTermMonths} mies. maksymalny wykup to ${editorBuyoutLimit}%.`
    : null
  const previewOffer: ManagedOffer | null = selectedOffer
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
        financingInputMode: 'AMOUNT' as const,
        financingInputValue: liveFinancingInputValue !== null && !Number.isNaN(liveFinancingInputValue) ? liveFinancingInputValue : null,
        financingBuyoutPercent: liveFinancingBuyoutPercent !== null && !Number.isNaN(liveFinancingBuyoutPercent) ? liveFinancingBuyoutPercent : null,
        notes: editorNotes || null,
        totalGross: liveCalculation?.finalPriceGross ?? selectedOffer.totalGross,
        totalNet: liveCalculation?.finalPriceNet ?? selectedOffer.totalNet,
        calculation: liveCalculation ?? selectedOffer.calculation,
      }
    : null

  async function createDraftOffer(formData: FormData, mode: 'LEAD' | 'FREE') {
    setCreateFeedback(null)
    setEditorFeedback(null)

    const result = await createOfferAction(formData)

    if (!result.ok) {
      setCreateFeedback(result.error || 'Nie udało się utworzyć oferty.')
      return
    }

    setCreateOpen(false)
    setCreateSelectedLeadId('')
    setSelectedOfferId(result.offerId ?? null)
    setEditorFeedback(
      mode === 'FREE'
        ? 'Szkic oferty został utworzony. Uzupełnij konfigurację i dane dopiero wtedy, kiedy będą potrzebne.'
        : 'Szkic oferty dla wybranego klienta został utworzony.'
    )
    router.refresh()
  }

  async function handleQuickCreateFreeOffer() {
    const formData = new FormData()
    formData.set('title', '')
    formData.set('customerType', 'PRIVATE')
    await createDraftOffer(formData, 'FREE')
  }

  async function handleCreateOfferForLead(leadId: string) {
    setCreateSelectedLeadId(leadId)

    const formData = new FormData()
    formData.set('leadId', leadId)
    formData.set('title', '')
    formData.set('customerType', 'PRIVATE')
    await createDraftOffer(formData, 'LEAD')
  }

  async function handleAssignOfferLead(formData: FormData) {
    setLeadBindingFeedback(null)
    const result = await assignOfferLeadAction(formData)

    if (!result.ok) {
      setLeadBindingFeedback(result.error || 'Nie udało się przypisać leada do oferty.')
      return
    }

    setLeadBindingFeedback('Lead został przypisany do oferty. Możesz teraz zapisać dokument PDF.')
    router.refresh()
  }

  async function handleCreateLeadForOffer(formData: FormData) {
    setLeadBindingFeedback(null)
    const result = await createOfferLeadAction(formData)

    if (!result.ok) {
      setLeadBindingFeedback(result.error || 'Nie udało się utworzyć leada z oferty.')
      return
    }

    setLeadBindingFeedback('Nowy lead został utworzony i przypisany do oferty. Możesz zapisać dokument PDF.')
    router.refresh()
  }

  async function handleUpdateOffer(formData: FormData) {
    setEditorFeedback(null)

    if (editorBuyoutError) {
      setEditorFeedback(editorBuyoutError)
      return
    }

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

    if (!selectedOffer) {
      setEditorFeedback('Nie wybrano aktywnej oferty.')
      return
    }

    if (!selectedOffer?.leadId) {
      const leadFormData = new FormData()
      leadFormData.set('offerId', selectedOffer.id)
      leadFormData.set('fullName', newLeadFullName.trim() || selectedOffer.customerName)
      leadFormData.set('email', newLeadEmail.trim() || selectedOffer.customerEmail || '')
      leadFormData.set('phone', newLeadPhone.trim() || selectedOffer.customerPhone || '')
      leadFormData.set('region', newLeadRegion.trim())

      const leadResult = await createOfferLeadAction(leadFormData)

      if (!leadResult.ok) {
        setEditorFeedback(leadResult.error || 'Nie udało się automatycznie utworzyć leada dla tej oferty.')
        return
      }

      setLeadBindingFeedback('Lead został utworzony automatycznie z danych oferty i przypisany przed zapisem dokumentu.')
    }

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

  function handleEditorPricingChange(nextKey: string) {
    setEditorPricingCatalogKey(nextKey)

    const option = pricingOptionsByKey.get(nextKey)
    const palette = option ? colorPalettesByKey.get(buildPaletteKey(option.brand, option.model)) ?? null : null
    setEditorSelectedColorName(palette?.baseColorName ?? '')
  }

  return (
    <main className="grid gap-6">
      <section className="overflow-hidden rounded-[32px] border border-[#e8e2d3] bg-[linear-gradient(135deg,#ffffff_0%,#fbf8f1_52%,#f7f3e8_100%)] px-5 py-5 shadow-[0_24px_70px_rgba(31,31,31,0.06)] lg:px-6 lg:py-6">
        <div className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
          <div className="min-w-0">
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Oferty PDF</div>
            <h2 className="mt-2 text-2xl font-semibold text-[#1f1f1f]">Generator ofert</h2>
          </div>

          <div className="flex flex-wrap gap-3">
            <button type="button" onClick={() => openCreateFlow()} className="inline-flex h-11 items-center justify-center gap-2 rounded-[14px] bg-[#c9a13b] px-4 text-sm font-semibold text-white shadow-[0_16px_32px_rgba(201,161,59,0.24)] transition hover:bg-[#b8932f]">
              <FilePlus2 className="h-4 w-4" />
              <span>Oferta dla klienta w systemie</span>
            </button>
            <button type="button" onClick={handleQuickCreateFreeOffer} className="inline-flex h-11 items-center justify-center gap-2 rounded-[14px] border border-[#e5dfd1] bg-white px-4 text-sm font-medium text-[#4d4d4d] transition hover:border-[rgba(201,161,59,0.26)] hover:text-[#1f1f1f]">
              <FilePlus2 className="h-4 w-4" />
              <span>Nowa oferta</span>
            </button>
          </div>
        </div>
      </section>

      <section className="grid gap-4">
        {isCreateOpen ? (
          <section className="rounded-[28px] border border-[#e8e1d4] bg-white p-4 shadow-[0_18px_42px_rgba(31,31,31,0.05)] lg:p-5">
            <div className="flex items-start justify-between gap-4 border-b border-[#eee6d9] pb-4">
              <div>
                <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Nowa oferta</div>
                <h3 className="mt-1 text-xl font-semibold text-[#1f1f1f]">Wybierz klienta z systemu</h3>
              </div>
              <button type="button" onClick={() => setCreateOpen(false)} className="inline-flex h-10 w-10 items-center justify-center rounded-2xl border border-[#ebe3d6] bg-white text-[#5f5a4f] transition hover:border-[rgba(201,161,59,0.24)] hover:text-[#8f6b18]">
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="mt-5 grid gap-3 rounded-[22px] border border-[#e8e1d4] bg-white p-4">
              <label className="flex h-11 items-center gap-3 rounded-2xl border border-[#e8e1d4] bg-[#fcfbf8] px-4 text-sm text-[#5f5a4f]">
                <Search className="h-4 w-4 text-[#9d7b27]" />
                <input value={createLeadSearchQuery} onChange={(event) => setCreateLeadSearchQuery(event.target.value)} className="h-full w-full bg-transparent text-sm text-[#1f1f1f] outline-none placeholder:text-[#8a826f]" placeholder="Wyszukaj klienta, model albo kontakt..." />
              </label>
              <div className="grid max-h-72 gap-2 overflow-y-auto">
                {filteredCreateLeadOptions.map((lead) => (
                  <button key={lead.id} type="button" onClick={() => handleCreateOfferForLead(lead.id)} className={[
                    'rounded-[18px] border px-4 py-3 text-left transition',
                    createSelectedLeadId === lead.id
                      ? 'border-[rgba(201,161,59,0.30)] bg-[rgba(201,161,59,0.10)]'
                      : 'border-[#e8e1d4] bg-[#fcfbf8] hover:border-[rgba(201,161,59,0.24)]',
                  ].join(' ')}>
                    <div className="text-sm font-semibold text-[#1f1f1f]">{lead.label}</div>
                    <div className="mt-1 text-sm text-[#6b6b6b]">{lead.modelName ?? 'Model do uzupełnienia'}{lead.contact ? ` • ${lead.contact}` : ''}</div>
                  </button>
                ))}
                {filteredCreateLeadOptions.length === 0 ? (
                  <div className="rounded-[18px] border border-dashed border-[#e7dfd0] bg-[#fcfbf8] px-4 py-8 text-center text-sm text-[#8a826f]">Brak leadów pasujących do wyszukiwania.</div>
                ) : null}
              </div>

              {createFeedback ? (
                <div className="rounded-[18px] border border-[#f1d4d2] bg-[#fff5f4] px-4 py-3 text-sm text-[#a64b45]">{createFeedback}</div>
              ) : null}

              <div className="text-sm text-[#6b6b6b]">Kliknięcie klienta od razu utworzy szkic oferty i przypisze go do wybranego leada.</div>
            </div>
          </section>
        ) : null}

        {selectedOffer ? (
          <div className="grid gap-4">
            <section className="rounded-[28px] border border-[#e8e1d4] bg-white p-4 shadow-[0_18px_42px_rgba(31,31,31,0.05)] lg:p-5">
              <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
                <div className="grid gap-3 lg:min-w-[320px]">
                  <label className="block">
                    <span className="text-xs font-semibold uppercase tracking-[0.16em] text-[#8a826f]">Aktywna oferta</span>
                    <select value={selectedOfferId ?? ''} onChange={(event) => setSelectedOfferId(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]">
                      {offers.map((offer) => (
                        <option key={offer.id} value={offer.id}>{offer.number} • {offer.customerName} • {statusOptions.find((status) => status.value === offer.status)?.label ?? offer.status}</option>
                      ))}
                    </select>
                  </label>
                  <form action={handleCreateVersion} className="flex flex-wrap gap-3">
                    <input type="hidden" name="offerId" value={selectedOffer.id} />
                    <Link href={`/offers/${selectedOffer.id}/pdf`} target="_blank" className="inline-flex h-11 items-center justify-center gap-2 rounded-[14px] border border-[#e5dfd1] bg-white px-4 text-sm font-medium text-[#4d4d4d] transition hover:border-[rgba(201,161,59,0.26)] hover:text-[#1f1f1f]">
                      <ExternalLink className="h-4 w-4" />
                      <span>Otwórz podgląd dokumentu</span>
                    </Link>
                    <button type="submit" className="inline-flex h-11 items-center justify-center gap-2 rounded-[14px] bg-[#c9a13b] px-4 text-sm font-medium text-white transition hover:bg-[#b8932f]">
                      <FileDown className="h-4 w-4" />
                      <span>Zapisz i otwórz dokument PDF</span>
                    </button>
                  </form>
                </div>
                <div className="flex flex-wrap gap-2 text-[11px] uppercase tracking-[0.16em] text-[#6b6b6b] lg:justify-end">
                  <span className="rounded-full border border-[#e7dfd0] bg-[#fcfbf8] px-3 py-1">{selectedOffer.number}</span>
                  <span className="rounded-full border border-[#e7dfd0] bg-[#fcfbf8] px-3 py-1">Klient: {selectedOffer.customerName}</span>
                  <span className="rounded-full border border-[#e7dfd0] bg-[#fcfbf8] px-3 py-1">{selectedOffer.leadId ? 'Lead przypisany' : 'Oferta wolna'}</span>
                </div>
              </div>
            </section>

            {!selectedOffer.leadId ? (
              <section className="grid gap-4 xl:grid-cols-2">
                  <form action={handleAssignOfferLead} className="rounded-[22px] border border-[#e8e1d4] bg-white p-4">
                    <input type="hidden" name="offerId" value={selectedOffer.id} />
                    <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Przypisz istniejącego leada</div>
                    <label className="mt-3 flex h-11 items-center gap-3 rounded-2xl border border-[#e8e1d4] bg-[#fcfbf8] px-4 text-sm text-[#5f5a4f]">
                      <Search className="h-4 w-4 text-[#9d7b27]" />
                      <input value={assignLeadSearchQuery} onChange={(event) => setAssignLeadSearchQuery(event.target.value)} className="h-full w-full bg-transparent text-sm text-[#1f1f1f] outline-none placeholder:text-[#8a826f]" placeholder="Wyszukaj klienta z leadów..." />
                    </label>
                    <select name="leadId" value={assignLeadId} onChange={(event) => setAssignLeadId(event.target.value)} className="mt-3 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]">
                      <option value="">Wybierz klienta z systemu</option>
                      {filteredAssignLeadOptions.map((lead) => (
                        <option key={lead.id} value={lead.id}>{lead.label}{lead.modelName ? ` • ${lead.modelName}` : ''}{lead.contact ? ` • ${lead.contact}` : ''}</option>
                      ))}
                    </select>
                    <button type="submit" className="mt-3 inline-flex h-11 items-center justify-center rounded-[14px] border border-[#e5dfd1] bg-white px-4 text-sm font-medium text-[#4d4d4d] transition hover:border-[rgba(201,161,59,0.26)] hover:text-[#1f1f1f]">
                      Przypisz tego leada
                    </button>
                  </form>

                  <form action={handleCreateLeadForOffer} className="rounded-[22px] border border-[#e8e1d4] bg-white p-4">
                    <input type="hidden" name="offerId" value={selectedOffer.id} />
                    <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Utwórz leada z tej oferty</div>
                    <div className="mt-3 grid gap-3 md:grid-cols-2">
                      <input name="fullName" value={newLeadFullName} onChange={(event) => setNewLeadFullName(event.target.value)} className="h-11 rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="Imię i nazwisko" />
                      <input name="region" value={newLeadRegion} onChange={(event) => setNewLeadRegion(event.target.value)} className="h-11 rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="Region" />
                    </div>
                    <div className="mt-3 grid gap-3 md:grid-cols-2">
                      <input name="email" value={newLeadEmail} onChange={(event) => setNewLeadEmail(event.target.value)} className="h-11 rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="Email" />
                      <input name="phone" value={newLeadPhone} onChange={(event) => setNewLeadPhone(event.target.value)} className="h-11 rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="Telefon" />
                    </div>
                    <button type="submit" className="mt-3 inline-flex h-11 items-center justify-center rounded-[14px] bg-[#c9a13b] px-4 text-sm font-semibold text-white transition hover:bg-[#b8932f]">
                      Utwórz leada i przypisz ofertę
                    </button>
                  </form>

                {leadBindingFeedback ? (
                  <div className="xl:col-span-2 rounded-[18px] border border-[#e8e1d4] bg-white px-4 py-3 text-sm text-[#555555]">{leadBindingFeedback}</div>
                ) : null}
              </section>
            ) : null}

            <div className="grid items-start gap-4 2xl:grid-cols-[minmax(0,0.95fr)_360px]">
              <form action={handleUpdateOffer} className="grid self-start gap-4 rounded-[28px] border border-[#e8e1d4] bg-white p-4 shadow-[0_18px_42px_rgba(31,31,31,0.05)] lg:p-5">
                <input type="hidden" name="offerId" value={selectedOffer.id} />
                <div className="grid gap-4 md:grid-cols-[minmax(260px,420px)_220px] md:items-end">
                  <label className="block max-w-[420px]">
                    <span className="text-sm font-medium text-[#1f1f1f]">Tytuł oferty</span>
                    <input name="title" value={editorTitle} onChange={(event) => setEditorTitle(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" />
                  </label>
                  <label className="block max-w-[220px]">
                    <span className="text-sm font-medium text-[#1f1f1f]">Status</span>
                    <select name="status" defaultValue={selectedOffer.status} className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]">
                      {statusOptions.map((status) => (
                        <option key={status.value} value={status.value}>{status.label}</option>
                      ))}
                    </select>
                  </label>
                </div>

                <div className="grid gap-4 md:grid-cols-[220px_220px] md:items-end">
                  <label className="block max-w-[220px]">
                    <span className="text-sm font-medium text-[#1f1f1f]">Typ klienta</span>
                    <select name="customerType" value={editorCustomerType} onChange={(event) => setEditorCustomerType(event.target.value as OfferCustomerType)} className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]">
                      <option value="PRIVATE">Klient prywatny</option>
                      <option value="BUSINESS">Firma</option>
                    </select>
                  </label>
                  <label className="block max-w-[220px]">
                    <span className="text-sm font-medium text-[#1f1f1f]">Ważna do</span>
                    <input type="date" name="validUntil" value={editorValidUntil} onChange={(event) => setEditorValidUntil(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" />
                  </label>
                </div>

                <label className="block max-w-[640px]">
                  <span className="text-sm font-medium text-[#1f1f1f]">Konfiguracja z polityki cenowej</span>
                  <select name="pricingCatalogKey" value={editorPricingCatalogKey} onChange={(event) => handleEditorPricingChange(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]">
                    <option value="">Wybierz konfigurację</option>
                    {pricingOptions.map((option) => (
                      <option key={option.key} value={option.key}>{option.label}</option>
                    ))}
                  </select>
                </label>

                <label className="block max-w-[520px]">
                  <span className="text-sm font-medium text-[#1f1f1f]">Kolor</span>
                  <div className="relative mt-2">
                    <Palette className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-[#9d7b27]" />
                    <select name="selectedColorName" value={editorSelectedColorName} onChange={(event) => setEditorSelectedColorName(event.target.value)} disabled={!selectedEditorPalette} className="h-11 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] pl-10 pr-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)] disabled:cursor-not-allowed disabled:opacity-60">
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
                    <span className="text-sm font-medium text-[#1f1f1f]">Rabat klienta (kwota PLN, nie %)</span>
                    <input type="number" step="0.01" name="discountValue" value={editorDiscountValue} onChange={(event) => setEditorDiscountValue(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="np. 3000 PLN" />
                    <div className="mt-2 text-xs text-[#8a826f]">Obecnie to pole oznacza kwotę rabatu. Jeśli chcesz rabat procentowy, dodamy osobny tryb.</div>
                    {editorPoolAmount !== null ? (
                      <div className="mt-1 text-xs text-[#8a826f]">Dostępna pula oferty: {formatMoney(editorPoolAmount)}. Po tym rabacie pozostaje: {formatMoney(editorRemainingPoolAmount)}.</div>
                    ) : null}
                  </label>
                  <label className="block">
                    <span className="text-sm font-medium text-[#1f1f1f]">Wariant finansowania</span>
                    <select name="financingVariant" value={editorFinancingVariant} onChange={(event) => setEditorFinancingVariant(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]">
                      <option value="">Brak</option>
                      {getFinancingVariantOptions(editorCustomerType).map((variant) => (
                        <option key={variant} value={variant}>{variant}</option>
                      ))}
                    </select>
                  </label>
                </div>

                <div className="grid gap-4 md:grid-cols-3">
                  <label className="block">
                    <span className="text-sm font-medium text-[#1f1f1f]">Okres finansowania</span>
                    <select name="financingTermMonths" value={editorFinancingTermMonths} onChange={(event) => setEditorFinancingTermMonths(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]">
                      <option value="">Brak</option>
                      <option value="24">24 mies.</option>
                      <option value="36">36 mies.</option>
                      <option value="48">48 mies.</option>
                      <option value="60">60 mies.</option>
                      <option value="71">71 mies.</option>
                    </select>
                  </label>
                  <label className="block">
                    <span className="text-sm font-medium text-[#1f1f1f]">Wpłata własna</span>
                    <input type="number" step="0.01" name="financingInputValue" value={editorFinancingInputValue} onChange={(event) => setEditorFinancingInputValue(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="np. 20000" />
                    <div className="mt-2 text-xs text-[#8a826f]">Pole przyjmuje wyłącznie kwotę w PLN.</div>
                  </label>
                  <label className="block">
                    <span className="text-sm font-medium text-[#1f1f1f]">Wykup (%)</span>
                    <input type="number" step="0.01" name="financingBuyoutPercent" value={editorFinancingBuyoutPercent} onChange={(event) => setEditorFinancingBuyoutPercent(event.target.value)} className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="np. 20" />
                    {editorBuyoutLimit !== null ? (
                      <div className={[
                        'mt-2 text-xs',
                        editorBuyoutError ? 'text-[#a64b45]' : 'text-[#8a826f]'
                      ].join(' ')}>
                        Maksymalny wykup dla {liveFinancingTermMonths} mies. wynosi {editorBuyoutLimit}%.
                      </div>
                    ) : null}
                    {editorBuyoutError ? <div className="mt-1 text-xs text-[#a64b45]">{editorBuyoutError}</div> : null}
                  </label>
                </div>

                <label className="block">
                  <span className="text-sm font-medium text-[#1f1f1f]">Uwagi do dokumentu</span>
                  <textarea name="notes" rows={6} value={editorNotes} onChange={(event) => setEditorNotes(event.target.value)} className="mt-2 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 py-3 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="Co ma się znaleźć w ofercie, jakie ustalenia ma zawierać dokument, jakie dodatki i warunki?" />
                </label>

                {editorFeedback ? (
                  <div className="rounded-[18px] border border-[#e8e1d4] bg-[#fcfbf8] px-4 py-3 text-sm text-[#555555]">{editorFeedback}</div>
                ) : null}

                <button type="submit" className="inline-flex h-11 items-center justify-center rounded-[14px] bg-[#c9a13b] px-4 text-sm font-medium text-white transition hover:bg-[#b8932f]">
                  Zapisz generator oferty
                </button>
              </form>

              <div className="grid self-start gap-4">
                <CalculationCard offer={previewOffer ?? selectedOffer} />
                <FinancingPreviewCard
                  customerType={editorCustomerType}
                  finalPriceGross={previewOffer?.calculation?.finalPriceGross ?? previewOffer?.totalGross ?? selectedOffer.calculation?.finalPriceGross ?? selectedOffer.totalGross}
                  finalPriceNet={previewOffer?.calculation?.finalPriceNet ?? previewOffer?.totalNet ?? selectedOffer.calculation?.finalPriceNet ?? selectedOffer.totalNet}
                  termMonths={liveFinancingTermMonths !== null && !Number.isNaN(liveFinancingTermMonths) ? liveFinancingTermMonths : null}
                  inputValue={liveFinancingInputValue !== null && !Number.isNaN(liveFinancingInputValue) ? liveFinancingInputValue : null}
                  buyoutPercent={liveFinancingBuyoutPercent !== null && !Number.isNaN(liveFinancingBuyoutPercent) ? liveFinancingBuyoutPercent : null}
                />

                <section className="rounded-[28px] border border-[#e8e1d4] bg-white p-4 shadow-[0_18px_42px_rgba(31,31,31,0.05)] lg:p-5">
                  <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Podgląd PDF</div>
                  <div className="mt-1 text-sm text-[#6b6b6b]">To jest podgląd treści dokumentu. Pobranie pliku następuje po kliknięciu "Zapisz i otwórz dokument PDF".</div>
                  <div className="mt-4 rounded-[24px] border border-[#e8e1d4] bg-[linear-gradient(180deg,#ffffff,#faf8f3)] p-5">
                    <div className="text-[11px] uppercase tracking-[0.16em] text-[#8a826f]">Dokument handlowy</div>
                    <div className="mt-2 text-2xl font-semibold text-[#1f1f1f]">{previewOffer?.title ?? selectedOffer.title}</div>
                    <div className="mt-4 grid gap-2 text-sm text-[#555555]">
                      <div>Klient: {previewOffer?.customerName ?? selectedOffer.customerName}</div>
                      <div>Kontakt: {previewOffer?.customerEmail ?? previewOffer?.customerPhone ?? selectedOffer.customerEmail ?? selectedOffer.customerPhone ?? 'Do uzupełnienia'}</div>
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
                    <div className="mt-5 rounded-[18px] border border-[#eee6d9] bg-[#fcfbf8] p-4 text-sm leading-6 text-[#555555]">
                      {previewOffer?.notes ?? 'Dodaj uwagi do oferty, aby przygotować treść dokumentu dla klienta.'}
                    </div>
                  </div>
                </section>

                <section className="rounded-[28px] border border-[#e8e1d4] bg-white p-4 shadow-[0_18px_42px_rgba(31,31,31,0.05)] lg:p-5">
                  <div className="flex items-center justify-between gap-3">
                    <div>
                      <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Historia wersji</div>
                      <div className="mt-1 text-sm text-[#6b6b6b]">Snapshoty gotowe pod kolejne PDF-y dla klienta.</div>
                    </div>
                    <div className="rounded-full border border-[#e7dfd0] bg-[#fcfbf8] px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#7a7262]">
                      {selectedOffer.versions.length} wersji
                    </div>
                  </div>

                  <div className="mt-4 grid gap-3">
                    {selectedOffer.versions.length > 0 ? selectedOffer.versions.map((version) => (
                      <article key={version.id} className="rounded-[20px] border border-[#e8e1d4] bg-[#fcfbf8] p-4">
                        <div className="flex items-center justify-between gap-3">
                          <div className="text-sm font-semibold text-[#1f1f1f]">Wersja {version.versionNumber}</div>
                          <div className="text-[11px] uppercase tracking-[0.16em] text-[#8a826f]">{formatDate(version.createdAt)}</div>
                        </div>
                        <div className="mt-2 text-sm leading-6 text-[#555555]">{version.summary}</div>
                        {version.pdfUrl ? (
                          <div className="mt-3">
                            <Link href={version.pdfUrl} target="_blank" className="inline-flex items-center gap-2 text-sm font-medium text-[#8f6b18] transition hover:text-[#1f1f1f]">
                              <ExternalLink className="h-4 w-4" />
                              <span>Otwórz tę wersję i zapisz PDF</span>
                            </Link>
                          </div>
                        ) : null}
                      </article>
                    )) : (
                      <div className="rounded-[20px] border border-dashed border-[#e7dfd0] bg-[#fcfbf8] px-4 py-8 text-center text-sm text-[#8a826f]">
                        Brak zapisanych wersji. Kliknij "Zapisz i otwórz dokument PDF", aby utworzyć pierwszą wersję do pobrania.
                      </div>
                    )}
                  </div>
                </section>
              </div>
            </div>
          </div>
        ) : (
          <div className="rounded-[28px] border border-dashed border-[#e7dfd0] bg-[#fcfbf8] px-4 py-20 text-center text-sm text-[#8a826f]">
            Zacznij od kliknięcia jednego z przycisków na górze: oferta dla klienta z systemu albo oferta wolna bez przypisanego leada.
          </div>
        )}
      </section>

    </main>
  )
}