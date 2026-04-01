# Plan przebudowy CRM VeloPrime

## Cel dokumentu

Ten dokument jest glownym punktem odniesienia dla przebudowy systemu.
Nie opieramy dalszej pracy na samej historii rozmow. Kazdy etap, decyzja i ryzyko musza byc odnotowane w dokumentach repo.

Ten plik odpowiada na pytania:

- co przebudowujemy
- po co to robimy
- jaka jest docelowa architektura
- jakie sa etapy realizacji
- jakie obszary zawsze trzeba sprawdzac przy kazdej zmianie

Powiazane dokumenty:

- `docs/REBUILD_DECISIONS.md` - rejestr zatwierdzonych decyzji
- `docs/REBUILD_BACKLOG.md` - backlog etapow i zadan
- `docs/REBUILD_CHECKPOINT.md` - ostatni stan projektu i punkt wznowienia pracy
- `docs/REBUILD_STAGE1_MODEL.md` - techniczny opis docelowego modelu Etapu 1
- `docs/SALES_CALCULATION_MODEL.md` - reguly biznesowe kalkulacji sprzedazy
- `docs/HYBRID_CLIENT_IMPLEMENTATION_PLAN.md` - zalozenia architektury klienta lokalnego i centrali

## Zalozenia bazowe

- Aplikacja desktopowa jest glownym interfejsem pracy dla handlowca i administratora.
- Warstwa web nie jest docelowym miejscem pracy operacyjnej zespolu.
- Backend pozostaje centralnym zrodlem prawdy dla danych, uprawnien, audytu, publikacji i walidacji.
- Synchronizacja `DATA`, `ASSETS` i `APPLICATION` pozostaje osobnym mechanizmem.
- Oferta klienta, podglad PDF, PDF, mail i publiczny link oferty musza korzystac z tego samego snapshotu danych.

## Docelowy model systemu

### Desktop

Zakres docelowy aplikacji:

- praca handlowca na leadach i ofertach
- konfiguracja oferty i kalkulacje
- podglad oferty i generowanie PDF
- administracja katalogiem aut
- administracja polityka cenowa
- administracja kolorami i materialami
- administracja uzytkownikami i struktura
- publikacja nowych wersji `DATA` i `ASSETS`

### Backend

Zakres docelowy centrali:

- uwierzytelnianie i role
- centralna baza danych
- zapis i odczyt katalogu, polityki cenowej, kolorow i assetow
- walidacja finalizacji oferty
- audyt i historia zmian
- generowanie snapshotow dokumentow oferty
- publiczny link oferty i wysylka email
- publikacja i porownanie wersji `DATA`, `ASSETS`, `APPLICATION`

## Gdzie jestesmy dzisiaj

Stan obecny, potwierdzony w analizie:

- katalog cen jest nadal mocno oparty o plaski arkusz `pricing-sheet`
- kolory sa utrzymywane osobno od glownego katalogu
- assety ofert sa mapowane przez manifest i aliasy modelu
- backend zna wiecej danych katalogowych niz obecnie konsumuje klient desktopowy
- generator oferty i warstwa PDF dzialaja, ale dalej skladaja dane z kilku miejsc

## Problem do rozwiazania

Przebudowa ma doprowadzic do jednego spojnego modelu:

- produkt sprzedazowy
- polityka cenowa
- kolory i doplaty
- materialy i assety
- snapshot oferty

Bez tego kazda kolejna zmiana bedzie wymagala poprawiania kilku rozdzielonych warstw, co zwiekszy ryzyko rozjazdu miedzy kalkulacja, PDF, mailem i podgladem w aplikacji.

## Zakres przebudowy

### Obszary wchodzace do przebudowy

- model danych katalogu sprzedazowego
- polityka cenowa i podzial puli marzowej
- model kolorow i doplat
- model materialow i assetow
- bootstrap i synchronizacja klienta desktopowego
- generator oferty
- snapshot dokumentu oferty
- zakladka podgladu PDF
- generator PDF
- wysylka email i publiczny link oferty
- role i widocznosc danych
- audyt, publikacja i wersjonowanie

