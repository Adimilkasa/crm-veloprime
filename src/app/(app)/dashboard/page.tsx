const stats = [
  { label: 'Nowe leady', value: '18', change: '+12% tydzień do tygodnia' },
  { label: 'Oferty w toku', value: '34', change: '7 do akceptacji managera' },
  { label: 'Samochody dostępne', value: '126', change: '14 wymaga aktualizacji ceny' },
  { label: 'Konwersja miesiąca', value: '21%', change: '+3 pp vs poprzedni miesiąc' },
]

const activity = [
  'Nowy lead z formularza strony przypisany do regionu Warszawa.',
  'Oferta PDF dla BYD Seal 5 oczekuje na akceptację rabatu.',
  'Administrator zaktualizował ceny bazowe dla 8 samochodów.',
  'Manager przypisał 3 leady do zespołu południe.',
]

export default function DashboardPage() {
  return (
    <main className="grid gap-6">
      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {stats.map((item) => (
          <article key={item.label} className="rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-5 shadow-[0_18px_48px_rgba(0,0,0,0.16)]">
            <p className="text-sm text-[#9ba6b2]">{item.label}</p>
            <div className="mt-3 text-4xl font-semibold text-white">{item.value}</div>
            <p className="mt-3 text-sm text-[#d6bc72]">{item.change}</p>
          </article>
        ))}
      </section>

      <section className="grid gap-6 xl:grid-cols-[1.1fr_0.9fr]">
        <article className="rounded-[32px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-6 shadow-[0_18px_48px_rgba(0,0,0,0.16)]">
          <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Priorytety MVP</div>
          <h2 className="mt-3 text-2xl font-semibold text-white">Fundament pod pierwszy etap CRM</h2>
          <div className="mt-5 grid gap-3 text-sm leading-6 text-[#aeb7c2]">
            <p>Ten panel ma już osobny shell aplikacji, definicje ról oraz przygotowany model danych pod użytkowników, leady, klientów, samochody i oferty PDF.</p>
            <p>Kolejnym krokiem jest podłączenie logowania i bazy danych, a następnie wdrożenie pierwszych ekranów operacyjnych: leady, samochody i oferty.</p>
          </div>
        </article>

        <article className="rounded-[32px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-6 shadow-[0_18px_48px_rgba(0,0,0,0.16)]">
          <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Ostatnia aktywność</div>
          <div className="mt-5 grid gap-3">
            {activity.map((item) => (
              <div key={item} className="rounded-2xl border border-white/6 bg-white/[0.03] px-4 py-3 text-sm leading-6 text-[#aeb7c2]">
                {item}
              </div>
            ))}
          </div>
        </article>
      </section>
    </main>
  )
}