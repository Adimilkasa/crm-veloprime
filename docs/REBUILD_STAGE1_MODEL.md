# Etap 1 - Model docelowy katalogu i oferty

Status: zakonczony i zatwierdzony 2026-04-01; fundamenty kodowe dodane do schematu i typow wspoldzielonych

## Cel dokumentu

Ten dokument rozpisuje techniczny model docelowy dla pierwszego etapu przebudowy.
Nie jest to jeszcze implementacja tabel ani endpointow. To jest specyfikacja, ktora ma zamknac zaleznosci i zakres przed pracami programistycznymi.

## Zakres etapu 1

Etap obejmuje opis techniczny dla:

- hierarchii katalogu sprzedazowego
- parametrow technicznych produktu
- polityki cenowej
- kolorow i doplat
- miejsca na assety i materialy
- snapshotu oferty
- zaleznosci miedzy backendem, desktopem, PDF, mailem i synchronizacja

Poza zakresem tego etapu pozostaje jeszcze szczegolowy model assetow graficznych i PDF specyfikacji jako osobny podetap implementacyjny. Na tym etapie trzeba jednak zarezerwowac dla nich miejsce w modelu.

## 1. Hierarchia katalogu sprzedazowego

Docelowa hierarchia katalogu:

1. `Brand`
2. `SalesModel`
3. `SalesVersion`

Relacje:

- jedna marka ma wiele modeli
- jeden model nalezy do jednej marki
- jeden model ma wiele wersji sprzedazowych
- jedna wersja nalezy do jednego modelu

### 1.1 Brand

Minimalny zestaw pol:

- `id`
- `code` - stabilny kod techniczny, na przyklad `BYD`
- `name` - nazwa wyswietlana, na przyklad `BYD`
- `sortOrder`
- `createdAt`
- `updatedAt`

Zastosowanie:

- administrator dodaje marke raz
- handlowiec najpierw wybiera marke
- po wyborze marki aplikacja pokazuje tylko modele z tej marki

### 1.2 SalesModel

Minimalny zestaw pol:

- `id`
- `brandId`
- `code` - stabilny kod modelu, na przyklad `SEAL_U`
- `name` - nazwa modelu, na przyklad `Seal U`
- `marketingName` - opcjonalna nazwa handlowa do oferty i materialow
- `status` - `ACTIVE`, `ARCHIVED`
- `sortOrder`
- `createdAt`
- `updatedAt`

Pola pomocnicze do wyswietlania w wyborze handlowca:

- `availablePowertrains` - lista wynikajaca z aktywnych wersji, na przyklad `ELECTRIC`, `HYBRID`
- `defaultColorPaletteId`
- `defaultAssetBundleId`

Wazna zasada:

- zrodlem prawdy dla rodzaju napedu jest wersja sprzedazowa
- model przechowuje tylko zagregowana informacje do wygodnego wyswietlenia na liscie
- archiwizacja modelu blokuje jego dostepnosc w nowych ofertach

To pozwala pokazac handlowcowi juz na poziomie modelu, czy model wystepuje jako hybryda, elektryk albo spalinowy, bez utraty dokladnosci na poziomie wersji.

Rekomendacja UX dla administratora:

- na glownej liscie samochodow widoczna jest akcja `Archiwizuj`
- zarchiwizowany model nie jest dostepny przy tworzeniu nowych ofert
- zarchiwizowany model pozostaje widoczny w historii i starych snapshotach ofert

## 1.4 Pola widoczne dla administratora vs pola techniczne

W v1 nie chcemy przetechnologizowac panelu administratora. Dlatego trzeba od poczatku rozdzielic dwa poziomy:

- pola, ktore administrator widzi i uzupelnia recznie
- pola techniczne, ktore system tworzy albo liczy sam

### Brand - pola widoczne dla administratora

- `name` - nazwa marki, na przyklad `BYD`
- `sortOrder` - kolejnosc wyswietlania marki na liscie, jesli bedzie potrzebna

### Brand - pola techniczne systemu

- `id`
- `code` - generowany automatycznie ze stabilnej nazwy technicznej
- `createdAt`
- `updatedAt`

Administrator nie powinien recznie wpisywac `code`, chyba ze w przyszlosci pojawi sie potrzeba integracji z zewnetrznym katalogiem.

### SalesModel - pola widoczne dla administratora

