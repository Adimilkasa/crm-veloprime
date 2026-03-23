import 'server-only'

import { mkdir, readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'

import type { AuthSession } from '@/lib/auth'

export type ModelColorOption = {
  name: string
  isBase: boolean
  surchargeGross: number | null
  surchargeNet: number | null
  sortOrder: number
}

export type ModelColorPalette = {
  paletteKey: string
  brand: string
  model: string
  baseColorName: string
  optionalColorSurchargeGross: number | null
  optionalColorSurchargeNet: number | null
  colors: ModelColorOption[]
}

type RawModelColorOption = {
  name?: unknown
  isBase?: unknown
  surchargeGross?: unknown
  surchargeNet?: unknown
  sortOrder?: unknown
}

type RawModelColorPalette = {
  brand?: unknown
  model?: unknown
  baseColorName?: unknown
  optionalColorSurchargeGross?: unknown
  optionalColorSurchargeNet?: unknown
  colors?: unknown
}

const COLOR_PALETTES_PATH = path.join(process.cwd(), 'data', 'byd-color-palettes.json')

function canManageColorPalettes(role: AuthSession['role']) {
  return role === 'ADMIN' || role === 'DIRECTOR'
}

function normalizeText(value: unknown) {
  return typeof value === 'string' ? value.trim() : ''
}

function normalizeNumber(value: unknown) {
  return typeof value === 'number' && Number.isFinite(value) ? value : null
}

export function buildModelColorPaletteKey(brand: string, model: string) {
  return `${brand.trim().toLowerCase()}::${model.trim().toLowerCase()}`
}

function normalizeColorOption(option: RawModelColorOption, index: number): ModelColorOption | null {
  const name = normalizeText(option.name)

  if (!name) {
    return null
  }

  return {
    name,
    isBase: Boolean(option.isBase),
    surchargeGross: normalizeNumber(option.surchargeGross),
    surchargeNet: normalizeNumber(option.surchargeNet),
    sortOrder: typeof option.sortOrder === 'number' && Number.isFinite(option.sortOrder) ? option.sortOrder : index,
  }
}

async function readColorPalettesFile() {
  const raw = await readFile(COLOR_PALETTES_PATH, 'utf8')
  const parsed = JSON.parse(raw)

  return Array.isArray(parsed) ? parsed as RawModelColorPalette[] : []
}

async function ensureColorPalettesFile() {
  await mkdir(path.dirname(COLOR_PALETTES_PATH), { recursive: true })

  try {
    await readFile(COLOR_PALETTES_PATH, 'utf8')
  } catch {
    await writeFile(COLOR_PALETTES_PATH, '[]', 'utf8')
  }
}

async function writeColorPalettesFile(palettes: ModelColorPalette[]) {
  await ensureColorPalettesFile()
  await writeFile(
    COLOR_PALETTES_PATH,
    JSON.stringify(
      palettes.map((palette) => ({
        brand: palette.brand,
        model: palette.model,
        baseColorName: palette.baseColorName,
        optionalColorSurchargeGross: palette.optionalColorSurchargeGross,
        optionalColorSurchargeNet: palette.optionalColorSurchargeNet,
        colors: palette.colors.map((color) => ({
          name: color.name,
          isBase: color.isBase,
          surchargeGross: color.surchargeGross,
          surchargeNet: color.surchargeNet,
          sortOrder: color.sortOrder,
        })),
      })),
      null,
      2
    ),
    'utf8'
  )
}

export async function listColorPalettes() {
  const rawPalettes = await readColorPalettesFile()

  return rawPalettes
    .map((palette) => {
      const brand = normalizeText(palette.brand)
      const model = normalizeText(palette.model)
      const baseColorName = normalizeText(palette.baseColorName)

      if (!brand || !model || !baseColorName) {
        return null
      }

      const colors = Array.isArray(palette.colors)
        ? palette.colors
            .map((color, index) => normalizeColorOption(color as RawModelColorOption, index))
            .filter((color): color is ModelColorOption => color !== null)
            .sort((left, right) => left.sortOrder - right.sortOrder || left.name.localeCompare(right.name, 'pl'))
        : []

      return {
        paletteKey: buildModelColorPaletteKey(brand, model),
        brand,
        model,
        baseColorName,
        optionalColorSurchargeGross: normalizeNumber(palette.optionalColorSurchargeGross),
        optionalColorSurchargeNet: normalizeNumber(palette.optionalColorSurchargeNet),
        colors,
      } satisfies ModelColorPalette
    })
    .filter((palette): palette is ModelColorPalette => palette !== null)
}

export async function findColorPalette(brand: string, model: string) {
  const key = buildModelColorPaletteKey(brand, model)
  const palettes = await listColorPalettes()

  return palettes.find((palette) => palette.paletteKey === key) ?? null
}

export async function getColorPaletteWorkspace(session: AuthSession) {
  if (!canManageColorPalettes(session.role)) {
    return { ok: false as const, error: 'Tylko administrator lub dyrektor mogą zarządzać paletami kolorów.' }
  }

  return {
    ok: true as const,
    palettes: await listColorPalettes(),
  }
}

export async function saveColorPalettes(
  session: AuthSession,
  input: {
    palettes: ModelColorPalette[]
  }
) {
  if (!canManageColorPalettes(session.role)) {
    return { ok: false as const, error: 'Tylko administrator lub dyrektor mogą zapisywać palety kolorów.' }
  }

  const normalizedPalettes = input.palettes
    .map((palette) => {
      const brand = palette.brand.trim()
      const model = palette.model.trim()
      const baseColorName = palette.baseColorName.trim()
      const colors = palette.colors
        .map((color, index) => ({
          name: color.name.trim(),
          isBase: color.isBase,
          surchargeGross: color.surchargeGross,
          surchargeNet: color.surchargeNet,
          sortOrder: index,
        }))
        .filter((color) => color.name.length > 0)

      if (!brand || !model || !baseColorName || colors.length === 0) {
        return null
      }

      return {
        paletteKey: buildModelColorPaletteKey(brand, model),
        brand,
        model,
        baseColorName,
        optionalColorSurchargeGross: palette.optionalColorSurchargeGross,
        optionalColorSurchargeNet: palette.optionalColorSurchargeNet,
        colors: colors.map((color) => ({
          ...color,
          isBase: color.name === baseColorName,
        })),
      } satisfies ModelColorPalette
    })
    .filter((palette): palette is ModelColorPalette => palette !== null)
    .sort((left, right) => left.brand.localeCompare(right.brand, 'pl') || left.model.localeCompare(right.model, 'pl'))

  await writeColorPalettesFile(normalizedPalettes)

  return { ok: true as const, palettes: normalizedPalettes }
}