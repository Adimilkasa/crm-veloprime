'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Bell, LogOut, Search } from 'lucide-react'

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
    <div className="min-h-screen bg-[linear-gradient(180deg,#0b0f14_0%,#10161d_100%)] text-white">
      <div className="min-h-screen">
        <header className="sticky top-0 z-30 border-b border-white/8 bg-[rgba(11,15,20,0.9)] backdrop-blur-xl">
          <div className="flex w-full flex-col gap-4 px-4 py-4 lg:px-6">
            <div className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
              <div className="flex flex-col gap-3 xl:flex-row xl:items-center xl:gap-4">
                <Link href="/dashboard" className="inline-flex w-fit items-center rounded-full border border-[rgba(216,180,90,0.25)] bg-[rgba(216,180,90,0.12)] px-4 py-1.5 text-xs font-semibold uppercase tracking-[0.2em] text-[#f3d998]">
                  CRM VeloPrime
                </Link>
                <div className="min-w-0">
                  <p className="text-xs uppercase tracking-[0.18em] text-[#f3d998]">Panel operacyjny</p>
                  <div className="mt-1 flex flex-wrap items-center gap-3">
                    <h1 className="text-xl font-semibold text-white lg:text-2xl">Zarządzanie sprzedażą i ofertami</h1>
                    <span className="inline-flex rounded-full border border-white/8 bg-white/[0.03] px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#aeb7c2]">
                      {roleDefinition.label}
                    </span>
                  </div>
                </div>
              </div>

              <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
                <div className="rounded-2xl border border-white/8 bg-white/[0.03] px-4 py-3 text-sm text-[#d5dce5]">
                  {userName}
                </div>
                <div className="flex items-center gap-2 rounded-2xl border border-white/8 bg-white/[0.03] px-4 py-3 text-sm text-[#aeb7c2]">
                  <Search className="h-4 w-4" />
                  <span>Wyszukaj klienta, VIN lub ofertę</span>
                </div>
                <button type="button" className="inline-flex h-12 w-12 items-center justify-center rounded-2xl border border-white/8 bg-white/[0.03] text-[#d5dce5] transition hover:bg-white/[0.08]">
                  <Bell className="h-4 w-4" />
                </button>
                <Link href="/logout" className="inline-flex h-12 items-center justify-center gap-2 rounded-2xl border border-white/8 bg-white/[0.03] px-4 text-sm font-medium text-[#d5dce5] transition hover:bg-white/[0.08]">
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
                      'inline-flex items-center gap-2 rounded-2xl border px-4 py-2.5 text-sm font-medium transition',
                      isActive
                        ? 'border-[rgba(216,180,90,0.28)] bg-[rgba(216,180,90,0.12)] text-white'
                        : 'border-white/6 bg-white/[0.03] text-[#aeb7c2] hover:border-white/12 hover:bg-white/[0.05] hover:text-white',
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

        <div className="min-w-0 px-4 py-4 lg:px-6 lg:py-5">
          <div>{children}</div>
        </div>
      </div>
    </div>
  )
}