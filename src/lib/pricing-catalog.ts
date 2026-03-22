import 'server-only'

import type { PricingSheet } from '@/lib/pricing-management'

export type PricingCatalogItem = {
  key: string
  brand: string
  model: string
  version: string
  year: string | null
}

export type DetailedPricingCatalogItem = PricingCatalogItem & {
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

function normalizeHeader(value: string) {
  return value
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim()
}

function findHeaderIndex(headers: string[], candidates: string[]) {
  const normalizedHeaders = headers.map(normalizeHeader)
  return normalizedHeaders.findIndex((header) => candidates.some((candidate) => header === normalizeHeader(candidate)))
}

function normalizeCell(value: string | undefined) {
  return (value || '').trim()
}

function parseLocalizedMoney(value: string | undefined) {
  const normalized = normalizeCell(value)
    .replace(/zł/gi, '')
    .replace(/\s+/g, '')
    .replace(/,/g, '.')

  if (!normalized) {
    return null
  }

  const parsed = Number(normalized)
  return Number.isFinite(parsed) ? parsed : null
}

export function buildPricingCatalog(sheet: PricingSheet): PricingCatalogItem[] {
  if (sheet.headers.length === 0 || sheet.rows.length === 0) {
    return []
  }

  const brandIndex = findHeaderIndex(sheet.headers, ['Marka', 'Brand'])
  const modelIndex = findHeaderIndex(sheet.headers, ['Model'])
  const versionIndex = findHeaderIndex(sheet.headers, ['Wersja', 'Version'])
  const yearIndex = findHeaderIndex(sheet.headers, ['Rocznik', 'Rok', 'Year'])

  if (brandIndex === -1 || modelIndex === -1 || versionIndex === -1) {
    return []
  }

  const seen = new Set<string>()

  return sheet.rows
    .map((row) => {
      const brand = normalizeCell(row[brandIndex])
      const model = normalizeCell(row[modelIndex])
      const version = normalizeCell(row[versionIndex])
      const year = yearIndex === -1 ? null : normalizeCell(row[yearIndex]) || null

      if (!brand || !model || !version) {
        return null
      }

      const key = [brand, model, version, year || ''].join('::').toLowerCase()

      if (seen.has(key)) {
        return null
      }

      seen.add(key)

      return {
        key,
        brand,
        model,
        version,
        year,
      } satisfies PricingCatalogItem
    })
    .filter((item): item is PricingCatalogItem => item !== null)
}

export function buildDetailedPricingCatalog(sheet: PricingSheet): DetailedPricingCatalogItem[] {
  if (sheet.headers.length === 0 || sheet.rows.length === 0) {
    return []
  }

  const brandIndex = findHeaderIndex(sheet.headers, ['Marka', 'Brand'])
  const modelIndex = findHeaderIndex(sheet.headers, ['Model'])
  const versionIndex = findHeaderIndex(sheet.headers, ['Wersja', 'Version'])
  const yearIndex = findHeaderIndex(sheet.headers, ['Rocznik', 'Rok', 'Year'])
  const powertrainIndex = findHeaderIndex(sheet.headers, ['Typ napędu', 'Powertrain'])
  const powerHpIndex = findHeaderIndex(sheet.headers, ['Moc ( KM )', 'Moc', 'Power'])
  const listPriceGrossIndex = findHeaderIndex(sheet.headers, ['Cena katalogowa BRUTTO', 'List price gross'])
  const listPriceNetIndex = findHeaderIndex(sheet.headers, ['Cena katalogowa NETTO', 'List price net'])
  const basePriceGrossIndex = findHeaderIndex(sheet.headers, ['CENA bazowa brutto', 'Cena bazowa brutto', 'Base price gross'])
  const basePriceNetIndex = findHeaderIndex(sheet.headers, ['CENA BAZA SPRZEDAŻY netto', 'Cena baza sprzedazy netto', 'Cena bazowa netto', 'Base price net'])

  if (brandIndex === -1 || modelIndex === -1 || versionIndex === -1) {
    return []
  }

  const seen = new Set<string>()

  return sheet.rows
    .map((row) => {
      const brand = normalizeCell(row[brandIndex])
      const model = normalizeCell(row[modelIndex])
      const version = normalizeCell(row[versionIndex])
      const year = yearIndex === -1 ? null : normalizeCell(row[yearIndex]) || null

      if (!brand || !model || !version) {
        return null
      }

      const key = [brand, model, version, year || ''].join('::').toLowerCase()

      if (seen.has(key)) {
        return null
      }

      seen.add(key)

      const listPriceGross = listPriceGrossIndex === -1 ? null : parseLocalizedMoney(row[listPriceGrossIndex])
      const listPriceNet = listPriceNetIndex === -1 ? null : parseLocalizedMoney(row[listPriceNetIndex])
      const basePriceGross = basePriceGrossIndex === -1 ? null : parseLocalizedMoney(row[basePriceGrossIndex])
      const basePriceNet = basePriceNetIndex === -1 ? null : parseLocalizedMoney(row[basePriceNetIndex])

      return {
        key,
        brand,
        model,
        version,
        year,
        powertrain: powertrainIndex === -1 ? null : normalizeCell(row[powertrainIndex]) || null,
        powerHp: powerHpIndex === -1 ? null : normalizeCell(row[powerHpIndex]) || null,
        listPriceGross,
        listPriceNet,
        basePriceGross,
        basePriceNet,
        marginPoolGross: listPriceGross !== null && basePriceGross !== null ? Number((listPriceGross - basePriceGross).toFixed(2)) : null,
        marginPoolNet: listPriceNet !== null && basePriceNet !== null ? Number((listPriceNet - basePriceNet).toFixed(2)) : null,
        label: [brand, model, version, year].filter(Boolean).join(' / '),
      } satisfies DetailedPricingCatalogItem
    })
    .filter((item): item is DetailedPricingCatalogItem => item !== null)
}