### Obszary poza glownym celem

- rozbudowa webowego CRM jako codziennego UI dla handlowcow
- kosmetyczne dopracowywanie nieuzywanych ekranow webowych
- zmiany niezwiązane z glowna sciezka ofertowa i administracyjna

## Zasady prowadzenia przebudowy

1. Nie rozpoczynamy implementacji etapu bez zapisania zalozen i zakresu.
2. Pracujemy jednym etapem na raz: Copilot proponuje etap, uzytkownik zatwierdza albo koryguje, a implementacja rusza dopiero po decyzji.
2. Kazdy etap musi miec kryteria zakoncznia i liste testow.
3. Kazda zmiana oferty wymaga sprawdzenia calego lancucha: dane -> kalkulacja -> snapshot -> UI desktop -> podglad PDF -> PDF -> mail -> publiczny link -> synchronizacja.
4. Kazda decyzja biznesowa musi trafic do `REBUILD_DECISIONS.md` albo `SALES_CALCULATION_MODEL.md`.
5. Po kazdej wiekszej sesji aktualizujemy `REBUILD_CHECKPOINT.md`.

## Tryb pracy etapami

Kazdy etap prowadzimy wedlug tego samego schematu:

1. Copilot przygotowuje propozycje etapu.
2. Propozycja zawiera: cel, zakres, macierz wplywu, ryzyka, blokery, kryteria done i proponowany sposob weryfikacji.
3. Uzytkownik zatwierdza etap albo koryguje zalozenia.
4. Dopiero po zatwierdzeniu rozpoczyna sie implementacja.
5. Po zakonczeniu etapu aktualizujemy backlog, decyzje i checkpoint.

Nie laczymy kilku duzych etapow w jednej sesji bez osobnej decyzji uzytkownika.

## Szablon propozycji etapu

Kazda propozycja etapu powinna zawierac:

- cel biznesowy i techniczny
- zakres wchodzacy do etapu
- zakres swiadomie wyjety z etapu
- macierz wplywu na dane, backend, desktop, PDF, mail i synchronizacje
- ryzyka i decyzje blokujace
- definicje done
- sposob testowania albo walidacji

## Obowiazkowa macierz wplywu dla kazdego etapu

Przy kazdym etapie trzeba odpowiedziec, czy zmiana dotyka:

- modelu danych
- backend API
- synchronizacji `DATA`
- synchronizacji `ASSETS`
- klienta desktopowego Flutter
- kalkulacji ofertowej
- snapshotu oferty
- zakladki oferty PDF
- generatora PDF
- wysylki email
- publicznego linku oferty
- rol i uprawnien
- migracji danych
- testow i rollbacku

## Etapy przebudowy

### Etap 0 - Przygotowanie i decyzje

Cel:

- zamkniecie zalozen biznesowych i architektonicznych
- przygotowanie dokumentow prowadzacych przebudowe

Status:

- zakonczony

### Etap 1 - Model docelowy

Cel:

- zaprojektowanie docelowego modelu katalogu, polityki cenowej, kolorow, assetow i snapshotu oferty

Status:

- zakonczony i zatwierdzony jako baza do dalszych etapow; fundamenty modelu zostaly zapisane w schemacie i typach wspoldzielonych

Zakres proponowany:

- katalog sprzedazowy: marka, model, wersja sprzedazowa, rocznik, parametry techniczne, status aktywnosci, identyfikatory publikacji
- polityka cenowa: cena katalogowa, cena bazowa, pula marzowa, reguly struktury, ograniczenia rabatu i widocznosc danych
- kolory i doplaty: paleta per model lub rodzina modelowa, kolor bazowy, kolory opcjonalne, doplaty netto i brutto, zwiazek z oferta
- assety i materialy: galerie, PDF specyfikacji, branding, materialy dodatkowe, identyfikatory assetow i poziom przypiecia
- snapshot oferty: sekcja produktu, klienta, doradcy, cen, finansowania, wersji publikacji i danych wewnetrznych
- analiza wplywu na backend, synchronizacje, aplikacje desktopowa, zakladke PDF, generator PDF, mail i publiczny link oferty

