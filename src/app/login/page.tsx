import Link from 'next/link'
import { redirect } from 'next/navigation'

import { getDemoUsers, getSession } from '@/lib/auth'
import { loginAction } from '@/app/login/actions'

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

  return (
    <main className="mx-auto flex min-h-screen w-full max-w-6xl items-center px-6 py-10 lg:px-10">
      <div className="grid w-full gap-8 lg:grid-cols-[1.05fr_0.95fr]">
        <section className="rounded-[32px] border border-white/8 bg-[rgba(18,24,33,0.82)] p-8 shadow-[0_28px_70px_rgba(0,0,0,0.2)] lg:p-10">
          <div className="inline-flex rounded-full border border-[rgba(216,180,90,0.35)] bg-[rgba(216,180,90,0.12)] px-4 py-1.5 text-xs font-semibold uppercase tracking-[0.2em] text-[#f3d998]">
            Logowanie CRM
          </div>
          <h1 className="mt-5 max-w-[12ch] text-4xl font-semibold leading-tight text-white lg:text-5xl">
            Panel sprzedażowy dla zespołu VeloPrime.
          </h1>
          <p className="mt-5 max-w-xl text-base leading-7 text-[#aeb7c2]">
            To jest pierwszy działający etap logowania. Uwierzytelnianie działa na demo kontach z rolami, a w następnym kroku podepniemy je do bazy użytkowników.
          </p>

          <div className="mt-8 grid gap-4 sm:grid-cols-2">
            <div className="rounded-[24px] border border-white/8 bg-white/[0.03] p-5">
              <div className="text-sm font-semibold text-white">Administrator</div>
              <p className="mt-2 text-sm leading-6 text-[#9ba6b2]">Tworzy konta, role, flotę, cenniki i konfiguracje systemowe.</p>
            </div>
            <div className="rounded-[24px] border border-white/8 bg-white/[0.03] p-5">
              <div className="text-sm font-semibold text-white">Sprzedaż</div>
              <p className="mt-2 text-sm leading-6 text-[#9ba6b2]">Pracuje na leadach, klientach i generuje oferty PDF dla klientów.</p>
            </div>
          </div>

          <div className="mt-8 rounded-[24px] border border-white/8 bg-white/[0.03] p-5">
            <div className="text-sm font-semibold text-white">Konta demo do testów</div>
            <div className="mt-4 grid gap-3">
              {demoUsers.map((user) => (
                <div key={user.email} className="rounded-2xl border border-white/8 bg-[rgba(255,255,255,0.03)] px-4 py-3 text-sm text-[#c2cad4]">
                  <div className="font-medium text-white">{user.fullName}</div>
                  <div className="mt-1">{user.email}</div>
                  <div className="mt-1 text-[#f3d998]">Hasło: {user.role === 'ADMIN' ? 'Admin123!' : user.role === 'DIRECTOR' ? 'Director123!' : user.role === 'MANAGER' ? 'Manager123!' : 'Sales123!'}</div>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="rounded-[32px] border border-white/8 bg-[rgba(18,24,33,0.82)] p-8 shadow-[0_28px_70px_rgba(0,0,0,0.2)] lg:p-10">
          <form action={loginAction} className="space-y-5">
            <label className="block">
              <span className="text-sm font-medium text-white">Email</span>
              <input name="email" className="mt-2 h-12 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="handlowiec@veloprime.pl" defaultValue="handlowiec@veloprime.pl" />
            </label>
            <label className="block">
              <span className="text-sm font-medium text-white">Hasło</span>
              <input name="password" type="password" className="mt-2 h-12 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="••••••••" defaultValue="Sales123!" />
            </label>
            {error === 'credentials' ? (
              <div className="rounded-2xl border border-red-400/20 bg-red-500/10 px-4 py-3 text-sm text-red-200">
                Nieprawidłowy email lub hasło.
              </div>
            ) : null}

            <button type="submit" className="mt-6 inline-flex h-12 w-full items-center justify-center rounded-2xl border border-[rgba(216,180,90,0.4)] bg-[linear-gradient(135deg,#d8b45a,#b98b1d)] px-5 text-sm font-semibold text-[#111827] shadow-[0_18px_32px_rgba(185,139,29,0.24)] transition hover:brightness-105">
              Zaloguj do panelu
            </button>

            <div className="mt-6 rounded-[24px] border border-white/8 bg-white/[0.03] p-5 text-sm leading-6 text-[#9ba6b2]">
              Logowanie korzysta z demo kont. Kolejny etap to podpięcie użytkowników z bazy i prawdziwych uprawnień.
            </div>
          </form>

          <Link href="/dashboard" className="mt-5 inline-flex text-sm font-medium text-[#f3d998] transition hover:text-white">
            Podejrzyj shell dashboardu
          </Link>
        </section>
      </div>
    </main>
  )
}