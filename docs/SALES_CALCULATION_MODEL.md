# Model kalkulacji sprzedaży CRM VeloPrime

## Cel

CRM liczy ofertę dla konfiguracji sprzedażowej auta, a nie dla konkretnego egzemplarza stojącego na placu.

Ścieżka wyboru produktu:

- marka
- model
- wersja

Opcjonalne parametry oferty:

- typ klienta: firma lub klient prywatny
- rocznik
- kolor bazowy lub kolor dodatkowo płatny
- wariant finansowania
- okres finansowania
- wpłata własna
- wykup

System nie wymaga pól takich jak VIN, stock number, lokalizacja auta, status placowy ani przebieg.

## Główne role i odpowiedzialność

### Administrator

- ustala cenę bazową dla każdej wersji auta
- ustala ceny katalogowe netto i brutto
- ustala bazowy kolor i dopłatę za kolory opcjonalne dla danego modelu
- zarządza strukturą użytkowników

### Dyrektor

- może odkładać część puli marżowej dla swojej struktury
- reguła może być zdefiniowana jako kwota albo procent
- reguła może być ustawiona dla marki, modelu albo konkretnej wersji

### Menadżer

- może odkładać część puli marżowej dla swojego zespołu
- reguła może być zdefiniowana jako kwota albo procent
- reguła może być ustawiona dla marki, modelu albo konkretnej wersji

### Handlowiec

- wybiera produkt i buduje ofertę
- może udzielić klientowi rabatu tylko z puli pozostałej po odjęciu udziału dyrektora i menadżera
- jego prowizja jest resztą puli po wszystkich wcześniejszych potrąceniach i po rabacie dla klienta

## Widoczność danych w ofercie

### Dokument dla klienta

Oferta generowana dla klienta pokazuje wyłącznie:

- cenę katalogową
- cenę po rabacie
- rabat procentowy
- rabat kwotowy
- informacje o finansowaniu jako propozycję

Oferta dla klienta nie pokazuje:

- ceny bazowej
- prowizji dyrektora
- prowizji menadżera
- prowizji handlowca

### Widoczność wewnętrzna

- menadżer nie powinien widzieć prowizji dyrektora
- handlowiec nie powinien widzieć prowizji menadżera ani dyrektora
- pełna kalkulacja marży pozostaje danymi wewnętrznymi CRM

## Podstawowy model cenowy

Dla każdej konfiguracji produktowej musimy przechowywać:

- marka
- model
- wersja
- rocznik
- typ napędu
- moc
- cena katalogowa brutto
- cena katalogowa netto
- cena bazowa brutto
- cena bazowa netto

Różnica między ceną katalogową a ceną bazową tworzy pulę marżową.

### Wzory bazowe

Niech:

- $K$ oznacza cenę katalogową
- $B$ oznacza cenę bazową
- $P$ oznacza pulę marżową

Wtedy:

$$
P = K - B
$$

System powinien liczyć pulę automatycznie. Pole opisane jako rabat w imporcie nie powinno być źródłem prawdy biznesowej, jeśli da się je obliczyć z cen bazowych i katalogowych.

## Hierarchiczny podział puli

Niech:

- $P$ oznacza pulę całkowitą
- $D$ oznacza udział dyrektora
- $M$ oznacza udział menadżera
- $R$ oznacza rabat udzielony klientowi
- $H$ oznacza prowizję handlowca

Kalkulacja przebiega sekwencyjnie:

$$
P_1 = P - D
$$

$$
P_2 = P_1 - M
$$

$$
H = P_2 - R
$$

Warunek bezpieczeństwa:

$$
H \ge 0
$$

To oznacza, że system nie może pozwolić, aby suma udziału dyrektora, udziału menadżera i rabatu klienta przekroczyła dostępną pulę marżową.

## Typ klienta i wybór netto lub brutto

### Klient prywatny

Główna kalkulacja i decyzje handlowe powinny być oparte o ceny brutto.

### Firma

Główna kalkulacja i decyzje handlowe powinny być oparte o ceny netto, ale oferta może nadal pokazywać obie wartości.

W praktyce system powinien przechowywać oba zestawy wartości i wyliczać pulę dla odpowiedniego typu klienta.

## Dopłata za kolor

Dopłata za kolor niestandardowy:

- jest definiowana na poziomie marki i modelu
- nie jest definiowana per egzemplarz
- może być doliczana jednorazowo do oferty

Przykład:

- BYD Dolphin Surf: dopłata 3000 zł
- BYD Atto 2: dopłata 3400 zł
- BYD Seal 6: dopłata 5000 zł

W ramach jednego modelu możemy mieć:

