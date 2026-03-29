# Repository Changeset Plan

## Cel

Uporzadkowac obecne zmiany na male, czytelne commity tak, aby GitHub pozostawal jedynym zrodlem prawdy i zeby historia repo byla zrozumiala przy kolejnych wdrozeniach.

## Zalecana kolejnosc commitow

### 1. Dokumentacja procesu i kierunku produktu

Zakres:

- `docs/DEPLOYMENT_WORKFLOW.md`
- `docs/HYBRID_CLIENT_IMPLEMENTATION_PLAN.md`
- `docs/CRM_PREMIUM_VISUAL_SYSTEM.md`

Cel commitu:

- zapisanie zasad pracy, wdrozen i kierunku architektury zanim trafi kod wykonawczy

Proponowany commit message:

- `docs: codify deployment workflow and hybrid client direction`

### 2. Backend i kontrakty dla klienta hybrydowego

Zakres:

- `prisma/migrations/20260329_persist_leads_and_history/migration.sql`
- `data/update-manifest.json`
- `src/lib/update-management.ts`
- `vercel.json`
- `src/app/api/updates/**`
- `src/app/api/offers/validate-finalization/route.ts`
- `src/app/api/client/account/password/route.ts`
- `src/app/api/client/bootstrap/route.ts`
- `src/app/api/client/commissions/route.ts`
- `src/app/api/client/leads/**`
- `src/app/api/client/offers/**`
- `src/app/api/client/pricing/**`
- `src/app/api/client/users/**`

Cel commitu:

- dodanie warstwy API, wersjonowania i walidacji potrzebnej dla lokalnego klienta

Proponowany commit message:

- `feat: add hybrid client api, updates and lead persistence`

### 3. Klient Flutter Windows i testy klienta

Zakres:

- `client/veloprime_hybrid_app/lib/**`
- `client/veloprime_hybrid_app/test/**`
- `client/veloprime_hybrid_app/pubspec.yaml`
- `client/veloprime_hybrid_app/pubspec.lock`
- `client/veloprime_hybrid_app/windows/**`

Cel commitu:

- wydzielenie samej aplikacji desktopowej od zmian serwerowych i release workflow

Proponowany commit message:

- `feat: add flutter hybrid crm client for windows`

### 4. Strona pobrania i lekkie artefakty wdrozeniowe

Zakres:

- `src/app/download/page.tsx`
- `public/download/VeloPrime-CRM-Test.appinstaller`
- `public/download/install-test-certificate.ps1`
- `public/download/veloprime-crm-test-signing.cer`

Cel commitu:

- oddzielenie publicznej dystrybucji klienta od samego kodu aplikacji

Proponowany commit message:

- `feat: add public download flow for windows client`

### 5. Skrypty smoke i utrzymaniowe

Zakres:

- `scripts/cleanup-smoke-users.ps1`
- `scripts/deactivate-smoke-users.cjs`
- `scripts/smoke-account-flows.ps1`
- `scripts/smoke-lead-offer-pdf.ps1`

Cel commitu:

- zamkniecie operacyjnej warstwy testow i cleanupu poza glownym kodem produktu

Proponowany commit message:

- `chore: add smoke and cleanup scripts for crm flows`

## Pliki do wyjecia z glownego repo changesetu

Nie laczyc z powyzszymi commitami binarnych paczek:

- `public/download/versions/*.msix`
- `client/veloprime_hybrid_app/deploy/msix/artifacts/**`
- `client/veloprime_hybrid_app/deploy/*.zip`

Powod:

- sa ciezkie, slabo diffowalne i szybko zasmiecaja historie gita
- powinny miec osobny proces publikacji jako artefakty release, nie jako standardowy kod produktu

## Zasada praktyczna

Najpierw commity 1-5 na GitHub.
Potem osobny, kontrolowany proces publikacji binarek zgodnie z polityka w `docs/RELEASE_ASSET_POLICY.md`.