- `brandId` - wybierane z listy marek
- `name` - nazwa modelu, na przyklad `Seal U`
- `marketingName` - opcjonalna nazwa handlowa, jesli ma sie roznic od nazwy modelu
- `sortOrder` - kolejnosc wyswietlania modelu w marce

### SalesModel - pola techniczne systemu

- `id`
- `code` - generowany automatycznie
- `status` - zmieniany przez akcje `Archiwizuj` albo `Przywroc`
- `availablePowertrains` - liczone automatycznie z wersji modelu
- `defaultColorPaletteId`
- `defaultAssetBundleId`
- `createdAt`
- `updatedAt`

Administrator nie powinien ustawiac recznie pola `status` z poziomu formularza. Zmiana dostepnosci modelu powinna odbywac sie przez jedna czytelna akcje na liscie: `Archiwizuj` albo `Przywroc`.

### SalesVersion - pola widoczne dla administratora

- `name` - nazwa wersji wyposazenia, na przyklad `Active`
- `year`
- `powertrainType` - `ELECTRIC`, `HYBRID`, `ICE`
- `driveType` - jesli chcemy pokazywac naped osi
- `systemPowerHp`
- `batteryCapacityKwh` - dla elektryka i hybrydy, jesli wystepuje
- `combustionEnginePowerHp` - opcjonalnie dla hybrydy lub spalinowego
- `engineDisplacementCc` - opcjonalnie dla hybrydy lub spalinowego
- `rangeKm` - opcjonalnie
- `notes` - opcjonalne uwagi wewnetrzne
- `sortOrder`

### SalesVersion - pola techniczne systemu

- `id`
- `modelId`
- `code` - generowany automatycznie
- `createdAt`
- `updatedAt`

### SalesColor - pola widoczne dla administratora

- `name` - nazwa koloru
- `isBaseColor` - czy kolor jest bazowy
- `hasSurcharge` - czy kolor jest platny
- `surchargeNet`
- `sortOrder`

### SalesColor - pola techniczne systemu

- `id`
- `modelId`
- `code` - generowany automatycznie albo uzupelniany z kodu fabrycznego, jesli bedzie dostepny
- `finishType` - opcjonalne pole systemowe do dalszego rozwoju

W praktyce panel administratora dla koloru powinien byc prosty:

1. wpisujesz nazwe koloru
2. zaznaczasz, czy jest bazowy
3. zaznaczasz, czy jest za doplata
4. jesli jest za doplata, wpisujesz kwote

### SalesPricing - pola widoczne dla administratora

- `listPriceNet`
- `basePriceNet`
- `vatRate` - w v1 domyslnie `23%`
- `pricingEffectiveFrom` - opcjonalnie, jesli chcemy planowac wejscie cen
- `pricingEffectiveTo` - opcjonalnie

### SalesPricing - pola techniczne systemu

- `marginPoolNet`
- `marginPoolGross`
- `pricingStatus`
- `createdAt`
- `updatedAt`

Pula marzowa nie powinna byc wpisywana recznie. System musi liczyc ja automatycznie z ceny katalogowej i bazowej.

## 1.5 Minimalny formularz administratora w v1

Z perspektywy administratora v1 formularz powinien byc mozliwie prosty i podzielony na sekcje:

1. `Marka`
2. `Model`
3. `Wersje`
4. `Kolory`
5. `Ceny`

### Sekcja Marka

Administrator wpisuje tylko:

- nazwe marki

Opcjonalnie:

- kolejnosc wyswietlania

### Sekcja Model

Administrator wpisuje tylko:

- wybor marki
- nazwe modelu
- opcjonalna nazwe handlowa

Na liscie modeli ma osobna akcje:

- `Archiwizuj`
- `Przywroc`

### Sekcja Wersje

Administrator wpisuje dla kazdej wersji:

- nazwe wersji wyposazenia
- rocznik
- typ napedu
- moc
- baterie, jesli wystepuje
- opcjonalnie dane silnika spalinowego

### Sekcja Kolory

Administrator wpisuje dla kazdego koloru:

- nazwe koloru
- czy jest bazowy
- czy jest za doplata
- kwote doplaty, jesli jest platny

### Sekcja Ceny

Administrator wpisuje dla wersji:

- cene katalogowa
- cene bazowa
- opcjonalnie zakres obowiazywania ceny

System sam liczy:

- brutto z netto przy VAT `23%`
- pule marzowa
- wartosci do snapshotu i kalkulacji oferty

## 1.6 Cykl zycia oferty historycznej i oferty odswiezonej

