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
        <article className="overflow-hidden rounded-[32px] border border-[#e8e2d3] bg-[linear-gradient(135deg,#ffffff_0%,#fbf8f1_52%,#f7f3e8_100%)] p-6 shadow-[0_24px_70px_rgba(31,31,31,0.06)] lg:p-8">
          <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Administracja kontami</div>
          <h2 className="mt-3 text-[28px] font-semibold text-[#1f1f1f]">Użytkownicy i uprawnienia</h2>
          <p className="mt-3 max-w-2xl text-sm leading-7 text-[#5f5a4f]">
            To jest pierwszy moduł administracyjny CRM. Administrator może tworzyć konta foundation, przypisywać role oraz czasowo blokować dostęp użytkownikom.
          </p>

          <div className="mt-5 grid gap-4 md:grid-cols-3">
            <div className="rounded-[24px] border border-[#ece6d9] bg-white/90 p-5 shadow-[0_16px_34px_rgba(31,31,31,0.04)]">
              <div className="text-sm text-[#7a7466]">Wszystkie konta</div>
              <div className="mt-2 text-3xl font-semibold text-[#1f1f1f]">{users.length}</div>
            </div>
            <div className="rounded-[24px] border border-[#ece6d9] bg-white/90 p-5 shadow-[0_16px_34px_rgba(31,31,31,0.04)]">
              <div className="text-sm text-[#7a7466]">Aktywne</div>
              <div className="mt-2 text-3xl font-semibold text-[#1f1f1f]">{users.filter((user) => user.isActive).length}</div>
            </div>
            <div className="rounded-[24px] border border-[#ece6d9] bg-white/90 p-5 shadow-[0_16px_34px_rgba(31,31,31,0.04)]">
              <div className="text-sm text-[#7a7466]">Role systemowe</div>
              <div className="mt-2 text-3xl font-semibold text-[#1f1f1f]">{roleDefinitions.length}</div>
            </div>
          </div>
        </article>

        <article className="rounded-[32px] border border-[#e8e2d3] bg-white p-6 shadow-[0_20px_60px_rgba(31,31,31,0.05)] lg:p-8">
          <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Nowe konto</div>
          <h2 className="mt-3 text-[24px] font-semibold text-[#1f1f1f]">Dodaj użytkownika</h2>

          <form action={createUserAction} className="mt-5 grid gap-4">
            <label className="block">
              <span className="text-sm font-medium text-[#2f2a22]">Imię i nazwisko</span>
              <input name="fullName" className="mt-2 h-12 w-full rounded-2xl border border-[#e6dfd2] bg-[#fcfbf8] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.42)] focus:bg-white" placeholder="Jan Kowalski" />
            </label>

            <label className="block">
              <span className="text-sm font-medium text-[#2f2a22]">Email</span>
              <input name="email" className="mt-2 h-12 w-full rounded-2xl border border-[#e6dfd2] bg-[#fcfbf8] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.42)] focus:bg-white" placeholder="jan@veloprime.pl" />
            </label>

            <label className="block">
              <span className="text-sm font-medium text-[#2f2a22]">Rola</span>
              <select name="role" className="mt-2 h-12 w-full rounded-2xl border border-[#e6dfd2] bg-[#fcfbf8] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.42)] focus:bg-white">
                {roleDefinitions.map((role) => (
                  <option key={role.key} value={role.key}>
                    {role.label}
                  </option>
                ))}
              </select>
            </label>

            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-[#2f2a22]">Region</span>
                <input name="region" className="mt-2 h-12 w-full rounded-2xl border border-[#e6dfd2] bg-[#fcfbf8] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.42)] focus:bg-white" placeholder="Warszawa" />
              </label>

              <label className="block">
                <span className="text-sm font-medium text-[#2f2a22]">Zespół</span>
                <input name="teamName" className="mt-2 h-12 w-full rounded-2xl border border-[#e6dfd2] bg-[#fcfbf8] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.42)] focus:bg-white" placeholder="Polnoc" />
              </label>
            </div>

            <label className="block">
              <span className="text-sm font-medium text-[#2f2a22]">Bezpośredni przełożony</span>
              <select name="reportsToUserId" className="mt-2 h-12 w-full rounded-2xl border border-[#e6dfd2] bg-[#fcfbf8] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.42)] focus:bg-white">
                <option value="">Brak przypisania</option>
                {supervisorOptions.map((user) => (
                  <option key={user.id} value={user.id}>
                    {user.fullName} ({roleDefinitions.find((role) => role.key === user.role)?.label ?? user.role})
                  </option>
                ))}
              </select>
              <p className="mt-2 text-xs leading-6 text-[#7a7466]">
                Manager powinien wskazywać dyrektora. Handlowiec powinien wskazywać managera albo bezpośrednio dyrektora.
              </p>
            </label>

            <button type="submit" className="inline-flex h-12 items-center justify-center rounded-2xl border border-[rgba(201,161,59,0.3)] bg-[#c9a13b] px-5 text-sm font-semibold text-white shadow-[0_16px_32px_rgba(201,161,59,0.22)] transition hover:bg-[#b8932f]">
              Utwórz konto
            </button>
          </form>

          {error ? (
            <div className="mt-4 rounded-2xl border border-[#f1caca] bg-[#fff4f4] px-4 py-3 text-sm text-[#a14b4b]">{error}</div>
          ) : null}
          {success ? (
            <div className="mt-4 rounded-2xl border border-[#d8ead8] bg-[#f4fbf4] px-4 py-3 text-sm text-[#3f7a4c]">
              {success === 'created' ? 'Nowe konto zostało dodane.' : 'Status użytkownika został zmieniony.'}
            </div>
          ) : null}
        </article>
      </section>

      <section className="rounded-[32px] border border-[#e8e2d3] bg-white p-6 shadow-[0_20px_60px_rgba(31,31,31,0.05)] lg:p-8">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Lista kont</div>
            <h2 className="mt-2 text-[24px] font-semibold text-[#1f1f1f] lg:text-[28px]">Użytkownicy systemu</h2>
          </div>
          <p className="max-w-xl text-sm leading-7 text-[#6b6b6b]">
            Konta oznaczone jako `seed` pochodzą z demo auth. Konta `custom` są dodawane przez administratora w ramach foundation i utrzymywane w pamięci aplikacji.
          </p>
        </div>

        <div className="mt-6 overflow-hidden rounded-[24px] border border-[#ece6d9] bg-[#fcfbf8]">
          <div className="hidden grid-cols-[1.2fr_1.05fr_0.75fr_0.8fr_1fr_0.9fr_0.8fr] gap-4 border-b border-[#ece6d9] bg-[#f8f3e8] px-5 py-4 text-xs font-semibold uppercase tracking-[0.18em] text-[#8f6b18] lg:grid">
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
              <div key={user.id} className="grid gap-4 border-b border-[#eee8dd] bg-white px-5 py-5 last:border-b-0 lg:grid-cols-[1.2fr_1.05fr_0.75fr_0.8fr_1fr_0.9fr_0.8fr] lg:items-center">
                <div>
                  <div className="text-sm font-semibold text-[#1f1f1f]">{user.fullName}</div>
                  <div className="mt-1 text-xs uppercase tracking-[0.18em] text-[#8a826f]">{user.source === 'seed' ? 'konto demo' : 'konto custom'}</div>
                </div>
                <div className="text-sm text-[#666666]">{user.email}</div>
                <div className="text-sm text-[#1f1f1f]">{roleDefinitions.find((role) => role.key === user.role)?.label ?? user.role}</div>
                <div className="text-sm text-[#666666]">{user.region ?? '—'}</div>
                <div className="text-sm text-[#666666]">
                  {user.reportsToUserId ? usersById.get(user.reportsToUserId)?.fullName ?? 'Nieznany przelozony' : '—'}
                </div>
                <div>
                  <div className={[
                    'inline-flex rounded-full border px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em]',
                    user.isActive
                      ? 'border-[#d8ead8] bg-[#f4fbf4] text-[#3f7a4c]'
                      : 'border-[#e6dfd2] bg-[#f6f3ed] text-[#7a7466]',
                  ].join(' ')}>
                    {user.isActive ? 'Aktywny' : 'Zablokowany'}
                  </div>
                  <div className="mt-2 text-xs text-[#8a826f]">{formatDate(user.createdAt)}</div>
                </div>
                <form action={toggleUserStatusAction}>
                  <input type="hidden" name="userId" value={user.id} />
                  <button type="submit" className="inline-flex h-10 items-center justify-center rounded-2xl border border-[#e5dfd1] bg-[#fcfbf8] px-4 text-sm font-medium text-[#4d4d4d] transition hover:border-[rgba(201,161,59,0.26)] hover:bg-white hover:text-[#1f1f1f]">
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