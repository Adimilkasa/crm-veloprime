'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Bell, LogOut } from 'lucide-react'

import { getNavigationForRole, getRoleDefinition, type UserRoleKey } from '@/lib/rbac'

export function AppShell({
  children,
  role,
  userName,
}: {
  children: React.ReactNode
  role: UserRoleKey
  userName: string
}) {
  const pathname = usePathname()
  const roleDefinition = getRoleDefinition(role)
  const navigation = getNavigationForRole(role)

  return (
    <div className="min-h-screen bg-[radial-gradient(circle_at_top,rgba(201,161,59,0.14),transparent_28%),linear-gradient(180deg,#fafaf9_0%,#f7f6f4_100%)] text-[#1f1f1f]">
      <div className="min-h-screen">
        <header className="sticky top-0 z-30 border-b border-[#e9e4d9] bg-[rgba(250,250,249,0.86)] backdrop-blur-xl">
          <div className="mx-auto flex w-full max-w-[1440px] flex-col gap-4 px-4 py-4 lg:px-8">
            <div className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
              <div className="flex flex-col gap-3 xl:flex-row xl:items-center xl:gap-4">
                <Link href="/dashboard" className="inline-flex w-fit items-center rounded-full border border-[rgba(201,161,59,0.28)] bg-[rgba(201,161,59,0.12)] px-4 py-1.5 text-xs font-semibold uppercase tracking-[0.2em] text-[#8f6b18] shadow-[0_8px_22px_rgba(201,161,59,0.12)]">
                  CRM VeloPrime
                </Link>
                <div className="min-w-0">
                  <p className="text-xs uppercase tracking-[0.18em] text-[#9d7b27]">Panel operacyjny</p>
                  <div className="mt-2">
                    <span className="inline-flex rounded-full border border-[#ebe5d8] bg-white px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#6b6b6b] shadow-[0_8px_24px_rgba(31,31,31,0.04)]">
                      {roleDefinition.label}
                    </span>
                  </div>
                </div>
              </div>

              <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
                <button type="button" className="inline-flex h-12 w-12 items-center justify-center rounded-2xl border border-[#ebe5d8] bg-white text-[#4d4d4d] shadow-[0_10px_30px_rgba(31,31,31,0.04)] transition hover:border-[rgba(201,161,59,0.28)] hover:text-[#8f6b18]">
                  <Bell className="h-4 w-4" />
                </button>
                <Link href="/logout" className="inline-flex h-12 items-center justify-center gap-2 rounded-2xl border border-[#ebe5d8] bg-white px-4 text-sm font-medium text-[#4d4d4d] shadow-[0_10px_30px_rgba(31,31,31,0.04)] transition hover:border-[rgba(201,161,59,0.28)] hover:text-[#8f6b18]">
                  <LogOut className="h-4 w-4" />
                  <span>Wyloguj</span>
                </Link>
              </div>
            </div>

            <nav className="flex flex-wrap gap-2">
              {navigation.map((item) => {
                const isActive = pathname === item.href || pathname.startsWith(`${item.href}/`)
                const Icon = item.icon

                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={[
                      'inline-flex items-center gap-2 rounded-2xl border px-4 py-2.5 text-sm font-medium shadow-[0_10px_24px_rgba(31,31,31,0.03)] transition',
                      isActive
                        ? 'border-[rgba(201,161,59,0.34)] bg-[#c9a13b] text-white shadow-[0_16px_32px_rgba(201,161,59,0.22)]'
                        : 'border-[#ebe5d8] bg-white text-[#6b6b6b] hover:border-[rgba(201,161,59,0.24)] hover:text-[#1f1f1f]',
                    ].join(' ')}
                  >
                    <Icon className="h-4 w-4" />
                    <span>{item.label}</span>
                  </Link>
                )
              })}
            </nav>
          </div>
        </header>

        <div className="mx-auto min-w-0 max-w-[1720px] px-4 py-6 lg:px-8 lg:py-8">
          <div>{children}</div>
        </div>
      </div>
    </div>
  )
}