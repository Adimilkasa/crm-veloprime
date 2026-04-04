import Link from 'next/link'

const roles = [
  'Administrator',
  'Dyrektor',
  'Manager',
  'Handlowiec',
]

const modules = [
  {
    title: 'Leady i klienci',
    body: 'Obsługa kontaktów ze strony, statusów sprzedaży, przypisań i historii działań.',
  },
  {
    title: 'Baza samochodów',
    body: 'Zarządzanie dostępnymi autami, cenami bazowymi, rabatami i konfiguracją ofert.',
  },
  {
    title: 'Oferty w aplikacji Windows',
    body: 'Główny generator ofert działa w aplikacji Flutter dla Windows, a web obsługuje publiczny link dla klienta.',
  },
  {
    title: 'Uprawnienia i konta',
    body: 'Administrator tworzy użytkowników, nadaje role i kontroluje dostęp do modułów.',
  },
]

export default function Home() {
  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,rgba(201,161,59,0.14),transparent_28%),linear-gradient(180deg,#fafaf9_0%,#f7f6f4_100%)]">
      <div className="mx-auto flex min-h-screen max-w-7xl flex-col gap-10 px-6 py-10 lg:px-10">
      <section className="grid gap-6 rounded-[32px] border border-[#e8e2d3] bg-[linear-gradient(135deg,#ffffff_0%,#fbf8f1_52%,#f7f3e8_100%)] p-8 shadow-[0_24px_70px_rgba(31,31,31,0.06)] lg:grid-cols-[1.2fr_0.8fr]">
        <div>
          <div className="inline-flex rounded-full border border-[rgba(201,161,59,0.28)] bg-[rgba(201,161,59,0.12)] px-4 py-1.5 text-xs font-semibold uppercase tracking-[0.2em] text-[#8f6b18]">
            CRM foundation
          </div>
          <h1 className="mt-5 max-w-[14ch] text-4xl font-semibold leading-tight text-[#1f1f1f] lg:text-6xl">
            Osobny panel CRM dla zespołu sprzedaży VeloPrime.
          </h1>
          <p className="mt-5 max-w-2xl text-base leading-7 text-[#5f5a4f]">
            Panel CRM dla logowania, ról, leadów, konfiguracji i publicznego renderu oferty. Operacyjna praca na ofertach odbywa się w aplikacji Windows.
          </p>
        </div>

        <div className="rounded-[28px] border border-[#ece6d9] bg-white/90 p-6 shadow-[0_16px_34px_rgba(31,31,31,0.04)]">
          <div className="text-sm font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Role systemowe</div>
          <div className="mt-4 grid gap-3">
            {roles.map((role) => (
              <div key={role} className="rounded-2xl border border-[#ece6d9] bg-[#fcfbf8] px-4 py-3 text-sm font-medium text-[#1f1f1f]">
                {role}
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="grid gap-5 md:grid-cols-2 xl:grid-cols-4">
        {modules.map((module) => (
          <article key={module.title} className="rounded-[28px] border border-[#ece6d9] bg-white p-6 shadow-[0_18px_48px_rgba(31,31,31,0.05)]">
            <h2 className="text-xl font-semibold text-[#1f1f1f]">{module.title}</h2>
            <p className="mt-3 text-sm leading-7 text-[#6b6b6b]">{module.body}</p>
          </article>
        ))}
      </section>

      <section className="flex flex-col gap-3 sm:flex-row">
        <Link
          href="/download"
          className="inline-flex items-center justify-center rounded-2xl border border-[rgba(201,161,59,0.28)] bg-[linear-gradient(180deg,#f4dfae_0%,#d7af58_100%)] px-6 py-3 text-sm font-semibold text-[#1a1610] shadow-[0_18px_32px_rgba(201,161,59,0.22)] transition hover:translate-y-[-1px] hover:brightness-[1.02]"
        >
          Pobierz aplikację Windows
        </Link>
        <Link
          href="/login"
          className="inline-flex items-center justify-center rounded-2xl border border-[rgba(201,161,59,0.3)] bg-[#c9a13b] px-6 py-3 text-sm font-semibold text-white shadow-[0_16px_32px_rgba(201,161,59,0.22)] transition hover:bg-[#b8932f]"
        >
          Zobacz ekran logowania
        </Link>
        <Link
          href="/dashboard"
          className="inline-flex items-center justify-center rounded-2xl border border-[#e5dfd1] bg-white px-6 py-3 text-sm font-semibold text-[#4d4d4d] transition hover:border-[rgba(201,161,59,0.26)] hover:text-[#1f1f1f]"
        >
          Zobacz shell dashboardu
        </Link>
      </section>
      </div>
    </main>
  )
}
