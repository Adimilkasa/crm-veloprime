'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

import { getSession } from '@/lib/auth'
import { syncCommissionRules } from '@/lib/commission-management'
import { clearPricingSheet, importPricingSheet, savePricingSheet } from '@/lib/pricing-management'

async function requireSession() {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  return session
}

export async function savePricingSheetAction(formData: FormData) {
  const session = await requireSession()
  const headersRaw = String(formData.get('headersJson') || '[]')
  const rowsRaw = String(formData.get('rowsJson') || '[]')

  let headers: string[] = []
  let rows: string[][] = []

  try {
    headers = JSON.parse(headersRaw) as string[]
    rows = JSON.parse(rowsRaw) as string[][]
  } catch {
    return { ok: false as const, error: 'Nie udało się odczytać danych arkusza.' }
  }

  const result = await savePricingSheet(session, { headers, rows })

  if (!result.ok) {
    return result
  }

  await syncCommissionRules(session.fullName)

  revalidatePath('/pricing')
  revalidatePath('/commissions')
  return { ok: true as const }
}

export async function importPricingSheetAction(formData: FormData) {
  const session = await requireSession()
  const result = await importPricingSheet(session, String(formData.get('sheetInput') || ''))

  if (!result.ok) {
    return result
  }

  await syncCommissionRules(session.fullName)

  revalidatePath('/pricing')
  revalidatePath('/commissions')
  return { ok: true as const }
}

export async function clearPricingSheetAction() {
  const session = await requireSession()
  const result = await clearPricingSheet(session)

  if (!result.ok) {
    return result
  }

  await syncCommissionRules(session.fullName)

  revalidatePath('/pricing')
  revalidatePath('/commissions')
  return { ok: true as const }
}