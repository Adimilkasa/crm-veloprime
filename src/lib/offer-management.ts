import 'server-only'

import { OfferColorKind, Prisma } from '@prisma/client'

import type { AuthSession } from '@/lib/auth'
import { getDemoUsers } from '@/lib/auth'
import { findColorPalette, listColorPalettes, type ModelColorPalette } from '@/lib/color-management'
import { listActiveCommissionRules } from '@/lib/commission-management'
import { db, hasDatabaseUrl } from '@/lib/db'
import { calculateOfferFinancing, type FinancingInputMode, type OfferFinancingSummary } from '@/lib/offer-financing'
import { createManagedLead, listManagedLeads, listManagedLeadStages, type ManagedLead } from '@/lib/lead-management'
import { calculateOfferSummary, type OfferCalculationSummary, type OfferCustomerType } from '@/lib/offer-calculations'
import { buildDetailedPricingCatalog, type DetailedPricingCatalogItem } from '@/lib/pricing-catalog'
import { getActivePricingSheet } from '@/lib/pricing-management'
import { listManagedUsers, type ManagedUser } from '@/lib/user-management'

export type OfferStatus = 'DRAFT' | 'SENT' | 'APPROVED' | 'REJECTED' | 'EXPIRED'

export type OfferVersion = {
  id: string
  versionNumber: number
  summary: string
  createdAt: string
  pdfUrl: string | null
  payloadJson: OfferDocumentPayload | null
  customerSnapshotJson: OfferCustomerSnapshot | null
  internalSnapshotJson: OfferInternalSnapshot | null
}

export type OfferCustomerSnapshot = {
  offerNumber: string
  title: string
  customerName: string
  customerEmail: string | null
  customerPhone: string | null
  modelName: string | null
  selectedColorName: string | null
  financingVariant: string | null
  notes: string | null
  validUntil: string | null
  listPriceLabel: string
  discountLabel: string
  discountPercentLabel: string
  finalGrossLabel: string
  finalNetLabel: string
  financingSummary: string | null
  financingDisclaimer: string | null
  createdAt: string
}

export type OfferInternalSnapshot = {
  catalogKey: string | null
  customerType: OfferCustomerType
  listPriceGross: number | null
  listPriceNet: number | null
  basePriceGross: number | null
  basePriceNet: number | null
  colorSurchargeGross: number | null
  colorSurchargeNet: number | null
  marginPoolGross: number | null
  marginPoolNet: number | null
  directorShare: number | null
  managerShare: number | null
  availableDiscount: number | null
  appliedDiscount: number | null
  salespersonCommission: number | null
  finalPriceGross: number | null
  finalPriceNet: number | null
  selectedColorName: string | null
  baseColorName: string | null
  ownerName: string
  ownerRole: AuthSession['role']
  financing: OfferFinancingSummary | null
  generatedAt: string
}

export type OfferDocumentPayload = {
  versionId: string
  versionNumber: number
  createdAt: string
  customer: OfferCustomerSnapshot
  internal: OfferInternalSnapshot
}

export type ManagedOffer = {
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
  financingInputMode: FinancingInputMode
  financingInputValue: number | null
  financingBuyoutPercent: number | null
  notes: string | null
  versions: OfferVersion[]
  createdAt: string
  updatedAt: string
}

export type ManagedOfferWithCalculation = ManagedOffer & {
  calculation: OfferCalculationSummary | null
}

export type OfferLeadOption = {
  id: string
  label: string
  modelName: string | null
  contact: string | null
  ownerName: string | null
}

