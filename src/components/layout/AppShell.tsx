'use client'

import Link from 'next/link'
import { useEffect, useState } from 'react'
import { usePathname } from 'next/navigation'
import { Bell, Check, ChevronDown, LogOut, Palette } from 'lucide-react'

import { getNavigationForRole, getRoleDefinition, type UserRoleKey } from '@/lib/rbac'

const PRIMARY_NAV_HREFS = ['/dashboard', '/leads', '/customers']
const BACKGROUND_STORAGE_KEY = 'crm-veloprime-shell-background'
const BACKGROUND_PRESETS = [
  {
    key: 'signature',
    label: 'Signature',
    description: 'Domyślny wariant VeloPrime: jasny, ciepły i najbardziej premium.',
    shellBackground: 'radial-gradient(circle at top, rgba(212,168,79,0.1), transparent 24%), radial-gradient(circle at 12% 16%, rgba(255,249,238,0.92), transparent 18%), linear-gradient(180deg, #fcfcfa 0%, #f4f1eb 100%)',
    swatchBackground: 'linear-gradient(135deg, #f8f0de 0%, #e4c98d 100%)',
  },
  {
    key: 'studio',
    label: 'Studio',
    description: 'Chłodniejszy wariant do dłuższej pracy z danymi i ofertami.',
    shellBackground: 'radial-gradient(circle at top, rgba(145,155,170,0.08), transparent 24%), radial-gradient(circle at 86% 14%, rgba(240,243,247,0.84), transparent 18%), linear-gradient(180deg, #fbfcfd 0%, #eef1f4 100%)',
    swatchBackground: 'linear-gradient(135deg, #e6eaef 0%, #b0bbc8 100%)',
  },
] as const

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
  const navigation = getNavigationForRole(role).filter((item) => item.href !== '/colors')
  const [isMoreOpen, setMoreOpen] = useState(false)
  const [isThemeOpen, setThemeOpen] = useState(false)
  const [backgroundPresetKey, setBackgroundPresetKey] = useState<(typeof BACKGROUND_PRESETS)[number]['key']>(() => {
    if (typeof window === 'undefined') {
      return 'signature'
    }

    const storedPreset = window.localStorage.getItem(BACKGROUND_STORAGE_KEY)
    return BACKGROUND_PRESETS.some((preset) => preset.key === storedPreset)
      ? storedPreset as (typeof BACKGROUND_PRESETS)[number]['key']
      : 'signature'
  })
  const primaryNavigation = navigation.filter((item) => PRIMARY_NAV_HREFS.includes(item.href))
  const secondaryNavigation = navigation.filter((item) => !PRIMARY_NAV_HREFS.includes(item.href))
  const hasActiveSecondaryItem = secondaryNavigation.some((item) => pathname === item.href || pathname.startsWith(`${item.href}/`))
  const activeBackgroundPreset = BACKGROUND_PRESETS.find((preset) => preset.key === backgroundPresetKey) ?? BACKGROUND_PRESETS[0]

  useEffect(() => {
    const closeMenusTimer = window.setTimeout(() => {
      setMoreOpen(false)
      setThemeOpen(false)
    }, 0)

    return () => {
      window.clearTimeout(closeMenusTimer)
    }
  }, [pathname])

  useEffect(() => {
    window.localStorage.setItem(BACKGROUND_STORAGE_KEY, backgroundPresetKey)
  }, [backgroundPresetKey])

  return (
    <div className="min-h-screen text-[#111111] transition-[background] duration-300" style={{ background: activeBackgroundPreset.shellBackground }}>
      <div className="min-h-screen">
        <header className="crm-glass-nav sticky top-0 z-30 transition-colors duration-300">
          <div className="mx-auto flex w-full max-w-[1440px] flex-col gap-2.5 px-4 py-3 lg:px-8 xl:flex-row xl:items-center xl:justify-between">
            <Link href="/dashboard" className="crm-pill inline-flex h-8 w-fit shrink-0 items-center px-3.5 text-[11px] font-semibold uppercase tracking-[0.2em] text-[#8c6b22] shadow-[0_10px_24px_rgba(212,168,79,0.1)]">
              CRM VeloPrime
            </Link>

            <nav className="flex min-w-0 flex-wrap gap-2 xl:flex-1 xl:flex-nowrap xl:justify-center xl:overflow-x-auto xl:px-3">
              {primaryNavigation.map((item) => {
                  const isActive = pathname === item.href || pathname.startsWith(`${item.href}/`)
                  const Icon = item.icon

                  return (
                    <Link
                      key={item.href}
                      href={item.href}
                      className={[
                        'inline-flex h-9 shrink-0 items-center gap-2 rounded-[16px] px-3 text-[13px] font-medium transition',
                        isActive
                          ? 'crm-button-primary'
                          : 'crm-button-secondary text-[#575247]',
                      ].join(' ')}
                    >
                        <Icon className={[
                          'h-3.5 w-3.5 transition',
                          isActive ? 'text-[#181512]' : 'text-[#8a857a]',
                        ].join(' ')} />
                      <span>{item.label}</span>
                    </Link>
                  )
                })}

                {secondaryNavigation.length > 0 ? (
                  <div className="relative shrink-0">
                    <button
                      type="button"
                      onClick={() => setMoreOpen((current) => !current)}
                      className={[
                        'inline-flex h-9 items-center gap-2 rounded-[16px] px-3 text-[13px] font-medium transition',
                        hasActiveSecondaryItem || isMoreOpen
                          ? 'crm-button-primary'
                          : 'crm-button-secondary text-[#575247]',
                      ].join(' ')}
                    >
                      <span>Więcej</span>
                      <ChevronDown className={[
                        'h-3.5 w-3.5 transition-transform',
                        isMoreOpen ? 'rotate-180' : '',
                      ].join(' ')} />
                    </button>

                    {isMoreOpen ? (
                      <div className="crm-overlay absolute right-0 top-[calc(100%+10px)] z-40 w-[280px] rounded-[22px] p-3">
                        <div className="crm-card rounded-[18px] px-3.5 py-3">
                          <div className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#8c6715]">Sekcje dodatkowe</div>
                          <div className="mt-1 text-[13px] leading-5 text-[#5f5a4f]">Rzadziej używane moduły dostępne z jednego miejsca.</div>
                        </div>

                        <div className="mt-3 grid gap-2">
                          {secondaryNavigation.map((item) => {
                            const isActive = pathname === item.href || pathname.startsWith(`${item.href}/`)
                            const Icon = item.icon

                            return (
                              <Link
                                key={item.href}
                                href={item.href}
                                className={[
                                  'flex items-center justify-between gap-3 rounded-[16px] px-3.5 py-3 transition',
                                  isActive
                                    ? 'crm-button-primary text-[#181512]'
                                    : 'crm-card text-[#5f5a4f] hover:text-[#1f1f1f]',
                                ].join(' ')}
                              >
                                <div className="flex min-w-0 items-center gap-3">
                                  <span className="crm-pill inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-[14px] bg-[rgba(255,255,255,0.74)]">
                                    <Icon className={['h-4 w-4', isActive ? 'text-[#181512]' : 'text-[#8a857a]'].join(' ')} />
                                  </span>
                                  <span className="truncate text-[13px] font-medium">{item.label}</span>
                                </div>
                                <span className="text-[11px] uppercase tracking-[0.16em] text-[#8a826f]">Wejdź</span>
                              </Link>
                            )
                          })}
                        </div>
                      </div>
                    ) : null}
                  </div>
                ) : null}
            </nav>

            <div className="relative flex shrink-0 flex-wrap gap-2 sm:items-center sm:justify-end">
              <span className="crm-pill hidden px-3 py-1 text-[11px] uppercase tracking-[0.16em] text-[#746e62] shadow-[0_8px_24px_rgba(31,31,31,0.03)] lg:inline-flex">
                {userName}
              </span>
              <span className={[
                'inline-flex h-7 items-center rounded-full px-3 text-[11px] uppercase tracking-[0.16em] shadow-[0_8px_24px_rgba(31,31,31,0.03)]',
                'crm-pill text-[#6b6b6b]',
              ].join(' ')}>
                {roleDefinition.label}
              </span>
              <button
                type="button"
                onClick={() => setThemeOpen((current) => !current)}
                className={[
                  'inline-flex h-9 items-center justify-center gap-2 rounded-[16px] px-3 text-[13px] font-medium transition',
                  isThemeOpen
                    ? 'crm-button-primary text-[#181512]'
                    : 'crm-button-secondary text-[#4d4d4d] hover:text-[#1f1f1f]',
                ].join(' ')}
              >
                <Palette className="h-4 w-4 text-[#8a857a]" />
                <span className="hidden md:inline">Tło</span>
              </button>
              <button type="button" className="crm-button-icon inline-flex h-9 w-9 items-center justify-center rounded-[16px] text-[#4d4d4d] hover:text-[#1f1f1f]">
                <Bell className="h-4 w-4" />
              </button>
              <form action="/logout" method="post">
                <button type="submit" className="crm-button-secondary inline-flex h-9 items-center justify-center gap-2 rounded-[16px] px-3 text-[13px] font-medium text-[#4d4d4d] hover:text-[#1f1f1f]">
                  <LogOut className="h-3.5 w-3.5" />
                  <span className="hidden sm:inline">Wyloguj</span>
                </button>
              </form>

              {isThemeOpen ? (
                <div className="crm-overlay absolute right-0 top-[calc(100%+10px)] z-40 w-[320px] rounded-[22px] p-3">
                  <div className="crm-card rounded-[18px] px-3.5 py-3">
                    <div className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#8c6715]">Tło aplikacji</div>
                    <div className="mt-1 text-[13px] leading-5 text-[#5f5a4f]">Dwa dopracowane warianty utrzymują spójny charakter marki. Ustawienie zapisuje się lokalnie w przeglądarce.</div>
                  </div>

                  <div className="mt-3 grid gap-2">
                    {BACKGROUND_PRESETS.map((preset) => {
                      const isActive = preset.key === backgroundPresetKey

                      return (
                        <button
                          key={preset.key}
                          type="button"
                          onClick={() => {
                            setBackgroundPresetKey(preset.key)
                            setThemeOpen(false)
                          }}
                          className={[
                            'flex items-center justify-between gap-3 rounded-[16px] px-3.5 py-3 text-left transition',
                            isActive
                              ? 'crm-button-primary'
                              : 'crm-card',
                          ].join(' ')}
                        >
                          <div className="flex min-w-0 items-center gap-3">
                            <span className="inline-flex h-10 w-10 shrink-0 rounded-[14px] border border-[#ece4d7]" style={{ background: preset.swatchBackground }} />
                            <div className="min-w-0">
                              <div className="truncate text-[13px] font-medium text-[#1f1f1f]">{preset.label}</div>
                              <div className="mt-0.5 text-xs leading-5 text-[#6b6b6b]">{preset.description}</div>
                            </div>
                          </div>
                          <span className={[
                            'inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full border',
                            isActive ? 'border-[#d9c288] bg-white text-[#8f6b18]' : 'border-[rgba(0,0,0,0.04)] bg-[rgba(255,255,255,0.74)] text-transparent',
                          ].join(' ')}>
                            <Check className="h-3.5 w-3.5" />
                          </span>
                        </button>
                      )
                    })}
                  </div>
                </div>
              ) : null}
            </div>
          </div>
        </header>

        <div className="mx-auto min-w-0 max-w-[1720px] px-4 py-6 lg:px-8 lg:py-7">
          <div>{children}</div>
        </div>
      </div>
    </div>
  )
}