# Backlog przebudowy CRM VeloPrime

## Cel dokumentu

Ten plik przechowuje etapy i zadania wykonawcze. Nie opisuje calej architektury, tylko konkretna prace do zrobienia.

## Statusy

- `todo` - jeszcze nie rozpoczetie
- `in-progress` - aktywnie realizowane
- `blocked` - wymaga decyzji albo zaleznosci
- `done` - zakonczone i sprawdzone

## Etap 0 - Przygotowanie

### B-001

- Status: done
- Temat: Ustalenie modelu pracy dokumentowanej dla przebudowy.
- Wynik: Powstaly dokumenty `REBUILD_PLAN`, `REBUILD_DECISIONS`, `REBUILD_BACKLOG`, `REBUILD_CHECKPOINT`.
- Kryterium done: Dokumenty sa w repo i beda aktualizowane po kolejnych sesjach.

### B-002

- Status: done
- Temat: Uzupelnienie listy otwartych decyzji biznesowych.
- Zakres:
  - zasady przeliczania starych ofert
  - ewentualne doprecyzowanie zasad modelu assetow w v1
- Blokery: brak

### B-003

- Status: done
- Temat: Ustalenie trybu pracy etapami z obowiazkowym zatwierdzeniem zakresu.
- Wynik: Kazdy etap ma byc osobno proponowany, zatwierdzany i zamykany checkpointem.
- Kryterium done: Zasada zostala zapisana w planie i rejestrze decyzji.

## Etap 1 - Model docelowy

Cel etapu:

- opisanie docelowego modelu systemu przed rozpoczeciem implementacji
- zamkniecie granic odpowiedzialnosci miedzy desktopem, backendem i synchronizacja
- wskazanie decyzji biznesowych, bez ktorych nie wolno ruszac kolejnych etapow

Status etapu:

- done

### B-101

- Status: done
- Temat: Zaprojektowanie docelowego modelu katalogu sprzedazowego.
- Zakres:
  - marka
  - model
  - wersja sprzedazowa
  - parametry techniczne
  - status aktywnosci
  - identyfikatory synchronizacji
- Blokery: brak

### B-102

- Status: done
- Temat: Zaprojektowanie modelu polityki cenowej.
- Zakres:
  - ceny katalogowe z netto jako zrodlem prawdy
  - ceny bazowe z netto jako zrodlem prawdy
  - pula marzowa
  - reguly dyrektora i menadzera
  - ograniczenia rabatu handlowca
- Blokery: brak

### B-103

- Status: done
- Temat: Zaprojektowanie modelu kolorow i doplat.
- Zakres:
  - paleta per model
  - kolor bazowy
  - kolory opcjonalne
  - doplaty netto i brutto
  - powiazanie z materialami
- Blokery: brak

### B-104

- Status: done
- Temat: Zaprojektowanie modelu assetow i materialow.
- Zakres:
  - kategorie zdjec per model
  - PDF specyfikacji zalezny od typu napedu
  - logo i materialy brandingowe
  - identyfikatory assetow
  - wersjonowanie paczek `ASSETS`
- Blokery: brak

### B-105

- Status: done
- Temat: Zaprojektowanie snapshotu oferty.
- Zakres:
  - sekcja klienta
  - sekcja doradcy
  - sekcja wewnetrzna
  - sekcja produktu
  - sekcja cenowa
  - sekcja finansowania
  - wersje `DATA` i `ASSETS`
- Blokery: model docelowy katalogu i polityki

### B-106

- Status: done
- Temat: Przygotowanie macierzy wplywu etapu 1.
- Zakres:
  - model danych
  - backend API
  - synchronizacja `DATA`
  - synchronizacja `ASSETS`
  - aplikacja desktopowa
  - zakladka PDF
  - generator PDF
  - mail i link publiczny
  - role i migracja danych
- Blokery: brak

### B-107

- Status: done
- Temat: Zamkniecie decyzji blokujacych dla modelu docelowego.
- Zakres:
  - zasady przeliczania starych ofert
  - ewentualne doprecyzowanie technicznego wariantu modelu assetow
