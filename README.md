# CRM VeloPrime

Osobny projekt CRM dla zespołu sprzedaży VeloPrime.

## Stack

- Next.js
- TypeScript
- Tailwind CSS
- App Router
- Prisma

## Start

```bash
npm install
npm run dev
```

## Prisma

```bash
npx prisma migrate deploy
npm run db:seed
```

Seed tworzy startowe konta użytkowników oraz wczytuje palety kolorów modeli z `data/byd-color-palettes.json` do tabel `SalesModelColorPalette` i `SalesModelColorOption`.

Konta startowe po seedzie:

- `admin@veloprime.pl` / `Admin123!`
- `dyrektor@veloprime.pl` / `Director123!`
- `manager@veloprime.pl` / `Manager123!`
- `handlowiec@veloprime.pl` / `Sales123!`

Po pierwszym logowaniu hasła tych kont powinny zostać zmienione lub zresetowane przez administratora.

## Smoke Test kont

Po uruchomieniu aplikacji w trybie developerskim można wykonać automatyczny smoke test kont i haseł:

```bash
npm run dev -- --hostname 127.0.0.1 --port 3005
npm run smoke:accounts
```

Skrypt testuje:

- logowanie administratora
- utworzenie nowego konta handlowca
- zmianę hasła przez użytkownika
- reset hasła przez administratora
- blokadę i odblokowanie konta
- ponowne logowanie po każdej zmianie

## Smoke Test lead -> oferta -> PDF

Po uruchomieniu aplikacji w trybie developerskim można wykonać automatyczny smoke test przepływu ofertowego:

```bash
npm run dev -- --hostname 127.0.0.1 --port 3005
npm run smoke:lead-offer-pdf
```

Skrypt testuje:

- pobranie danych bootstrap dla modułu ofertowego
- wybór istniejącego leada lub utworzenie leada awaryjnego
- utworzenie oferty powiązanej z leadem
- zapis aktualizacji oferty
- utworzenie wersji dokumentu PDF
- pobranie snapshotu dokumentu przez API
- otwarcie strony podglądu PDF z aktywną sesją

## Smoke Test klienta Flutter

Po uruchomieniu backendu w trybie developerskim można wykonać smoke test repozytoriów klienta Flutter:

```bash
npm run dev -- --hostname 127.0.0.1 --port 3005
flutter test --dart-define=RUN_API_SMOKE=true --dart-define=VELOPRIME_API_BASE_URL=http://127.0.0.1:3005 test/api_smoke_test.dart
```

Jeżeli Flutter jest instalowany przez Puro i nie ma go w `PATH`, użyj bezpośrednio `flutter.bat` z aktywnego środowiska, na przykład:

```bash
C:\Users\48510\.puro\envs\stable\flutter\bin\flutter.bat test --dart-define=RUN_API_SMOKE=true --dart-define=VELOPRIME_API_BASE_URL=http://127.0.0.1:3005 test/api_smoke_test.dart
```

Test sprawdza:

- logowanie klienta Flutter do backendu
- pobranie bootstrapu po zalogowaniu
- pobranie listy leadow i etapow
- utworzenie leada przez repozytorium klienta
- zmiane etapu leada
- dodanie wpisu do historii leada
- utworzenie oferty przez repozytorium klienta
- pobranie szczegółów oferty
- utworzenie wersji PDF
- pobranie snapshotu dokumentu oferty

## Runtime konfiguracja klienta Windows

Klient Flutter moze odczytac adres backendu bez przebudowy aplikacji. W katalogu z plikiem `veloprime_hybrid_app.exe` umiesc plik:

```json
{
	"baseUrl": "https://crm.veloprime.pl"
}
```

Domyslna nazwa pliku:

- `veloprime_client_config.json`

Klient szuka tego pliku:

- w aktualnym katalogu roboczym aplikacji
- w katalogu, w ktorym znajduje sie plik wykonywalny

Przyklad pliku wzorcowego znajduje sie w:

- `client/veloprime_hybrid_app/deploy/veloprime_client_config.example.json`

Jesli plik nie istnieje, klient korzysta z wartosci przekazanej przez `--dart-define=VELOPRIME_API_BASE_URL=...` albo z domyslnego `http://127.0.0.1:3000`.

## Environment

Skopiuj `.env.example` do `.env` i ustaw `DATABASE_URL` przed podpinaniem bazy danych.

## Założenia wersji startowej

