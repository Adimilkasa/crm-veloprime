import Link from 'next/link'

export const metadata = {
  title: 'Pobierz aplikację | CRM VeloPrime',
  description: 'Publiczna strona pobierania aplikacji Windows dla CRM VeloPrime.',
}

const highlights = [
  'Instalator Windows z aktualizacjami przez App Installer',
  'Połączenie z centralnym CRM VeloPrime po zalogowaniu',
  'Pakiet gotowy do testu na drugim komputerze',
]

const steps = [
  'Pobierz plik instalacyjny App Installer.',
  'Zaimportuj certyfikat testowy do magazynów Zaufane osoby i Zaufane główne urzędy certyfikacji.',
  'Uruchom instalację i zaloguj się na konto testowe w aplikacji.',
]

export default function DownloadPage() {
  return (
    <main className="min-h-screen overflow-hidden bg-[radial-gradient(circle_at_top,rgba(212,168,79,0.22),transparent_24%),radial-gradient(circle_at_12%_24%,rgba(255,249,238,0.92),transparent_20%),linear-gradient(180deg,#fcfcfa_0%,#f1ede5_100%)]">
      <div className="mx-auto flex min-h-screen max-w-7xl flex-col px-6 py-8 lg:px-10 lg:py-10">
        <header className="flex items-center justify-between rounded-[26px] border border-[rgba(17,17,17,0.05)] bg-white/75 px-5 py-4 shadow-[0_14px_36px_rgba(15,15,15,0.05)] backdrop-blur-xl">
          <div>
            <div className="text-[11px] font-semibold uppercase tracking-[0.28em] text-[#9d7b27]">
              VeloPrime CRM
            </div>
            <div className="mt-1 text-sm text-[#5c564a]">
              Publiczna strona pobierania aplikacji Windows
            </div>
          </div>
          <Link
            href="/login"
            className="inline-flex items-center justify-center rounded-full border border-[rgba(17,17,17,0.08)] bg-white px-4 py-2 text-sm font-medium text-[#2c2923] transition hover:border-[rgba(212,168,79,0.28)] hover:text-[#111111]"
          >
            Przejdź do logowania
          </Link>
        </header>

        <section className="relative mt-6 flex flex-1 items-center justify-center">
          <div className="absolute inset-x-[8%] top-10 h-56 rounded-full bg-[radial-gradient(circle,rgba(212,168,79,0.24)_0%,rgba(212,168,79,0.04)_46%,transparent_72%)] blur-3xl" />
          <div className="relative grid w-full items-center gap-8 rounded-[34px] border border-[rgba(17,17,17,0.05)] bg-[linear-gradient(145deg,rgba(255,255,255,0.95)_0%,rgba(249,246,240,0.9)_48%,rgba(243,237,226,0.96)_100%)] p-7 shadow-[0_28px_90px_rgba(15,15,15,0.08)] lg:grid-cols-[1.1fr_0.9fr] lg:p-10">
            <div>
              <div className="inline-flex rounded-full border border-[rgba(201,161,59,0.24)] bg-[rgba(201,161,59,0.11)] px-4 py-2 text-[11px] font-semibold uppercase tracking-[0.26em] text-[#8f6b18]">
                Windows App Delivery
              </div>
              <h1 className="mt-5 max-w-[11ch] text-4xl font-semibold leading-[0.98] text-[#181512] md:text-5xl lg:text-6xl">
                Pobierz aplikację CRM VeloPrime.
              </h1>
              <p className="mt-5 max-w-2xl text-base leading-8 text-[#5d574c] md:text-lg">
                Instalator jest publicznie dostępny bez logowania. Po instalacji aplikacja łączy się z centralnym środowiskiem CRM i pozwala zalogować się na istniejące konto testowe lub administracyjne.
              </p>

              <div className="mt-8 flex flex-col items-start gap-3 sm:flex-row">
                <a
                  href="/download/VeloPrime-CRM-Test.appinstaller"
                  className="inline-flex min-w-[240px] items-center justify-center rounded-[22px] border border-[rgba(190,147,62,0.26)] bg-[linear-gradient(180deg,#efd79d_0%,#d6ac53_100%)] px-7 py-4 text-base font-semibold text-[#17130e] shadow-[0_18px_38px_rgba(212,168,79,0.24)] transition hover:translate-y-[-1px] hover:brightness-[1.02]"
                >
                  Pobierz aplikację
                </a>
                <a
                  href="/download/veloprime-crm-test-signing.cer"
                  className="inline-flex min-w-[220px] items-center justify-center rounded-[22px] border border-[rgba(17,17,17,0.08)] bg-white px-7 py-4 text-base font-semibold text-[#2f2b25] shadow-[0_14px_28px_rgba(15,15,15,0.05)] transition hover:translate-y-[-1px] hover:border-[rgba(212,168,79,0.22)]"
                >
                  Pobierz certyfikat testowy
                </a>
                <a
                  href="/download/install-test-certificate.ps1"
                  className="inline-flex min-w-[220px] items-center justify-center rounded-[22px] border border-[rgba(17,17,17,0.08)] bg-white px-7 py-4 text-base font-semibold text-[#2f2b25] shadow-[0_14px_28px_rgba(15,15,15,0.05)] transition hover:translate-y-[-1px] hover:border-[rgba(212,168,79,0.22)]"
                >
                  Skrypt importu certyfikatu
                </a>
              </div>

              <div className="mt-6 flex flex-wrap gap-3 text-sm text-[#4e493f]">
                {highlights.map((item) => (
                  <div
                    key={item}
                    className="rounded-full border border-[rgba(17,17,17,0.06)] bg-white/80 px-4 py-2 shadow-[0_8px_20px_rgba(15,15,15,0.04)]"
                  >
                    {item}
                  </div>
                ))}
              </div>
            </div>

            <div className="rounded-[30px] border border-[rgba(17,17,17,0.06)] bg-[linear-gradient(180deg,rgba(255,255,255,0.94)_0%,rgba(247,243,235,0.92)_100%)] p-6 shadow-[0_22px_56px_rgba(15,15,15,0.06)]">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-[#9d7b27]">
                    Start testu
                  </div>
                  <h2 className="mt-3 text-2xl font-semibold text-[#1c1915]">
                    Instalacja w 3 krokach
                  </h2>
                </div>
                <div className="rounded-full border border-[rgba(201,161,59,0.24)] bg-[rgba(201,161,59,0.12)] px-3 py-1 text-xs font-semibold text-[#8f6b18]">
                  MSIX
                </div>
              </div>

              <div className="mt-6 grid gap-4">
                {steps.map((step, index) => (
                  <div
                    key={step}
                    className="rounded-[22px] border border-[rgba(17,17,17,0.06)] bg-white/90 p-4 shadow-[0_10px_24px_rgba(15,15,15,0.04)]"
                  >
                    <div className="flex items-center gap-3">
                      <div className="flex h-9 w-9 items-center justify-center rounded-full bg-[linear-gradient(180deg,#efd79d_0%,#d6ac53_100%)] text-sm font-semibold text-[#17130e]">
                        {index + 1}
                      </div>
                      <p className="text-sm leading-6 text-[#423d34]">{step}</p>
                    </div>
                  </div>
                ))}
              </div>

              <div className="mt-6 rounded-[24px] border border-[rgba(201,161,59,0.18)] bg-[rgba(201,161,59,0.08)] px-5 py-4 text-sm leading-7 text-[#5d533f]">
                Jeśli Windows pokaże ostrzeżenie o zaufaniu do wydawcy, nie wybieraj automatycznego magazynu certyfikatów. Użyj skryptu importu albo wskaż ręcznie magazyny Zaufane osoby i Zaufane główne urzędy certyfikacji dla Komputer lokalny.
              </div>
            </div>
          </div>
        </section>
      </div>
    </main>
  )
}