- Blokery: brak

### B-108

- Status: done
- Temat: Zakodowanie fundamentow Etapu 1 w schemacie i modelach wspoldzielonych.
- Zakres:
  - rozszerzenie `prisma/schema.prisma` o docelowe byty katalogu, cen, kolorow i assetow
  - dodanie wspoldzielonego modelu TypeScript dla nowego katalogu i snapshotu oferty
  - zachowanie kompatybilnosci z obecnym runtime bez przepinania jeszcze API i Fluttera
- Blokery: brak

## Etap 2 - Kontrakty i synchronizacja

### B-201

- Status: done
- Temat: Przebudowa bootstrapu klienta desktopowego.
- Postep:
  - backend korzysta juz z adaptera nowego katalogu z fallbackiem do legacy danych
  - `pricingOptions` dla ofert sa budowane przez wspolna warstwe katalogu
  - bootstrap zwraca juz znormalizowany katalog marek, modeli, wersji, palet kolorow, podsumowan assetow i manifest publikacji

### B-204

- Status: done
- Temat: Backendowy adapter nowego katalogu i migracja fundamentow runtime.
- Zakres:
  - nowy adapter katalogu po stronie backendu z fallbackiem do `pricing-sheet`
  - wspolny odczyt katalogu dla ofert i prowizji
  - helper synchronizacji legacy danych do nowych tabel katalogu
  - migracja Prisma dla nowych tabel `SalesBrand`, `SalesModel`, `SalesVersion`, `SalesVersionPricing`, `SalesModelColor`, `SalesModelAssetBundle`, `SalesAssetFile`
- Blokery: brak

### B-202

- Status: done
- Temat: API do administracji katalogiem, cenami, kolorami i assetami z poziomu aplikacji.
- Zakres:
  - endpoint `workspace` dla administratora
  - CRUD dla marek, modeli i wersji
  - zarządzanie rekordami cenowymi wraz z publikacją i archiwizacją
  - zarządzanie kolorami modelu
  - zarządzanie pakietem assetów modelu i plikami
  - uruchamianie synchronizacji legacy danych do nowego katalogu
- Kryterium done:
  - endpointy są dostępne pod `src/app/api/client/catalog/**`
  - operacje używają wspólnej warstwy `src/lib/catalog-admin.ts`
  - build przechodzi po wdrożeniu

### B-203

- Status: done
- Temat: Publikacja i porownywanie wersji `DATA` i `ASSETS`.
- Zakres:
  - publikacja `DATA` i `ASSETS` zapisuje snapshot aktualnego katalogu lub pakietow assetow
  - porownanie wersji zwraca rowniez snapshot publikacji dla klienta
  - publikacja blokuje sie, gdy brak danych do opublikowania
- Kryterium done:
  - manifest przechowuje snapshot publikacji
  - bootstrap zwraca manifest z rozszerzonymi informacjami o publikacji
  - build przechodzi po wdrozeniu

## Etap 3 - Aplikacja desktopowa

### B-301

- Status: done
- Temat: Moduly administratora dla katalogu i polityki cenowej.
- Wynik:
  - zakladka `Polityka cenowa` w Flutterze zostala przebudowana z arkusza legacy do workspace administratora opartego o `catalog/workspace`
  - administrator moze zarzadzac markami, modelami, wersjami i rekordami cenowymi oraz uruchamiac synchronizacje legacy
  - widocznosc modulu w shellu zostala zawężona do roli `ADMIN`, zgodnie z backendowym API katalogu
- Kryterium done: przebudowany modul przechodzi analize Fluttera bez nowych bledow w obszarze pricing

### B-302

