# VeloPrime CRM MSIX Distribution Plan

## Cel

Docelowy test ma odwzorować realny przepływ użytkownika:

1. użytkownik wchodzi na `https://crm.veloprime.pl`
2. pobiera instalator Windows
3. uruchamia instalację aplikacji
4. loguje się na istniejące konto CRM
5. pracuje na centralnym backendzie

## Architektura wdrożenia

### 1. Backend centralny

Na serwerze muszą działać:

1. Next.js CRM
2. PostgreSQL
3. Prisma migration deploy
4. seed z kontami testowymi

Wymagany plik środowiskowy:

- [../../.env.test-production.example](../../.env.test-production.example)

Minimalny zestaw do uzupełnienia na serwerze:

1. `DATABASE_URL`
2. `AUTH_SECRET`

## Konta testowe

Do pierwszego pełnego testu można zostawić aktualne konta seedowe:

1. `admin@veloprime.pl` / `Admin123!`
2. `dyrektor@veloprime.pl` / `Director123!`
3. `manager@veloprime.pl` / `Manager123!`
4. `handlowiec@veloprime.pl` / `Sales123!`

## Budowa instalatora MSIX

Konfiguracja pakietu jest zapisana w [../pubspec.yaml](../pubspec.yaml).

### Wariant testowy z certyfikatem self-signed

1. Wygeneruj certyfikat:

```powershell
powershell -ExecutionPolicy Bypass -File .\client\veloprime_hybrid_app\deploy\msix\create-test-signing-cert.ps1 -Password "TU_WLASNE_HASLO"
```

2. Zbuduj MSIX pod produkcyjny lub testowy backend:

```powershell
powershell -ExecutionPolicy Bypass -File .\client\veloprime_hybrid_app\deploy\msix\build-msix.ps1 -BaseUrl "https://crm.veloprime.pl" -CertificatePath ".\client\veloprime_hybrid_app\deploy\msix\artifacts\cert\veloprime-crm-test-signing.pfx" -CertificatePassword "TU_WLASNE_HASLO"
```

Jesli chcesz od razu przygotowac manifest pod GitHub Releases, rozdziel URL manifestu i URL binarki:

```powershell
powershell -ExecutionPolicy Bypass -File .\client\veloprime_hybrid_app\deploy\msix\build-msix.ps1 -BaseUrl "https://crm.veloprime.pl" -PublishBaseUrl "https://crm.veloprime.pl/download" -PackageBaseUrl "https://github.com/OWNER/REPO/releases/download/v0.1.2.0" -CertificatePath ".\client\veloprime_hybrid_app\deploy\msix\artifacts\cert\veloprime-crm-test-signing.pfx" -CertificatePassword "TU_WLASNE_HASLO"
```

Lokalny build wygeneruje tymczasowe artefakty tutaj:

- [../deploy/msix/artifacts/package](../deploy/msix/artifacts/package)

To jest katalog roboczy do lokalnej publikacji i testu, nie canonical source w repo.

Plik do dalszej publikacji:

- `VeloPrime-CRM-Test.msix`

Jesli `-PackageBaseUrl` wskazuje GitHub Release, wygenerowany lokalnie `.appinstaller` bedzie nadal publikowal swoj wlasny adres pod `crm.veloprime.pl`, ale `MainPackage Uri` bedzie juz kierowal na asset releasu w GitHub.

## Publikacja na stronie

Najprostszy wariant testowy:

1. wgraj `VeloPrime-CRM-Test.msix` na `crm.veloprime.pl`
2. wystaw link do pobrania na stronie
3. opcjonalnie udostępnij też plik `.cer`, jeśli używasz self-signed certificate

Przykładowy kanał pobierania:

1. `https://crm.veloprime.pl/downloads/windows/VeloPrime-CRM-Test.msix`
2. `https://crm.veloprime.pl/downloads/windows/veloprime-crm-test-signing.cer`

## Publikacja przez GitHub Releases

Docelowy wariant dla `main`:

1. zbuduj paczke `.msix` lokalnie
2. wypchnij kod i manifesty do GitHub
3. utworz tag releasu, np. `v0.1.2.0`
4. dodaj `VeloPrime-CRM-Test.msix` jako asset releasu
5. przestaw `public/download/VeloPrime-CRM-Test.appinstaller` na URL assetu releasu:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\update-appinstaller-github-release.ps1 -Version "0.1.2.0"
```

Skrypt sam sprobuje wywnioskowac repo z `git remote origin` i zbuduje URL w formacie:

- `https://github.com/Adimilkasa/crm-veloprime/releases/download/v0.1.2.0/veloprime_hybrid_app_0.1.2.0.msix`

Mozesz nadpisac to parametrami `-Repo`, `-Tag`, `-AssetName` albo pelnym `-PackageUrl`, jesli dany release ma niestandardowy uklad.

6. po zweryfikowaniu publicznego URL assetu commitnij zaktualizowany `.appinstaller` razem z usunieciem `public/download/versions/*.msix`
7. wypchnij changeset do GitHub i pozwol `GitHub -> Vercel` wdrozyc juz lekki manifest bez repo-hostowanej binarki

## Ważna uwaga o podpisie

### Self-signed cert

Ten wariant nadaje się do testu, ale na komputerze testowym trzeba najpierw zaufać certyfikatowi `.cer`.

### Certyfikat komercyjny

Jeśli chcesz docelowo uniknąć ręcznego importu certyfikatu i zminimalizować ostrzeżenia Windows, potrzebny będzie komercyjny code-signing certificate. Po jego otrzymaniu wystarczy podmienić `CertificatePath`, `CertificatePassword` i `Publisher` w skrypcie build.

## Instalacja na drugim komputerze

Wariant testowy z self-signed cert:

1. pobierz `.cer`
2. zainstaluj certyfikat dla bieżącego użytkownika do `Trusted People` lub `Trusted Root Certification Authorities`
3. pobierz `.msix`
4. uruchom instalator
5. zainstaluj aplikację
6. zaloguj się kontem administratora

## Co jeszcze jest potrzebne do uruchomienia prawdziwego testu

Z tego repo nadal nie da się uruchomić realnej migracji produkcyjnej bez prawdziwego `DATABASE_URL`.

Gdy baza będzie gotowa, wykonaj na serwerze:

```powershell
npx prisma migrate deploy
npm run db:seed
```
