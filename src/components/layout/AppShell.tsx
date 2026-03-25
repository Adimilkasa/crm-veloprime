'use client'

import Link from 'next/link'
import { useEffect, useState } from 'react'
import { usePathname } from 'next/navigation'
import { Bell, Check, ChevronDown, LogOut, Palette } from 'lucide-react'

import { getNavigationForRole, getRoleDefinition, type UserRoleKey } from '@/lib/rbac'

const PRIMARY_NAV_HREFS = ['/dashboard', '/leads', '/customers', '/offers']
const BACKGROUND_STORAGE_KEY = 'crm-veloprime-shell-background'
const BACKGROUND_PRESETS = [
  {
    key: 'sand',
    label: 'Piaskowe',
    description: 'Ciepły, domyślny wariant VeloPrime.',
    shellBackground: 'radial-gradient(circle at top, rgba(201,161,59,0.16), transparent 26%), radial-gradient(circle at 12% 18%, rgba(255,244,214,0.7), transparent 22%), linear-gradient(180deg, #fbfaf6 0%, #f4f0e8 100%)',
    swatchBackground: 'linear-gradient(135deg, #f6eedc 0%, #e7d1a0 100%)',
  },
  {
    key: 'ocean',
    label: 'Ocean',
    description: 'Chłodny, bardziej technologiczny klimat.',
    shellBackground: 'radial-gradient(circle at top, rgba(74,144,226,0.2), transparent 28%), radial-gradient(circle at 88% 14%, rgba(146,208,255,0.5), transparent 20%), linear-gradient(180deg, #f6fbff 0%, #e8f2fb 100%)',
    swatchBackground: 'linear-gradient(135deg, #d7ecff 0%, #78b3ea 100%)',
  },
  {
    key: 'sage',
    label: 'Szałwia',
    description: 'Spokojny, lekko zielony wariant do codziennej pracy.',
    shellBackground: 'radial-gradient(circle at top, rgba(31,143,106,0.18), transparent 28%), radial-gradient(circle at 18% 16%, rgba(208,240,223,0.65), transparent 22%), linear-gradient(180deg, #f6fbf8 0%, #e7f1ea 100%)',
    swatchBackground: 'linear-gradient(135deg, #d6ecde 0%, #7fbb9c 100%)',
  },
  {
    key: 'sunset',
    label: 'Zachód',
    description: 'Wyraźniejszy, bursztynowo-miedziany akcent.',
    shellBackground: 'radial-gradient(circle at top, rgba(192,86,33,0.2), transparent 30%), radial-gradient(circle at 82% 12%, rgba(255,204,168,0.52), transparent 18%), linear-gradient(180deg, #fcf7f2 0%, #f3e5da 100%)',
    swatchBackground: 'linear-gradient(135deg, #f8dcc7 0%, #cf7e55 100%)',
  },
  {
    key: 'lavender',
    label: 'Lawenda',
    description: 'Jaśniejszy wariant z chłodnym fioletem.',
    shellBackground: 'radial-gradient(circle at top, rgba(124,92,255,0.18), transparent 28%), radial-gradient(circle at 14% 20%, rgba(222,212,255,0.6), transparent 22%), linear-gradient(180deg, #fbfaff 0%, #eee9fb 100%)',
    swatchBackground: 'linear-gradient(135deg, #e7defb 0%, #9b84eb 100%)',
  },
  {
    key: 'stone',
    label: 'Szare',
    description: 'Neutralne, spokojne tło do dłuższej pracy.',
    shellBackground: 'radial-gradient(circle at top, rgba(120,128,140,0.16), transparent 28%), radial-gradient(circle at 86% 16%, rgba(228,232,238,0.65), transparent 20%), linear-gradient(180deg, #f5f6f8 0%, #e5e9ef 100%)',
    swatchBackground: 'linear-gradient(135deg, #dde1e7 0%, #95a0ae 100%)',
  },
] as const