- osobny panel pod subdomenę typu `crm.veloprime.pl`
- gotowość pod logowanie i role
- fundament pod leady, bazę samochodów, konfigurację cen i oferty PDF

## Role planowane

- Administrator
- Dyrektor
- Manager
- Handlowiec

## Dokumentacja domenowa

- `docs/SALES_CALCULATION_MODEL.md` - model kalkulacji sprzedaży, hierarchii prowizyjnej i reguł oferty
- `docs/HYBRID_CLIENT_IMPLEMENTATION_PLAN.md` - etapowy plan przejscia do klienta hybrydowego Windows + Android tablet
- `docs/DEPLOYMENT_WORKFLOW.md` - zasady wdrozen, w ktorych GitHub jest zrodlem prawdy, a Vercel tylko targetem build/deploy
- `docs/REPO_CHANGESET_PLAN.md` - proponowany podzial aktualnych zmian na male, czytelne commity
- `docs/REPO_CLEANUP_AUDIT.md` - audyt uzywanych, zduplikowanych i generowanych plikow przed cleanupem repo
- `docs/RELEASE_ASSET_POLICY.md` - polityka dla `public/download/` i binarnych paczek `.msix`

## Deployment

Obowiazuje workflow `GitHub -> Vercel`.

Nie wdrazamy produkcji bezposrednio z lokalnego workspace przez `vercel deploy`.

Kazda zmiana, ktora ma trafic na produkcje, musi najpierw znalezc sie w repozytorium GitHub. Dotyczy to rowniez plikow release w `public/download/`, jesli maja byc serwowane przez aplikacje webowa.

Podzial zmian na commity opisuje `docs/REPO_CHANGESET_PLAN.md`, a zasady dla artefaktow release opisuje `docs/RELEASE_ASSET_POLICY.md`.

## Moduły robocze

- `/pricing` - baza polityki cenowej i katalog modeli
- `/commissions` - prowizje dyrektora i managera synchronizowane z katalogiem modeli

## API pod klienta hybrydowego

- `GET /api/client/bootstrap` - dane startowe klienta lokalnego dla MVP ofertowego
- `GET /api/client/leads` - lista leadow, etapow i powiazanych ofert dla klienta lokalnego
- `POST /api/client/leads` - utworzenie nowego leada z poziomu klienta lokalnego
- `GET /api/client/leads/:leadId` - szczegoly pojedynczego leada wraz z etapami i powiazanymi ofertami
- `PATCH /api/client/leads/:leadId/stage` - zmiana etapu leada z poziomu klienta lokalnego
- `PATCH /api/client/leads/:leadId/salesperson` - przypisanie lub wyczyszczenie handlowca leada
- `POST /api/client/leads/:leadId/details` - dodanie komentarza lub informacji do historii leada
- `GET /api/client/users` - lista kont i przełożonych dla lokalnego modułu administracji
- `POST /api/client/users` - utworzenie konta z hasłem startowym lub hasłem tymczasowym
- `PATCH /api/client/users/:userId/status` - aktywacja lub blokada konta
- `POST /api/client/users/:userId/password-reset` - reset hasła użytkownika z poziomu administratora
- `POST /api/client/account/password` - zmiana hasła zalogowanego użytkownika
- `POST /api/client/offers` - utworzenie nowej oferty z poziomu klienta lokalnego
- `GET /api/client/offers/:offerId` - szczegoly pojedynczej oferty wraz z kalkulacja dla klienta lokalnego
- `PATCH /api/client/offers/:offerId` - bezpieczna aktualizacja podstawowych danych oferty z zachowaniem obecnej kalkulacji i konfiguracji
- `POST /api/client/offers/:offerId/lead` - przypiecie istniejacego leada do oferty z poziomu klienta lokalnego
- `GET /api/client/offers/:offerId/document` - snapshot dokumentu oferty i assety do lokalnego podgladu PDF
- `POST /api/client/offers/:offerId/pdf-version` - utworzenie nowej wersji dokumentu PDF oferty po stronie centrali
- `GET /api/updates/manifest` - pobranie opublikowanych wersji `DATA`, `ASSETS`, `APPLICATION`
- `POST /api/updates/compare` - porownanie wersji klienta lokalnego z wersjami opublikowanymi centralnie
- `POST /api/updates/publish` - publikacja nowej wersji przez administratora lub dyrektora
- `POST /api/offers/validate-finalization` - walidacja finalizacji oferty przed lokalnym generowaniem PDF
