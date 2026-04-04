# Deployment Workflow

## Zasada nadrzedna

GitHub jest jedynym zrodlem prawdy dla kodu i plikow wdrozeniowych.
Vercel sluzy tylko do budowania i uruchamiania tego, co jest w repozytorium.

Nie wykonujemy produkcyjnych wdrozen bezposrednio z lokalnego katalogu przez `vercel deploy`.

## Obowiazujacy przeplyw

1. Zmieniamy kod lokalnie.
2. Uruchamiamy lokalna weryfikacje: `npm run lint`, `npm run build`, potrzebne smoke testy.
3. Sprawdzamy `git status` i upewniamy sie, ze commit zawiera tylko zamierzone zmiany.
4. Commitujemy zmiany do repozytorium.
5. Wypychamy commit na GitHub.
6. Vercel wdraza wersje z GitHub, a nie z lokalnego workspace.

Przy buildzie produkcyjnym, jesli `DATABASE_URL` jest ustawione w srodowisku, uruchamiamy tez `prisma migrate deploy` przed `next build`.
To zabezpiecza wdrozenia, w ktorych kod wymaga nowej schemy bazy, na przyklad dla trwałych leadow i historii komentarzy.

## Czego nie robimy

- nie wdrazamy produkcji poleceniem `vercel deploy` z lokalnego katalogu
- nie traktujemy aktualnego stanu na Vercel jako zrodla prawdy
- nie mieszamy kodu produktu z lokalnymi logami, screenshotami i buildami

## Artefakty lokalne

Do repo nie powinny trafac lokalne pliki tymczasowe, w szczegolnosci:

- logi typu `tailwindcss-*.log`, `vercel-deploy.log`
- lokalne screenshoty robocze w `screeny/`
- buildy Fluttera z `client/veloprime_hybrid_app/build/`

## Artefakty release klienta Windows

Jesli pliki w `public/download/` maja byc czescia produkcyjnego wdrozenia, musza trafic do GitHub w normalnym commicie przed wdrozeniem.

To oznacza:

- najpierw aktualizacja manifestu, strony download i plikow release w repo
- potem commit i push
- dopiero potem wdrozenie na Vercel z GitHub

Szczegolowa polityka dla assetow release jest opisana w `docs/RELEASE_ASSET_POLICY.md`.

W skrocie:

- lekkie pliki release i konfiguracja zostaja w repo
- duze binarne paczki `.msix` powinny trafic do GitHub Releases, nie do glownej galezi jako zwykle pliki projektu

### Build MSIX bez szukania starego hasla PFX

Skrypt `client/veloprime_hybrid_app/deploy/msix/build-msix.ps1` ma obslugiwac standardowy flow release bez recznego szukania sekretu do historycznego pliku `.pfx`.

Obowiazujacy flow:

- skrypt najpierw probuje znalezc certyfikat pasujacy do `public/download/veloprime-crm-test-signing.cer` w `Cert:\CurrentUser\My`
- jesli znajdzie matching prywatny klucz, eksportuje tymczasowy `.pfx` tylko na czas builda i sam nadaje mu jednorazowe haslo
- dopiero gdy nie znajdzie certyfikatu w magazynie, trzeba jawnie podac `-CertificatePath` i `-CertificatePassword`

To oznacza, ze na maszynie release wystarczy miec poprawnie zainstalowany cert z prywatnym kluczem; nie trzeba pamietac starego hasla do repozytoryjnego `.pfx`.

### Unikanie sztucznego podbijania wersji przez msix:publish

Ten sam skrypt domyslnie czysci `client/veloprime_hybrid_app/deploy/msix/artifacts/publish/` przed `msix:publish`.

Powod:

- stare pliki w `publish/versions/` potrafia wymusic interaktywne podbicie wersji ponad wartosc podana w `-MsixVersion`
- czysty katalog publish utrzymuje `msix:publish` w trybie deterministycznym

Jesli z jakiegos powodu chcesz zachowac historyczne pliki publish, uzyj jawnie przelacznika `-PreservePublishArtifacts`.

## Sytuacje awaryjne

Jesli pojawia sie presja na szybki hotfix, i tak najpierw zapisujemy zmiane w repo i dopiero z repo wdrazamy produkcje.

Wyjatek operacyjny bez GitHub moze byc tylko tymczasowa akcja ratunkowa, po ktorej natychmiast trzeba odtworzyc identyczny stan w repo. Taki tryb nie jest standardem pracy.