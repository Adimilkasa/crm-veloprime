# Rejestr decyzji przebudowy CRM VeloPrime

## Cel dokumentu

Ten plik przechowuje wszystkie decyzje, ktore maja pozostac zrodlem prawdy w trakcie przebudowy.
Kazda decyzja powinna byc krotka, jednoznaczna i zawierac wplyw na system.

## Jak uzupelniac wpisy

Kazdy wpis powinien miec:

- identyfikator, na przyklad `DEC-001`
- status: `proposed`, `accepted`, `replaced`, `rejected`
- date
- decyzje
- uzasadnienie
- wplyw na system
- powiazane dokumenty albo moduly

## Aktywne decyzje

### DEC-001

- Status: accepted
- Data: 2026-04-01
- Decyzja: Aplikacja desktopowa jest docelowym interfejsem pracy dla handlowca i administratora.
- Uzasadnienie: Zespol nie planuje finalnej pracy w webowym CRM, a klient lokalny ma przejac glowny workflow operacyjny i administracyjny.
- Wplyw na system: Nowe moduly administracyjne nalezy projektowac przede wszystkim w Flutterze, a web utrzymywac jako backend i warstwe uslugowa.
- Powiazania: `docs/REBUILD_PLAN.md`, `docs/HYBRID_CLIENT_IMPLEMENTATION_PLAN.md`

### DEC-002

- Status: accepted
- Data: 2026-04-01
- Decyzja: Backend pozostaje centralnym zrodlem prawdy dla danych, uprawnien, audytu, publikacji i walidacji finalizacji oferty.
- Uzasadnienie: Lokalny klient nie moze byc jedynym zrodlem prawdy dla krytycznych danych biznesowych i wersji publikacji.
- Wplyw na system: Zmiany administracyjne wykonywane w aplikacji musza byc zapisywane centralnie i publikowane do pozostalych klientow.
- Powiazania: `docs/REBUILD_PLAN.md`, `docs/HYBRID_CLIENT_IMPLEMENTATION_PLAN.md`

### DEC-003

- Status: accepted
- Data: 2026-04-01
- Decyzja: Oferta klienta, podglad PDF, PDF, mail i publiczny link musza korzystac z jednego snapshotu oferty.
- Uzasadnienie: Obecnie dane sa skladane z kilku warstw, co zwieksza ryzyko rozjazdu miedzy dokumentem, mailem i widokiem aplikacji.
- Wplyw na system: Kazda przebudowa generatora oferty musi obejmowac takze warstwe dokumentu, email i publicznego linku.
- Powiazania: `docs/REBUILD_PLAN.md`, `docs/SALES_CALCULATION_MODEL.md`

### DEC-004

- Status: accepted
- Data: 2026-04-01
- Decyzja: Przebudowa jest realizowana etapami, a kazdy etap wymaga osobnej propozycji i zatwierdzenia przed wdrozeniem.
- Uzasadnienie: Przy dlugiej przebudowie trzeba ograniczyc ryzyko gubienia ustalen i niekontrolowanego rozszerzania zakresu.
- Wplyw na system: Copilot nie rozszerza samowolnie zakresu zmian, a po kazdym etapie aktualizowane sa plan, backlog, decyzje i checkpoint.
- Powiazania: `docs/REBUILD_PLAN.md`, `docs/REBUILD_BACKLOG.md`, `docs/REBUILD_CHECKPOINT.md`

### DEC-005

- Status: accepted
- Data: 2026-04-01
- Decyzja: Katalog sprzedazowy ma byc grupowany jako marka -> model -> wersja sprzedazowa.
- Uzasadnienie: Handlowiec ma najpierw wybierac marke, potem widziec modele tej marki, a nastepnie konkretne wersje wyposazenia tego modelu.
- Wplyw na system: Model danych, UI desktop, bootstrap klienta, API katalogowe i snapshot oferty musza opierac sie na tej hierarchii.
- Powiazania: `docs/REBUILD_PLAN.md`, `docs/REBUILD_STAGE1_MODEL.md`

### DEC-006

- Status: accepted
- Data: 2026-04-01
- Decyzja: Typ napedu jest zrodlem prawdy na poziomie wersji, ale przy modelu handlowiec ma widziec zagregowana informacje, czy model wystepuje jako elektryk, hybryda albo spalinowy.
- Uzasadnienie: Uzytkownik chce grupowac oferte po marce i modelu, ale jednoczesnie juz na liscie modelu widziec podstawowa informacje o rodzaju napedu.
- Wplyw na system: Model katalogu, desktopowe listy wyboru, bootstrap i snapshot produktu musza obsluzyc zarowno dane wersji, jak i skrot informacyjny na poziomie modelu.
- Powiazania: `docs/REBUILD_STAGE1_MODEL.md`

