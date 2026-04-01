import 'server-only'

import { OfferColorKind, Prisma } from '@prisma/client'

import type { AuthSession } from '@/lib/auth'
import { getOfferAssetBundle } from '@/lib/offer-assets'
import type { ModelColorPalette } from '@/lib/color-management'
import { listActiveCommissionRules } from '@/lib/commission-management'
import { db, hasDatabaseUrl } from '@/lib/db'
import { sendTransactionalEmail } from '@/lib/email-service'
import { calculateOfferFinancing, type FinancingInputMode, type OfferFinancingSummary } from '@/lib/offer-financing'
import { createManagedLead, listManagedLeads, listManagedLeadStages, logManagedLeadActivity, type ManagedLead } from '@/lib/lead-management'
import { calculateOfferSummary, type OfferCalculationSummary, type OfferCustomerType } from '@/lib/offer-calculations'
import { findSalesCatalogItemByKey, listSalesCatalogItems, listSalesModelColorPalettes, syncLegacyCatalogItemsToDb, type SalesCatalogRuntimeItem } from '@/lib/sales-catalog-management'
import { listManagedUsers, type ManagedUser } from '@/lib/user-management'

export type OfferStatus = 'DRAFT' | 'SENT' | 'APPROVED' | 'REJECTED' | 'EXPIRED'

export type OfferVersion = {
  id: string
  versionNumber: number
  summary: string
  createdAt: string
  pdfUrl: string | null
  shareToken: string | null
  sharedAt: string | null
  shareExpiresAt: string | null
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
  powertrainType?: string | null
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
  advisor: OfferAdvisorSnapshot
  internal: OfferInternalSnapshot
}

