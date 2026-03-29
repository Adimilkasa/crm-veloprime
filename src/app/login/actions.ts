'use server'

import { redirect } from 'next/navigation'

import { createSession, validateDemoCredentials } from '@/lib/auth'

export async function loginAction(formData: FormData) {
  const email = String(formData.get('email') || '')
  const password = String(formData.get('password') || '')

  const user = await validateDemoCredentials(email, password)

  if (!user) {
    redirect('/login?error=credentials')
  }

  await createSession({
    sub: user.sub,
    email: user.email,
    fullName: user.fullName,
    role: user.role,
  })

  redirect('/dashboard')
}