- Status: done
- Temat: Moduly administratora dla kolorow i materialow.
- Wynik:
  - zakladka `Polityka cenowa` w Flutterze zostala rozszerzona o sekcje kolorow modelu i materialow modelu
  - administrator moze dodawac, edytowac i usuwac kolory modelu z doplatami netto i brutto
  - administrator moze zarzadzac pakietem materialow modelu, tagiem wersji assetow oraz plikami w kategoriach `PRIMARY`, `EXTERIOR`, `INTERIOR`, `DETAILS`, `PREMIUM`, `SPEC_PDF`, `LOGO`, `OTHER`
  - workspace katalogu dostal tez panel aktywnego ciagu wyboru marka -> model -> wersja, zeby uproscic prace administratora
  - workspace katalogu zostal przebudowany na jawny, samochodocentryczny przeplyw bez auto-wyboru pierwszego modelu i wersji
  - dodawanie materialow modelu obsluguje wybor pliku z dysku oraz przeciagnij i upusc
- Kryterium done: nowe sekcje przechodza analize Fluttera bez nowych bledow w obszarze pricing

### B-303

- Status: done
- Temat: Moduly administratora dla publikacji i kontroli wersji.
- Wynik:
  - w Flutterze dodano osobny modul administratora do przegladu manifestu aktualizacji i publikacji `DATA`, `ASSETS` oraz `APPLICATION`
  - administrator widzi opublikowane wersje, lokalne wersje klienta, priorytet, autora, podsumowanie oraz snapshot publikacji
  - shell udostepnia modul `Publikacje` tylko dla roli `ADMIN`
- Kryterium done: modul przechodzi analize Fluttera bez nowych bledow we wlasnym zakresie; pozostaja jedynie stare info-linty shella i placeholdera

### B-304

- Status: done
- Temat: Przebudowa generatora oferty na nowy model.
- Wynik:
  - istniejaca zakladka oferty w Flutterze korzysta juz z wyboru marka -> model -> wersja -> kolor
  - konfiguracja zapisuje kolor i doplate za kolor poza pula rabatowo-prowizyjna
  - lokalny preview oferty korzysta z tego samego klucza katalogowego i typu napedu przy fallbacku assetow
- Kryterium done: generator oferty przechodzi analize Fluttera bez nowych bledow w obszarze offers

## Etap 4 - Dokument oferty

### B-401

- Status: done
- Temat: Przepiecie zakladki oferty PDF na wspolny snapshot.
- Wynik:
  - preview dokumentu korzysta ze wspolnego snapshotu dokumentu i resolvera assetow zgodnego z katalogiem oraz typem napedu
  - lokalny preview zostal ujednolicony z nowa logika fallbacku assetow

### B-402

- Status: done
- Temat: Przepiecie generatora PDF na wspolny snapshot.
- Wynik:
  - backendowy dokument PDF korzysta z tego samego snapshotu i katalogowego resolvera materialow
  - smoke test lead -> oferta -> wersja PDF -> dokument -> strona PDF zakonczyl sie sukcesem

### B-403

- Status: done
- Temat: Przepiecie maila i publicznego linku oferty na wspolny snapshot.
- Wynik:
  - publiczny link oferty korzysta ze wspolnego snapshotu i przeszedl lokalna weryfikacje na realnej ofercie smoke
  - sciezka maila korzysta z tego samego snapshotu i resolvera assetow; lokalna probna wysylka przechodzi teraz przez developerski outbox bez potrzeby konfiguracji SMTP

## Etap 5 - Migracja i testy

### B-501

- Status: done
- Temat: Plan migracji obecnych danych do nowego modelu.
- Wynik:
  - dodano runbook migracyjny w `docs/REBUILD_MIGRATION_RUNBOOK.md`
  - dodano powtarzalny smoke sync `npm run smoke:catalog-sync`

### B-502

- Status: todo
- Temat: Testy porownawcze starej i nowej kalkulacji.

### B-503

- Status: done
- Temat: Testy spojnosci UI desktop -> PDF -> mail -> link publiczny.
- Postep:
  - smoke sync katalogu legacy -> bootstrap przeszedl poprawnie (`SYNC_OK brands=1 models=8 versions=14 pricing=14`)
  - smoke test PDF przeszedl poprawnie
  - publiczny link oferty zostal zweryfikowany na realnej ofercie smoke
  - lokalna wysylka maila zostala zweryfikowana przez developerski outbox w `.mail-outbox/`

### B-504

- Status: todo
- Temat: Plan publikacji pierwszej wersji po przebudowie.