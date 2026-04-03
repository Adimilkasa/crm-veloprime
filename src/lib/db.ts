import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma?: PrismaClient
}

export function hasDatabaseUrl() {
  return Boolean(process.env.DATABASE_URL?.trim())
}

export function isDatabaseUnavailableError(error: unknown) {
  if (!error || typeof error !== 'object') {
    return false
  }

  const code = 'code' in error ? String((error as { code?: unknown }).code ?? '') : ''
  const message = 'message' in error ? String((error as { message?: unknown }).message ?? '') : ''
  const combined = `${code} ${message}`.toLowerCase()

  return (
    code === 'P1001'
    || code === 'P1002'
    || combined.includes('can\'t reach database server')
    || combined.includes('can’t reach database server')
    || combined.includes('database server') && combined.includes('timed out')
    || combined.includes('connection') && combined.includes('refused')
    || combined.includes('connection') && combined.includes('closed')
    || combined.includes('connection') && combined.includes('terminated')
    || combined.includes('getaddrinfo')
    || combined.includes('econnrefused')
    || combined.includes('enotfound')
    || combined.includes('server has closed the connection')
  )
}

export function getDb() {
  if (!hasDatabaseUrl()) {
    return null
  }

  if (!globalForPrisma.prisma) {
    globalForPrisma.prisma = new PrismaClient({
      log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
    })
  }

  return globalForPrisma.prisma
}

export const db = getDb()