export type OfferPricingOption = {
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

export type OfferColorPaletteOption = ModelColorPalette

const globalForOffers = globalThis as unknown as {
  crmOffers?: ManagedOffer[]
}

type DbOfferRecord = Prisma.OfferGetPayload<{
  include: {
    customer: true
    owner: true
    salesCatalogItem: true
    financing: true
    versions: true
  }
}>

export const offerStatusOptions: Array<{ value: OfferStatus; label: string }> = [
  { value: 'DRAFT', label: 'Szkic' },
  { value: 'SENT', label: 'Wysłana' },
  { value: 'APPROVED', label: 'Zaakceptowana' },
  { value: 'REJECTED', label: 'Odrzucona' },
  { value: 'EXPIRED', label: 'Wygasła' },
]

function canViewOffer(session: AuthSession, offer: ManagedOffer) {
  if (session.role === 'ADMIN' || session.role === 'DIRECTOR' || session.role === 'MANAGER') {
    return true
  }

  return offer.ownerId === session.sub
}

function normalizeComparable(value: string | null | undefined) {
  return value?.trim().toLowerCase() ?? ''
}

function matchLeadForOffer(leads: ManagedLead[], offer: Pick<ManagedOffer, 'customerName' | 'customerEmail' | 'customerPhone'>) {
  const normalizedName = normalizeComparable(offer.customerName)
  const normalizedEmail = normalizeComparable(offer.customerEmail)
  const normalizedPhone = normalizeComparable(offer.customerPhone)

  return leads.find((lead) => {
    const sameEmail = normalizedEmail && normalizeComparable(lead.email) === normalizedEmail
    const samePhone = normalizedPhone && normalizeComparable(lead.phone) === normalizedPhone
    const sameName = normalizedName && normalizeComparable(lead.fullName) === normalizedName

    return Boolean(sameEmail || samePhone || (sameName && (!normalizedEmail || !normalizedPhone)))
  }) ?? null
}

function formatMoney(value: number | null) {
  if (value === null) {
    return 'kwota do ustalenia'
  }

  return new Intl.NumberFormat('pl-PL', {
    style: 'currency',
    currency: 'PLN',
    maximumFractionDigits: 2,
  }).format(value)
}

function formatPercent(value: number) {
  return `${value.toFixed(2).replace('.', ',')}%`
}

function buildFinancingPersistence(input: {
  financingTermMonths: number | null
  financingInputMode: FinancingInputMode
  financingInputValue: number | null
  financingBuyoutPercent: number | null
  financingSummary: OfferFinancingSummary | null
}) {
  if (
    input.financingTermMonths === null
    || input.financingInputValue === null
    || input.financingBuyoutPercent === null
  ) {
    return null
  }

  return {
    termMonths: input.financingTermMonths,
    downPaymentInputMode: input.financingInputMode,
    downPaymentInputValue: input.financingInputValue,
    downPaymentAmount: input.financingSummary?.downPaymentAmount ?? null,
    downPaymentPercent: input.financingSummary?.downPaymentPercent ?? null,
    buyoutPercent: input.financingBuyoutPercent,
    buyoutAmount: input.financingSummary?.buyoutAmount ?? null,
    financedAssetValue: input.financingSummary?.financedAssetValue ?? null,
    leaseTotalFactor: input.financingSummary?.leaseTotalFactor ?? null,
    totalLeaseCost: input.financingSummary?.totalLeaseCost ?? null,
    estimatedInstallment: input.financingSummary?.estimatedInstallment ?? null,
    disclaimerText: input.financingSummary?.disclaimerText ?? null,
  } satisfies Prisma.OfferFinancingCreateWithoutOfferInput
}

function nextOfferNumber(offers: ManagedOffer[]) {
  const now = new Date()
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')
  const sequence = String(offers.length + 1).padStart(3, '0')

  return `OFR-${year}${month}${day}-${sequence}`
}

async function buildSeedOffers() {
  const adminSession = getDemoUsers().find((user) => user.role === 'ADMIN') ?? getDemoUsers()[0]
  const leads = adminSession ? await listManagedLeads(adminSession) : []

  return leads.slice(0, 2).map((lead, index) => {
    const createdAt = new Date(Date.now() - (index + 1) * 86400000).toISOString()

    return {
      id: `offer-seed-${index + 1}`,
      number: `OFR-2026032${index + 1}-00${index + 1}`,
      status: index === 0 ? 'DRAFT' : 'SENT',
      title: `Oferta ${lead.interestedModel ?? 'samochodu'} dla ${lead.fullName}`,
      leadId: lead.id,
      customerName: lead.fullName,
      customerEmail: lead.email,
      customerPhone: lead.phone,
      modelName: lead.interestedModel,
      pricingCatalogKey: null,
      selectedColorName: null,
      customerType: 'PRIVATE',
      discountValue: null,
      ownerId: lead.salespersonId ?? adminSession?.sub ?? 'demo-admin',
      ownerName: lead.salespersonName ?? adminSession?.fullName ?? 'Administrator VeloPrime',
      validUntil: new Date(Date.now() + (index + 5) * 86400000).toISOString(),
      totalGross: index === 0 ? 184900 : 203500,
      totalNet: index === 0 ? 150325.2 : 165447.15,
      financingVariant: index === 0 ? 'Leasing 36 miesięcy / wpłata 15%' : 'Wynajem długoterminowy 48 miesięcy',
      financingTermMonths: index === 0 ? 36 : 48,
      financingInputMode: 'AMOUNT',
      financingInputValue: index === 0 ? 27735 : 20350,
      financingBuyoutPercent: index === 0 ? 30 : 20,
      notes: index === 0 ? 'Uwzględniono pakiet serwisowy i odbiór w Warszawie.' : 'Klient prosi o porównanie z finansowaniem gotówkowym.',
      versions: [
        {
          id: `offer-seed-${index + 1}-version-1`,
          versionNumber: 1,
          summary: `Wersja startowa / ${lead.interestedModel ?? 'model'} / ${formatMoney(index === 0 ? 184900 : 203500)}`,
          createdAt,
          pdfUrl: null,
          payloadJson: null,
          customerSnapshotJson: null,
          internalSnapshotJson: null,
        },
      ],
      createdAt,
      updatedAt: createdAt,
    } satisfies ManagedOffer
  })
}

async function getStore() {
  if (!globalForOffers.crmOffers) {
    globalForOffers.crmOffers = await buildSeedOffers()
  }

  return globalForOffers.crmOffers
}

function buildOfferVersionSnapshot(offer: ManagedOfferWithCalculation, versionId: string, versionNumber: number): OfferDocumentPayload {
  const discountAmount = offer.calculation?.appliedDiscount ?? offer.discountValue ?? 0
  const referencePrice = offer.customerType === 'BUSINESS'
    ? offer.calculation?.listPriceNet ?? offer.totalNet ?? 0
    : offer.calculation?.listPriceGross ?? offer.totalGross ?? 0
  const discountPercent = referencePrice > 0 ? (discountAmount / referencePrice) * 100 : 0
  const createdAt = new Date().toISOString()
  const financing = calculateOfferFinancing({
    customerType: offer.customerType,
    finalPriceGross: offer.totalGross,
    finalPriceNet: offer.totalNet,
    termMonths: offer.financingTermMonths,
    downPaymentInputMode: offer.financingInputMode,
    downPaymentInputValue: offer.financingInputValue,
    buyoutPercent: offer.financingBuyoutPercent,
  })
  const financingSummary = financing && financing.ok
    ? `${financing.summary.termMonths} mies. / wplata ${formatMoney(financing.summary.downPaymentAmount)} / wykup ${formatPercent(financing.summary.buyoutPercent)} / rata od ${formatMoney(financing.summary.estimatedInstallment)}`
    : offer.financingVariant

  return {
    versionId,
    versionNumber,
    createdAt,
    customer: {
      offerNumber: offer.number,
      title: offer.title,
      customerName: offer.customerName,
      customerEmail: offer.customerEmail,
      customerPhone: offer.customerPhone,
      modelName: offer.modelName,
      selectedColorName: offer.calculation?.selectedColorName ?? offer.selectedColorName,
      financingVariant: offer.financingVariant,
      notes: offer.notes,
      validUntil: offer.validUntil,
      listPriceLabel: formatMoney(offer.customerType === 'BUSINESS' ? offer.calculation?.listPriceNet ?? offer.totalNet : offer.calculation?.listPriceGross ?? offer.totalGross),
      discountLabel: formatMoney(discountAmount),
      discountPercentLabel: formatPercent(discountPercent),
      finalGrossLabel: formatMoney(offer.totalGross),
      finalNetLabel: formatMoney(offer.totalNet),
      financingSummary,
      financingDisclaimer: financing && financing.ok ? financing.summary.disclaimerText : null,
      createdAt,
    },
    internal: {
      catalogKey: offer.pricingCatalogKey,
      customerType: offer.customerType,
      listPriceGross: offer.calculation?.listPriceGross ?? null,
      listPriceNet: offer.calculation?.listPriceNet ?? null,
      basePriceGross: offer.calculation?.basePriceGross ?? null,
      basePriceNet: offer.calculation?.basePriceNet ?? null,
      colorSurchargeGross: offer.calculation?.colorSurchargeGross ?? null,
      colorSurchargeNet: offer.calculation?.colorSurchargeNet ?? null,
      marginPoolGross: offer.calculation?.marginPoolGross ?? null,
      marginPoolNet: offer.calculation?.marginPoolNet ?? null,
      directorShare: offer.calculation?.directorShare ?? null,
      managerShare: offer.calculation?.managerShare ?? null,
      availableDiscount: offer.calculation?.availableDiscount ?? null,
      appliedDiscount: offer.calculation?.appliedDiscount ?? null,
      salespersonCommission: offer.calculation?.salespersonCommission ?? null,
      finalPriceGross: offer.calculation?.finalPriceGross ?? offer.totalGross,
      finalPriceNet: offer.calculation?.finalPriceNet ?? offer.totalNet,
      selectedColorName: offer.calculation?.selectedColorName ?? offer.selectedColorName,
      baseColorName: offer.calculation?.baseColorName ?? null,
      ownerName: offer.ownerName,
      ownerRole: offer.calculation?.ownerRole ?? 'SALES',
      financing: financing && financing.ok ? financing.summary : null,
      generatedAt: createdAt,
    },
  }
}

async function resolveOfferPricing(input: {
  pricingCatalogKey?: string
  customerType: OfferCustomerType
  discountValue: number | null
  ownerId: string
  selectedColorName?: string | null
}) {
  if (!input.pricingCatalogKey) {
    return null
  }

  const [pricingSheet, commissionRules, users] = await Promise.all([
    getActivePricingSheet(),
    listActiveCommissionRules(),
    listManagedUsers(),
  ])

  const catalogItem = buildDetailedPricingCatalog(pricingSheet).find((item) => item.key === input.pricingCatalogKey)

  if (!catalogItem) {
    return { ok: false as const, error: 'Wybrana konfiguracja cenowa nie istnieje w zapisanej polityce cenowej.' }
  }

  const colorPalette = await findColorPalette(catalogItem.brand, catalogItem.model)
  const resolvedColorName = input.selectedColorName?.trim()
    ? colorPalette?.colors.find((color) => color.name === input.selectedColorName?.trim())?.name ?? null
    : colorPalette?.colors.find((color) => color.isBase)?.name ?? colorPalette?.baseColorName ?? null

  const calculation = calculateOfferSummary({
    catalogItem,
    ownerId: input.ownerId,
    users,
    commissionRules,
    customerType: input.customerType,
    discountValue: input.discountValue,
    colorPalette,
    selectedColorName: resolvedColorName,
  })

  if (!calculation) {
    return { ok: false as const, error: 'Wybrana konfiguracja nie ma kompletnych cen katalogowych i bazowych.' }
  }

  return { ok: true as const, catalogItem, calculation, selectedColorName: resolvedColorName, colorPalette }
}

export async function listManagedOffers(session: AuthSession) {
  const leads = await listManagedLeads(session)

  if (isPrismaOfferStorageEnabled() && db) {
    const offers = await db.offer.findMany({
      include: {
        customer: true,
        owner: true,
        salesCatalogItem: true,
        financing: true,
        versions: true,
      },
      orderBy: {
        updatedAt: 'desc',
      },
    })

    return offers
      .map((offer) => {
        const mapped = mapDbOfferToManagedOffer(offer)
        const matchedLead = matchLeadForOffer(leads, mapped)
        return matchedLead ? { ...mapped, leadId: matchedLead.id } : mapped
      })
      .filter((offer) => canViewOffer(session, offer))
  }

  const offers = await getStore()

  return [...offers]
    .filter((offer) => canViewOffer(session, offer))
    .sort((left, right) => new Date(right.updatedAt).getTime() - new Date(left.updatedAt).getTime())
}

export async function listManagedOffersWithCalculation(session: AuthSession) {
  const [offers, pricingSheet, commissionRules, users, colorPalettes] = await Promise.all([
    listManagedOffers(session),
    getActivePricingSheet(),
    listActiveCommissionRules(),
    listManagedUsers(),
    listColorPalettes(),
  ])

  const catalogByKey = new Map(buildDetailedPricingCatalog(pricingSheet).map((item) => [item.key, item]))
  const paletteByKey = new Map(colorPalettes.map((palette) => [palette.paletteKey, palette]))

  return offers.map((offer) => ({
    ...offer,
    calculation: offer.pricingCatalogKey
      ? (() => {
          const catalogItem = catalogByKey.get(offer.pricingCatalogKey)
          const colorPalette = catalogItem ? paletteByKey.get(`${catalogItem.brand.toLowerCase()}::${catalogItem.model.toLowerCase()}`) ?? null : null
          return catalogItem
            ? calculateOfferSummary({
                catalogItem,
                ownerId: offer.ownerId,
                users,
                commissionRules,
                customerType: offer.customerType,
                discountValue: offer.discountValue,
                colorPalette,
                selectedColorName: offer.selectedColorName,
              })
            : null
        })()
      : null,
  })) satisfies ManagedOfferWithCalculation[]
}

export async function getManagedOfferWithCalculation(session: AuthSession, offerId: string) {
  const offers = await listManagedOffersWithCalculation(session)
  return offers.find((offer) => offer.id === offerId) ?? null
}

export async function getOfferDocumentSnapshot(session: AuthSession, offerId: string, versionId?: string | null) {
  const offer = await getManagedOfferWithCalculation(session, offerId)

  if (!offer) {
    return null
  }

  const version = versionId
    ? offer.versions.find((entry) => entry.id === versionId) ?? null
    : offer.versions[0] ?? null

  if (version?.payloadJson && version.customerSnapshotJson && version.internalSnapshotJson) {
    return {
      offer,
      version,
      payload: version.payloadJson,
    }
  }

  return {
    offer,
    version,
    payload: buildOfferVersionSnapshot(offer, version?.id ?? `offer-live-${offer.id}`, version?.versionNumber ?? offer.versions.length),
  }
}

export async function listOfferLeadOptions(session: AuthSession) {
  const leads = await listManagedLeads(session)

  return leads.map((lead) => ({
    id: lead.id,
    label: lead.fullName,
    modelName: lead.interestedModel,
    contact: lead.email ?? lead.phone,
    ownerName: lead.salespersonName,
  })) satisfies OfferLeadOption[]
}

export async function listOfferPricingOptions() {
  const pricingSheet = await getActivePricingSheet()

  return buildDetailedPricingCatalog(pricingSheet).map((item) => ({
    key: item.key,
    label: item.label,
    brand: item.brand,
    model: item.model,
    version: item.version,
    year: item.year,
    powertrain: item.powertrain,
    powerHp: item.powerHp,
    listPriceGross: item.listPriceGross,
    listPriceNet: item.listPriceNet,
    basePriceGross: item.basePriceGross,
    basePriceNet: item.basePriceNet,
    marginPoolGross: item.marginPoolGross,
    marginPoolNet: item.marginPoolNet,
  })) satisfies OfferPricingOption[]
}

export async function listOfferColorPalettes() {
  return listColorPalettes()
}

export async function createManagedOffer(
  session: AuthSession,
  input: {
    leadId?: string
    customerName?: string
    customerEmail?: string
    customerPhone?: string
    customerRegion?: string
    title: string
    pricingCatalogKey?: string
    selectedColorName?: string
    customerType?: OfferCustomerType
    discountValue?: string
    financingVariant?: string
    financingTermMonths?: string
    financingInputMode?: FinancingInputMode
    financingInputValue?: string
    financingBuyoutPercent?: string
    validUntil?: string
    notes?: string
  }
) {
  const leads = await listManagedLeads(session)
  const lead = input.leadId?.trim() ? leads.find((entry) => entry.id === input.leadId?.trim()) ?? null : null

  if (input.leadId?.trim() && !lead) {
    return { ok: false as const, error: 'Wybierz poprawnego leada do utworzenia oferty.' }
  }

  const customerNameInput = input.customerName?.trim() ?? ''
  const customerName = (lead?.fullName ?? customerNameInput) || 'Klient do uzupełnienia'
  const customerEmail = lead?.email ?? (input.customerEmail?.trim() || null)
  const customerPhone = lead?.phone ?? (input.customerPhone?.trim() || null)
  const customerRegion = lead?.region ?? (input.customerRegion?.trim() || null)

  if (lead && !customerName) {
    return { ok: false as const, error: 'Podaj klienta albo wybierz istniejącego leada.' }
  }

  if (lead && !customerEmail && !customerPhone) {
    return { ok: false as const, error: 'Podaj email lub telefon klienta, aby zapisać ofertę.' }
  }

  const title = input.title.trim() || (lead ? `Oferta ${lead?.interestedModel ?? 'sprzedażowa'} dla ${customerName}` : 'Nowa oferta')
  const customerType = input.customerType === 'BUSINESS' ? 'BUSINESS' : 'PRIVATE'
  const discountValue = input.discountValue?.trim() ? Number(input.discountValue) : null
  const financingTermMonths = input.financingTermMonths?.trim() ? Number(input.financingTermMonths) : null
  const financingInputValue = input.financingInputValue?.trim() ? Number(input.financingInputValue) : null
  const financingBuyoutPercent = input.financingBuyoutPercent?.trim() ? Number(input.financingBuyoutPercent) : null
  const financingInputMode = 'AMOUNT'

  if (input.discountValue?.trim() && (discountValue === null || Number.isNaN(discountValue))) {
    return { ok: false as const, error: 'Rabat klienta musi być poprawną liczbą.' }
  }

  if (input.financingTermMonths?.trim() && (financingTermMonths === null || Number.isNaN(financingTermMonths))) {
    return { ok: false as const, error: 'Okres finansowania musi być poprawną liczbą.' }
  }

  if (input.financingInputValue?.trim() && (financingInputValue === null || Number.isNaN(financingInputValue))) {
    return { ok: false as const, error: 'Wpłata własna musi być poprawną liczbą.' }
  }

  if (input.financingBuyoutPercent?.trim() && (financingBuyoutPercent === null || Number.isNaN(financingBuyoutPercent))) {
    return { ok: false as const, error: 'Wykup musi być poprawną liczbą.' }
  }

  const ownerId = lead?.salespersonId ?? session.sub
  const pricingSheet = await getActivePricingSheet()
  const catalogItems = buildDetailedPricingCatalog(pricingSheet)
  const pricingResult = await resolveOfferPricing({
    pricingCatalogKey: input.pricingCatalogKey?.trim() || undefined,
    customerType,
    discountValue,
    ownerId,
    selectedColorName: input.selectedColorName,
  })

  if (pricingResult && !pricingResult.ok) {
    return pricingResult
  }

  if (pricingResult && pricingResult.ok) {
    const financingResult = calculateOfferFinancing({
      customerType,
      finalPriceGross: pricingResult.calculation.finalPriceGross,
      finalPriceNet: pricingResult.calculation.finalPriceNet,
      termMonths: financingTermMonths,
      downPaymentInputMode: financingInputMode,
      downPaymentInputValue: financingInputValue,
      buyoutPercent: financingBuyoutPercent,
    })

    if (financingResult && !financingResult.ok) {
      return financingResult
    }
  }

  const financingResult = pricingResult && pricingResult.ok
    ? calculateOfferFinancing({
        customerType,
        finalPriceGross: pricingResult.calculation.finalPriceGross,
        finalPriceNet: pricingResult.calculation.finalPriceNet,
        termMonths: financingTermMonths,
        downPaymentInputMode: financingInputMode,
        downPaymentInputValue: financingInputValue,
        buyoutPercent: financingBuyoutPercent,
      })
    : null

  const financingPersistence = buildFinancingPersistence({
    financingTermMonths,
    financingInputMode,
    financingInputValue,
    financingBuyoutPercent,
    financingSummary: financingResult && financingResult.ok ? financingResult.summary : null,
  })

  if (isPrismaOfferStorageEnabled() && db) {
    const users = await listManagedUsers()
    await ensureUsersInDb(users)
    const catalogIds = await syncCatalogItemsToDb(catalogItems)
    const customer = lead
      ? await ensureCustomerFromLead(lead, ownerId)
      : await ensureCustomerRecord({
          fullName: customerName,
          email: customerEmail,
          phone: customerPhone,
          city: customerRegion,
          notes: input.notes?.trim() || null,
          ownerId,
        })

    if (!customer) {
      return { ok: false as const, error: 'Nie udało się przygotować klienta do zapisu w bazie.' }
    }

    const offers = await listManagedOffers(session)
    const created = await db.offer.create({
      data: {
        number: nextOfferNumber(offers),
        status: 'DRAFT',
        title,
        customerId: customer.id,
        ownerId,
        salesCatalogItemId: pricingResult && pricingResult.ok ? catalogIds.get(pricingResult.catalogItem.key) ?? null : null,
        customerType,
        selectedColorKind: pricingResult && pricingResult.ok && pricingResult.calculation.colorSurchargeGross > 0 ? OfferColorKind.EXTRA_PAID : OfferColorKind.BASE,
        selectedColorName: pricingResult && pricingResult.ok ? pricingResult.selectedColorName : null,
        colorSurchargeGross: pricingResult && pricingResult.ok ? pricingResult.calculation.colorSurchargeGross : null,
        colorSurchargeNet: pricingResult && pricingResult.ok ? pricingResult.calculation.colorSurchargeNet : null,
        discountAmount: discountValue,
        validUntil: input.validUntil?.trim() ? new Date(input.validUntil) : null,
        totalGross: pricingResult && pricingResult.ok ? pricingResult.calculation.finalPriceGross : null,
        totalNet: pricingResult && pricingResult.ok ? pricingResult.calculation.finalPriceNet : null,
        financingVariant: input.financingVariant?.trim() || null,
        notes: input.notes?.trim() || lead?.message || null,
        ...(financingPersistence ? { financing: { create: financingPersistence } } : {}),
      },
      include: {
        customer: true,
        owner: true,
        salesCatalogItem: true,
        financing: true,
        versions: true,
      },
    })

    return { ok: true as const, offer: mapDbOfferToManagedOffer(created) }
  }

  const offers = await getStore()
  const nextOffer: ManagedOffer = {
    id: `offer-${crypto.randomUUID()}`,
    number: nextOfferNumber(offers),
    status: 'DRAFT',
    title,
    leadId: lead?.id ?? null,
    customerName,
    customerEmail,
    customerPhone,
    modelName: pricingResult && pricingResult.ok ? `${pricingResult.catalogItem.brand} ${pricingResult.catalogItem.model} ${pricingResult.catalogItem.version}` : lead?.interestedModel ?? null,
    pricingCatalogKey: pricingResult && pricingResult.ok ? pricingResult.catalogItem.key : null,
    selectedColorName: pricingResult && pricingResult.ok ? pricingResult.selectedColorName : null,
    customerType,
    discountValue,
    ownerId,
    ownerName: lead?.salespersonName ?? session.fullName,
    validUntil: input.validUntil?.trim() ? new Date(input.validUntil).toISOString() : null,
    totalGross: pricingResult && pricingResult.ok ? pricingResult.calculation.finalPriceGross : null,
    totalNet: pricingResult && pricingResult.ok ? pricingResult.calculation.finalPriceNet : null,
    financingVariant: input.financingVariant?.trim() || null,
    financingTermMonths,
    financingInputMode,
    financingInputValue,
    financingBuyoutPercent,
    notes: input.notes?.trim() || lead?.message || null,
    versions: [],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  }

  offers.unshift(nextOffer)

  return { ok: true as const, offer: nextOffer }
}

export async function updateManagedOffer(
  session: AuthSession,
  input: {
    offerId: string
    title: string
    status: OfferStatus
    customerName?: string
    customerEmail?: string
    customerPhone?: string
    customerRegion?: string
    pricingCatalogKey?: string
    selectedColorName?: string
    customerType?: OfferCustomerType
    discountValue?: string
    financingVariant?: string
    financingTermMonths?: string
    financingInputMode?: FinancingInputMode
    financingInputValue?: string
    financingBuyoutPercent?: string
    validUntil?: string
    notes?: string
  }
) {
  const offer = isPrismaOfferStorageEnabled()
    ? await getManagedOfferWithCalculation(session, input.offerId)
    : (await getStore()).find((entry) => entry.id === input.offerId) ?? null

  if (!offer) {
    return { ok: false as const, error: 'Nie znaleziono oferty.' }
  }

  if (!canViewOffer(session, offer)) {
    return { ok: false as const, error: 'Nie masz dostępu do tej oferty.' }
  }

  const customerType = input.customerType === 'BUSINESS' ? 'BUSINESS' : 'PRIVATE'
  const customerName = input.customerName?.trim() || offer.customerName || 'Klient do uzupełnienia'
  const customerEmail = input.customerEmail?.trim() || null
  const customerPhone = input.customerPhone?.trim() || null
  const customerRegion = input.customerRegion?.trim() || null
  const discountValue = input.discountValue?.trim() ? Number(input.discountValue) : null
  const financingTermMonths = input.financingTermMonths?.trim() ? Number(input.financingTermMonths) : null
  const financingInputValue = input.financingInputValue?.trim() ? Number(input.financingInputValue) : null
  const financingBuyoutPercent = input.financingBuyoutPercent?.trim() ? Number(input.financingBuyoutPercent) : null
  const financingInputMode = 'AMOUNT'

  if (input.discountValue?.trim() && (discountValue === null || Number.isNaN(discountValue))) {
    return { ok: false as const, error: 'Rabat klienta musi być poprawną liczbą.' }
  }

  if (input.financingTermMonths?.trim() && (financingTermMonths === null || Number.isNaN(financingTermMonths))) {
    return { ok: false as const, error: 'Okres finansowania musi być poprawną liczbą.' }
  }

  if (input.financingInputValue?.trim() && (financingInputValue === null || Number.isNaN(financingInputValue))) {
    return { ok: false as const, error: 'Wpłata własna musi być poprawną liczbą.' }
  }

  if (input.financingBuyoutPercent?.trim() && (financingBuyoutPercent === null || Number.isNaN(financingBuyoutPercent))) {
    return { ok: false as const, error: 'Wykup musi być poprawną liczbą.' }
  }

  const pricingResult = await resolveOfferPricing({
    pricingCatalogKey: input.pricingCatalogKey?.trim() || undefined,
    customerType,
    discountValue,
    ownerId: offer.ownerId,
    selectedColorName: input.selectedColorName,
  })

  if (pricingResult && !pricingResult.ok) {
    return pricingResult
  }

  if (pricingResult && pricingResult.ok) {
    const financingResult = calculateOfferFinancing({
      customerType,
      finalPriceGross: pricingResult.calculation.finalPriceGross,
      finalPriceNet: pricingResult.calculation.finalPriceNet,
      termMonths: financingTermMonths,
      downPaymentInputMode: financingInputMode,
      downPaymentInputValue: financingInputValue,
      buyoutPercent: financingBuyoutPercent,
    })

    if (financingResult && !financingResult.ok) {
      return financingResult
    }
  }

  const financingResult = pricingResult && pricingResult.ok
    ? calculateOfferFinancing({
        customerType,
        finalPriceGross: pricingResult.calculation.finalPriceGross,
        finalPriceNet: pricingResult.calculation.finalPriceNet,
        termMonths: financingTermMonths,
        downPaymentInputMode: financingInputMode,
        downPaymentInputValue: financingInputValue,
        buyoutPercent: financingBuyoutPercent,
      })
    : null

  const financingPersistence = buildFinancingPersistence({
    financingTermMonths,
    financingInputMode,
    financingInputValue,
    financingBuyoutPercent,
    financingSummary: financingResult && financingResult.ok ? financingResult.summary : null,
  })

  if (isPrismaOfferStorageEnabled() && db) {
    const pricingSheet = await getActivePricingSheet()
    const catalogItems = buildDetailedPricingCatalog(pricingSheet)
    await ensureUsersInDb(await listManagedUsers())
    const catalogIds = await syncCatalogItemsToDb(catalogItems)

    if (!offer.leadId) {
      const offerRecord = await db.offer.findUnique({
        where: { id: input.offerId },
        select: { customerId: true },
      })

      if (offerRecord?.customerId) {
        await db.customer.update({
          where: { id: offerRecord.customerId },
          data: {
            fullName: customerName,
            email: customerEmail,
            phone: customerPhone,
            city: customerRegion,
          },
        })
      }
    }

    const updated = await db.offer.update({
      where: { id: input.offerId },
      data: {
        title: input.title.trim() || offer.title,
        status: input.status,
        salesCatalogItemId: pricingResult && pricingResult.ok ? catalogIds.get(pricingResult.catalogItem.key) ?? null : null,
        customerType,
        selectedColorKind: pricingResult && pricingResult.ok && pricingResult.calculation.colorSurchargeGross > 0 ? OfferColorKind.EXTRA_PAID : OfferColorKind.BASE,
        selectedColorName: pricingResult && pricingResult.ok ? pricingResult.selectedColorName : null,
        colorSurchargeGross: pricingResult && pricingResult.ok ? pricingResult.calculation.colorSurchargeGross : null,
        colorSurchargeNet: pricingResult && pricingResult.ok ? pricingResult.calculation.colorSurchargeNet : null,
        discountAmount: discountValue,
        financingVariant: input.financingVariant?.trim() || null,
        validUntil: input.validUntil?.trim() ? new Date(input.validUntil) : null,
        totalGross: pricingResult && pricingResult.ok ? pricingResult.calculation.finalPriceGross : null,
        totalNet: pricingResult && pricingResult.ok ? pricingResult.calculation.finalPriceNet : null,
        notes: input.notes?.trim() || null,
        ...(financingPersistence
          ? {
              financing: {
                upsert: {
                  create: financingPersistence,
                  update: financingPersistence,
                },
              },
            }
          : offer.financingTermMonths !== null
            ? {
                financing: {
                  delete: true,
                },
              }
            : {}),
      },
      include: {
        customer: true,
        owner: true,
        salesCatalogItem: true,
        financing: true,
        versions: true,
      },
    })

    return { ok: true as const, offer: mapDbOfferToManagedOffer(updated) }
  }

  offer.title = input.title.trim() || offer.title
  offer.status = input.status
  offer.customerName = customerName
  offer.customerEmail = customerEmail
  offer.customerPhone = customerPhone
  offer.pricingCatalogKey = pricingResult && pricingResult.ok ? pricingResult.catalogItem.key : null
  offer.selectedColorName = pricingResult && pricingResult.ok ? pricingResult.selectedColorName : null
  offer.customerType = customerType
  offer.discountValue = discountValue
  offer.financingVariant = input.financingVariant?.trim() || null
  offer.financingTermMonths = financingTermMonths
  offer.financingInputMode = financingInputMode
  offer.financingInputValue = financingInputValue
  offer.financingBuyoutPercent = financingBuyoutPercent
  offer.totalGross = pricingResult && pricingResult.ok ? pricingResult.calculation.finalPriceGross : null
  offer.totalNet = pricingResult && pricingResult.ok ? pricingResult.calculation.finalPriceNet : null
  offer.modelName = pricingResult && pricingResult.ok ? `${pricingResult.catalogItem.brand} ${pricingResult.catalogItem.model} ${pricingResult.catalogItem.version}` : offer.modelName
  offer.validUntil = input.validUntil?.trim() ? new Date(input.validUntil).toISOString() : null
  offer.notes = input.notes?.trim() || null
  offer.updatedAt = new Date().toISOString()

  return { ok: true as const, offer }
}

export async function createManagedOfferVersion(session: AuthSession, offerId: string) {
  const offer = await getManagedOfferWithCalculation(session, offerId)

  if (!offer) {
    return { ok: false as const, error: 'Nie znaleziono oferty.' }
  }

  if (!canViewOffer(session, offer)) {
    return { ok: false as const, error: 'Nie masz dostępu do tej oferty.' }
  }

  const versionId = `offer-version-${crypto.randomUUID()}`
  const versionNumber = offer.versions.length + 1
  const payload = buildOfferVersionSnapshot(offer, versionId, versionNumber)

  const nextVersion: OfferVersion = {
    id: versionId,
    versionNumber,
    summary: `${offer.title} / ${offer.selectedColorName ?? 'kolor bazowy'} / ${offer.financingVariant ?? 'wariant bez finansowania'} / ${formatMoney(offer.totalGross)}`,
    createdAt: payload.createdAt,
    pdfUrl: `/offers/${offer.id}/pdf?versionId=${versionId}`,
    payloadJson: payload,
    customerSnapshotJson: payload.customer,
    internalSnapshotJson: payload.internal,
  }

  if (isPrismaOfferStorageEnabled() && db) {
    await db.offerVersion.create({
      data: {
        id: nextVersion.id,
        offerId: offer.id,
        versionNumber: nextVersion.versionNumber,
        pdfUrl: nextVersion.pdfUrl,
        payloadJson: nextVersion.payloadJson as Prisma.InputJsonValue,
        customerSnapshotJson: nextVersion.customerSnapshotJson as Prisma.InputJsonValue,
        internalSnapshotJson: nextVersion.internalSnapshotJson as Prisma.InputJsonValue,
      },
    })

    return { ok: true as const, version: nextVersion }
  }

  const offers = await getStore()
  const storedOffer = offers.find((entry) => entry.id === offerId)

  if (!storedOffer) {
    return { ok: false as const, error: 'Nie znaleziono oferty w pamięci roboczej.' }
  }

  storedOffer.versions.unshift(nextVersion)
  storedOffer.updatedAt = new Date().toISOString()

  return { ok: true as const, version: nextVersion }
}

export async function assignManagedOfferLead(
  session: AuthSession,
  input: {
    offerId: string
    leadId: string
  }
) {
  const leads = await listManagedLeads(session)
  const lead = leads.find((entry) => entry.id === input.leadId)

  if (!lead) {
    return { ok: false as const, error: 'Wybierz poprawnego leada do przypisania oferty.' }
  }

  const offer = isPrismaOfferStorageEnabled()
    ? await getManagedOfferWithCalculation(session, input.offerId)
    : (await getStore()).find((entry) => entry.id === input.offerId) ?? null

  if (!offer) {
    return { ok: false as const, error: 'Nie znaleziono oferty.' }
  }

  if (!canViewOffer(session, offer)) {
    return { ok: false as const, error: 'Nie masz dostępu do tej oferty.' }
  }

  const nextOwnerId = lead.salespersonId ?? offer.ownerId
  const nextOwnerName = lead.salespersonName ?? offer.ownerName

  if (isPrismaOfferStorageEnabled() && db) {
    const customer = await ensureCustomerFromLead(lead, nextOwnerId)

    if (!customer) {
      return { ok: false as const, error: 'Nie udało się przypisać klienta z leada do oferty.' }
    }

    const updated = await db.offer.update({
      where: { id: input.offerId },
      data: {
        customerId: customer.id,
        ownerId: nextOwnerId,
        notes: offer.notes ?? lead.message ?? null,
      },
      include: {
        customer: true,
        owner: true,
        salesCatalogItem: true,
        financing: true,
        versions: true,
      },
    })

    return { ok: true as const, offer: { ...mapDbOfferToManagedOffer(updated), leadId: lead.id } }
  }

  offer.leadId = lead.id
  offer.customerName = lead.fullName
  offer.customerEmail = lead.email
  offer.customerPhone = lead.phone
  offer.ownerId = nextOwnerId
  offer.ownerName = nextOwnerName
  offer.notes = offer.notes ?? lead.message ?? null
  offer.updatedAt = new Date().toISOString()

  return { ok: true as const, offer }
}

export async function createLeadForManagedOffer(
  session: AuthSession,
  input: {
    offerId: string
    fullName?: string
    email?: string
    phone?: string
    region?: string
  }
) {
  const offer = isPrismaOfferStorageEnabled()
    ? await getManagedOfferWithCalculation(session, input.offerId)
    : (await getStore()).find((entry) => entry.id === input.offerId) ?? null

  if (!offer) {
    return { ok: false as const, error: 'Nie znaleziono oferty.' }
  }

  if (!canViewOffer(session, offer)) {
    return { ok: false as const, error: 'Nie masz dostępu do tej oferty.' }
  }

  const stages = await listManagedLeadStages()
  const firstStageId = stages.find((stage) => stage.kind === 'OPEN')?.id ?? stages[0]?.id ?? ''
  const fullName = input.fullName?.trim() || offer.customerName
  const email = input.email?.trim() || offer.customerEmail || ''
  const phone = input.phone?.trim() || offer.customerPhone || ''
  const region = input.region?.trim() || ''

  const leadResult = await createManagedLead(session, {
    source: 'Oferta PDF',
    fullName,
    email,
    phone,
    interestedModel: offer.modelName ?? '',
    region,
    message: offer.notes ?? '',
    stageId: firstStageId,
    salespersonId: offer.ownerId,
  })

  if (!leadResult.ok) {
    return leadResult
  }

  const attachResult = await assignManagedOfferLead(session, {
    offerId: offer.id,
    leadId: leadResult.lead.id,
  })

  if (!attachResult.ok) {
    return attachResult
  }

  return { ok: true as const, lead: leadResult.lead, offer: attachResult.offer }
}

function isPrismaOfferStorageEnabled() {
  return hasDatabaseUrl() && Boolean(db)
}

async function ensureUsersInDb(users: ManagedUser[]) {
  if (!db) {
    return
  }

  const sortedUsers = [...users].sort((left, right) => {
    const rank = { ADMIN: 0, DIRECTOR: 1, MANAGER: 2, SALES: 3 } as const
    return rank[left.role] - rank[right.role]
  })

  for (const user of sortedUsers) {
    await db.user.upsert({
      where: { id: user.id },
      update: {
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        isActive: user.isActive,
        region: user.region,
        teamName: user.teamName,
        reportsToUserId: user.reportsToUserId,
      },
      create: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        isActive: user.isActive,
        region: user.region,
        teamName: user.teamName,
        reportsToUserId: user.reportsToUserId,
      },
    })
  }
}

