export const DEFAULT_VAT_RATE = 23

export const SALES_MODEL_STATUSES = ['ACTIVE', 'ARCHIVED'] as const
export const SALES_POWERTRAIN_TYPES = ['ELECTRIC', 'HYBRID', 'ICE'] as const
export const SALES_DRIVE_TYPES = ['FWD', 'RWD', 'AWD'] as const
export const SALES_PRICING_STATUSES = ['DRAFT', 'PUBLISHED', 'ARCHIVED'] as const
export const SALES_ASSET_CATEGORIES = ['PRIMARY', 'EXTERIOR', 'INTERIOR', 'DETAILS', 'PREMIUM', 'SPEC_PDF', 'LOGO', 'OTHER'] as const

export type SalesModelStatus = (typeof SALES_MODEL_STATUSES)[number]
export type SalesPowertrainType = (typeof SALES_POWERTRAIN_TYPES)[number]
export type SalesDriveType = (typeof SALES_DRIVE_TYPES)[number]
export type SalesPricingStatus = (typeof SALES_PRICING_STATUSES)[number]
export type SalesAssetCategory = (typeof SALES_ASSET_CATEGORIES)[number]

export type SalesBrandRecord = {
  id: string
  code: string
  name: string
  sortOrder: number
  createdAt: string
  updatedAt: string
}

export type SalesModelRecord = {
  id: string
  brandId: string
  code: string
  name: string
  marketingName: string | null
  status: SalesModelStatus
  sortOrder: number
  availablePowertrains: SalesPowertrainType[]
  createdAt: string
  updatedAt: string
}

export type SalesVersionRecord = {
  id: string
  modelId: string
  code: string
  name: string
  year: number | null
  powertrainType: SalesPowertrainType
  driveType: SalesDriveType | null
  systemPowerHp: number | null
  batteryCapacityKwh: number | null
  combustionEnginePowerHp: number | null
  engineDisplacementCc: number | null
  rangeKm: number | null
  notes: string | null
  sortOrder: number
  createdAt: string
  updatedAt: string
}

export type SalesVersionPricingRecord = {
  id: string
  versionId: string
  listPriceNet: number
  listPriceGross: number
  basePriceNet: number
  basePriceGross: number
  vatRate: number
  marginPoolNet: number
  marginPoolGross: number
  pricingStatus: SalesPricingStatus
  effectiveFrom: string | null
  effectiveTo: string | null
  createdAt: string
  updatedAt: string
}

export type SalesModelColorRecord = {
  id: string
  modelId: string
  code: string
  name: string
  finishType: string | null
  isBaseColor: boolean
  hasSurcharge: boolean
  surchargeNet: number | null
  surchargeGross: number | null
  sortOrder: number
  createdAt: string
  updatedAt: string
}

export type SalesAssetFileRecord = {
  id: string
  bundleId: string
  category: SalesAssetCategory
  powertrainType: SalesPowertrainType | null
  fileName: string
  filePath: string
  mimeType: string | null
  sortOrder: number
  createdAt: string
  updatedAt: string
}

export type SalesModelAssetBundleRecord = {
  id: string
  modelId: string
  assetsVersionTag: string | null
  isActive: boolean
  createdAt: string
  updatedAt: string
  files: SalesAssetFileRecord[]
}

export type SalesOfferSnapshotProduct = {
  brandName: string
  modelName: string
  versionName: string
  year: number | null
  powertrainType: SalesPowertrainType
  systemPowerHp: number | null
  batteryCapacityKwh: number | null
  combustionEnginePowerHp: number | null
  engineDisplacementCc: number | null
}

export type SalesOfferSnapshotColor = {
  selectedColorName: string | null
  selectedColorCode: string | null
  isBaseColor: boolean
  colorSurchargeNet: number | null
  colorSurchargeGross: number | null
}

export type SalesOfferSnapshotPricing = {
  listPriceNet: number | null
  listPriceGross: number | null
  basePriceNet: number | null
  basePriceGross: number | null
  marginPoolNet: number | null
  marginPoolGross: number | null
  discountAmountNet: number | null
  discountAmountGross: number | null
  discountPercent: number | null
  finalVehiclePriceNet: number | null
  finalVehiclePriceGross: number | null
  finalOfferPriceNet: number | null
  finalOfferPriceGross: number | null
}

export type SalesOfferSnapshotInternal = {
  directorShareNet: number | null
  directorShareGross: number | null
  managerShareNet: number | null
  managerShareGross: number | null
  salespersonCommissionNet: number | null
  salespersonCommissionGross: number | null
  availableDiscountNet: number | null
  availableDiscountGross: number | null
}