function getNavIconClassName(href: string) {
  switch (href) {
    case '/dashboard':
      return 'text-[#4a90e2]'
    case '/leads':
      return 'text-[#b7791f]'
    case '/customers':
      return 'text-[#1f8f6a]'
    case '/vehicles':
      return 'text-[#c05621]'
    case '/offers':
      return 'text-[#8f6b18]'
    case '/commissions':
      return 'text-[#7c5cff]'
    case '/users':
      return 'text-[#c53030]'
    case '/pricing':
      return 'text-[#2b6cb0]'
    default:
      return 'text-[#8a826f]'
  }
}

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
  const [backgroundPresetKey, setBackgroundPresetKey] = useState<(typeof BACKGROUND_PRESETS)[number]['key']>('sand')
  const primaryNavigation = navigation.filter((item) => PRIMARY_NAV_HREFS.includes(item.href))
  const secondaryNavigation = navigation.filter((item) => !PRIMARY_NAV_HREFS.includes(item.href))
  const hasActiveSecondaryItem = secondaryNavigation.some((item) => pathname === item.href || pathname.startsWith(`${item.href}/`))
  const activeBackgroundPreset = BACKGROUND_PRESETS.find((preset) => preset.key === backgroundPresetKey) ?? BACKGROUND_PRESETS[0]

  useEffect(() => {
    setMoreOpen(false)
    setThemeOpen(false)
  }, [pathname])

  useEffect(() => {
    const storedPreset = window.localStorage.getItem(BACKGROUND_STORAGE_KEY)

    if (storedPreset && BACKGROUND_PRESETS.some((preset) => preset.key === storedPreset)) {
      setBackgroundPresetKey(storedPreset as (typeof BACKGROUND_PRESETS)[number]['key'])
    }
  }, [])

  useEffect(() => {
    window.localStorage.setItem(BACKGROUND_STORAGE_KEY, backgroundPresetKey)
  }, [backgroundPresetKey])

  return (
    <div className="min-h-screen text-[#1f1f1f] transition-[background] duration-300" style={{ background: activeBackgroundPreset.shellBackground }}>
      <div className="min-h-screen">
        <header className="sticky top-0 z-30 border-b border-[#e9e4d9] bg-[rgba(250,250,249,0.86)] backdrop-blur-xl transition-colors duration-300">
          <div className="mx-auto flex w-full max-w-[1440px] flex-col gap-2 px-4 py-2.5 lg:px-8 lg:py-2.5 xl:flex-row xl:items-center xl:justify-between">
            <Link href="/dashboard" className="inline-flex h-8 w-fit shrink-0 items-center rounded-full border border-[rgba(201,161,59,0.28)] bg-[rgba(201,161,59,0.12)] px-3.5 text-[11px] font-semibold uppercase tracking-[0.2em] text-[#8f6b18] shadow-[0_8px_22px_rgba(201,161,59,0.12)]">
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
                        'inline-flex h-9 shrink-0 items-center gap-2 rounded-[16px] border px-3 text-[13px] font-medium shadow-[0_10px_24px_rgba(31,31,31,0.03)] transition',
                        isActive
                          ? 'border-[rgba(201,161,59,0.34)] bg-[#c9a13b] text-white shadow-[0_16px_32px_rgba(201,161,59,0.22)]'
                          : 'border-[#ebe5d8] bg-white text-[#6b6b6b] hover:border-[rgba(201,161,59,0.24)] hover:text-[#1f1f1f]',
                      ].join(' ')}
                    >
                        <Icon className={[
                          'h-3.5 w-3.5 transition',
                          isActive ? 'text-white' : getNavIconClassName(item.href),
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
                        'inline-flex h-9 items-center gap-2 rounded-[16px] border px-3 text-[13px] font-medium shadow-[0_10px_24px_rgba(31,31,31,0.03)] transition',
                        hasActiveSecondaryItem || isMoreOpen
                          ? 'border-[rgba(201,161,59,0.34)] bg-[#c9a13b] text-white shadow-[0_16px_32px_rgba(201,161,59,0.22)]'
                          : 'border-[#ebe5d8] bg-white text-[#6b6b6b] hover:border-[rgba(201,161,59,0.24)] hover:text-[#1f1f1f]',
                      ].join(' ')}
                    >
                      <span>Więcej</span>
                      <ChevronDown className={[
                        'h-3.5 w-3.5 transition-transform',
                        isMoreOpen ? 'rotate-180' : '',
                      ].join(' ')} />
                    </button>

                    {isMoreOpen ? (
                      <div className="absolute right-0 top-[calc(100%+10px)] z-40 w-[280px] rounded-[22px] border border-[#e8e1d4] bg-[linear-gradient(180deg,rgba(255,255,255,0.98)_0%,rgba(250,247,241,0.98)_100%)] p-3 shadow-[0_22px_48px_rgba(31,31,31,0.12)] backdrop-blur-xl">
                        <div className="rounded-[18px] border border-[#ece4d7] bg-[linear-gradient(135deg,#fffdfa_0%,#f7f0e2_100%)] px-3.5 py-3">
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
                                  'flex items-center justify-between gap-3 rounded-[16px] border px-3.5 py-3 transition',
                                  isActive
                                    ? 'border-[#ead7a7] bg-[linear-gradient(135deg,#fff8e8_0%,#f8ecd0_100%)] text-[#1f1f1f] shadow-[0_10px_24px_rgba(201,161,59,0.12)]'
                                    : 'border-[#ece4d7] bg-white/90 text-[#5f5a4f] hover:border-[#e1d3b2] hover:bg-[#fffdfa] hover:text-[#1f1f1f]',
                                ].join(' ')}
                              >
                                <div className="flex min-w-0 items-center gap-3">
                                  <span className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-[14px] border border-[#ece4d7] bg-[#fcfbf8]">
                                    <Icon className={['h-4 w-4', getNavIconClassName(item.href)].join(' ')} />
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
              <span className={[
                'inline-flex h-7 items-center rounded-full px-3 text-[11px] uppercase tracking-[0.16em] shadow-[0_8px_24px_rgba(31,31,31,0.04)]',
                'border border-[#ebe5d8] bg-white text-[#6b6b6b]',
              ].join(' ')}>
                {roleDefinition.label}
              </span>
              <button
                type="button"
                onClick={() => setThemeOpen((current) => !current)}
                className={[
                  'inline-flex h-9 items-center justify-center gap-2 rounded-[16px] border bg-white px-3 text-[13px] font-medium shadow-[0_10px_30px_rgba(31,31,31,0.04)] transition',
                  isThemeOpen
                    ? 'border-[rgba(201,161,59,0.34)] text-[#8f6b18]'
                    : 'border-[#ebe5d8] text-[#4d4d4d] hover:border-[rgba(201,161,59,0.28)] hover:text-[#8f6b18]',
                ].join(' ')}
              >
                <Palette className="h-4 w-4 text-[#8f6b18]" />
                <span className="hidden md:inline">Tło</span>
              </button>
              <button type="button" className="inline-flex h-9 w-9 items-center justify-center rounded-[16px] border border-[#ebe5d8] bg-white text-[#4d4d4d] shadow-[0_10px_30px_rgba(31,31,31,0.04)] transition hover:border-[rgba(201,161,59,0.28)] hover:text-[#8f6b18]">
                <Bell className="h-4 w-4" />
              </button>
              <Link href="/logout" className="inline-flex h-9 items-center justify-center gap-2 rounded-[16px] border border-[#ebe5d8] bg-white px-3 text-[13px] font-medium text-[#4d4d4d] shadow-[0_10px_30px_rgba(31,31,31,0.04)] transition hover:border-[rgba(201,161,59,0.28)] hover:text-[#8f6b18]">
                <LogOut className="h-3.5 w-3.5" />
                <span className="hidden sm:inline">Wyloguj</span>
              </Link>

              {isThemeOpen ? (
                <div className="absolute right-0 top-[calc(100%+10px)] z-40 w-[320px] rounded-[22px] border border-[#e8e1d4] bg-[linear-gradient(180deg,rgba(255,255,255,0.98)_0%,rgba(250,247,241,0.98)_100%)] p-3 shadow-[0_22px_48px_rgba(31,31,31,0.12)] backdrop-blur-xl">
                  <div className="rounded-[18px] border border-[#ece4d7] bg-[linear-gradient(135deg,#fffdfa_0%,#f7f0e2_100%)] px-3.5 py-3">
                    <div className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#8c6715]">Tło aplikacji</div>
                    <div className="mt-1 text-[13px] leading-5 text-[#5f5a4f]">Każdy użytkownik może dobrać własny wariant wizualny. Ustawienie zapisuje się lokalnie w przeglądarce.</div>
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
                            'flex items-center justify-between gap-3 rounded-[16px] border px-3.5 py-3 text-left transition',
                            isActive
                              ? 'border-[#ead7a7] bg-[linear-gradient(135deg,#fff8e8_0%,#f8ecd0_100%)] shadow-[0_10px_24px_rgba(201,161,59,0.12)]'
                              : 'border-[#ece4d7] bg-white/90 hover:border-[#e1d3b2] hover:bg-[#fffdfa]',
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
                            isActive ? 'border-[#d9c288] bg-white text-[#8f6b18]' : 'border-[#e7dfd0] bg-[#fcfbf8] text-transparent',
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

        <div className="mx-auto min-w-0 max-w-[1720px] px-4 py-5 lg:px-8 lg:py-6">
          <div>{children}</div>
        </div>
      </div>
    </div>
  )
}