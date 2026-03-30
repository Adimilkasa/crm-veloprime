'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

import { getSession } from '@/lib/auth'
import { syncCommissionRules } from '@/lib/commission-management'
import type { UserRoleKey } from '@/lib/rbac'
import { createManagedUser, toggleManagedUserStatus } from '@/lib/user-management'

async function requireAdmin() {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  if (session.role !== 'ADMIN') {
    redirect('/dashboard')
  }

  return session
}

export async function createUserAction(formData: FormData) {
  const session = await requireAdmin()

  const result = await createManagedUser({
    fullName: String(formData.get('fullName') || ''),
    email: String(formData.get('email') || ''),
    phone: String(formData.get('phone') || ''),
    role: String(formData.get('role') || 'SALES') as UserRoleKey,
    password: String(formData.get('password') || ''),
    region: String(formData.get('region') || ''),
    teamName: String(formData.get('teamName') || ''),
    reportsToUserId: String(formData.get('reportsToUserId') || ''),
  })

  if (!result.ok) {
    redirect(`/users?error=${encodeURIComponent(result.error)}`)
  }

  await syncCommissionRules(session.fullName)

  revalidatePath('/users')
  const nextUrl = new URL('/users', 'http://localhost')
  nextUrl.searchParams.set('success', 'created')

  if (result.temporaryPassword) {
    nextUrl.searchParams.set('tempPassword', result.temporaryPassword)
  }

  redirect(`${nextUrl.pathname}${nextUrl.search}`)
}

export async function toggleUserStatusAction(formData: FormData) {
  const session = await requireAdmin()

  const userId = String(formData.get('userId') || '')
  const result = await toggleManagedUserStatus(userId)

  if (!result.ok) {
    redirect(`/users?error=${encodeURIComponent(result.error)}`)
  }

  await syncCommissionRules(session.fullName)

  revalidatePath('/users')
  redirect('/users?success=toggled')
}