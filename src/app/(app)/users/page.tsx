import { redirect } from 'next/navigation'

import { getSession } from '@/lib/auth'
import { roleDefinitions } from '@/lib/rbac'
import { listManagedUsers } from '@/lib/user-management'
import { createUserAction, toggleUserStatusAction } from '@/app/(app)/users/actions'

function formatDate(value: string) {
  return new Intl.DateTimeFormat('pl-PL', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

export default async function UsersPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string; success?: string }>
}) {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  if (session.role !== 'ADMIN') {
    redirect('/dashboard')
  }

  const users = await listManagedUsers()
  const { error, success } = await searchParams
  const usersById = new Map(users.map((user) => [user.id, user]))
  const supervisorOptions = users.filter((user) => user.isActive && (user.role === 'DIRECTOR' || user.role === 'MANAGER'))

  return (
    <main className="grid gap-6">
      <section className="grid gap-6 xl:grid-cols-[1.1fr_0.9fr]">
        <article className="rounded-[32px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-6 shadow-[0_18px_48px_rgba(0,0,0,0.16)]">
          <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Administracja kontami</div>
          <h2 className="mt-3 text-2xl font-semibold text-white">Użytkownicy i uprawnienia</h2>
          <p className="mt-3 max-w-2xl text-sm leading-6 text-[#aeb7c2]">
            To jest pierwszy moduł administracyjny CRM. Administrator może tworzyć konta foundation, przypisywać role oraz czasowo blokować dostęp użytkownikom.
          </p>

          <div className="mt-5 grid gap-4 md:grid-cols-3">
            <div className="rounded-2xl border border-white/8 bg-white/[0.03] p-4">
              <div className="text-sm text-[#9ba6b2]">Wszystkie konta</div>
              <div className="mt-2 text-3xl font-semibold text-white">{users.length}</div>
            </div>
            <div className="rounded-2xl border border-white/8 bg-white/[0.03] p-4">
              <div className="text-sm text-[#9ba6b2]">Aktywne</div>
              <div className="mt-2 text-3xl font-semibold text-white">{users.filter((user) => user.isActive).length}</div>
            </div>
            <div className="rounded-2xl border border-white/8 bg-white/[0.03] p-4">
              <div className="text-sm text-[#9ba6b2]">Role systemowe</div>
              <div className="mt-2 text-3xl font-semibold text-white">{roleDefinitions.length}</div>
            </div>
          </div>
        </article>

        <article className="rounded-[32px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-6 shadow-[0_18px_48px_rgba(0,0,0,0.16)]">
          <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Nowe konto</div>
          <h2 className="mt-3 text-xl font-semibold text-white">Dodaj użytkownika</h2>

          <form action={createUserAction} className="mt-5 grid gap-4">
            <label className="block">
              <span className="text-sm font-medium text-white">Imię i nazwisko</span>
              <input name="fullName" className="mt-2 h-12 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Jan Kowalski" />
            </label>

            <label className="block">
              <span className="text-sm font-medium text-white">Email</span>
              <input name="email" className="mt-2 h-12 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="jan@veloprime.pl" />
            </label>

            <label className="block">
              <span className="text-sm font-medium text-white">Rola</span>
              <select name="role" className="mt-2 h-12 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                {roleDefinitions.map((role) => (
                  <option key={role.key} value={role.key}>
                    {role.label}
                  </option>
                ))}
              </select>
            </label>

            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-white">Region</span>
                <input name="region" className="mt-2 h-12 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Warszawa" />
              </label>

              <label className="block">
                <span className="text-sm font-medium text-white">Zespół</span>
                <input name="teamName" className="mt-2 h-12 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Polnoc" />
              </label>
            </div>

            <label className="block">
              <span className="text-sm font-medium text-white">Bezpośredni przełożony</span>
              <select name="reportsToUserId" className="mt-2 h-12 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                <option value="">Brak przypisania</option>
                {supervisorOptions.map((user) => (
                  <option key={user.id} value={user.id}>
                    {user.fullName} ({roleDefinitions.find((role) => role.key === user.role)?.label ?? user.role})
                  </option>
                ))}
              </select>
              <p className="mt-2 text-xs leading-5 text-[#7f8a97]">
                Manager powinien wskazywać dyrektora. Handlowiec powinien wskazywać managera albo bezpośrednio dyrektora.
              </p>
            </label>

            <button type="submit" className="inline-flex h-12 items-center justify-center rounded-2xl border border-[rgba(216,180,90,0.4)] bg-[linear-gradient(135deg,#d8b45a,#b98b1d)] px-5 text-sm font-semibold text-[#111827] shadow-[0_18px_32px_rgba(185,139,29,0.24)] transition hover:brightness-105">
              Utwórz konto
            </button>
          </form>

          {error ? (
            <div className="mt-4 rounded-2xl border border-red-400/20 bg-red-500/10 px-4 py-3 text-sm text-red-200">{error}</div>
          ) : null}
          {success ? (
            <div className="mt-4 rounded-2xl border border-emerald-400/20 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-200">
              {success === 'created' ? 'Nowe konto zostało dodane.' : 'Status użytkownika został zmieniony.'}
            </div>
          ) : null}
        </article>
      </section>

      <section className="rounded-[32px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-6 shadow-[0_18px_48px_rgba(0,0,0,0.16)]">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Lista kont</div>
            <h2 className="mt-2 text-2xl font-semibold text-white">Użytkownicy systemu</h2>
          </div>
          <p className="max-w-xl text-sm leading-6 text-[#9ba6b2]">
            Konta oznaczone jako `seed` pochodzą z demo auth. Konta `custom` są dodawane przez administratora w ramach foundation i utrzymywane w pamięci aplikacji.
          </p>
        </div>

        <div className="mt-6 overflow-hidden rounded-[24px] border border-white/8">
          <div className="hidden grid-cols-[1.2fr_1.05fr_0.75fr_0.8fr_1fr_0.9fr_0.8fr] gap-4 border-b border-white/8 bg-white/[0.03] px-5 py-4 text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998] lg:grid">
            <span>Użytkownik</span>
            <span>Email</span>
            <span>Rola</span>
            <span>Region</span>
            <span>Struktura</span>
            <span>Status</span>
            <span>Akcja</span>
          </div>

          <div className="grid">
            {users.map((user) => (
              <div key={user.id} className="grid gap-4 border-b border-white/6 px-5 py-5 lg:grid-cols-[1.2fr_1.05fr_0.75fr_0.8fr_1fr_0.9fr_0.8fr] lg:items-center">
                <div>
                  <div className="text-sm font-semibold text-white">{user.fullName}</div>
                  <div className="mt-1 text-xs uppercase tracking-[0.18em] text-[#9ba6b2]">{user.source === 'seed' ? 'konto demo' : 'konto custom'}</div>
                </div>
                <div className="text-sm text-[#c2cad4]">{user.email}</div>
                <div className="text-sm text-white">{roleDefinitions.find((role) => role.key === user.role)?.label ?? user.role}</div>
                <div className="text-sm text-[#c2cad4]">{user.region ?? '—'}</div>
                <div className="text-sm text-[#c2cad4]">
                  {user.reportsToUserId ? usersById.get(user.reportsToUserId)?.fullName ?? 'Nieznany przelozony' : '—'}
                </div>
                <div>
                  <div className={[
                    'inline-flex rounded-full border px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em]',
                    user.isActive
                      ? 'border-emerald-400/20 bg-emerald-500/10 text-emerald-200'
                      : 'border-white/10 bg-white/[0.04] text-[#9ba6b2]',
                  ].join(' ')}>
                    {user.isActive ? 'Aktywny' : 'Zablokowany'}
                  </div>
                  <div className="mt-2 text-xs text-[#7f8a97]">{formatDate(user.createdAt)}</div>
                </div>
                <form action={toggleUserStatusAction}>
                  <input type="hidden" name="userId" value={user.id} />
                  <button type="submit" className="inline-flex h-10 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm font-medium text-white transition hover:bg-white/[0.08]">
                    {user.isActive ? 'Zablokuj' : 'Aktywuj'}
                  </button>
                </form>
              </div>
            ))}
          </div>
        </div>
      </section>
    </main>
  )
}