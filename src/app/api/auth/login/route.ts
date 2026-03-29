import { NextResponse } from 'next/server'

import { createSessionToken, getCookieName, getSessionCookieSettings, validateDemoCredentials } from '@/lib/auth'

export async function POST(request: Request) {
  const formData = await request.formData()
  const email = String(formData.get('email') || '')
  const password = String(formData.get('password') || '')
  const user = await validateDemoCredentials(email, password)
  const loginUrl = new URL('/login', request.url)

  if (!user) {
    loginUrl.searchParams.set('error', 'credentials')
    return NextResponse.redirect(loginUrl, { status: 303 })
  }

  const response = NextResponse.redirect(new URL('/dashboard', request.url), { status: 303 })
  const token = await createSessionToken({
    sub: user.sub,
    email: user.email,
    fullName: user.fullName,
    role: user.role,
  })

  response.cookies.set(getCookieName(), token, getSessionCookieSettings())

  return response
}