- jeden kolor bazowy w cenie 0 zł
- wiele kolorów opcjonalnych z tą samą dopłatą

Różne modele tej samej marki mogą mieć różne dopłaty za lakier.

Kolor jest wybierany na etapie oferty, a nie jako osobny rekord katalogowy dla każdej wersji.

## Finansowanie

Oferta musi wspierać konfigurację finansowania przez handlowca.

Minimalne pola finansowania:

- okres finansowania w miesiącach: 24, 36, 48, 60, 71
- wpłata własna kwotowa albo procentowa
- wykup procentowy
- wartość pojazdu do finansowania po rabacie

### Reguły wykupu

- dla 71 miesięcy wykup nie może być większy niż 20%
- dla 60 miesięcy wykup nie może być większy niż 30%
- dla 48 miesięcy wykup nie może być większy niż 40%
- dla 36 miesięcy wykup nie może być większy niż 50%
- dla 24 miesięcy wykup nie może być większy niż 60%

Okres 12 miesięcy nie jest wspierany.

### Sposób wprowadzania wpłaty własnej

Handlowiec może wprowadzić wpłatę własną:

- procentowo, na przykład 10% lub 20%
- kwotowo, na przykład 20000 zł

System powinien zapisać obie postacie:

- tryb wejścia
- wartość źródłową wpisaną przez handlowca
- wyliczoną wartość kwotową i procentową do snapshotu oferty

### Charakter wyliczeń finansowania

Wyliczenia finansowania prezentowane w ofercie mają charakter szacunkowy i poglądowy.

Wygenerowana oferta musi zawierać zastrzeżenie, że:

- przedstawione warunki finansowania są propozycją
- nie stanowią wiążącej oferty w rozumieniu przepisów prawa
- warunki finansowe są weryfikowane indywidualnie na podstawie zdolności finansowej klienta
- wyliczenia służą zobrazowaniu wariantu finansowania, a nie gwarancji uzyskania finansowania

### Model leasingu 120%

Na potrzeby CRM przyjmujemy, że leasing `120%` oznacza:

- łączny koszt leasingu wynosi 120% wartości pojazdu
- różnica między 120% a 100% wartości pojazdu stanowi koszt finansowania

Przykład:

- wartość pojazdu: 100000 zł
- leasing 120%: łącznie do zapłaty 120000 zł
- koszt finansowania: 20000 zł

### Uproszczony algorytm wyliczenia raty

Niech:

- $V$ oznacza wartość pojazdu przyjętą do finansowania
- $F$ oznacza współczynnik leasingu, domyślnie $1.20$
- $W_w$ oznacza wpłatę własną kwotową
- $W_k$ oznacza wykup kwotowy
- $N$ oznacza liczbę miesięcy

Wtedy:

$$
K_{total} = V \cdot F
$$

$$
K_{rat} = K_{total} - W_w - W_k
$$

$$
Rata = \frac{K_{rat}}{N}
$$

Jest to uproszczony model poglądowy, zgodny z wymaganiem biznesowym, że oferta ma prezentować szacunkową propozycję finansowania, a nie harmonogram prawny lub księgowy od leasingodawcy.

## Struktura danych do wdrożenia

### 1. Katalog produktów sprzedażowych

Tabela lub model powinien przechowywać konfigurację katalogową:

- brand
- model
- version
- year
- powertrain
- powerKw lub powerHp
- listPriceGross
- listPriceNet
- basePriceGross
- basePriceNet
- isActive

Ta struktura zastępuje magazynowy model pojazdu w miejscach, gdzie celem jest kalkulacja sprzedaży.

### 2. Ustawienia marki

Tabela lub model powinien przechowywać ustawienia wspólne dla marki:

- brand
- defaultCurrency
- isActive

### 2a. Paleta kolorów modelu

Tabela lub model powinien przechowywać reguły koloru dla konkretnego modelu:

- brand
- model
- baseColorName
- optionalColorSurchargeGross
- optionalColorSurchargeNet opcjonalnie
- isActive

Tabela podrzędna powinna przechowywać konkretne kolory:

- paletteId
- colorName
- isBase
- surchargeGross
- surchargeNet opcjonalnie
- sortOrder
- isActive

### 2b. Ustawienia finansowania

Tabela lub model powinien przechowywać parametry potrzebne do kalkulacji propozycji finansowania:

- allowedTerms
- buyoutLimitByTerm
- leaseTotalFactor, domyślnie `1.20`
- disclaimerTemplate
- isActive

### 3. Struktura podległości użytkowników

System powinien wiedzieć:

- jaki handlowiec należy do którego menadżera
- jaki menadżer należy do którego dyrektora

Minimalne pola:

