import Link from 'next/link'
import { redirect } from 'next/navigation'

import { getSession } from '@/lib/auth'

export default async function OffersPage({
}: {
  searchParams: Promise<{ leadId?: string; offerId?: string }>
}) {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  await Promise.resolve()

  return (
    <main className="grid gap-6">
      <section className="rounded-[28px] border border-[#ebe4d7] bg-[linear-gradient(135deg,#ffffff_0%,#fbf8f1_52%,#f7f3e8_100%)] px-6 py-7 shadow-[0_18px_48px_rgba(31,31,31,0.05)] sm:px-8">
        <div className="inline-flex rounded-full border border-[rgba(201,161,59,0.28)] bg-[rgba(201,161,59,0.12)] px-4 py-1.5 text-xs font-semibold uppercase tracking-[0.2em] text-[#8f6b18]">
          Oferty w aplikacji Windows
        </div>
        <h1 className="mt-5 text-[30px] font-semibold leading-tight text-[#1f1f1f] sm:text-[40px]">
          Webowy generator ofert został wyłączony.
        </h1>
        <p className="mt-4 max-w-3xl text-[15px] leading-8 text-[#5f5a4f]">
          Operacyjna praca na ofertach odbywa się wyłącznie w aplikacji Flutter dla Windows. W CRM online zostaje tylko publiczna oferta klienta z linku i zaplecze API używane przez aplikację.
        </p>
        <div className="mt-6 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          <div className="rounded-[22px] border border-[#ece6d9] bg-white/88 px-5 py-4">
            <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Numer 1</div>
            <div className="mt-2 text-base font-semibold text-[#1f1f1f]">Wygeneruj ofertę w Flutterze</div>
            <p className="mt-2 text-sm leading-7 text-[#6b6b6b]">To jest jedyny aktywny generator i główny workflow handlowca.</p>
          </div>
          <div className="rounded-[22px] border border-[#ece6d9] bg-white/88 px-5 py-4">
            <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Numer 2</div>
            <div className="mt-2 text-base font-semibold text-[#1f1f1f]">Wyślij ofertę z maila</div>
            <p className="mt-2 text-sm leading-7 text-[#6b6b6b]">Klient widzi tylko publiczny snapshot tej samej wygenerowanej wersji.</p>
          </div>
          <div className="rounded-[22px] border border-[#ece6d9] bg-white/88 px-5 py-4">
            <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Web CRM</div>
            <div className="mt-2 text-base font-semibold text-[#1f1f1f]">Bez generatora</div>
            <p className="mt-2 text-sm leading-7 text-[#6b6b6b]">Tu zostają leady, konfiguracja i publiczny renderer oferty po linku.</p>
          </div>
        </div>
        <div className="mt-8 flex flex-wrap gap-3">
          <Link
            href="/download"
            className="inline-flex items-center justify-center rounded-2xl border border-[rgba(201,161,59,0.28)] bg-[linear-gradient(180deg,#f4dfae_0%,#d7af58_100%)] px-6 py-3 text-sm font-semibold text-[#1a1610] shadow-[0_18px_32px_rgba(201,161,59,0.22)] transition hover:translate-y-[-1px] hover:brightness-[1.02]"
          >
            Pobierz aplikację Windows
          </Link>
          <Link
            href="/leads"
            className="inline-flex items-center justify-center rounded-2xl border border-[#e5dfd1] bg-white px-6 py-3 text-sm font-semibold text-[#4d4d4d] transition hover:border-[rgba(201,161,59,0.26)] hover:text-[#1f1f1f]"
          >
            Wróć do leadów
          </Link>
        </div>
      </section>
    </main>
  )
}