export type OfferAdvisorSnapshot = {
  fullName: string
  email: string | null
  phone: string | null
  role: AuthSession['role']
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
  ownerEmail: string | null
  ownerPhone: string | null
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

export type ManagedOfferShare = {
  offerId: string
  versionId: string
  token: string
  expiresAt: string | null
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

function buildUserHierarchyMaps(users: ManagedUser[]) {
  const children = new Map<string, ManagedUser[]>()

  for (const user of users) {
    const supervisorId = user.reportsToUserId ?? null

    if (!supervisorId) {
      continue
    }

    const bucket = children.get(supervisorId) ?? []
    bucket.push(user)
    children.set(supervisorId, bucket)
  }

  return { children }
}

function getVisibleOfferOwnerIds(session: AuthSession, users: ManagedUser[]) {
  if (session.role === 'ADMIN') {
    return new Set(users.map((user) => user.id))
  }

  const { children } = buildUserHierarchyMaps(users)
  const visible = new Set<string>([session.sub])
  const queue = [session.sub]

  while (queue.length > 0) {
    const current = queue.shift()!
    const descendants = children.get(current) ?? []

    for (const descendant of descendants) {
      if (visible.has(descendant.id)) {
        continue
      }

      visible.add(descendant.id)
      queue.push(descendant.id)
    }
  }

  return visible
}

function canViewOffer(offer: ManagedOffer, visibleOwnerIds: Set<string>) {
  if (!offer.ownerId) {
    return false
  }

  return visibleOwnerIds.has(offer.ownerId)
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

function buildOfferShareToken() {
  return crypto.randomUUID().replace(/-/g, '')
}

function resolveOfferShareExpiresAt(validUntil: string | null, fallbackCreatedAt: string) {
  if (validUntil) {
    const validUntilDate = new Date(validUntil)

    if (!Number.isNaN(validUntilDate.getTime())) {
      return validUntilDate.toISOString()
    }
  }

  const createdAt = new Date(fallbackCreatedAt)
  const baseTime = Number.isNaN(createdAt.getTime()) ? Date.now() : createdAt.getTime()
  return new Date(baseTime + 7 * 86400000).toISOString()
}

function stripHtml(value: string) {
  return value.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim()
}

function buildAbsoluteUrl(origin: string, path: string) {
  return new URL(path, origin).toString()
}

function buildOfferEmailContent(input: {
  publicUrl: string
  logoUrl: string
  heroImageUrl: string | null
  modelName: string
  customerName: string
  offerNumber: string
  validUntil: string | null
  finalGrossLabel: string
  financingSummary: string | null
  advisorName: string
  advisorEmail: string | null
  advisorPhone: string | null
}) {
  const validityLabel = input.validUntil
    ? new Intl.DateTimeFormat('pl-PL', { dateStyle: 'medium' }).format(new Date(input.validUntil))
    : 'bez określonej daty końcowej'
  const advisorContact = [input.advisorEmail, input.advisorPhone].filter(Boolean).join(' • ') || 'W razie pytań skontaktuj się z opiekunem oferty.'
  const financingLabel = input.financingSummary ?? 'Szczegóły finansowania znajdziesz w pełnej wersji oferty online.'
  const heroMarkup = input.heroImageUrl
    ? `<img src="${input.heroImageUrl}" alt="${input.modelName}" style="display:block;width:100%;max-width:520px;height:auto;border-radius:24px;object-fit:cover;" />`
    : ''

  const html = `
    <div style="margin:0;padding:32px 16px;background:#f4f7fb;font-family:Inter,Arial,sans-serif;color:#172033;">
      <div style="max-width:640px;margin:0 auto;background:linear-gradient(180deg,#ffffff 0%,#f9fbff 100%);border:1px solid rgba(20,33,61,0.08);border-radius:28px;overflow:hidden;box-shadow:0 24px 70px rgba(17,32,67,0.12);">
        <div style="padding:28px 28px 16px;background:linear-gradient(135deg,#17325f 0%,#214b87 100%);color:#ffffff;">
          <img src="${input.logoUrl}" alt="VeloPrime" style="display:block;height:34px;width:auto;max-width:180px;" />
          <div style="margin-top:18px;font-size:11px;font-weight:700;letter-spacing:0.24em;text-transform:uppercase;color:rgba(255,255,255,0.66);">Twoja oferta</div>
          <h1 style="margin:14px 0 0;font-size:34px;line-height:1.1;font-weight:700;letter-spacing:-0.03em;">${input.modelName}</h1>
          <p style="margin:14px 0 0;font-size:15px;line-height:1.8;color:rgba(255,255,255,0.8);">Przygotowaliśmy ofertę dla ${input.customerName}. Pod poniższym linkiem znajdziesz pełną konfigurację samochodu, warunki finansowania i dane opiekuna.</p>
        </div>
        <div style="padding:24px 28px 0;">${heroMarkup}</div>
        <div style="padding:28px;">
          <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;">
            <div style="border:1px solid rgba(20,33,61,0.08);border-radius:20px;padding:16px;background:#ffffff;">
              <div style="font-size:11px;letter-spacing:0.2em;text-transform:uppercase;color:#8b7746;font-weight:700;">Numer oferty</div>
              <div style="margin-top:10px;font-size:18px;font-weight:700;color:#172033;">${input.offerNumber}</div>
            </div>
            <div style="border:1px solid rgba(20,33,61,0.08);border-radius:20px;padding:16px;background:#ffffff;">
              <div style="font-size:11px;letter-spacing:0.2em;text-transform:uppercase;color:#8b7746;font-weight:700;">Cena końcowa</div>
              <div style="margin-top:10px;font-size:18px;font-weight:700;color:#172033;">${input.finalGrossLabel}</div>
            </div>
            <div style="border:1px solid rgba(20,33,61,0.08);border-radius:20px;padding:16px;background:#ffffff;">
              <div style="font-size:11px;letter-spacing:0.2em;text-transform:uppercase;color:#8b7746;font-weight:700;">Ważność</div>
              <div style="margin-top:10px;font-size:18px;font-weight:700;color:#172033;">${validityLabel}</div>
            </div>
          </div>

          <div style="margin-top:18px;border:1px solid rgba(20,33,61,0.08);border-radius:24px;background:linear-gradient(180deg,#f9fbfe 0%,#f4f7fb 100%);padding:18px 20px;">
            <div style="font-size:11px;letter-spacing:0.2em;text-transform:uppercase;color:#8b7746;font-weight:700;">Finansowanie</div>
            <p style="margin:12px 0 0;font-size:15px;line-height:1.8;color:#55627d;">${financingLabel}</p>
          </div>

          <div style="margin-top:24px;text-align:center;">
            <a href="${input.publicUrl}" style="display:inline-block;padding:14px 26px;border-radius:999px;background:linear-gradient(180deg,#e3c986 0%,#d6ad56 100%);color:#1c1711;text-decoration:none;font-size:15px;font-weight:700;box-shadow:0 16px 34px rgba(212,168,79,0.18);">Otwórz ofertę online</a>
            <div style="margin-top:14px;font-size:13px;line-height:1.7;color:#667389;">Jeśli przycisk nie otwiera oferty, skorzystaj z poniższego linku: <br /><a href="${input.publicUrl}" style="color:#214b87;word-break:break-all;">${input.publicUrl}</a></div>
          </div>

          <div style="margin-top:24px;border-top:1px solid rgba(20,33,61,0.08);padding-top:20px;">
            <div style="font-size:11px;letter-spacing:0.2em;text-transform:uppercase;color:#8b7746;font-weight:700;">Opiekun oferty</div>
            <div style="margin-top:10px;font-size:18px;font-weight:700;color:#172033;">${input.advisorName}</div>
            <div style="margin-top:8px;font-size:14px;line-height:1.8;color:#55627d;">${advisorContact}</div>
          </div>
        </div>
      </div>
    </div>
  `.trim()

  const text = [
    `VeloPrime | Oferta ${input.modelName}`,
    '',
    `Klient: ${input.customerName}`,
    `Numer oferty: ${input.offerNumber}`,
    `Cena końcowa: ${input.finalGrossLabel}`,
    `Ważność: ${validityLabel}`,
    `Finansowanie: ${financingLabel}`,
    '',
    `Oferta online: ${input.publicUrl}`,
    '',
    `Opiekun oferty: ${input.advisorName}`,
    advisorContact,
  ].join('\n')

  return { html, text }
}

async function markManagedOfferAsSent(session: AuthSession, offerId: string) {
  const offer = await getManagedOfferWithCalculation(session, offerId)

  if (!offer) {
    return
  }

  if (isPrismaOfferStorageEnabled() && db) {
    if (offer.status !== 'SENT') {
      await db.offer.update({
        where: { id: offerId },
        data: { status: 'SENT' },
      })
    }
  } else {
    const offers = await getStore()
    const storedOffer = offers.find((entry) => entry.id === offerId)

    if (storedOffer) {
      storedOffer.status = 'SENT'
      storedOffer.updatedAt = new Date().toISOString()
    }
  }

  if (!offer.leadId) {
    return
  }

  const stages = await listManagedLeadStages()
  const offerSharedStage = stages.find((stage) => stage.name === 'Oferta przekazana') ?? null

  if (offerSharedStage) {
    const { moveManagedLeadToStage } = await import('@/lib/lead-management')
    await moveManagedLeadToStage(session, offer.leadId, offerSharedStage.id)
  }

  await logManagedLeadActivity(session, {
    leadId: offer.leadId,
    label: 'Oferta wysłana e-mailem',
    value: `Oferta ${offer.number} została wysłana e-mailem do klienta.`,
  })
}

async function buildSeedOffers() {
  const users = await listManagedUsers()
  const adminSession = users.find((user) => user.role === 'ADMIN') ?? users[0]
  const leads = adminSession
    ? await listManagedLeads({
        sub: adminSession.id,
        email: adminSession.email,
        fullName: adminSession.fullName,
        role: adminSession.role,
      })
    : []

  return leads.slice(0, 2).map((lead, index) => {
    const createdAt = new Date(Date.now() - (index + 1) * 86400000).toISOString()
    const ownerUser = users.find((user) => user.id === (lead.salespersonId ?? adminSession?.id)) ?? adminSession

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
      ownerId: lead.salespersonId ?? adminSession?.id ?? 'demo-admin',
      ownerName: lead.salespersonName ?? adminSession?.fullName ?? 'Administrator VeloPrime',
      ownerEmail: ownerUser?.email ?? null,
      ownerPhone: ownerUser?.phone ?? null,
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
          shareToken: null,
          sharedAt: null,
          shareExpiresAt: null,
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

function buildOfferVersionSnapshot(
  offer: ManagedOfferWithCalculation,
  versionId: string,
  versionNumber: number,
  catalogItem: SalesCatalogRuntimeItem | null,
): OfferDocumentPayload {
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
    advisor: {
      fullName: offer.ownerName,
      email: offer.ownerEmail,
      phone: offer.ownerPhone,
      role: offer.calculation?.ownerRole ?? 'SALES',
    },
    internal: {
      catalogKey: offer.pricingCatalogKey,
      powertrainType: catalogItem?.powertrain ?? null,
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

  const [catalogItem, palettes, commissionRules, users] = await Promise.all([
    findSalesCatalogItemByKey(input.pricingCatalogKey),
    listSalesModelColorPalettes(),
    listActiveCommissionRules(),
    listManagedUsers(),
  ])

  if (!catalogItem) {
    return { ok: false as const, error: 'Wybrana konfiguracja cenowa nie istnieje w zapisanej polityce cenowej.' }
  }

  const paletteByKey = new Map(
    palettes
      .filter((palette): palette is ModelColorPalette => palette !== null)
      .map((palette) => [palette.paletteKey, palette] as const)
  )
  const colorPalette = paletteByKey.get(`${catalogItem.brand.toLowerCase()}::${catalogItem.model.toLowerCase()}`) ?? null
  const resolvedColorName = input.selectedColorName?.trim() || null

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

function buildOfferCalculation(
  offer: ManagedOffer,
  references: {
    catalogByKey: Map<string, SalesCatalogRuntimeItem>
    paletteByKey: Map<string, ModelColorPalette>
    users: ManagedUser[]
    commissionRules: Awaited<ReturnType<typeof listActiveCommissionRules>>
  }
) {
  if (!offer.pricingCatalogKey) {
    return null
  }

  const catalogItem = references.catalogByKey.get(offer.pricingCatalogKey)
  const colorPalette = catalogItem
    ? references.paletteByKey.get(`${catalogItem.brand.toLowerCase()}::${catalogItem.model.toLowerCase()}`) ?? null
    : null

  if (!catalogItem) {
    return null
  }

  return calculateOfferSummary({
    catalogItem,
    ownerId: offer.ownerId,
    users: references.users,
    commissionRules: references.commissionRules,
    customerType: offer.customerType,
    discountValue: offer.discountValue,
    colorPalette,
    selectedColorName: offer.selectedColorName,
  })
}

async function getManagedOffer(session: AuthSession, offerId: string) {
  const users = await listManagedUsers()
  const visibleOwnerIds = getVisibleOfferOwnerIds(session, users)

  if (isPrismaOfferStorageEnabled() && db) {
    const record = await db.offer.findUnique({
      where: { id: offerId },
      include: {
        customer: true,
        owner: true,
        salesCatalogItem: true,
        financing: true,
        versions: true,
      },
    })

    if (!record) {
      return null
    }

    const mapped = mapDbOfferToManagedOffer(record)

    if (!canViewOffer(mapped, visibleOwnerIds)) {
      return null
    }

    const leadLookupFilters = [
      record.customerId ? { customerId: record.customerId } : null,
      record.customer.email ? { email: record.customer.email } : null,
      record.customer.phone ? { phone: record.customer.phone } : null,
    ].filter(Boolean) as Prisma.LeadWhereInput[]

    if (leadLookupFilters.length > 0) {
      const linkedLead = await db.lead.findFirst({
        where: {
          OR: leadLookupFilters,
          ...(session.role === 'ADMIN'
            ? {}
            : {
                salespersonId: {
                  in: Array.from(visibleOwnerIds),
                },
              }),
        },
        orderBy: { updatedAt: 'desc' },
        select: { id: true },
      })

      if (linkedLead) {
        return { ...mapped, leadId: linkedLead.id }
      }
    }

    const leads = await listManagedLeads(session)
    const matchedLead = matchLeadForOffer(leads, mapped)

    return matchedLead ? { ...mapped, leadId: matchedLead.id } : mapped
  }

  const offer = (await getStore()).find((entry) => entry.id === offerId) ?? null

  if (!offer || !canViewOffer(offer, visibleOwnerIds)) {
    return null
  }

  return offer
}

export async function listManagedOffers(session: AuthSession) {
  const [leads, users] = await Promise.all([
    listManagedLeads(session),
    listManagedUsers(),
  ])
  const visibleOwnerIds = getVisibleOfferOwnerIds(session, users)

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
      .filter((offer) => canViewOffer(offer, visibleOwnerIds))
  }

  const offers = await getStore()

  return [...offers]
    .filter((offer) => canViewOffer(offer, visibleOwnerIds))
    .sort((left, right) => new Date(right.updatedAt).getTime() - new Date(left.updatedAt).getTime())
}

export async function listManagedOffersWithCalculation(session: AuthSession) {
  const [offers, catalogItems, palettes, commissionRules, users] = await Promise.all([
    listManagedOffers(session),
    listSalesCatalogItems(),
    listSalesModelColorPalettes(),
    listActiveCommissionRules(),
    listManagedUsers(),
  ])

  const catalogByKey = new Map(catalogItems.map((item) => [item.key, item] as const))
  const paletteByKey = new Map(
    palettes
      .filter((palette): palette is ModelColorPalette => palette !== null)
      .map((palette) => [palette.paletteKey, palette] as const)
  )

  return offers.map((offer) => ({
    ...offer,
    calculation: buildOfferCalculation(offer, {
      catalogByKey,
      paletteByKey,
      users,
      commissionRules,
    }),
  })) satisfies ManagedOfferWithCalculation[]
}

export async function getManagedOfferWithCalculation(session: AuthSession, offerId: string) {
  const offer = await getManagedOffer(session, offerId)

  if (!offer) {
    return null
  }

  if (!offer.pricingCatalogKey) {
    return {
      ...offer,
      calculation: null,
    } satisfies ManagedOfferWithCalculation
  }

  const [catalogItems, palettes, commissionRules, users] = await Promise.all([
    listSalesCatalogItems(),
    listSalesModelColorPalettes(),
    listActiveCommissionRules(),
    listManagedUsers(),
  ])

  const catalogByKey = new Map(catalogItems.map((item) => [item.key, item] as const))
  const paletteByKey = new Map(
    palettes
      .filter((palette): palette is ModelColorPalette => palette !== null)
      .map((palette) => [palette.paletteKey, palette] as const)
  )

  return {
    ...offer,
    calculation: buildOfferCalculation(offer, {
      catalogByKey,
      paletteByKey,
      users,
      commissionRules,
    }),
  } satisfies ManagedOfferWithCalculation
}

export async function getOfferDocumentSnapshot(session: AuthSession, offerId: string, versionId?: string | null) {
  const offer = await getManagedOfferWithCalculation(session, offerId)

  if (!offer) {
    return null
  }

  const version = versionId
    ? offer.versions.find((entry) => entry.id === versionId) ?? null
    : offer.versions[0] ?? null

  const catalogItem = offer.pricingCatalogKey ? await findSalesCatalogItemByKey(offer.pricingCatalogKey) : null

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
      payload: buildOfferVersionSnapshot(offer, version?.id ?? `offer-live-${offer.id}`, version?.versionNumber ?? offer.versions.length, catalogItem),
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
  const catalogItems = await listSalesCatalogItems()

  return catalogItems.map((item) => ({
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
  const users = await listManagedUsers()
  const ownerUser = users.find((user) => user.id === ownerId) ?? null
  const resolvedOwnerName = lead?.salespersonName ?? ownerUser?.fullName ?? session.fullName
  const resolvedOwnerEmail = ownerUser?.email ?? session.email
  const resolvedOwnerPhone = ownerUser?.phone ?? null
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

  if (financingResult && !financingResult.ok) {
    return financingResult
  }

  const financingPersistence = buildFinancingPersistence({
    financingTermMonths,
    financingInputMode,
    financingInputValue,
    financingBuyoutPercent,
    financingSummary: financingResult && financingResult.ok ? financingResult.summary : null,
  })

  if (isPrismaOfferStorageEnabled() && db) {
    await ensureUsersInDb(users)
    const catalogItems = await listSalesCatalogItems()
    const catalogIds = await syncLegacyCatalogItemsToDb(catalogItems)
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

    if (lead) {
      await logManagedLeadActivity(session, {
        leadId: lead.id,
        label: 'Oferta utworzona',
        value: `Utworzono ofertę ${created.number} (${created.title}).`,
      })
    }

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
    ownerName: resolvedOwnerName,
    ownerEmail: resolvedOwnerEmail,
    ownerPhone: resolvedOwnerPhone,
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

  if (lead) {
    await logManagedLeadActivity(session, {
      leadId: lead.id,
      label: 'Oferta utworzona',
      value: `Utworzono ofertę ${nextOffer.number} (${nextOffer.title}).`,
    })
  }

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
  const offer = await getManagedOfferWithCalculation(session, input.offerId)

  if (!offer) {
    return { ok: false as const, error: 'Nie znaleziono oferty.' }
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
    await ensureUsersInDb(await listManagedUsers())
    const catalogItems = await listSalesCatalogItems()
    const catalogIds = await syncLegacyCatalogItemsToDb(catalogItems)

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

  const catalogItem = offer.pricingCatalogKey ? await findSalesCatalogItemByKey(offer.pricingCatalogKey) : null
  const versionId = `offer-version-${crypto.randomUUID()}`
  const versionNumber = offer.versions.length + 1
  const payload = buildOfferVersionSnapshot(offer, versionId, versionNumber, catalogItem)

  const nextVersion: OfferVersion = {
    id: versionId,
    versionNumber,
    summary: `${offer.title} / ${offer.selectedColorName ?? 'kolor bazowy'} / ${offer.financingVariant ?? 'wariant bez finansowania'} / ${formatMoney(offer.totalGross)}`,
    createdAt: payload.createdAt,
    pdfUrl: `/offers/${offer.id}/pdf?versionId=${versionId}`,
    shareToken: null,
    sharedAt: null,
    shareExpiresAt: null,
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
        shareToken: nextVersion.shareToken,
        sharedAt: nextVersion.sharedAt ? new Date(nextVersion.sharedAt) : null,
        shareExpiresAt: nextVersion.shareExpiresAt ? new Date(nextVersion.shareExpiresAt) : null,
        payloadJson: nextVersion.payloadJson as Prisma.InputJsonValue,
        customerSnapshotJson: nextVersion.customerSnapshotJson as Prisma.InputJsonValue,
        internalSnapshotJson: nextVersion.internalSnapshotJson as Prisma.InputJsonValue,
      },
    })

    if (offer.leadId) {
      await logManagedLeadActivity(session, {
        leadId: offer.leadId,
        label: 'Nowa wersja oferty',
        value: `Dodano wersję ${nextVersion.versionNumber} do oferty ${offer.number}.`,
      })
    }

    return { ok: true as const, version: nextVersion }
  }

  const offers = await getStore()
  const storedOffer = offers.find((entry) => entry.id === offerId)

  if (!storedOffer) {
    return { ok: false as const, error: 'Nie znaleziono oferty w pamięci roboczej.' }
  }

  storedOffer.versions.unshift(nextVersion)
  storedOffer.updatedAt = new Date().toISOString()

  if (offer.leadId) {
    await logManagedLeadActivity(session, {
      leadId: offer.leadId,
      label: 'Nowa wersja oferty',
      value: `Dodano wersję ${nextVersion.versionNumber} do oferty ${offer.number}.`,
    })
  }

  return { ok: true as const, version: nextVersion }
}

export async function createManagedOfferShare(
  session: AuthSession,
  input: {
    offerId: string
    versionId?: string | null
  },
) {
  const offer = await getManagedOfferWithCalculation(session, input.offerId)

  if (!offer) {
    return { ok: false as const, error: 'Nie znaleziono oferty do udostępnienia.' }
  }

  let version = input.versionId?.trim()
    ? offer.versions.find((entry) => entry.id === input.versionId?.trim()) ?? null
    : offer.versions[0] ?? null

  if (input.versionId?.trim() && !version) {
    return { ok: false as const, error: 'Nie znaleziono wskazanej wersji oferty.' }
  }

  if (!version) {
    const versionResult = await createManagedOfferVersion(session, offer.id)

    if (!versionResult.ok) {
      return versionResult
    }

    version = versionResult.version
  }

  const token = version.shareToken ?? buildOfferShareToken()
  const expiresAt = resolveOfferShareExpiresAt(offer.validUntil, version.createdAt)
  const sharedAt = new Date().toISOString()

  if (isPrismaOfferStorageEnabled() && db) {
    await db.offerVersion.update({
      where: { id: version.id },
      data: {
        shareToken: token,
        sharedAt: new Date(sharedAt),
        shareExpiresAt: expiresAt ? new Date(expiresAt) : null,
      },
    })
  } else {
    version.shareToken = token
    version.sharedAt = sharedAt
    version.shareExpiresAt = expiresAt
  }

  return {
    ok: true as const,
    share: {
      offerId: offer.id,
      versionId: version.id,
      token,
      expiresAt,
    } satisfies ManagedOfferShare,
  }
}

export async function getPublicOfferDocumentSnapshot(token: string) {
  const normalizedToken = token.trim()

  if (!normalizedToken) {
    return { ok: false as const, status: 'not-found' as const }
  }

  if (isPrismaOfferStorageEnabled() && db) {
    const version = await db.offerVersion.findUnique({
      where: { shareToken: normalizedToken },
      include: {
        offer: {
          include: {
            customer: true,
            owner: true,
          },
        },
      },
    })

    if (!version) {
      return { ok: false as const, status: 'not-found' as const }
    }

    if (version.shareExpiresAt && version.shareExpiresAt.getTime() < Date.now()) {
      return {
        ok: false as const,
        status: 'expired' as const,
        title: version.offer.title,
        advisorName: version.offer.owner.fullName,
        advisorEmail: version.offer.owner.email,
        advisorPhone: version.offer.owner.phone,
      }
    }

    const payload = version.payloadJson as OfferDocumentPayload | null

    if (!payload) {
      return { ok: false as const, status: 'not-found' as const }
    }

    return {
      ok: true as const,
      offerId: version.offerId,
      offerNumber: version.offer.number,
      title: version.offer.title,
      shareExpiresAt: version.shareExpiresAt?.toISOString() ?? null,
      version: {
        id: version.id,
        versionNumber: version.versionNumber,
        summary: `${version.offer.title} / ${payload.customer.finalGrossLabel}`,
        createdAt: version.createdAt.toISOString(),
        pdfUrl: version.pdfUrl,
        shareToken: version.shareToken,
        sharedAt: version.sharedAt?.toISOString() ?? null,
        shareExpiresAt: version.shareExpiresAt?.toISOString() ?? null,
        payloadJson: payload,
        customerSnapshotJson: (version.customerSnapshotJson as OfferCustomerSnapshot | null) ?? payload.customer,
        internalSnapshotJson: (version.internalSnapshotJson as OfferInternalSnapshot | null) ?? payload.internal,
      } satisfies OfferVersion,
      payload,
      assets: await getOfferAssetBundle({
        modelName: payload.customer.modelName,
        catalogKey: payload.internal.catalogKey,
        powertrainType: payload.internal.powertrainType,
      }),
    }
  }

  const offers = await getStore()

  for (const offer of offers) {
    const version = offer.versions.find((entry) => entry.shareToken === normalizedToken)

    if (!version) {
      continue
    }

    if (version.shareExpiresAt && new Date(version.shareExpiresAt).getTime() < Date.now()) {
      return {
        ok: false as const,
        status: 'expired' as const,
        title: offer.title,
        advisorName: offer.ownerName,
        advisorEmail: offer.ownerEmail,
        advisorPhone: offer.ownerPhone,
      }
    }

    const payload = version.payloadJson

    if (!payload) {
      return { ok: false as const, status: 'not-found' as const }
    }

    return {
      ok: true as const,
      offerId: offer.id,
      offerNumber: offer.number,
      title: offer.title,
      shareExpiresAt: version.shareExpiresAt,
      version,
      payload,
      assets: await getOfferAssetBundle({
        modelName: payload.customer.modelName,
        catalogKey: payload.internal.catalogKey,
        powertrainType: payload.internal.powertrainType,
      }),
    }
  }

  return { ok: false as const, status: 'not-found' as const }
}

export async function sendManagedOfferEmail(
  session: AuthSession,
  input: {
    offerId: string
    versionId?: string | null
    toEmail?: string | null
  },
  origin: string,
) {
  const shareResult = await createManagedOfferShare(session, {
    offerId: input.offerId,
    versionId: input.versionId,
  })

  if (!shareResult.ok) {
    return shareResult
  }

  const document = await getOfferDocumentSnapshot(session, input.offerId, shareResult.share.versionId)

  if (!document) {
    return { ok: false as const, error: 'Nie udało się przygotować dokumentu oferty do wysyłki.' }
  }

  const recipient = (input.toEmail?.trim() || document.payload.customer.customerEmail || '').trim().toLowerCase()

  if (!recipient || !recipient.includes('@')) {
    return { ok: false as const, error: 'Oferta nie ma poprawnego adresu email klienta.' }
  }

  const modelName = document.payload.customer.modelName ?? document.payload.customer.title ?? document.offer.title
  const publicUrl = `${origin}/oferta/${shareResult.share.token}`
  const assets = await getOfferAssetBundle({
    modelName: document.payload.customer.modelName,
    catalogKey: document.payload.internal.catalogKey,
    powertrainType: document.payload.internal.powertrainType,
  })
  const absoluteLogoUrl = buildAbsoluteUrl(origin, assets.logoUrl)
  const heroImage = assets.images.premium[0] ?? assets.images.exterior[0] ?? assets.images.other[0] ?? null
  const absoluteHeroImage = heroImage ? buildAbsoluteUrl(origin, heroImage) : null
  const advisorName = document.payload.advisor.fullName || document.payload.internal.ownerName || 'Opiekun VeloPrime'
  const { html, text } = buildOfferEmailContent({
    publicUrl,
    logoUrl: absoluteLogoUrl,
    heroImageUrl: absoluteHeroImage,
    modelName,
    customerName: document.payload.customer.customerName,
    offerNumber: document.payload.customer.offerNumber,
    validUntil: document.payload.customer.validUntil ?? shareResult.share.expiresAt,
    finalGrossLabel: document.payload.customer.finalGrossLabel,
    financingSummary: document.payload.customer.financingSummary ?? document.payload.customer.financingVariant,
    advisorName,
    advisorEmail: document.payload.advisor.email,
    advisorPhone: document.payload.advisor.phone,
  })

  await sendTransactionalEmail({
    to: recipient,
    subject: `VeloPrime | Oferta ${stripHtml(modelName)} | ${stripHtml(document.payload.customer.customerName)}`,
    html,
    text,
    replyTo: document.payload.advisor.email,
  })

  await markManagedOfferAsSent(session, input.offerId)

  return {
    ok: true as const,
    email: {
      to: recipient,
      publicUrl,
      expiresAt: shareResult.share.expiresAt,
      versionId: shareResult.share.versionId,
    },
  }
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

  const offer = await getManagedOfferWithCalculation(session, input.offerId)

  if (!offer) {
    return { ok: false as const, error: 'Nie znaleziono oferty.' }
  }

  const nextOwnerId = lead.salespersonId ?? offer.ownerId
  const nextOwnerName = lead.salespersonName ?? offer.ownerName
  const users = await listManagedUsers()
  const nextOwnerUser = users.find((user) => user.id === nextOwnerId) ?? null

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

    await db.lead.update({
      where: { id: lead.id },
      data: {
        customerId: customer.id,
      },
    })

    await logManagedLeadActivity(session, {
      leadId: lead.id,
      label: 'Oferta przypięta',
      value: `Oferta ${updated.number} została przypięta do leada.`,
    })

    return { ok: true as const, offer: { ...mapDbOfferToManagedOffer(updated), leadId: lead.id } }
  }

  offer.leadId = lead.id
  offer.customerName = lead.fullName
  offer.customerEmail = lead.email
  offer.customerPhone = lead.phone
  offer.ownerId = nextOwnerId
  offer.ownerName = nextOwnerName
  offer.ownerEmail = nextOwnerUser?.email ?? offer.ownerEmail
  offer.ownerPhone = nextOwnerUser?.phone ?? offer.ownerPhone
  offer.notes = offer.notes ?? lead.message ?? null
  offer.updatedAt = new Date().toISOString()

  await logManagedLeadActivity(session, {
    leadId: lead.id,
    label: 'Oferta przypięta',
    value: `Oferta ${offer.number} została przypięta do leada.`,
  })

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
  const offer = await getManagedOfferWithCalculation(session, input.offerId)

  if (!offer) {
    return { ok: false as const, error: 'Nie znaleziono oferty.' }
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
        phone: user.phone,
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
        phone: user.phone,
        region: user.region,
        teamName: user.teamName,
        reportsToUserId: user.reportsToUserId,
      },
    })
  }
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
    ownerEmail: offer.owner.email,
    ownerPhone: offer.owner.phone,
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
        shareToken: version.shareToken,
        sharedAt: version.sharedAt?.toISOString() ?? null,
        shareExpiresAt: version.shareExpiresAt?.toISOString() ?? null,
        payloadJson: (version.payloadJson as OfferDocumentPayload | null) ?? null,
        customerSnapshotJson: (version.customerSnapshotJson as OfferCustomerSnapshot | null) ?? null,
        internalSnapshotJson: (version.internalSnapshotJson as OfferInternalSnapshot | null) ?? null,
      })),
    createdAt: offer.createdAt.toISOString(),
    updatedAt: offer.updatedAt.toISOString(),
  }
}