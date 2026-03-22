import 'server-only'

import type { CommissionRule } from '@/lib/commission-management'
import type { DetailedPricingCatalogItem } from '@/lib/pricing-catalog'
import type { ManagedUser } from '@/lib/user-management'

export type OfferCustomerType = 'PRIVATE' | 'BUSINESS'

export type OfferCalculationSummary = {
  catalogKey: string
  catalogLabel: string
  customerType: OfferCustomerType
  ownerRole: ManagedUser['role'] | null
  directorName: string | null
  managerName: string | null
  listPriceGross: number | null
  listPriceNet: number | null
  basePriceGross: number | null
  basePriceNet: number | null
  marginPoolGross: number | null
  marginPoolNet: number | null
  directorShare: number
  managerShare: number
  availableDiscount: number
  appliedDiscount: number
  salespersonCommission: number
  finalPriceGross: number | null
  finalPriceNet: number | null
}

function roundMoney(value: number) {
  return Number(value.toFixed(2))
}

function resolveCommissionShare(pool: number, rule?: CommissionRule | null) {
  if (!rule || rule.value === null) {
    return 0
  }

  if (rule.valueType === 'PERCENT') {
    return roundMoney(pool * (rule.value / 100))
  }

  return roundMoney(rule.value)
}

function resolveHierarchy(ownerId: string, users: ManagedUser[]) {
  const usersById = new Map(users.map((user) => [user.id, user]))
  let current = usersById.get(ownerId) ?? null
  let manager: ManagedUser | null = current?.role === 'MANAGER' ? current : null
  let director: ManagedUser | null = current?.role === 'DIRECTOR' ? current : null
  let steps = 0

  while (current?.reportsToUserId && steps < 10) {
    const supervisor = usersById.get(current.reportsToUserId) ?? null

    if (!supervisor) {
      break
    }

    if (!manager && supervisor.role === 'MANAGER') {
      manager = supervisor
    }

    if (!director && supervisor.role === 'DIRECTOR') {
      director = supervisor
    }

    current = supervisor
    steps += 1
  }

  return {
    owner: usersById.get(ownerId) ?? null,
    manager,
    director,
  }
}

export function calculateOfferSummary(input: {
  catalogItem: DetailedPricingCatalogItem
  ownerId: string
  users: ManagedUser[]
  commissionRules: CommissionRule[]
  customerType: OfferCustomerType
  discountValue: number | null
}) {
  const hierarchy = resolveHierarchy(input.ownerId, input.users)
  const usesNet = input.customerType === 'BUSINESS'
  const listPrice = usesNet ? input.catalogItem.listPriceNet : input.catalogItem.listPriceGross
  const basePrice = usesNet ? input.catalogItem.basePriceNet : input.catalogItem.basePriceGross

  if (listPrice === null || basePrice === null) {
    return null
  }

  const pool = roundMoney(Math.max(listPrice - basePrice, 0))
  const directorRule = hierarchy.director
    ? input.commissionRules.find((rule) => rule.userId === hierarchy.director?.id && rule.catalogKey === input.catalogItem.key && !rule.isArchived)
    : null
  const directorShare = Math.min(resolveCommissionShare(pool, directorRule), pool)
  const poolAfterDirector = roundMoney(Math.max(pool - directorShare, 0))
  const managerRule = hierarchy.manager
    ? input.commissionRules.find((rule) => rule.userId === hierarchy.manager?.id && rule.catalogKey === input.catalogItem.key && !rule.isArchived)
    : null
  const managerShare = Math.min(resolveCommissionShare(poolAfterDirector, managerRule), poolAfterDirector)
  const availableDiscount = roundMoney(Math.max(poolAfterDirector - managerShare, 0))
  const appliedDiscount = roundMoney(Math.min(Math.max(input.discountValue ?? 0, 0), availableDiscount))
  const salespersonCommission = roundMoney(Math.max(availableDiscount - appliedDiscount, 0))
  const vatRatio = input.catalogItem.listPriceNet && input.catalogItem.listPriceNet > 0 && input.catalogItem.listPriceGross
    ? input.catalogItem.listPriceGross / input.catalogItem.listPriceNet
    : 1.23

  const finalPriceNet = input.catalogItem.listPriceNet === null
    ? (usesNet ? roundMoney(listPrice - appliedDiscount) : input.catalogItem.listPriceGross !== null ? roundMoney((input.catalogItem.listPriceGross - appliedDiscount) / vatRatio) : null)
    : (usesNet ? roundMoney(input.catalogItem.listPriceNet - appliedDiscount) : roundMoney(input.catalogItem.listPriceNet - (appliedDiscount / vatRatio)))

  const finalPriceGross = input.catalogItem.listPriceGross === null
    ? (finalPriceNet !== null ? roundMoney(finalPriceNet * vatRatio) : null)
    : (usesNet ? roundMoney((finalPriceNet ?? 0) * vatRatio) : roundMoney(input.catalogItem.listPriceGross - appliedDiscount))

  return {
    catalogKey: input.catalogItem.key,
    catalogLabel: input.catalogItem.label,
    customerType: input.customerType,
    ownerRole: hierarchy.owner?.role ?? null,
    directorName: hierarchy.director?.fullName ?? null,
    managerName: hierarchy.manager?.fullName ?? null,
    listPriceGross: input.catalogItem.listPriceGross,
    listPriceNet: input.catalogItem.listPriceNet,
    basePriceGross: input.catalogItem.basePriceGross,
    basePriceNet: input.catalogItem.basePriceNet,
    marginPoolGross: input.catalogItem.marginPoolGross,
    marginPoolNet: input.catalogItem.marginPoolNet,
    directorShare,
    managerShare,
    availableDiscount,
    appliedDiscount,
    salespersonCommission,
    finalPriceGross,
    finalPriceNet,
  } satisfies OfferCalculationSummary
}