async function syncCatalogItemsToDb(catalogItems: DetailedPricingCatalogItem[]) {
  if (!db) {
    return new Map<string, string>()
  }

  const idsByKey = new Map<string, string>()

  for (const item of catalogItems) {
    const brandSetting = await db.brandSetting.upsert({
      where: { brand: item.brand },
      update: {
        isActive: true,
      },
      create: {
        brand: item.brand,
      },
    })

    const existing = await db.salesCatalogItem.findFirst({
      where: {
        brand: item.brand,
        model: item.model,
        version: item.version,
        year: item.year,
      },
    })

    const record = existing
      ? await db.salesCatalogItem.update({
          where: { id: existing.id },
          data: {
            powertrain: item.powertrain,
            powerHp: item.powerHp,
            listPriceGross: item.listPriceGross,
            listPriceNet: item.listPriceNet,
            basePriceGross: item.basePriceGross,
            basePriceNet: item.basePriceNet,
            isActive: true,
            brandSettingId: brandSetting.id,
          },
        })
      : await db.salesCatalogItem.create({
          data: {
            brand: item.brand,
            model: item.model,
            version: item.version,
            year: item.year,
            powertrain: item.powertrain,
            powerHp: item.powerHp,
            listPriceGross: item.listPriceGross,
            listPriceNet: item.listPriceNet,
            basePriceGross: item.basePriceGross,
            basePriceNet: item.basePriceNet,
            isActive: true,
            brandSettingId: brandSetting.id,
          },
        })

    idsByKey.set(item.key, record.id)
  }

  return idsByKey
}

