import 'server-only'

import type { AuthSession } from '@/lib/auth'
import { getDemoUsers } from '@/lib/auth'
import { listActiveCommissionRules } from '@/lib/commission-management'
import { listManagedLeads } from '@/lib/lead-management'
import { calculateOfferSummary, type OfferCalculationSummary, type OfferCustomerType } from '@/lib/offer-calculations'
import { buildDetailedPricingCatalog } from '@/lib/pricing-catalog'
import { getActivePricingSheet } from '@/lib/pricing-management'
import { listManagedUsers } from '@/lib/user-management'

export type OfferStatus = 'DRAFT' | 'SENT' | 'APPROVED' | 'REJECTED' | 'EXPIRED'

export type OfferVersion = {
  id: string
  versionNumber: number
  summary: string
  createdAt: string
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
  customerType: OfferCustomerType
  discountValue: number | null
  ownerId: string
  ownerName: string
  validUntil: string | null
  totalGross: number | null
  totalNet: number | null
  financingVariant: string | null
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
}

const globalForOffers = globalThis as unknown as {
  crmOffers?: ManagedOffer[]
}

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
      customerType: 'PRIVATE',
      discountValue: null,
      ownerId: lead.salespersonId ?? adminSession?.sub ?? 'demo-admin',
      ownerName: lead.salespersonName ?? adminSession?.fullName ?? 'Administrator VeloPrime',
      validUntil: new Date(Date.now() + (index + 5) * 86400000).toISOString(),
      totalGross: index === 0 ? 184900 : 203500,
      totalNet: index === 0 ? 150325.2 : 165447.15,
      financingVariant: index === 0 ? 'Leasing 36 miesięcy / wpłata 15%' : 'Wynajem długoterminowy 48 miesięcy',
      notes: index === 0 ? 'Uwzględniono pakiet serwisowy i odbiór w Warszawie.' : 'Klient prosi o porównanie z finansowaniem gotówkowym.',
      versions: [
        {
          id: `offer-seed-${index + 1}-version-1`,
          versionNumber: 1,
          summary: `Wersja startowa / ${lead.interestedModel ?? 'model'} / ${formatMoney(index === 0 ? 184900 : 203500)}`,
          createdAt,
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

async function resolveOfferPricing(input: {
  pricingCatalogKey?: string
  customerType: OfferCustomerType
  discountValue: number | null
  ownerId: string
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

  const calculation = calculateOfferSummary({
    catalogItem,
    ownerId: input.ownerId,
    users,
    commissionRules,
    customerType: input.customerType,
    discountValue: input.discountValue,
  })

  if (!calculation) {
    return { ok: false as const, error: 'Wybrana konfiguracja nie ma kompletnych cen katalogowych i bazowych.' }
  }

  return { ok: true as const, catalogItem, calculation }
}

export async function listManagedOffers(session: AuthSession) {
  const offers = await getStore()

  return [...offers]
    .filter((offer) => canViewOffer(session, offer))
    .sort((left, right) => new Date(right.updatedAt).getTime() - new Date(left.updatedAt).getTime())
}

export async function listManagedOffersWithCalculation(session: AuthSession) {
  const [offers, pricingSheet, commissionRules, users] = await Promise.all([
    listManagedOffers(session),
    getActivePricingSheet(),
    listActiveCommissionRules(),
    listManagedUsers(),
  ])

  const catalogByKey = new Map(buildDetailedPricingCatalog(pricingSheet).map((item) => [item.key, item]))

  return offers.map((offer) => ({
    ...offer,
    calculation: offer.pricingCatalogKey
      ? (() => {
          const catalogItem = catalogByKey.get(offer.pricingCatalogKey)
          return catalogItem
            ? calculateOfferSummary({
                catalogItem,
                ownerId: offer.ownerId,
                users,
                commissionRules,
                customerType: offer.customerType,
                discountValue: offer.discountValue,
              })
            : null
        })()
      : null,
  })) satisfies ManagedOfferWithCalculation[]
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
  })) satisfies OfferPricingOption[]
}

