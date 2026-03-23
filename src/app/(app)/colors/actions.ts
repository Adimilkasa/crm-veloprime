'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

import { getSession } from '@/lib/auth'
import { saveColorPalettes } from '@/lib/color-management'

async function requireSession() {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  return session
}

export async function saveColorPalettesAction(formData: FormData) {
  const session = await requireSession()
  const palettesJson = String(formData.get('palettesJson') || '[]')

  try {
    const palettes = JSON.parse(palettesJson)
    const result = await saveColorPalettes(session, { palettes })

    if (!result.ok) {
      return result
    }

    revalidatePath('/colors')
    revalidatePath('/offers')
    return { ok: true as const }
  } catch {
    return { ok: false as const, error: 'Nie udało się odczytać danych palet do zapisu.' }
  }
}