W modelu v1 trzeba wyraznie rozdzielic dwa przypadki:

1. odczyt oferty historycznej
2. swiadome odswiezenie oferty na aktualnym cenniku

### Odczyt oferty historycznej

Zasada:

- kazda zapisana oferta otwiera sie z wlasnego snapshotu
- oferta historyczna pokazuje dokladnie te dane, ktore obowiazywaly w chwili jej zapisania
- zmiana cen, polityki, kolorow albo materialow nie moze automatycznie zmienic tresci juz zapisanej oferty

To dotyczy takze:

- widoku w aplikacji
- zakladki oferty PDF
- wygenerowanego PDF
- tresci maila
- publicznego linku oferty

### Oferta niewazna albo oparta o nieaktualny cennik

Jesli system wykryje, ze oferta jest niewazna albo korzysta z nieaktualnych danych handlowych, powinien:

- nadal pozwolic otworzyc oferte historyczna
- pokazac wyrazny komunikat typu `Zweryfikuj aktualne ceny. Aby przygotowac aktualna propozycje dla klienta, odswiez oferte.`
- nie wykonywac zadnej automatycznej aktualizacji danych oferty

### Odswiezenie oferty przez handlowca

Odswiezenie oferty jest swiadoma akcja handlowca. Jej celem nie jest nadpisanie historii, tylko przygotowanie nowej propozycji na aktualnym cenniku.

Zasady:

- akcja odswiezenia jest wykonywana recznie przez handlowca
- system pobiera aktualne dane katalogowe, cenowe i materialowe
- stary snapshot pozostaje bez zmian
- wynik odswiezenia powinien tworzyc nowy byt roboczy powiazany z poprzednia oferta, aby zachowac ciaglosc historii i audytu

W implementacji mozna to pokazac jako:

- nowa wersje oferty
albo
- nowa oferte powiazana z oferta zrodlowa

Istotne jest nie nazewnictwo techniczne, tylko zasada biznesowa:

- historia pozostaje nienaruszona
- przejscie na nowy cennik nie dzieje sie automatycznie
- handlowiec musi wiedziec, ze przygotowuje nowa aktualna propozycje

### 1.3 SalesVersion

Minimalny zestaw pol:

- `id`
- `modelId`
- `code` - stabilny kod wersji, na przyklad `SEAL_U_ACTIVE_2026`
- `name` - nazwa wersji wyposazenia, na przyklad `Active`
- `year`
- `powertrainType` - `ELECTRIC`, `HYBRID`, `ICE`
- `sortOrder`
- `createdAt`
- `updatedAt`

Wersja sprzedazowa jest faktycznym produktem wybieranym do oferty. To na tym poziomie musza byc zapisane ceny, technikalia i powiazania z polityka cenowa.

W v1 wersja nie dostaje osobnego statusu archiwizacji w panelu administratora. Jej dostepnosc do nowych ofert wynika z tego, czy model nadrzedny jest aktywny czy zarchiwizowany.

## 2. Parametry techniczne produktu

## 2.1 Zasada ogolna

Techniczne dane auta musza byc zapisane na poziomie `SalesVersion`, bo to wersja jest faktycznie sprzedawana i wyceniana.

### 2.2 Proponowany zestaw pol technicznych

- `powertrainType` - `ELECTRIC`, `HYBRID`, `ICE`
- `driveType` - opcjonalnie `FWD`, `RWD`, `AWD`
- `systemPowerHp` - glowna moc pokazywana handlowcowi i klientowi
- `batteryCapacityKwh` - dla elektryka i hybrydy, jesli wystepuje
- `combustionEnginePowerHp` - dla hybrydy i spalinowego, jesli potrzebne do opisu
- `engineDisplacementCc` - dla spalinowego lub hybrydy, jesli potrzebne
- `rangeKm` - opcjonalnie do dalszego rozwoju materialow handlowych
- `notes` - wewnetrzne uwagi techniczne

### 2.3 Jak to dziala dla roznych typow napedu

#### Elektryk

Minimalnie wypelniamy:

- `powertrainType = ELECTRIC`
- `systemPowerHp`
- `batteryCapacityKwh`

#### Hybryda

Minimalnie wypelniamy:

- `powertrainType = HYBRID`
- `systemPowerHp`
- `batteryCapacityKwh`
- `engineDisplacementCc`

W v1 przyjmujemy, ze dla hybrydy obowiazkowo zapisujemy:

- glowna moc ukladu
- pojemnosc baterii
- pojemnosc silnika spalinowego

#### Spalinowy

Minimalnie wypelniamy:

- `powertrainType = ICE`
- `systemPowerHp`
- `engineDisplacementCc`

### 2.4 Rekomendacja UX dla wyboru produktu

Sciezka wyboru w aplikacji:

1. handlowiec wybiera marke
2. system pokazuje modele z tej marki
3. przy modelu wyswietlane sa badge z dostepnymi typami napedu
4. po wyborze modelu system pokazuje wersje wyposazenia
5. przy wersji widoczny jest dokladny typ napedu, moc i kluczowe technikalia

To ogranicza chaos na liscie modeli i pozwala zachowac logiczne grupowanie danych.

## 3. Polityka cenowa

## 3.1 Zasada ogolna

Polityka cenowa musi byc podpieta do wersji sprzedazowej. Wersja ma miec jednoznacznie zdefiniowane ceny katalogowe i bazowe, a pula marzowa jest liczona automatycznie.

### 3.2 Minimalny zestaw pol cenowych

- `listPriceNet`
- `listPriceGross`
- `basePriceNet`
- `basePriceGross`
- `vatRate`
- `marginPoolNet`
- `marginPoolGross`
- `pricingStatus` - na przyklad `DRAFT`, `PUBLISHED`, `ARCHIVED`
- `pricingEffectiveFrom`
- `pricingEffectiveTo`

### 3.3 Zasady kalkulacji

- pula marzowa nie jest wpisywana recznie
- pula marzowa jest liczona jako `listPrice - basePrice`
- handlowiec korzysta z puli pozostalej po odjeciu udzialu dyrektora i menadzera
- prowizja handlowca jest reszta puli po odjeciu rabatu klienta

### 3.4 Doplata za kolor

Decyzja juz ustalona:

- doplata za kolor nie wchodzi do puli rabatowo-prowizyjnej
- doplata za kolor jest dodatkowa kwota doliczana do ceny samochodu

Skutek techniczny:

- doplata za kolor musi byc liczona osobno od ceny wersji
- rabat i prowizja nie moga konsumowac doplaty kolorystycznej
- w snapshotcie oferty trzeba rozdzielic kwote bazowego produktu od kwoty doplaty za kolor

### 3.5 Przyjete zrodlo prawdy dla netto i brutto

W v1 przyjmujemy:

- administrator wpisuje `listPriceNet` i `basePriceNet`
- system automatycznie liczy `listPriceGross` i `basePriceGross` po `vatRate = 23%`
- w ofercie i snapshotcie przechowujemy obie wartosci wynikowe

To oznacza, ze netto jest wartoscia kanoniczna dla cennika, a brutto jest wartoscia wynikowa do prezentacji i kalkulacji klientowskiej.

## 4. Kolory i doplaty

## 4.1 Poziom przypiecia

Podstawowa rekomendacja:

- paleta kolorow jest przypisana do modelu
- oferta wybiera konkretny kolor przy wybranej wersji tego modelu

To pasuje do obecnej logiki biznesowej, wedlug ktorej kolor nie tworzy osobnego produktu dla kazdej wersji.

### 4.2 Minimalny model koloru

- `id`
- `modelId`
- `name`
- `code` - stabilny identyfikator techniczny
- `finishType` - opcjonalnie `SOLID`, `METALLIC`, `PEARL`, `MATTE`
- `isBaseColor`
- `hasSurcharge`
- `surchargeNet`
- `surchargeGross`
- `sortOrder`

### 4.3 Zasady administracyjne

Administrator powinien moc:

1. dodac kolor do modelu
2. oznaczyc, czy kolor jest bazowy
3. oznaczyc, czy kolor jest za doplata
4. wpisac kwote doplaty, jesli kolor jest platny
5. ustawic kilka kolorow dla jednego modelu

W v1 kolor nie ma osobnego przelacznika aktywnosci. Jesli model zostaje zarchiwizowany, cala jego paleta przestaje byc dostepna do nowych ofert.

### 4.4 Zasady ofertowe

- kolor jest wybierany po wyborze wersji
- jesli kolor ma doplate, system dolicza ja do ceny koncowej poza pula marzowa
- oferta klienta pokazuje wybrany kolor i doplate, jesli wystepuje
- widok wewnetrzny pokazuje dodatkowo, ze doplata nie podlega rabatowaniu z puli

## 5. Assety i materialy