Zakres swiadomie wyjety:

- implementacja nowych tabel, endpointow i migracji
- przebudowa widokow Flutter i komponentow webowych
- zmiana generatora PDF lub maila w kodzie
- publikacja nowej wersji aplikacji

Pytania blokujace do zamkniecia w tym etapie:

- brak otwartych blokad biznesowych dla Etapu 1

Przyjety kierunek dla assetow w v1:

- zdjecia i materialy wizualne sa przypisane do modelu
- kategorie zdjec sa stale: grafika glowna, zewnatrz, wnetrze, detale, premium
- PDF specyfikacji jest dobierany wedlug typu napedu wersji, na przyklad osobno dla `ELECTRIC` i `HYBRID`

Definicja done dla tego etapu:

- opisany jest docelowy model danych wysokiego poziomu
- fundamenty modelu zostaly zakodowane w `prisma/schema.prisma` i `src/lib/sales-catalog-model.ts`
- opisane sa granice odpowiedzialnosci desktopu i backendu w tym modelu
- wskazany jest wspolny snapshot oferty oraz jego sekcje
- opisana jest zasada odczytu oferty historycznej i swiadomego odswiezenia na nowym cenniku
- zaktualizowano backlog o zadania wynikajace z modelu docelowego
- otwarte decyzje blokujace sa wypisane jawnie do decyzji uzytkownika
- uzytkownik potwierdzil zamkniecie Etapu 1

Sposob walidacji:

- przeglad dokumentu przez uzytkownika
- przeglad `docs/REBUILD_STAGE1_MODEL.md`
- potwierdzenie, ze model obejmuje dane, kalkulacje, PDF, mail, link publiczny i synchronizacje
- akceptacja uzytkownika przed rozpoczeciem implementacji backendu i aplikacji

### Etap 2 - Kontrakty backendowe

Cel:

- przygotowanie lub przebudowa API, bootstrapu i publikacji wersji pod nowy model

Status:

- zakonczony po stronie backendu

Postep na teraz:

- dodano backendowy adapter katalogu z fallbackiem do legacy `pricing-sheet`
- przepieto ofertowanie i synchronizacje prowizji na wspolny adapter katalogu
- dodano migracje Prisma dla nowych tabel katalogu
- dodano helper synchronizacji legacy danych do nowych tabel katalogu, kolorow i assetow
- dodano publiczne kontrakty administracyjne pod `src/app/api/client/catalog/**`
- bootstrap klienta zwraca znormalizowany katalog marek, modeli, wersji, palet kolorow, podsumowan assetow i manifest publikacji
- publikacja `DATA` i `ASSETS` zapisuje snapshot rzeczywistego stanu katalogu i assetow
- ekrany Flutter dla administratora pozostaja poza tym krokiem

### Etap 3 - Moduly administracyjne w aplikacji

Cel:

- przeniesienie zarzadzania katalogiem i polityka do klienta desktopowego

Status:

- oczekuje

### Etap 4 - Generator oferty i snapshot

Cel:

- przepiecie logiki oferty, PDF i maili na nowy snapshot

Status:

- oczekuje

### Etap 5 - Migracja, testy i publikacja

Cel:

- bezpieczne przejscie z obecnego modelu na nowy bez utraty spojnosci ofert

Status:

- oczekuje

## Definicja zakonczonego etapu

Etap uznajemy za zamkniety dopiero wtedy, gdy:

- zalozenia sa zapisane i zatwierdzone
- kod jest wdrozony dla uzgodnionego zakresu
- zaktualizowano dokumenty powiazane
- wykonano testy techniczne i biznesowe dla etapu
- odnotowano ryzyka pozostawione na kolejny etap

## Sposob pracy z tym dokumentem

- ten plik opisuje plan wysokiego poziomu
- szczegolowe decyzje trafiaja do `REBUILD_DECISIONS.md`
- konkretne zadania i statusy trafiaja do `REBUILD_BACKLOG.md`
- ostatni stan rozmowy i wznowienia prac trafia do `REBUILD_CHECKPOINT.md`