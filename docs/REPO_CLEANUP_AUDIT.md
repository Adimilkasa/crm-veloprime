# Repository Cleanup Audit

## Cel

Uporzadkowac repo bez naruszania dzialajacej funkcjonalnosci CRM web, klienta Flutter i publicznego flow pobierania.

Audyt byl wykonany przez porownanie:

- realnych importow i wywolan w aplikacji Flutter
- aktywnych route'ow Next.js
- plikow wykorzystywanych przez strone pobierania
- plikow wygenerowanych lokalnie podczas budowy MSIX

## Potwierdzone jako uzywane

### Web CRM i backend

- `src/app/(app)/**`
- `src/app/api/client/**`
- `src/app/api/updates/**`
- `src/app/api/offers/validate-finalization/route.ts`
- `src/lib/update-management.ts`
- `data/update-manifest.json`

Powod:

- te pliki obsluguja aktywne flow web CRM, bootstrap klienta hybrydowego, aktualizacje, leady, oferty, pricing i users.

### Flutter Windows client

- `client/veloprime_hybrid_app/lib/app.dart`
- `client/veloprime_hybrid_app/lib/features/bootstrap/**`
- `client/veloprime_hybrid_app/lib/features/leads/**`
- `client/veloprime_hybrid_app/lib/features/offers/**`
- `client/veloprime_hybrid_app/lib/features/pricing/**`
- `client/veloprime_hybrid_app/lib/features/commissions/**`
- `client/veloprime_hybrid_app/lib/features/users/**`
- `client/veloprime_hybrid_app/lib/features/update/**`
- `client/veloprime_hybrid_app/windows/**`

Powod:

- `app.dart` podpina te repozytoria i widoki do glownego shella aplikacji.
- `crm_shell_page.dart`, `leads_home_page.dart` i `lead_detail_page.dart` importuja aktywny widok ofert z `features/offers/presentation/offers_home_page.dart`.

### Publiczny flow pobierania

- `src/app/download/page.tsx`
- `public/download/VeloPrime-CRM-Test.appinstaller`
- `public/download/install-test-certificate.ps1`
- `public/download/veloprime-crm-test-signing.cer`

Powod:

- landing page pobierania jest obslugiwany przez route Next.js `src/app/download/page.tsx`.
- aktywna strona linkuje do `.appinstaller`, certyfikatu i skryptu.
- aktualny `.appinstaller` wskazuje bezposrednio na asset GitHub Release `v0.1.2.0`, wiec strona pobrania nie zalezy juz od repo-hostowanych binarek `.msix`.

## Potwierdzone jako zduplikowane lub martwe

### Duplikat w Flutter

- `client/veloprime_hybrid_app/lib/features/leads/presentation/offers_home_page.dart`

Powod:

- plik jest zdublowana kopia `client/veloprime_hybrid_app/lib/features/offers/presentation/offers_home_page.dart`.
- nie ma zadnego importu w kodzie.
- wszystkie realne importy wskazuja na wersje z `features/offers/presentation`.

### Martwa statyczna strona pobierania

- `public/download/index.html`

Powod:

- aplikacja i landing publiczny korzystaja z `src/app/download/page.tsx`.
- nie znaleziono zadnego realnego odniesienia runtime do `public/download/index.html` poza nim samym i kopiami w artefaktach builda.

## Potwierdzone jako artefakty wygenerowane lokalnie

- `client/veloprime_hybrid_app/deploy/msix/artifacts/**`
- `client/veloprime_hybrid_app/deploy/veloprime_hybrid_app_windows_release.zip`

Powod:

- to wynik lokalnego procesu budowy i pakowania MSIX.
- zawieraja kopie plikow, ktore juz istnieja w repo jako canonical source albo binarki wynikowe.
- nie sa importowane przez runtime aplikacji.

## Potwierdzone jako do zachowania mimo podobienstwa do artefaktow

- `client/veloprime_hybrid_app/deploy/MSIX_DISTRIBUTION_PLAN.md`
- `client/veloprime_hybrid_app/deploy/msix/build-msix.ps1`
- `client/veloprime_hybrid_app/deploy/msix/create-test-signing-cert.ps1`
- `client/veloprime_hybrid_app/deploy/veloprime_client_config.example.json`
- `client/veloprime_hybrid_app/deploy/veloprime_client_config.test-lan.json`

Powod:

- to dokumentacja, skrypty operacyjne i przyklady konfiguracji, a nie wynik builda.

## Cleanup wykonany w tym etapie

- usunieto nieuzywany duplikat `features/leads/presentation/offers_home_page.dart`
- usunieto martwy `public/download/index.html`
- usunieto wygenerowane `client/veloprime_hybrid_app/deploy/msix/artifacts/**`
- usunieto wygenerowany `client/veloprime_hybrid_app/deploy/veloprime_hybrid_app_windows_release.zip`
- dopisano reguly `.gitignore`, aby te artefakty nie wracaly do repo
- opublikowano `veloprime_hybrid_app_0.1.2.0.msix` w GitHub Release `v0.1.2.0`
- przestawiono `public/download/VeloPrime-CRM-Test.appinstaller` na URL assetu GitHub Release
- usunieto repo-hostowane `public/download/versions/*.msix`

## Narzedzie do lokalnego cleanupu

- `scripts/cleanup-local-artifacts.ps1`

Powod:

- czyści potwierdzone artefakty lokalne ignorowane przez git, bez dotykania kodu produktu
- domyslnie usuwa `.next`, `vercel-deploy.log`, `client/veloprime_hybrid_app/build`, `client/veloprime_hybrid_app/.dart_tool` oraz `client/veloprime_hybrid_app/deploy/msix/artifacts`
- katalog `screeny/` usuwa tylko po jawnym uruchomieniu z `-IncludeScreenshots`

## Usuniete po cutoverze

- `public/download/versions/*.msix`

Powod:

- publiczny `.appinstaller` nie wskazuje juz na repo-hostowane binarki.
- aktywny asset `0.1.2.0` jest publicznie dostepny z GitHub Releases.
- utrzymywanie tych plikow w `main` nie bylo juz potrzebne.

## Stan po migracji

1. Release `v0.1.2.0` zawiera publiczny asset `veloprime_hybrid_app_0.1.2.0.msix`.
2. `public/download/VeloPrime-CRM-Test.appinstaller` wskazuje na URL GitHub Releases.
3. `public/download/versions/*.msix` zostaly usuniete z glownej galezi roboczej.

Repo pozostaje przygotowane technicznie do kolejnych wersji przez:

- `client/veloprime_hybrid_app/deploy/msix/build-msix.ps1`, ktory obsluguje osobny `PackageBaseUrl`
- `scripts/update-appinstaller-github-release.ps1`, ktory przestawia publiczny manifest na URL assetu releasu