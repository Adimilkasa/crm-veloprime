import { NextResponse, type NextRequest } from 'next/server'
import { jwtVerify } from 'jose'

const SESSION_COOKIE = 'crmvp_session'

function getSecret() {
  return new TextEncoder().encode(process.env.AUTH_SECRET || 'crm-veloprime-dev-secret-change-me')
}

async function hasValidSession(request: NextRequest) {
  const token = request.cookies.get(SESSION_COOKIE)?.value
  if (!token) return false

  try {
    await jwtVerify(token, getSecret())
    return true
  } catch {
    return false
  }
}

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  const isAppRoute = pathname.startsWith('/dashboard') || pathname.startsWith('/users') || pathname.startsWith('/leads')
  const isLoginRoute = pathname === '/login'
  const isLogoutRoute = pathname === '/logout'

  const loggedIn = await hasValidSession(request)

  if (isAppRoute && !loggedIn) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  if (isLoginRoute && loggedIn) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  if (isLogoutRoute && !loggedIn) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/dashboard/:path*', '/users/:path*', '/leads/:path*', '/login', '/logout'],
}