- userId
- managerUserId
- directorUserId

Alternatywnie można przechowywać bezpośredniego przełożonego i wyliczać łańcuch zależności.

### 4. Reguły udziału prowizyjnego dla dyrektora i menadżera

Tabela lub model powinien wspierać:

- roleScope: DIRECTOR albo MANAGER
- ownerUserId
- brand
- model opcjonalnie
- version opcjonalnie
- deductionType: AMOUNT albo PERCENT
- deductionValue
- applyOrder
- isActive

Reguła bardziej szczegółowa powinna mieć priorytet nad bardziej ogólną.

Priorytet dopasowania:

1. marka + model + wersja
2. marka + model
3. marka

### 5. Snapshot oferty

Każda wygenerowana oferta powinna zapisywać pełny snapshot z momentu utworzenia, aby CRM pamiętał dokładnie, co zostało wcześniej przedstawione klientowi.

Snapshot powinien obejmować:

- dane konfiguracji produktu
- cenę katalogową z momentu generowania
- rabat kwotowy i procentowy
- cenę końcową netto i brutto
- dane finansowania z momentu generowania
- wewnętrzną kalkulację marży i prowizji

Ponowne przeliczenie tej samej oferty w przyszłości powinno korzystać już z nowych danych systemowych, ale wcześniejszy snapshot musi pozostać dostępny historycznie.

## Kolejność stosowania reguł

Rekomendowana kolejność liczenia:

1. wybór typu klienta
2. wybór marki
3. wybór modelu
4. wybór wersji
5. pobranie ceny katalogowej i bazowej dla wybranego typu klienta
6. obliczenie puli całkowitej
7. pobranie aktywnej reguły dyrektora
8. odjęcie udziału dyrektora
9. pobranie aktywnej reguły menadżera
10. odjęcie udziału menadżera
11. doliczenie dopłaty za kolor, jeśli wybrano kolor dodatkowo płatny
12. wpisanie rabatu klienta przez handlowca
13. obliczenie ceny końcowej i prowizji handlowca
14. opcjonalne wyliczenie propozycji finansowania
15. zapis snapshotu oferty

## Wynik kalkulatora dla handlowca

Na ekranie oferty handlowiec powinien widzieć:

- cenę katalogową
- cenę po rabacie
- pozostałą pulę dla handlowca
- maksymalny możliwy rabat
- rabat wpisany dla klienta
- dopłatę za kolor
- cenę końcową netto i brutto
- prowizję handlowca po rabacie
- propozycję finansowania

Widoczność danych wewnętrznych musi być ograniczana per rola zgodnie z zasadami biznesowymi.

## Konsekwencje dla obecnego schematu

Aktualny model `Vehicle` i `VehiclePrice` jest bliższy stanowi magazynowemu niż katalogowi sprzedażowemu. Dla CRM ofertowego trzeba docelowo przesunąć środek ciężkości na konfiguracje katalogowe zamiast egzemplarzy.

Najbardziej prawdopodobne kierunki zmian:

- ograniczyć użycie `Vehicle` w generatorze oferty
- dodać osobny model katalogu sprzedażowego
- dodać model ustawień marki
- dodać model relacji organizacyjnych użytkowników
- dodać model reguł potrąceń prowizyjnych dla dyrektora i menadżera
- rozszerzyć ofertę o wynik kalkulacji i źródło danych katalogowych

## Zakres ekranów administracyjnych

### Ekran 1. Katalog cenowy

- administrator zarządza marką, modelem, wersją i cenami bazowymi oraz katalogowymi

### Ekran 2. Ustawienia marki

- administrator ustawia dopłatę za kolor niestandardowy dla każdej marki

### Ekran 3. Struktura sprzedaży

- administrator przypisuje handlowców do menadżerów
- administrator przypisuje menadżerów do dyrektorów

### Ekran 4. Reguły prowizyjne dyrektora i menadżera

- dyrektor lub administrator ustawia potrącenia dla swojej struktury
- menadżer lub administrator ustawia potrącenia dla swojego zespołu
- reguły można definiować jako kwotę albo procent
- reguły można definiować per marka, model albo wersja

### Ekran 5. Generator oferty

- handlowiec wybiera typ klienta, markę, model i wersję
- system liczy pulę oraz podział prowizji
- handlowiec ustala rabat dla klienta w granicach dostępnej puli

## Minimalna kolejność wdrożenia

1. wprowadzić model ustawień marki
2. wprowadzić strukturę podległości użytkowników
3. wprowadzić reguły udziału dyrektora i menadżera
4. podpiąć obliczenia do generatora oferty
5. dopiero później rozwijać PDF i końcowy wygląd dokumentu