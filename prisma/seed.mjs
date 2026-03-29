import { readFile } from 'node:fs/promises'
import path from 'node:path'
import { randomUUID, scryptSync } from 'node:crypto'

import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()
const VAT_RATE = 1.23
const PALETTES_PATH = path.join(process.cwd(), 'data', 'byd-color-palettes.json')
const PASSWORD_HASH_PREFIX = 'scrypt:'

const seedUsers = [
  {
    id: 'demo-admin',
    email: 'admin@veloprime.pl',
    fullName: 'Administrator VeloPrime',
    role: 'ADMIN',
    reportsToUserId: null,
    password: 'Admin123!',
  },
  {
    id: 'demo-director',
    email: 'dyrektor@veloprime.pl',
    fullName: 'Dyrektor Sprzedazy',
    role: 'DIRECTOR',
    reportsToUserId: null,
    password: 'Director123!',
  },
  {
    id: 'demo-manager',
    email: 'manager@veloprime.pl',
    fullName: 'Manager Regionu',
    role: 'MANAGER',
    reportsToUserId: 'demo-director',
    password: 'Manager123!',
  },
  {
    id: 'demo-sales',
    email: 'handlowiec@veloprime.pl',
    fullName: 'Handlowiec VeloPrime',
    role: 'SALES',
    reportsToUserId: 'demo-manager',
    password: 'Sales123!',
  },
]

function roundMoney(value) {
  return Number(value.toFixed(2))
}

function toNet(gross, explicitNet) {
  if (typeof explicitNet === 'number' && Number.isFinite(explicitNet)) {
    return explicitNet
  }

  if (typeof gross === 'number' && Number.isFinite(gross)) {
    return roundMoney(gross / VAT_RATE)
  }

  return null
}

function hashPassword(password) {
  const salt = randomUUID().replace(/-/g, '')
  const hash = scryptSync(password, salt, 64).toString('hex')
  return `${PASSWORD_HASH_PREFIX}${salt}:${hash}`
}

async function readPalettes() {
  const raw = await readFile(PALETTES_PATH, 'utf8')
  const parsed = JSON.parse(raw)

  return Array.isArray(parsed) ? parsed : []
}

async function main() {
  for (const user of seedUsers) {
    await prisma.user.upsert({
      where: { id: user.id },
      update: {
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        isActive: true,
        reportsToUserId: user.reportsToUserId,
        passwordHash: hashPassword(user.password),
      },
      create: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        isActive: true,
        reportsToUserId: user.reportsToUserId,
        passwordHash: hashPassword(user.password),
      },
    })
  }

  const palettes = await readPalettes()

  for (const palette of palettes) {
    if (!palette?.brand || !palette?.model || !palette?.baseColorName) {
      continue
    }

    const brandSetting = await prisma.brandSetting.upsert({
      where: { brand: palette.brand },
      update: {
        isActive: true,
      },
      create: {
        brand: palette.brand,
        defaultCurrency: 'PLN',
        isActive: true,
      },
    })

    const salesPalette = await prisma.salesModelColorPalette.upsert({
      where: {
        brand_model: {
          brand: palette.brand,
          model: palette.model,
        },
      },
      update: {
        baseColorName: palette.baseColorName,
        optionalColorSurchargeGross: typeof palette.optionalColorSurchargeGross === 'number' ? palette.optionalColorSurchargeGross : null,
        optionalColorSurchargeNet: toNet(palette.optionalColorSurchargeGross, palette.optionalColorSurchargeNet),
        isActive: true,
        brandSettingId: brandSetting.id,
      },
      create: {
        brand: palette.brand,
        model: palette.model,
        baseColorName: palette.baseColorName,
        optionalColorSurchargeGross: typeof palette.optionalColorSurchargeGross === 'number' ? palette.optionalColorSurchargeGross : null,
        optionalColorSurchargeNet: toNet(palette.optionalColorSurchargeGross, palette.optionalColorSurchargeNet),
        isActive: true,
        brandSettingId: brandSetting.id,
      },
    })

    await prisma.salesModelColorOption.deleteMany({
      where: { paletteId: salesPalette.id },
    })

    if (Array.isArray(palette.colors) && palette.colors.length > 0) {
      await prisma.salesModelColorOption.createMany({
        data: palette.colors
          .filter((color) => color?.name)
          .map((color, index) => ({
            paletteId: salesPalette.id,
            colorName: color.name,
            isBase: Boolean(color.isBase),
            surchargeGross: typeof color.surchargeGross === 'number' ? color.surchargeGross : null,
            surchargeNet: toNet(color.surchargeGross, color.surchargeNet),
            sortOrder: typeof color.sortOrder === 'number' ? color.sortOrder : index,
            isActive: true,
          })),
      })
    }

    await prisma.salesCatalogItem.updateMany({
      where: {
        brand: palette.brand,
        model: palette.model,
      },
      data: {
        baseColorName: palette.baseColorName,
        colorPaletteId: salesPalette.id,
      },
    })
  }

  console.log(`Seeded ${seedUsers.length} users and ${palettes.length} color palettes.`)
}

main()
  .catch((error) => {
    console.error(error)
    process.exitCode = 1
  })
  .finally(async () => {
    await prisma.$disconnect()
  })