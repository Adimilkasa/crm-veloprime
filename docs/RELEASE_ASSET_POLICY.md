# Release Asset Policy

## Cel

Utrzymac GitHub jako jedyne zrodlo prawdy, ale nie traktowac glownej historii gita jako magazynu dla duzych binarnych paczek `.msix`.

## Zasada glowna

Kod produktu, manifesty, konfiguracja pobierania i mala dokumentacja release sa wersjonowane w repozytorium.
Duze binarne paczki instalacyjne `.msix` nie powinny byc na stale commitowane do glownej galezi jako zwykle pliki projektu.

## Co zostaje w repo

W repo utrzymujemy:

- `src/app/download/page.tsx`
- `public/download/VeloPrime-CRM-Test.appinstaller`
- `public/download/install-test-certificate.ps1`
- `public/download/veloprime-crm-test-signing.cer`
- `data/update-manifest.json`
- kod API i konfiguracje potrzebne do publikacji oraz sprawdzania wersji

Powod:

- to sa lekkie pliki tekstowe lub male artefakty operacyjne
- ich historia w gicie jest czytelna
- sa czescia zachowania produkcyjnego aplikacji i strony pobrania

## Co nie powinno byc trzymane w glownej galezi

Nie trzymamy standardowo w glownej galezi:

- `public/download/versions/*.msix`

Powod:

- kazda wersja ma kilkadziesiat MB
- pliki binarne nie daja sensownego diffu
- szybko zwiekszaja rozmiar repo i kosztuja przy klonowaniu oraz CI

## Docelowy kanal dla `.msix`

Pliki `.msix` publikujemy jako artefakty releasowe w GitHub Releases przypisanych do tagu wersji.

To nadal spelnia zasade GitHub-first, bo:

- zrodlem prawdy pozostaje GitHub
- artefakt jest przypiety do konkretnego commitu i taga
- Vercel nie staje sie magazynem prawdy, tylko warstwa webowa moze linkowac do releasu z GitHub

## Zalecany przeplyw publikacji

1. Commitujemy do repo wszystkie zmiany kodu, manifestu i strony pobrania.
2. Wypychamy commit na GitHub.
3. Tagujemy wersje releasu klienta Windows.
4. Publikujemy `.msix` jako asset w GitHub Release dla tego taga.
5. Aktualizujemy `public/download/VeloPrime-CRM-Test.appinstaller`, aby wskazywal docelowy URL assetu releasu.
6. Commitujemy te lekkie zmiany tekstowe do repo i dopiero wtedy idzie wdrozenie `GitHub -> Vercel`.

## Operacyjny detal URL-i

W docelowym stanie rozdzielamy dwa adresy:

- `AppInstaller Uri` zostaje na `https://crm.veloprime.pl/download/VeloPrime-CRM-Test.appinstaller`
- `MainPackage Uri` wskazuje bezposrednio asset GitHub Release, np. `https://github.com/OWNER/REPO/releases/download/v0.1.2.0/veloprime_hybrid_app_0.1.2.0.msix`

Dzieki temu:

- strona pobrania i lekki manifest nadal sa wdrazane przez `GitHub -> Vercel`
- ciezka binarka nie siedzi juz w `main`
- Windows App Installer nadal zaczyna flow od stabilnego adresu `crm.veloprime.pl`

## Narzedzie do aktualizacji manifestu

Repo zawiera pomocniczy skrypt:

- `scripts/update-appinstaller-github-release.ps1`

Przyklad:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\update-appinstaller-github-release.ps1 -Version "0.1.2.0"
```

Skrypt:

- aktualizuje `MainPackage Uri`
- ustawia `Version` w `AppInstaller` i `MainPackage`
- domyslnie bierze repo z `git remote origin` i tag w formacie `v<wersja>`
- zostawia `AppInstaller Uri` na publicznym adresie `crm.veloprime.pl`, chyba ze podasz inny parametr `-AppInstallerUrl`

## Zasada przejsciowa

Jesli chwilowo trzeba utrzymac lokalny lub testowy obieg binarki, mozna wygenerowac `.msix` poza repo, ale nie powinno sie go commitowac do `main`, chyba ze user swiadomie zaakceptuje wyjatek dla konkretnego releasu.

## Wyjatek

Jesli w przyszlosci zapadnie swiadoma decyzja o trzymaniu binarek w repo, to tylko po jednej z dwoch zmian:

- przejsciu na Git LFS dla tych assetow
- wydzieleniu osobnego repo tylko na artefakty release

Bez takiej decyzji standardem pozostaje: repo przechowuje kod i lekkie pliki release, a `.msix` trafia do GitHub Releases.