### DEC-007

- Status: accepted
- Data: 2026-04-01
- Decyzja: Doplata za kolor nie wchodzi do puli rabatowo-prowizyjnej i jest doliczana jako odrebna dodatkowa kwota do samochodu.
- Uzasadnienie: Uzytkownik jednoznacznie wskazal, ze kolor za doplata ma byc liczony poza pula rabatowa i prowizyjna.
- Wplyw na system: Kalkulacja oferty, model kolorow, snapshot oferty, PDF i widok wewnetrzny musza rozdzielac cene pojazdu od doplat kolorystycznych.
- Powiazania: `docs/SALES_CALCULATION_MODEL.md`, `docs/REBUILD_STAGE1_MODEL.md`

### DEC-008

- Status: accepted
- Data: 2026-04-01
- Decyzja: W v1 stan dostepnosci do nowych ofert jest zarzadzany przez archiwizacje calego modelu samochodu, a nie przez osobne przelaczniki aktywnosci dla marki, wersji i kolorow.
- Uzasadnienie: W obecnym modelu sprzedazowym wpisywane pozycje sa traktowane jako aktywne. Gdy model przestaje byc sprzedawany, wystarczy zarchiwizowac go na liscie samochodow, aby zniknal z nowych ofert.
- Wplyw na system: UI administratora powinno udostepniac akcje `Archiwizuj` i `Przywroc` na poziomie modelu. Wersje i kolory dzialaja w ramach archiwizacji modelu. Stare oferty nadal musza poprawnie odtwarzac zarchiwizowane dane.
- Powiazania: `docs/REBUILD_STAGE1_MODEL.md`, `docs/REBUILD_PLAN.md`

### DEC-009

- Status: accepted
- Data: 2026-04-01
- Decyzja: Zrodlem prawdy dla cen katalogowych i bazowych w panelu administratora sa kwoty netto, a kwoty brutto sa liczone automatycznie przy VAT `23%`.
- Uzasadnienie: Uzytkownik potwierdzil, ze w modelu v1 chce wprowadzac ceny netto, a VAT ma byc doliczany automatycznie. To ogranicza ryzyko rozjazdu miedzy recznie wpisanym netto i brutto.
- Wplyw na system: Formularze administratora, model cenowy, snapshot oferty, import danych i kalkulacja musza traktowac netto jako wartosc kanoniczna, a brutto jako wartosc wyliczana.
- Powiazania: `docs/REBUILD_STAGE1_MODEL.md`, `docs/SALES_CALCULATION_MODEL.md`

### DEC-010

- Status: accepted
- Data: 2026-04-01
- Decyzja: W v1 dla hybrydy zapisujemy obowiazkowo moc glowna, pojemnosc silnika spalinowego oraz pojemnosc baterii.
- Uzasadnienie: Uzytkownik wskazal, ze dla hybrydy te trzy parametry powinny byc zawsze wpisywane i dostepne w katalogu oraz ofercie.
- Wplyw na system: Formularz wersji, snapshot produktu, UI wyboru wersji i dokument oferty musza przewidywac te pola jako standard dla napedu `HYBRID`.
- Powiazania: `docs/REBUILD_STAGE1_MODEL.md`, `docs/REBUILD_PLAN.md`

### DEC-011

- Status: accepted
- Data: 2026-04-01
- Decyzja: Zdjecia i materialy wizualne sa przypisywane do modelu samochodu, a nie do wersji wyposazenia; wyjatek stanowi PDF specyfikacji, ktory moze byc rozny dla typu napedu `ELECTRIC` i `HYBRID`.
- Uzasadnienie: Uzytkownik chce utrzymywac jeden zestaw materialow wizualnych dla calego modelu, a roznicowanie dokumentacji technicznej ma wynikac tylko z rodzaju napedu, nie z wersji wyposazenia.
- Wplyw na system: Model assetow, publikacja paczek `ASSETS`, generator oferty, PDF i podglad dokumentu musza obslugiwac stale kategorie zdjec na poziomie modelu oraz dobor PDF specyfikacji na podstawie `powertrainType` wybranej wersji.
- Powiazania: `docs/REBUILD_STAGE1_MODEL.md`, `docs/REBUILD_PLAN.md`, `docs/REBUILD_BACKLOG.md`

