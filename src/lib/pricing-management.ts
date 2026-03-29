import 'server-only'

import { mkdir, readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'

import type { AuthSession } from '@/lib/auth'

export type PricingSheet = {
  headers: string[]
  rows: string[][]
  updatedAt: string | null
  updatedBy: string | null
}

const PRICING_DATA_DIR = path.join(process.cwd(), 'data')
const PRICING_SHEET_PATH = path.join(PRICING_DATA_DIR, 'pricing-sheet.json')

let inMemoryPricingSheet: PricingSheet | null = null

function canManagePricing(role: AuthSession['role']) {
  return role === 'ADMIN' || role === 'DIRECTOR'
}

function normalizeHeader(value: string, index: number) {
  const trimmed = value.trim()
  return trimmed || `Kolumna ${index + 1}`
}

function normalizeRow(row: string[], length: number) {
  const nextRow = [...row]

  while (nextRow.length < length) {
    nextRow.push('')
  }

  return nextRow.slice(0, length)
}

function parseTabularInput(input: string) {
  const lines = input
    .replace(/\r/g, '')
    .split('\n')
    .map((line) => line.split('\t'))
    .filter((cells) => cells.some((cell) => cell.trim().length > 0))

  if (lines.length === 0) {
    return null
  }

  const widestRowLength = Math.max(...lines.map((row) => row.length))
  const headers = normalizeRow(lines[0], widestRowLength).map((value, index) => normalizeHeader(value, index))
  const rows = lines.slice(1).map((row) => normalizeRow(row, widestRowLength))

  return { headers, rows }
}

function buildSeedSheet(): PricingSheet {
  return {
    headers: [
      'Stock',
      'Marka',
      'Model',
      'Wersja',
      'Rok',
      'Kolor',
      'Status',
      'Cena brutto',
      'Cena docelowa',
      'Cena minimalna',
      'Rata od',
      'Uwagi',
    ],
    rows: [
      ['VP-001', 'BYD', 'Seal 6 DM-i', 'Comfort', '2026', 'Graphite', 'Dostępny', '184900', '181500', '178000', '1899', 'Auto demo / Warszawa'],
      ['VP-002', 'BYD', 'Seal U', 'Design', '2026', 'Snow White', 'W drodze', '203500', '199900', '195000', '2099', 'Dostawa kwiecień'],
    ],
    updatedAt: null,
    updatedBy: null,
  }
}

async function ensureStoreFile() {
  try {
    await mkdir(PRICING_DATA_DIR, { recursive: true })
    await readFile(PRICING_SHEET_PATH, 'utf8')
  } catch {
    const seedSheet = buildSeedSheet()
    inMemoryPricingSheet = seedSheet

    try {
      await writeFile(PRICING_SHEET_PATH, JSON.stringify(seedSheet, null, 2), 'utf8')
    } catch {
      // Serverless environments may not allow writes to the application filesystem.
    }
  }
}

async function readStore() {
  await ensureStoreFile()

  try {
    const raw = await readFile(PRICING_SHEET_PATH, 'utf8')
    const parsed = JSON.parse(raw) as Partial<PricingSheet>

    return {
      headers: Array.isArray(parsed.headers) ? parsed.headers : [],
      rows: Array.isArray(parsed.rows) ? parsed.rows.filter(Array.isArray) : [],
      updatedAt: typeof parsed.updatedAt === 'string' ? parsed.updatedAt : null,
      updatedBy: typeof parsed.updatedBy === 'string' ? parsed.updatedBy : null,
    } satisfies PricingSheet
  } catch {
    if (!inMemoryPricingSheet) {
      inMemoryPricingSheet = buildSeedSheet()
    }

    return inMemoryPricingSheet
  }
}

async function writeStore(sheet: PricingSheet) {
  inMemoryPricingSheet = sheet

  try {
    await ensureStoreFile()
    await writeFile(PRICING_SHEET_PATH, JSON.stringify(sheet, null, 2), 'utf8')
  } catch {
    // Ignore filesystem write failures in serverless hosting.
  }
}

export async function getActivePricingSheet() {
  return readStore()
}

export async function getPricingSheet(session: AuthSession) {
  if (!canManagePricing(session.role)) {
    return { ok: false as const, error: 'Tylko administrator lub dyrektor mogą zarządzać polityką cenową.' }
  }

  const sheet = await readStore()
  return { ok: true as const, sheet }
}

export async function importPricingSheet(session: AuthSession, rawInput: string) {
  if (!canManagePricing(session.role)) {
    return { ok: false as const, error: 'Tylko administrator lub dyrektor mogą importować bazę cenową.' }
  }

  const parsed = parseTabularInput(rawInput)

  if (!parsed) {
    return { ok: false as const, error: 'Wklej dane tabelaryczne z Excela wraz z nagłówkami.' }
  }

  if (parsed.headers.length < 2) {
    return { ok: false as const, error: 'Tabela musi zawierać przynajmniej dwie kolumny.' }
  }

  const sheet = await readStore()
  sheet.headers = parsed.headers
  sheet.rows = parsed.rows
  sheet.updatedAt = new Date().toISOString()
  sheet.updatedBy = session.fullName

  await writeStore(sheet)

  return { ok: true as const, sheet }
}

export async function savePricingSheet(
  session: AuthSession,
  input: {
    headers: string[]
    rows: string[][]
  }
) {
  if (!canManagePricing(session.role)) {
    return { ok: false as const, error: 'Tylko administrator lub dyrektor mogą zapisywać bazę cenową.' }
  }

  const normalizedHeaders = input.headers
    .map((value, index) => normalizeHeader(value, index))
    .filter((value) => value.trim().length > 0)

  if (normalizedHeaders.length < 2) {
    return { ok: false as const, error: 'Arkusz musi mieć przynajmniej dwie kolumny.' }
  }

  const normalizedRows = input.rows
    .map((row) => normalizeRow(row, normalizedHeaders.length))
    .filter((row) => row.some((cell) => cell.trim().length > 0))

  const sheet = await readStore()
  sheet.headers = normalizedHeaders
  sheet.rows = normalizedRows
  sheet.updatedAt = new Date().toISOString()
  sheet.updatedBy = session.fullName

  await writeStore(sheet)

  return { ok: true as const, sheet }
}

export async function clearPricingSheet(session: AuthSession) {
  if (!canManagePricing(session.role)) {
    return { ok: false as const, error: 'Tylko administrator lub dyrektor mogą wyczyścić bazę cenową.' }
  }

  const sheet = await readStore()
  sheet.headers = []
  sheet.rows = []
  sheet.updatedAt = new Date().toISOString()
  sheet.updatedBy = session.fullName

  await writeStore(sheet)

  return { ok: true as const }
}