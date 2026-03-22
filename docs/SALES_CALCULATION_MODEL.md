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

System nie wymaga pól takich jak VIN, stock number, lokalizacja auta, status placowy ani przebieg.

## Główne role i odpowiedzialność

### Administrator

- ustala cenę bazową dla każdej wersji auta
- ustala ceny katalogowe netto i brutto
- ustala dopłatę za kolor niestandardowy dla danej marki
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

- jest definiowana na poziomie marki
- nie jest definiowana per egzemplarz
- może być doliczana jednorazowo do oferty

Przykład:

- marka BYD
- dopłata za kolor niestandardowy: 4500 zł brutto

Niezależnie od modelu tej marki, dopłata za kolor jest taka sama, dopóki administrator jej nie zmieni.

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
- nonBaseColorSurchargeGross
- nonBaseColorSurchargeNet
- defaultCurrency
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

## Wynik kalkulatora dla handlowca

Na ekranie oferty handlowiec powinien widzieć:

- cenę katalogową
- cenę bazową
- pulę całkowitą
- udział dyrektora
- udział menadżera
- pozostałą pulę dla handlowca
- maksymalny możliwy rabat
- rabat wpisany dla klienta
- dopłatę za kolor
- cenę końcową netto i brutto
- prowizję handlowca po rabacie

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