## 5.1 Co trzeba przewidziec juz teraz

Chociaz szczegolowy etap assetowy bedzie realizowany pozniej, juz teraz model musi przewidziec miejsce na:

- grafike glowna modelu
- galerie zdjec zewnetrznych
- galerie zdjec wewnetrznych
- galerie detali
- grafiki premium jako wstawki marketingowe
- PDF specyfikacji zalezne od typu napedu modelu
- materialy brandingowe
- opcjonalne materialy dodatkowe

### 5.2 Minimalny model logiczny

Proponowane byty logiczne:

- `AssetBundle` - zestaw materialow
- `AssetFile` - pojedynczy plik

Relacje przyjete dla v1:

- model ma jeden glowny `AssetBundle` dla wszystkich materialow graficznych
- wersja nie dostaje osobnej galerii zdjec ani osobnych grafik marketingowych
- PDF specyfikacji jest wybierany wedlug typu napedu wystepujacego w danym modelu

W praktyce oznacza to:

- zdjecia i materialy wizualne sa wspolne dla calego modelu, na przyklad `Seal U`
- roznicowanie na poziomie wersji nie dotyczy galerii ani wstawek marketingowych
- wyjatek dotyczy PDF specyfikacji, ktory ma byc rozny dla wariantu `ELECTRIC` i `HYBRID`, jesli oba wystepuja w ramach danego modelu

### 5.3 Minimalne pola logiczne pakietu materialow

- `id`
- `scopeType` - w v1 domyslnie `MODEL`
- `scopeId`
- `primaryImageId`
- `exteriorImageIds`
- `interiorImageIds`
- `detailImageIds`
- `premiumImageIds`
- `specPdfByPowertrain` - mapa, na przyklad `ELECTRIC -> pdf`, `HYBRID -> pdf`
- `logoImageId`
- `isActive`
- `assetsVersionTag`

### 5.4 Kategorie materialow w v1

W modelu assetow trzeba od razu przewidziec stale kategorie, zeby generator oferty nie szukal zdjec po nazwach folderow ani recznych aliasach:

- `primary` - grafika glowna modelu
- `exterior` - zdjecia pokazujace samochod z zewnatrz
- `interior` - zdjecia pokazujace samochod wewnatrz
- `details` - ujecia detali samochodu
- `premium` - marketingowe wstawki premium

Skutek techniczny:

- administrator przypisuje zdjecia od razu do odpowiedniej kategorii
- generator oferty i PDF wiedza z gory, z jakiej puli maja pobierac material do konkretnej sekcji
- nie trzeba recznie wyszukiwac zdjec do sekcji dokumentu przy kazdej zmianie szablonu

### 5.5 PDF specyfikacji a typ napedu

W v1 nie roznicujemy galerii po wersjach wyposazenia, ale trzeba przewidziec roznice w PDF specyfikacji dla typu napedu.

Przyjeta zasada:

- model moze miec osobny PDF specyfikacji dla `ELECTRIC`
- model moze miec osobny PDF specyfikacji dla `HYBRID`
- wybor PDF w ofercie wynika z `powertrainType` wybranej wersji

To oznacza, ze przyklad `Seal U` moze miec:

- wspolne zdjecia dla calego modelu
- jeden PDF specyfikacji dla wariantu elektrycznego
- drugi PDF specyfikacji dla wariantu hybrydowego

## 6. Snapshot oferty

## 6.1 Zasada glowna

Snapshot musi byc wspolnym zrodlem prawdy dla:

- widoku oferty w aplikacji
- zakladki podgladu PDF
- wygenerowanego PDF
- maila
- publicznego linku oferty

### 6.2 Sekcje snapshotu

#### Produkt

- `brandName`
- `modelName`
- `versionName`
- `year`
- `powertrainType`
- `systemPowerHp`
- `batteryCapacityKwh`
- `combustionEnginePowerHp`
- `engineDisplacementCc`

#### Kolor

- `selectedColorName`
- `selectedColorCode`
- `isBaseColor`
- `colorSurchargeNet`
- `colorSurchargeGross`

#### Ceny

- `listPriceNet`
- `listPriceGross`
- `basePriceNet`
- `basePriceGross`
- `marginPoolNet`
- `marginPoolGross`
- `discountAmountNet`
- `discountAmountGross`
- `discountPercent`
- `finalVehiclePriceNet`
- `finalVehiclePriceGross`
- `finalOfferPriceNet`
- `finalOfferPriceGross`

