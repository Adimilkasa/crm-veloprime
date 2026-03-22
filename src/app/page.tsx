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
    title: 'Oferty PDF',
    body: 'Generator ofert dla klienta z wariantami finansowania i historią wersji dokumentu.',
  },
  {
    title: 'Uprawnienia i konta',
    body: 'Administrator tworzy użytkowników, nadaje role i kontroluje dostęp do modułów.',
  },
]

export default function Home() {
  return (
    <main className="mx-auto flex min-h-screen max-w-7xl flex-col gap-10 px-6 py-10 lg:px-10">
      <section className="grid gap-6 rounded-[32px] border border-white/10 bg-[rgba(18,24,33,0.82)] p-8 shadow-[0_30px_80px_rgba(0,0,0,0.28)] lg:grid-cols-[1.2fr_0.8fr]">
        <div>
          <div className="inline-flex rounded-full border border-[rgba(216,180,90,0.35)] bg-[rgba(216,180,90,0.12)] px-4 py-1.5 text-xs font-semibold uppercase tracking-[0.2em] text-[#f3d998]">
            CRM foundation
          </div>
          <h1 className="mt-5 max-w-[14ch] text-4xl font-semibold leading-tight text-white lg:text-6xl">
            Osobny panel CRM dla zespołu sprzedaży VeloPrime.
          </h1>
          <p className="mt-5 max-w-2xl text-base leading-7 text-[#b8c0cb]">
            Starter projektu pod logowanie, role, leady, samochody, wyceny i generowanie ofert PDF. Ten projekt jest niezależny od strony publicznej.
          </p>
        </div>

        <div className="rounded-[28px] border border-white/10 bg-[rgba(255,255,255,0.04)] p-6">
          <div className="text-sm font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Role systemowe</div>
          <div className="mt-4 grid gap-3">
            {roles.map((role) => (
              <div key={role} className="rounded-2xl border border-white/8 bg-[rgba(255,255,255,0.03)] px-4 py-3 text-sm font-medium text-white">
                {role}
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="grid gap-5 md:grid-cols-2 xl:grid-cols-4">
        {modules.map((module) => (
          <article key={module.title} className="rounded-[28px] border border-white/10 bg-[rgba(18,24,33,0.76)] p-6 shadow-[0_18px_48px_rgba(0,0,0,0.18)]">
            <h2 className="text-xl font-semibold text-white">{module.title}</h2>
            <p className="mt-3 text-sm leading-6 text-[#a8b1bc]">{module.body}</p>
          </article>
        ))}
      </section>

      <section className="flex flex-col gap-3 sm:flex-row">
        <Link
          href="/login"
          className="inline-flex items-center justify-center rounded-2xl border border-[rgba(216,180,90,0.35)] bg-[linear-gradient(135deg,#d8b45a,#b98b1d)] px-6 py-3 text-sm font-semibold text-[#10161d]"
        >
          Zobacz ekran logowania
        </Link>
        <Link
          href="/dashboard"
          className="inline-flex items-center justify-center rounded-2xl border border-white/10 bg-white/[0.04] px-6 py-3 text-sm font-semibold text-white"
        >
          Zobacz shell dashboardu
        </Link>
      </section>
    </main>
  )
}