### DEC-012

- Status: accepted
- Data: 2026-04-01
- Decyzja: Utworzona oferta zawsze otwiera sie z zapisanego snapshotu historycznego. Gdy oferta jest niewazna albo oparta o nieaktualny cennik, system pokazuje komunikat o koniecznosci weryfikacji aktualnych cen i wymaga swiadomej akcji handlowca, aby odswiezyc oferte na nowym cenniku. Proces ten nie moze byc automatyczny.
- Uzasadnienie: Handlowiec ma miec pelna swiadomosc, kiedy korzysta z historycznej oferty, a kiedy przechodzi na aktualne warunki handlowe. Stara oferta musi pozostac czytelna jako zapis tego, co bylo pokazane klientowi wczesniej.
- Wplyw na system: Logika ofert, UI desktop, snapshot oferty, walidacja waznosci, PDF, mail, publiczny link i audyt musza rozdzielac odczyt historycznej oferty od swiadomego odswiezenia na aktualnych danych. Odswiezenie nie nadpisuje starego snapshotu i powinno tworzyc nowy byt roboczy powiazany z poprzednia oferta.
- Powiazania: `docs/REBUILD_STAGE1_MODEL.md`, `docs/REBUILD_PLAN.md`, `docs/REBUILD_BACKLOG.md`, `docs/SALES_CALCULATION_MODEL.md`

## Otwarte decyzje do zamkniecia

### DEC-OPEN-001

- Status: replaced
- Data: 2026-04-01
- Decyzja: Ustalic, czy doplata za kolor wchodzi do puli rabatowo-prowizyjnej, czy jest doliczana poza pula.
- Uzasadnienie: Ta decyzja bezposrednio zmienia kalkulacje marzy, maksymalnego rabatu i prezentacji ceny koncowej.
- Wplyw na system: Model cenowy, kalkulacja oferty, PDF, widok wewnetrzny, testy.
- Powiazania: `docs/SALES_CALCULATION_MODEL.md`

Zastapione przez: `DEC-007`

### DEC-OPEN-002

- Status: replaced
- Data: 2026-04-01
- Decyzja: Ustalic, czy PDF specyfikacji i galerie sa przypisywane do modelu, wersji, czy obu poziomow.
- Uzasadnienie: To determinuje model assetow i sposob publikacji paczek `ASSETS`.
- Wplyw na system: Katalog, assety, generator oferty, PDF, synchronizacja.
- Powiazania: `docs/REBUILD_PLAN.md`

Zastapione przez: `DEC-011`

### DEC-OPEN-003

- Status: replaced
- Data: 2026-04-01
- Decyzja: Ustalic zasady ponownego przeliczania starej oferty po zmianie cennika lub polityki.
- Uzasadnienie: Trzeba jednoznacznie rozdzielic odtworzenie snapshotu od swiadomego przeliczenia na aktualnych danych.
- Wplyw na system: Logika ofert, historia wersji, audyt, UI desktop, testy.
- Powiazania: `docs/SALES_CALCULATION_MODEL.md`, `docs/REBUILD_PLAN.md`

Zastapione przez: `DEC-012`

### DEC-OPEN-004

- Status: replaced
- Data: 2026-04-01
- Decyzja: Ustalic, czy zrodlem prawdy dla cen katalogowych i bazowych w panelu administratora sa kwoty netto czy brutto.
- Uzasadnienie: VAT jest obecnie staly i wynosi 23%, ale system nie powinien dopuszczac do rozjazdu miedzy recznie wpisanym netto i brutto.
- Wplyw na system: Formularze administratora, model cenowy, kalkulacja oferty, snapshot i import danych.
- Powiazania: `docs/REBUILD_STAGE1_MODEL.md`

Zastapione przez: `DEC-009`

### DEC-OPEN-005

- Status: replaced
- Data: 2026-04-01
- Decyzja: Ustalic minimalny zakres danych technicznych dla hybrydy w v1: tylko jedna moc glowna czy rowniez osobne pole dla silnika spalinowego.
- Uzasadnienie: Uzytkownik chce zapisywac moc i pojemnosc baterii dla hybrydy, ale trzeba ustalic minimalny poziom szczegolowosci prezentowanej w katalogu i ofercie.
- Wplyw na system: Model katalogu, formularz administratora, UI wyboru wersji, snapshot i PDF.
- Powiazania: `docs/REBUILD_STAGE1_MODEL.md`

Zastapione przez: `DEC-010`