async function ensureCustomerFromLead(lead: ManagedLead, ownerId: string) {
  return ensureCustomerRecord({
    fullName: lead.fullName,
    email: lead.email,
    phone: lead.phone,
    city: lead.region,
    notes: lead.message,
    ownerId,
  })
}

async function ensureCustomerRecord(input: {
  fullName: string
  email: string | null
  phone: string | null
  city: string | null
  notes: string | null
  ownerId: string
}) {
  if (!db) {
    return null
  }

  const contactFilters = [
    input.email ? { email: input.email } : undefined,
    input.phone ? { phone: input.phone } : undefined,
  ].filter(Boolean) as Prisma.CustomerWhereInput[]

  const existing = contactFilters.length > 0
    ? await db.customer.findFirst({
        where: {
          fullName: input.fullName,
          OR: contactFilters,
        },
      })
    : null

  if (existing) {
    return existing
  }

  return db.customer.create({
    data: {
      fullName: input.fullName,
      email: input.email,
      phone: input.phone,
      city: input.city,
      notes: input.notes,
      ownerId: input.ownerId,
    },
  })
}

function mapDbOfferToManagedOffer(offer: DbOfferRecord): ManagedOffer {
  const pricingCatalogKey = offer.salesCatalogItem
    ? [offer.salesCatalogItem.brand, offer.salesCatalogItem.model, offer.salesCatalogItem.version, offer.salesCatalogItem.year || ''].join('::').toLowerCase()
    : null

  return {
    id: offer.id,
    number: offer.number,
    status: offer.status,
    title: offer.title,
    leadId: null,
    customerName: offer.customer.fullName,
    customerEmail: offer.customer.email,
    customerPhone: offer.customer.phone,
    modelName: offer.salesCatalogItem ? `${offer.salesCatalogItem.brand} ${offer.salesCatalogItem.model} ${offer.salesCatalogItem.version}` : null,
    pricingCatalogKey,
    selectedColorName: offer.selectedColorName,
    customerType: offer.customerType,
    discountValue: offer.discountAmount ? Number(offer.discountAmount) : null,
    ownerId: offer.ownerId,
    ownerName: offer.owner.fullName,
    validUntil: offer.validUntil?.toISOString() ?? null,
    totalGross: offer.totalGross ? Number(offer.totalGross) : null,
    totalNet: offer.totalNet ? Number(offer.totalNet) : null,
    financingVariant: offer.financingVariant,
    financingTermMonths: offer.financing?.termMonths ?? null,
    financingInputMode: offer.financing?.downPaymentInputMode ?? 'AMOUNT',
    financingInputValue: offer.financing?.downPaymentInputValue ? Number(offer.financing.downPaymentInputValue) : null,
    financingBuyoutPercent: offer.financing?.buyoutPercent ? Number(offer.financing.buyoutPercent) : null,
    notes: offer.notes,
    versions: offer.versions
      .sort((left, right) => right.versionNumber - left.versionNumber)
      .map((version) => ({
        id: version.id,
        versionNumber: version.versionNumber,
        summary: typeof version.payloadJson === 'object' && version.payloadJson && 'customer' in version.payloadJson
          ? `${offer.title} / ${offer.selectedColorName ?? 'kolor bazowy'} / ${offer.financingVariant ?? 'wariant bez finansowania'} / ${formatMoney(offer.totalGross ? Number(offer.totalGross) : null)}`
          : `${offer.title} / ${formatMoney(offer.totalGross ? Number(offer.totalGross) : null)}`,
        createdAt: version.createdAt.toISOString(),
        pdfUrl: version.pdfUrl,
        payloadJson: (version.payloadJson as OfferDocumentPayload | null) ?? null,
        customerSnapshotJson: (version.customerSnapshotJson as OfferCustomerSnapshot | null) ?? null,
        internalSnapshotJson: (version.internalSnapshotJson as OfferInternalSnapshot | null) ?? null,
      })),
    createdAt: offer.createdAt.toISOString(),
    updatedAt: offer.updatedAt.toISOString(),
  }
}