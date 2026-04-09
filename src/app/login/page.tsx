import Link from 'next/link'
import { redirect } from 'next/navigation'

import { getDemoUsers, getSession } from '@/lib/auth'
import { hasDatabaseUrl } from '@/lib/db'

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>
}) {
  const session = await getSession()
  if (session) {
    redirect('/dashboard')
  }

  const { error } = await searchParams
  const demoUsers = getDemoUsers()
  const usesDatabaseAuth = hasDatabaseUrl()

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,rgba(201,161,59,0.14),transparent_28%),linear-gradient(180deg,#fafaf9_0%,#f7f6f4_100%)]">
      <div className="mx-auto flex min-h-screen w-full max-w-6xl items-center px-6 py-10 lg:px-10">
      <div className="grid w-full gap-8 lg:grid-cols-[1.05fr_0.95fr]">
        <section className="rounded-[32px] border border-[#e8e2d3] bg-[linear-gradient(135deg,#ffffff_0%,#fbf8f1_52%,#f7f3e8_100%)] p-8 shadow-[0_24px_70px_rgba(31,31,31,0.06)] lg:p-10">
          <div className="inline-flex rounded-full border border-[rgba(201,161,59,0.28)] bg-[rgba(201,161,59,0.12)] px-4 py-1.5 text-xs font-semibold uppercase tracking-[0.2em] text-[#8f6b18]">
            Logowanie CRM
          </div>
          <h1 className="mt-5 max-w-[12ch] text-4xl font-semibold leading-tight text-[#1f1f1f] lg:text-5xl">
            Panel sprzedażowy dla zespołu VeloPrime.
          </h1>
          <p className="mt-5 max-w-xl text-base leading-7 text-[#5f5a4f]">
            {usesDatabaseAuth
              ? 'Logowanie korzysta z kont użytkowników zapisanych w bazie. Konta startowe mogą zostać później przejęte przez administratora i mieć zmienione hasła.'
              : 'Logowanie działa w trybie awaryjnym bez bazy danych. Dostępne są konta startowe do testów lokalnych.'}
          </p>

          <div className="mt-8 grid gap-4 sm:grid-cols-2">
            <div className="rounded-[24px] border border-[#ece6d9] bg-white/90 p-5 shadow-[0_16px_34px_rgba(31,31,31,0.04)]">
              <div className="text-sm font-semibold text-[#1f1f1f]">Administrator</div>
              <p className="mt-2 text-sm leading-6 text-[#6b6b6b]">Tworzy konta, role, flotę, cenniki i konfiguracje systemowe.</p>
            </div>
            <div className="rounded-[24px] border border-[#ece6d9] bg-white/90 p-5 shadow-[0_16px_34px_rgba(31,31,31,0.04)]">
              <div className="text-sm font-semibold text-[#1f1f1f]">Sprzedaż</div>
              <p className="mt-2 text-sm leading-6 text-[#6b6b6b]">Pracuje na leadach, klientach i przygotowuje oferty online dla klientów.</p>
            </div>
          </div>

          <div className="mt-8 rounded-[24px] border border-[#ece6d9] bg-white/90 p-5 shadow-[0_16px_34px_rgba(31,31,31,0.04)]">
            <div className="text-sm font-semibold text-[#1f1f1f]">
              {usesDatabaseAuth ? 'Konta startowe systemu' : 'Konta demo do testów'}
            </div>
            <div className="mt-4 grid gap-3">
              {demoUsers.map((user) => (
                <div key={user.email} className="rounded-2xl border border-[#ece6d9] bg-[#fcfbf8] px-4 py-3 text-sm text-[#666666]">
                  <div className="font-medium text-[#1f1f1f]">{user.fullName}</div>
                  <div className="mt-1">{user.email}</div>
                  <div className="mt-1 text-[#8f6b18]">
                    {usesDatabaseAuth
                      ? 'Hasło początkowe z wdrożenia lub ostatniego resetu administracyjnego.'
                      : `Hasło: ${user.role === 'ADMIN' ? 'Adrian05' : user.role === 'DIRECTOR' ? 'Director123!' : user.role === 'MANAGER' ? 'Manager123!' : 'Sales123!'}`}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="rounded-[32px] border border-[#e8e2d3] bg-white p-8 shadow-[0_24px_70px_rgba(31,31,31,0.06)] lg:p-10">
          <form action="/api/auth/login" method="post" className="space-y-5">
            <label className="block">
              <span className="text-sm font-medium text-[#2f2a22]">Email</span>
              <input name="email" className="mt-2 h-12 w-full rounded-2xl border border-[#e6dfd2] bg-[#fcfbf8] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.42)] focus:bg-white" placeholder="Wpisz swój login" />
            </label>
            <label className="block">
              <span className="text-sm font-medium text-[#2f2a22]">Hasło</span>
              <input name="password" type="password" className="mt-2 h-12 w-full rounded-2xl border border-[#e6dfd2] bg-[#fcfbf8] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.42)] focus:bg-white" placeholder="••••••••" />
            </label>
            {error === 'credentials' ? (
              <div className="rounded-2xl border border-[#f1caca] bg-[#fff4f4] px-4 py-3 text-sm text-[#a14b4b]">
                Nieprawidłowy email lub hasło.
              </div>
            ) : null}

            <button type="submit" className="mt-6 inline-flex h-12 w-full items-center justify-center rounded-2xl border border-[rgba(201,161,59,0.3)] bg-[#c9a13b] px-5 text-sm font-semibold text-white shadow-[0_16px_32px_rgba(201,161,59,0.22)] transition hover:bg-[#b8932f]">
              Zaloguj do panelu
            </button>

            <div className="mt-6 rounded-[24px] border border-[#ece6d9] bg-[#fcfbf8] p-5 text-sm leading-6 text-[#6b6b6b]">
              {usesDatabaseAuth
                ? 'Uprawnienia i hasła są obsługiwane przez centralną bazę użytkowników. Bez bazy aplikacja przełącza się na tryb awaryjny z kontami startowymi.'
                : 'Tryb bez bazy służy tylko do lokalnego developmentu. Produkcyjnie logowanie powinno działać na użytkownikach zapisanych w bazie.'}
            </div>
          </form>

          <Link href="/dashboard" className="mt-5 inline-flex text-sm font-medium text-[#8f6b18] transition hover:text-[#1f1f1f]">
            Podejrzyj shell dashboardu
          </Link>
        </section>
      </div>
      </div>
    </main>
  )
}