Rozroznienie jest celowe:

- `finalVehiclePrice*` dotyczy ceny auta po rabacie, bez doplat dodatkowych
- `finalOfferPrice*` dotyczy calosci dokumentu, czyli auto plus doplaty poza pula, na przyklad kolor

#### Wewnetrzne dane prowizyjne

- `directorShareNet`
- `directorShareGross`
- `managerShareNet`
- `managerShareGross`
- `salespersonCommissionNet`
- `salespersonCommissionGross`
- `availableDiscountNet`
- `availableDiscountGross`

#### Finansowanie

- `customerType`
- `financingVariant`
- `termMonths`
- `downPaymentAmount`
- `buyoutPercent`
- `buyoutAmount`
- `estimatedInstallment`
- `financingDisclaimer`

#### Materialy

- `assetBundleId`
- `assetsVersion`
- `primaryImageUrl`
- `specPdfUrl`
- `galleryUrls`

#### Wersje publikacji i audit

- `dataVersion`
- `assetsVersion`
- `applicationVersion`
- `generatedAt`
- `generatedByUserId`
- `generatedByUserRole`

## 7. Macierz zaleznosci i wplywu

## 7.1 Backend

Backend musi obsluzyc:

- nowy model katalogu i relacji marka -> model -> wersja
- nowy model kolorow i doplat
- nowy model cenowy i zasady wyliczania puli
- nowy snapshot oferty
- wersjonowanie i publikacje `DATA` oraz `ASSETS`

## 7.2 Desktop

Desktop musi obsluzyc:

- formularze administratora do marki, modelu, wersji, cen i kolorow
- wybor produktu przez handlowca w sekwencji marka -> model -> wersja
- pokazywanie badge typu napedu przy modelach
- wybor koloru i doliczanie doplaty poza pula
- korzystanie z nowego snapshotu oferty

## 7.3 Podglad oferty i PDF

Zakladka oferty PDF i generator PDF musza:

- czytac dane z jednego snapshotu
- pokazywac technikalia odpowiednie dla typu napedu
- odrozniac cene auta od doplat dodatkowych, jesli to potrzebne w prezentacji
- korzystac z poprawnie przypietego pakietu assetow

## 7.4 Mail i publiczny link

Mail oraz publiczny link oferty musza:

- korzystac z tego samego snapshotu co PDF
- nie wykonywac wlasnych niezaleznych wyliczen cenowych
- odtwarzac wlasciwe materialy i dane techniczne produktu

## 7.5 Synchronizacja

Synchronizacja musi rozrozniac:

- publikacje `DATA` - katalog, ceny, kolory, reguly
- publikacje `ASSETS` - materialy graficzne i PDF
- publikacje `APPLICATION` - kod klienta

Snapshot oferty powinien zapisywac, na jakich wersjach `DATA` i `ASSETS` zostal wygenerowany.

## 8. Decyzje juz ustalone w tym etapie

### Ustalono

1. desktop jest glownym interfejsem pracy handlowca i administratora
2. katalog ma byc grupowany jako marka -> model -> wersja
3. przy modelu handlowiec ma widziec, czy model wystepuje jako hybryda, elektryk albo spalinowy
4. techniczne dane produktu sa zapisywane na poziomie wersji
5. kolor jest wybierany w ofercie i nalezy do palety modelu
6. doplata za kolor nie wchodzi do puli rabatowo-prowizyjnej
7. PDF, mail i publiczny link maja korzystac z jednego snapshotu oferty

### Nadal otwarte

1. czy zrodlem prawdy dla cen w panelu administratora ma byc netto czy brutto
2. czy dla hybrydy w v1 pokazujemy tylko jedna moc glowna, czy takze oddzielna moc silnika spalinowego
3. czy assety w v1 przypinamy domyslnie do modelu z opcjonalnym nadpisaniem na wersji

## 9. Rekomendacja do decyzji uzytkownika

Rekomenduje przyjac nastepujacy wariant v1:

1. zrodlem prawdy dla cen sa kwoty netto, a brutto liczy system po `vatRate`
2. model ma domyslny pakiet assetow, a wersja moze go nadpisac tylko gdy potrzeba
3. dla hybrydy pokazujemy jedna moc glowna `systemPowerHp`, a dodatkowe pole silnika spalinowego traktujemy jako opcjonalne

Ten wariant jest najmniej ryzykowny do pierwszej implementacji i nie zamyka drogi do rozbudowy.