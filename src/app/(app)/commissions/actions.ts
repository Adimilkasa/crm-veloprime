'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

import { getSession } from '@/lib/auth'
import { saveCommissionRules } from '@/lib/commission-management'

async function requireSession() {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  return session
}

export async function saveCommissionRulesAction(formData: FormData) {
  const session = await requireSession()
  const targetUserId = String(formData.get('targetUserId') || '')
  const rulesRaw = String(formData.get('rulesJson') || '[]')

  let rules: Array<{ id: string; valueType: 'AMOUNT' | 'PERCENT'; value: number | null }> = []

  try {
    rules = JSON.parse(rulesRaw) as Array<{ id: string; valueType: 'AMOUNT' | 'PERCENT'; value: number | null }>
  } catch {
    return { ok: false as const, error: 'Nie udało się odczytać listy prowizji.' }
  }

  const result = await saveCommissionRules(session, { targetUserId, rules })

  if (!result.ok) {
    return result
  }

  revalidatePath('/commissions')
  return { ok: true as const }
}