export type OfferCustomerType = 'PRIVATE' | 'BUSINESS'

export type SharedModelColorOption = {
  name: string
  isBase: boolean
  surchargeGross: number | null
  surchargeNet: number | null
  sortOrder: number
}

export type SharedModelColorPalette = {
  paletteKey: string
  brand: string
  model: string
  baseColorName: string
  optionalColorSurchargeGross: number | null
  optionalColorSurchargeNet: number | null
  colors: SharedModelColorOption[]
}

export type SharedCommissionRule = {
  userId: string
  catalogKey: string
  valueType: 'AMOUNT' | 'PERCENT'
  value: number | null
  isArchived: boolean
}

export type SharedManagedUser = {
  id: string
  fullName: string
  role: 'ADMIN' | 'DIRECTOR' | 'MANAGER' | 'SALES'
  reportsToUserId: string | null
}

export type SharedDetailedPricingCatalogItem = {
  key: string
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
  label: string
}

export type OfferCalculationSummary = {
  catalogKey: string
  catalogLabel: string
  customerType: OfferCustomerType
  ownerRole: SharedManagedUser['role'] | null
  directorName: string | null
  managerName: string | null
  baseColorName: string | null
  selectedColorName: string | null
  colorSurchargeGross: number
  colorSurchargeNet: number
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

function resolveColorPricing(input: {
  colorPalette: SharedModelColorPalette | null
  selectedColorName?: string | null
  vatRatio: number
}) {
  const palette = input.colorPalette

  if (!palette) {
    return {
      baseColorName: null,
      selectedColorName: null,
      surchargeGross: 0,
      surchargeNet: 0,
    }
  }

  const baseColor = palette.colors.find((color) => color.isBase) ?? palette.colors.find((color) => color.name === palette.baseColorName) ?? null
  const fallbackColor = baseColor ?? palette.colors[0] ?? null
  const selectedColor = input.selectedColorName
    ? palette.colors.find((color) => color.name === input.selectedColorName)
    : fallbackColor

  if (!selectedColor) {
    return {
      baseColorName: palette.baseColorName,
      selectedColorName: palette.baseColorName,
      surchargeGross: 0,
      surchargeNet: 0,
    }
  }

  const surchargeGross = selectedColor.surchargeGross ?? (selectedColor.isBase ? 0 : palette.optionalColorSurchargeGross ?? 0)
  const surchargeNet = selectedColor.surchargeNet ?? (selectedColor.isBase ? 0 : palette.optionalColorSurchargeNet ?? roundMoney(surchargeGross / input.vatRatio))

  return {
    baseColorName: palette.baseColorName,
    selectedColorName: selectedColor.name,
    surchargeGross,
    surchargeNet,
  }
}

function resolveCommissionShare(pool: number, rule?: SharedCommissionRule | null) {
  if (!rule || rule.value === null) {
    return 0
  }

  if (rule.valueType === 'PERCENT') {
    return roundMoney(pool * (rule.value / 100))
  }

  return roundMoney(rule.value)
}

function resolveHierarchy(ownerId: string, users: SharedManagedUser[]) {
  const usersById = new Map(users.map((user) => [user.id, user]))
  let current = usersById.get(ownerId) ?? null
  let manager: SharedManagedUser | null = current?.role === 'MANAGER' ? current : null
  let director: SharedManagedUser | null = current?.role === 'DIRECTOR' ? current : null
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
  catalogItem: SharedDetailedPricingCatalogItem
  ownerId: string
  users: SharedManagedUser[]
  commissionRules: SharedCommissionRule[]
  customerType: OfferCustomerType
  discountValue: number | null
  colorPalette: SharedModelColorPalette | null
  selectedColorName?: string | null
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
  const colorPricing = resolveColorPricing({
    colorPalette: input.colorPalette,
    selectedColorName: input.selectedColorName,
    vatRatio,
  })

  const finalPriceNet = input.catalogItem.listPriceNet === null
    ? (usesNet ? roundMoney(listPrice - appliedDiscount + colorPricing.surchargeNet) : input.catalogItem.listPriceGross !== null ? roundMoney((input.catalogItem.listPriceGross + colorPricing.surchargeGross - appliedDiscount) / vatRatio) : null)
    : (usesNet ? roundMoney(input.catalogItem.listPriceNet + colorPricing.surchargeNet - appliedDiscount) : roundMoney(input.catalogItem.listPriceNet + colorPricing.surchargeNet - (appliedDiscount / vatRatio)))

  const finalPriceGross = input.catalogItem.listPriceGross === null
    ? (finalPriceNet !== null ? roundMoney(finalPriceNet * vatRatio) : null)
    : (usesNet ? roundMoney((finalPriceNet ?? 0) * vatRatio) : roundMoney(input.catalogItem.listPriceGross + colorPricing.surchargeGross - appliedDiscount))

  return {
    catalogKey: input.catalogItem.key,
    catalogLabel: input.catalogItem.label,
    customerType: input.customerType,
    ownerRole: hierarchy.owner?.role ?? null,
    directorName: hierarchy.director?.fullName ?? null,
    managerName: hierarchy.manager?.fullName ?? null,
    baseColorName: colorPricing.baseColorName,
    selectedColorName: colorPricing.selectedColorName,
    colorSurchargeGross: colorPricing.surchargeGross,
    colorSurchargeNet: colorPricing.surchargeNet,
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