export async function createManagedOffer(
  session: AuthSession,
  input: {
    leadId: string
    title: string
    pricingCatalogKey?: string
    customerType?: OfferCustomerType
    discountValue?: string
    financingVariant?: string
    validUntil?: string
    notes?: string
  }
) {
  const leads = await listManagedLeads(session)
  const lead = leads.find((entry) => entry.id === input.leadId)

  if (!lead) {
    return { ok: false as const, error: 'Wybierz poprawnego leada do utworzenia oferty.' }
  }

  const title = input.title.trim() || `Oferta ${lead.interestedModel ?? 'sprzedażowa'} dla ${lead.fullName}`
  const customerType = input.customerType === 'BUSINESS' ? 'BUSINESS' : 'PRIVATE'
  const discountValue = input.discountValue?.trim() ? Number(input.discountValue) : null

  if (input.discountValue?.trim() && (discountValue === null || Number.isNaN(discountValue))) {
    return { ok: false as const, error: 'Rabat klienta musi być poprawną liczbą.' }
  }

  const ownerId = lead.salespersonId ?? session.sub
  const pricingResult = await resolveOfferPricing({
    pricingCatalogKey: input.pricingCatalogKey?.trim() || undefined,
    customerType,
    discountValue,
    ownerId,
  })

  if (pricingResult && !pricingResult.ok) {
    return pricingResult
  }

  const offers = await getStore()
  const nextOffer: ManagedOffer = {
    id: `offer-${crypto.randomUUID()}`,
    number: nextOfferNumber(offers),
    status: 'DRAFT',
    title,
    leadId: lead.id,
    customerName: lead.fullName,
    customerEmail: lead.email,
    customerPhone: lead.phone,
    modelName: pricingResult && pricingResult.ok ? `${pricingResult.catalogItem.brand} ${pricingResult.catalogItem.model} ${pricingResult.catalogItem.version}` : lead.interestedModel,
    pricingCatalogKey: pricingResult && pricingResult.ok ? pricingResult.catalogItem.key : null,
    customerType,
    discountValue,
    ownerId,
    ownerName: lead.salespersonName ?? session.fullName,
    validUntil: input.validUntil?.trim() ? new Date(input.validUntil).toISOString() : null,
    totalGross: pricingResult && pricingResult.ok ? pricingResult.calculation.finalPriceGross : null,
    totalNet: pricingResult && pricingResult.ok ? pricingResult.calculation.finalPriceNet : null,
    financingVariant: input.financingVariant?.trim() || null,
    notes: input.notes?.trim() || lead.message || null,
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
    pricingCatalogKey?: string
    customerType?: OfferCustomerType
    discountValue?: string
    financingVariant?: string
    validUntil?: string
    notes?: string
  }
) {
  const offers = await getStore()
  const offer = offers.find((entry) => entry.id === input.offerId)

  if (!offer) {
    return { ok: false as const, error: 'Nie znaleziono oferty.' }
  }

  if (!canViewOffer(session, offer)) {
    return { ok: false as const, error: 'Nie masz dostępu do tej oferty.' }
  }

  const customerType = input.customerType === 'BUSINESS' ? 'BUSINESS' : 'PRIVATE'
  const discountValue = input.discountValue?.trim() ? Number(input.discountValue) : null

  if (input.discountValue?.trim() && (discountValue === null || Number.isNaN(discountValue))) {
    return { ok: false as const, error: 'Rabat klienta musi być poprawną liczbą.' }
  }

  const pricingResult = await resolveOfferPricing({
    pricingCatalogKey: input.pricingCatalogKey?.trim() || undefined,
    customerType,
    discountValue,
    ownerId: offer.ownerId,
  })

  if (pricingResult && !pricingResult.ok) {
    return pricingResult
  }

  offer.title = input.title.trim() || offer.title
  offer.status = input.status
  offer.pricingCatalogKey = pricingResult && pricingResult.ok ? pricingResult.catalogItem.key : null
  offer.customerType = customerType
  offer.discountValue = discountValue
  offer.financingVariant = input.financingVariant?.trim() || null
  offer.totalGross = pricingResult && pricingResult.ok ? pricingResult.calculation.finalPriceGross : null
  offer.totalNet = pricingResult && pricingResult.ok ? pricingResult.calculation.finalPriceNet : null
  offer.modelName = pricingResult && pricingResult.ok ? `${pricingResult.catalogItem.brand} ${pricingResult.catalogItem.model} ${pricingResult.catalogItem.version}` : offer.modelName
  offer.validUntil = input.validUntil?.trim() ? new Date(input.validUntil).toISOString() : null
  offer.notes = input.notes?.trim() || null
  offer.updatedAt = new Date().toISOString()

  return { ok: true as const, offer }
}

export async function createManagedOfferVersion(session: AuthSession, offerId: string) {
  const offers = await getStore()
  const offer = offers.find((entry) => entry.id === offerId)

  if (!offer) {
    return { ok: false as const, error: 'Nie znaleziono oferty.' }
  }

  if (!canViewOffer(session, offer)) {
    return { ok: false as const, error: 'Nie masz dostępu do tej oferty.' }
  }

  const nextVersion: OfferVersion = {
    id: `offer-version-${crypto.randomUUID()}`,
    versionNumber: offer.versions.length + 1,
    summary: `${offer.title} / ${offer.financingVariant ?? 'wariant bez finansowania'} / ${formatMoney(offer.totalGross)}`,
    createdAt: new Date().toISOString(),
  }

  offer.versions.unshift(nextVersion)
  offer.updatedAt = new Date().toISOString()

  return { ok: true as const, version: nextVersion }
}