export type SalesOfferSnapshotFinancing = {
  customerType: 'PRIVATE' | 'BUSINESS'
  financingVariant: string | null
  termMonths: number | null
  downPaymentAmount: number | null
  buyoutPercent: number | null
  buyoutAmount: number | null
  estimatedInstallment: number | null
  financingDisclaimer: string | null
}

export type SalesOfferSnapshotAssets = {
  assetBundleId: string | null
  assetsVersion: string | null
  primaryImageUrl: string | null
  specPdfUrl: string | null
  galleryUrls: Partial<Record<SalesAssetCategory, string[]>>
}

export type SalesOfferSnapshotAudit = {
  dataVersion: string | null
  assetsVersion: string | null
  applicationVersion: string | null
  generatedAt: string
  generatedByUserId: string
  generatedByUserRole: 'ADMIN' | 'DIRECTOR' | 'MANAGER' | 'SALES'
}

export type SalesOfferSnapshot = {
  product: SalesOfferSnapshotProduct
  color: SalesOfferSnapshotColor
  pricing: SalesOfferSnapshotPricing
  internal: SalesOfferSnapshotInternal
  financing: SalesOfferSnapshotFinancing | null
  assets: SalesOfferSnapshotAssets
  audit: SalesOfferSnapshotAudit
}

export function roundMoney(value: number) {
  return Math.round((value + Number.EPSILON) * 100) / 100
}

export function buildStableCatalogCode(...parts: Array<string | number | null | undefined>) {
  return parts
    .filter((part) => part !== null && part !== undefined)
    .map((part) => String(part).trim())
    .filter((part) => part.length > 0)
    .join('_')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .toUpperCase()
}

export function calculateGrossFromNet(net: number, vatRate = DEFAULT_VAT_RATE) {
  return roundMoney(net * (1 + vatRate / 100))
}

export function calculateNetFromGross(gross: number, vatRate = DEFAULT_VAT_RATE) {
  return roundMoney(gross / (1 + vatRate / 100))
}

export function calculateMarginPool(listPrice: number, basePrice: number) {
  return roundMoney(listPrice - basePrice)
}

export function buildDerivedPricing(input: {
  listPriceNet: number
  basePriceNet: number
  vatRate?: number
  pricingStatus?: SalesPricingStatus
  effectiveFrom?: string | null
  effectiveTo?: string | null
}): Omit<SalesVersionPricingRecord, 'id' | 'versionId' | 'createdAt' | 'updatedAt'> {
  const vatRate = input.vatRate ?? DEFAULT_VAT_RATE
  const listPriceGross = calculateGrossFromNet(input.listPriceNet, vatRate)
  const basePriceGross = calculateGrossFromNet(input.basePriceNet, vatRate)

  return {
    listPriceNet: roundMoney(input.listPriceNet),
    listPriceGross,
    basePriceNet: roundMoney(input.basePriceNet),
    basePriceGross,
    vatRate,
    marginPoolNet: calculateMarginPool(input.listPriceNet, input.basePriceNet),
    marginPoolGross: calculateMarginPool(listPriceGross, basePriceGross),
    pricingStatus: input.pricingStatus ?? 'DRAFT',
    effectiveFrom: input.effectiveFrom ?? null,
    effectiveTo: input.effectiveTo ?? null,
  }
}

export function collectModelPowertrainTypes(versions: Array<Pick<SalesVersionRecord, 'powertrainType'>>) {
  return [...new Set(versions.map((version) => version.powertrainType))].sort() as SalesPowertrainType[]
}

export function groupAssetFilesByCategory(files: SalesAssetFileRecord[]) {
  return files.reduce<Partial<Record<SalesAssetCategory, SalesAssetFileRecord[]>>>((groups, file) => {
    const bucket = groups[file.category] ?? []
    bucket.push(file)
    groups[file.category] = bucket.sort((left, right) => left.sortOrder - right.sortOrder || left.fileName.localeCompare(right.fileName, 'pl'))
    return groups
  }, {})
}

export function findSpecPdfForPowertrain(bundle: SalesModelAssetBundleRecord, powertrainType: SalesPowertrainType) {
  return bundle.files.find((file) => file.category === 'SPEC_PDF' && file.powertrainType === powertrainType)
    ?? bundle.files.find((file) => file.category === 'SPEC_PDF' && file.powertrainType === null)
    ?? null
}