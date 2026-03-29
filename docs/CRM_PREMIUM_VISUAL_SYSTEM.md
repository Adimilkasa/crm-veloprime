# CRM Premium Visual System

## Cel

Zdefiniowanie jednego, spójnego systemu wizualnego dla całego CRM w kierunku nowoczesnego, lekkiego i premium SaaS. System ma działać jednakowo dobrze w modułach dashboard, kanban, formularze, oferty PDF, listy i modale, bez budowania osobnych wyjątków dla pojedynczych widoków.

Inspiracja kierunkowa:
- Apple: czystość, światło, oddech
- Linear: hierarchia, dyscyplina, subtelne warstwy
- Vercel: minimalizm, precyzja, spokojna elegancja

Ten dokument nie definiuje layoutów ekranów. Definiuje wyłącznie uniwersalny język wizualny.

## 1. Rdzeń estetyki

System powinien opierać się na czterech zasadach:

1. Lekkość zamiast ciężkich paneli
2. Hierarchia budowana światłem, warstwami i typografią
3. Minimalizm bez sterylności
4. Premium przez proporcje, nie przez ozdobniki

Pożądany efekt:
- dużo oddechu
- mało agresywnych kontrastów
- subtelna głębia
- wyraźna czytelność stanu aktywnego
- spokojny, biznesowy ton wizualny

## 2. System warstw

Warstwy są kluczowe. Każdy poziom interfejsu musi mieć własny charakter. Nie wolno używać jednego identycznego stylu dla całej aplikacji.

### Base

Rola:
- tło całej aplikacji
- najniższy poziom wizualny

Charakter:
- bardzo jasne
- neutralne z lekkim ociepleniem
- delikatny gradient zamiast płaskiego fillu

Rekomendacja:
- gradient: biały do ciepłego szarego
- przykładowo: `#FFFFFF -> #F5F3EF`

Zasada:
- base nie może konkurować z treścią
- ma tylko nieść światło i miękko odcinać kolejne warstwy

### Surface

Rola:
- sekcje, obszary robocze, kontenery modułów
- np. obszar kanbanu, sekcja formularza, strefa treści

Charakter:
- subtelnie odróżnione od base
- lekko mleczne lub półprzezroczyste
- bardzo delikatny kontrast i miękka granica

Rekomendacja:
- tło: `rgba(255,255,255,0.62)` do `rgba(250,248,244,0.78)`
- blur tylko tam, gdzie ma znaczenie warstwowe

Zasada:
- surface ma być wyczuwalne, ale nie ciężkie
- jeśli surface zaczyna przypominać klasyczny szary panel, znaczy że jest za ciężkie

### Card

Rola:
- elementy interaktywne i najważniejsze bloki treści
- karty leadów, rekordy, panele formularzy, elementy preview

Charakter:
- bardziej solidne niż surface
- białe lub lekko rozświetlone
- miękki cień zamiast mocnego obramowania

Rekomendacja:
- tło: `rgba(255,255,255,0.88)` albo `#FFFFFF`
- border: `rgba(17,17,17,0.05)`
- cień: szeroki i miękki, bez ostrego kontrastu

Zasada:
- karta ma odcinać się od surface przez światło i cień
- nie przez ciężki border ani ciemne tło

### Overlay / Focus

Rola:
- modale
- aktywne stany
- focus ring
- dropdowny i warstwy tymczasowe

Charakter:
- najwyższy poziom czytelności
- najbardziej dopracowane światło
- wyższa ostrość i czystość niż pozostałe warstwy

Rekomendacja:
- tło: prawie pełna biel lub mleczne szkło
- wyraźniejszy cień niż dla card
- bardzo subtelny akcent w focus state

Zasada:
- overlay ma być premium i czytelny
- nie może być ani ciężkim czarnym modalem, ani przesadnie rozmytym glassmorphismem

## 3. Kolorystyka

Kolory mają być spokojne i oszczędne. Akcent ma budować wartość, nie dominować UI.

### Neutrale

- text-primary: `#111111`
- text-secondary: `#666666`
- text-tertiary: `#8A8A8A`
- background-base-top: `#FFFFFF`
- background-base-bottom: `#F5F3EF`
- surface-1: `rgba(255,255,255,0.68)`
- surface-2: `rgba(248,245,240,0.82)`
- card: `#FFFFFF`
- border-soft: `rgba(0,0,0,0.04)`
- border-stronger: `rgba(17,17,17,0.08)`

### Akcent główny

- accent-gold: `#D4A84F`
- accent-gold-deep: `#BE933E`
- accent-gold-soft: `#E9D3A0`
- accent-glow: `rgba(212,168,79,0.22)`

Zasada użycia akcentu:
- primary button
- aktywny element
- highlight
- focus i wybrane stany

Zakaz:
- nie używać złota jako dużego tła sekcji
- nie zalewać złotem kart i paneli
- nie budować całej hierarchii tylko kolorem akcentu

### Stany semantyczne

Statusy pozostają różnorodne, ale ich użycie ma być subtelne:

- info: chłodny błękit przygaszony
- success: stonowana zieleń
- warning: zgaszony bursztyn
- danger: elegancka, lekko przybrudzona czerwień

Wszystkie stany semantyczne:
- używane jako akcent, badge, linia, ikona, tint tła
- nie jako agresywne pełne wypełnienie dużych bloków

## 4. Typografia

### Kierunek

Font systemowy powinien być nowoczesny, neutralny i biznesowy.

Priorytet:
1. Inter
2. SF Pro
3. Plus Jakarta Sans

### Zasady

- hierarchia ma wynikać z rozmiaru, grubości i spacingu
- kolory tekstu mają wspierać hierarchię, nie zastępować jej
- interfejs ma oddychać: większe line-height i odstępy między sekcjami

### Skala typograficzna

- Display / page title: 30-40 px, semibold, tracking lekko ujemny
- Section title: 20-24 px, semibold
- Card title: 16-18 px, semibold
- Body: 14-16 px, regular lub medium
- Small label: 11-12 px, medium, lekko zwiększony tracking
- Micro meta: 10-11 px, medium, oszczędnie

### Line-height

- display: 1.1-1.2
- section heading: 1.2-1.3
- body: 1.5-1.65
- small labels: 1.35-1.45

## 5. Promień, bordery i cień

### Radius

- main surfaces: 24-32 px
- cards: 20-28 px
- inputs: 16-20 px
- badges: 999 px lub 12-14 px

### Bordery

Zasady:
- minimalne
- miękkie
- prawie niewidoczne

Tokeny:
- default border: `1px solid rgba(0,0,0,0.04)`
- emphasized border: `1px solid rgba(17,17,17,0.08)`

Nie stosować:
- ciemnych ramek
- grubych separatorów
- obrysów jako głównego narzędzia hierarchii

### Cień

Cień ma budować głębię, nie dramat.

Przykładowe poziomy:

- shadow-surface: `0 10px 30px rgba(15, 15, 15, 0.04)`
- shadow-card: `0 18px 50px rgba(15, 15, 15, 0.07)`
- shadow-overlay: `0 28px 80px rgba(15, 15, 15, 0.12)`
- shadow-gold-glow: `0 10px 28px rgba(212, 168, 79, 0.20)`

## 6. Komponenty bazowe

### Karty

Karta ma wyglądać jak precyzyjny obiekt osadzony na lekkim tle.

Specyfikacja:
- radius: 20-28 px
- tło: białe lub lekko podbite
- border: bardzo subtelny
- cień: miękki, szeroki
- spacing wewnętrzny: hojny

Zasada:
- więcej paddingu, mniej dekoracji

### Przyciski

#### Primary

- złoty gradient, ale elegancki i stonowany
- delikatny glow
- tekst ciemny lub bardzo ciemny, dla premium kontrastu

Przykładowy kierunek:
- `linear-gradient(180deg, #E2C27A 0%, #D4A84F 100%)`

Hover:
- lekki lift
- trochę więcej światła
- subtelne wzmocnienie cienia

#### Secondary

- neutralne, jasne
- bez ciężkiego fillu
- delikatny border i subtelne tło

Hover:
- minimalne rozjaśnienie
- lekki ruch w górę

#### Ghost / Tertiary

- bardzo oszczędne
- używane tylko do działań drugoplanowych

### Inputy

Specyfikacja:
- wysokość: 48-56 px
- radius: 16-20 px
- tło: delikatnie odróżnione od karty
- border: subtelny
- tekst i placeholder spokojne, nowoczesne

Focus:
- lekki złoty glow
- delikatne rozjaśnienie tła
- brak agresywnego, ciemnego outline

### Badge

Badge ma być informacyjny, nie dekoracyjny.

Zasady:
- małe
- spokojne
- mało kontrastowe
- ograniczona liczba na ekranie

Styl:
- cienki tint tła
- subtelny tekst
- niewielki radius

### Navbar

Kierunek:
- glass
- backdrop blur
- cienki border
- wysoka czystość

Specyfikacja:
- tło: półprzezroczysta biel
- blur: umiarkowany
- dolna krawędź bardzo delikatna

Zasada:
- navbar ma wyglądać jak warstwa premium, nie jak klasyczny sztywny pasek aplikacyjny

## 7. Ruch i mikrointerakcje

Animacje mają wspierać jakość odbioru, nie odciągać uwagi.

### Czas trwania

- hover i focus: 180-220 ms
- wejście kart i overlay: 220-300 ms
- zmiany tła i cienia: 200-260 ms

### Krzywe

- preferowane easing z miękkim wyhamowaniem
- bez sprężynowania w większości systemowych interakcji

### Dozwolone efekty

- `translateY(-1px)` lub `translateY(-2px)` na hover
- subtelna zmiana światła
- płynne przejście cienia
- delikatny fade/slide dla overlay

### Niedozwolone

- mocne skale
- nadmierne bounce
- przesadne blur transitions
- animowanie zbyt wielu elementów jednocześnie

## 8. Kanban

Kanban ma pozostać zróżnicowany kolorystycznie, ale musi stracić ciężar paneli.

### Kolumny

Zasady:
- traktować jako lekkie surface, nie jako ciężkie bloki
- bardzo subtelne tło
- kolor etapu tylko jako tint i akcent
- brak grubych ramek i mocnych filli

Kierunek wizualny:
- jasne, półprzezroczyste sekcje
- delikatna warstwa z odrobiną koloru etapu
- bardziej światło niż kolor

### Kolor etapu

Kolor etapu może wpływać na:
- cienki pasek akcentowy
- badge kolumny
- subtelne tło nagłówka
- focus i highlight drop zone

Nie powinien wpływać na:
- pełne wypełnienie całej kolumny mocnym kolorem

### Karty kanban

Zasady:
- wyraźniej odcięte niż kolumny
- bardziej solidne
- białe lub lekko podbite
- z cieniem, który pozwala je odczytać jako obiekt ponad kolumną

Efekt docelowy:
- kolumna jest lekkim środowiskiem pracy
- karta jest właściwym obiektem roboczym

## 9. Gęstość i spacing

System ma wyglądać premium dzięki proporcjom.

Zasady:
- większe odstępy między sekcjami
- większy padding w kluczowych kontenerach
- mniej elementów upchniętych obok siebie
- czytelne marginesy pionowe

Rekomendacja spacing scale:
- 4
- 8
- 12
- 16
- 24
- 32
- 40
- 48

Najczęściej używać 12, 16, 24, 32.

## 10. Zasady spójności między modułami

Ten system ma działać identycznie jako język wizualny w:
- dashboardzie
- kanbanie
- formularzach
- ofertach i PDF
- listach
- modalach

To oznacza:
- te same warstwy
- te same neutralne kolory
- ten sam akcent
- ta sama logika cienia
- ta sama typografia
- te same promienie i spacing

Nie budować osobnych estetyk dla poszczególnych modułów.

## 11. Czego unikać

- zbyt wielu borderów
- identycznego stylu wszystkich warstw
- ciężkich szarych paneli
- ostrych kontrastowych cieni
- złota używanego jako dominującego tła
- zbyt wielu badge'y
- płaskiego UI bez światła i głębi
- nadmiernego blur
- zbyt ciasnego spacingu

## 12. Tokeny startowe

### Core tokens

```txt
--bg-base-top: #FFFFFF
--bg-base-bottom: #F5F3EF
--surface-soft: rgba(255,255,255,0.68)
--surface-strong: rgba(248,245,240,0.82)
--card-bg: #FFFFFF
--overlay-bg: rgba(255,255,255,0.92)

--text-primary: #111111
--text-secondary: #666666
--text-tertiary: #8A8A8A

--border-soft: rgba(0,0,0,0.04)
--border-strong: rgba(17,17,17,0.08)

--accent-gold: #D4A84F
--accent-gold-deep: #BE933E
--accent-gold-soft: #E9D3A0
--accent-glow: rgba(212,168,79,0.22)

--shadow-surface: 0 10px 30px rgba(15,15,15,0.04)
--shadow-card: 0 18px 50px rgba(15,15,15,0.07)
--shadow-overlay: 0 28px 80px rgba(15,15,15,0.12)
--shadow-gold: 0 10px 28px rgba(212,168,79,0.20)

--radius-surface: 28px
--radius-card: 24px
--radius-input: 18px
--radius-pill: 999px
```

### Motion tokens

```txt
--motion-fast: 180ms
--motion-base: 220ms
--motion-slow: 280ms
--ease-standard: cubic-bezier(0.2, 0.8, 0.2, 1)
```

## 13. Zasady wdrożeniowe

Przy wdrażaniu w kodzie:

1. Najpierw zdefiniować tokeny globalne
2. Potem przepisać warstwy: base, surface, card, overlay
3. Następnie ujednolicić komponenty bazowe: button, input, card, modal, badge
4. Dopiero na końcu stroić moduły biznesowe, takie jak kanban i oferty PDF

Kolejność jest ważna, bo bez tokenów i warstw moduły będą rozjeżdżały się wizualnie.

## 14. Efekt docelowy

Finalny CRM powinien sprawiać wrażenie:
- lekkiego
- precyzyjnego
- nowoczesnego
- uporządkowanego
- premium, ale nie ostentacyjnego

To ma być produkt SaaS klasy automotive/fintech, który komunikuje jakość spokojem, światłem, proporcją i dyscypliną wizualną.

## 15. Audyt stanu obecnego

Poniższy audyt traktujemy jako punkt wyjścia do kolejnych prac. Celem nie jest krytyka pojedynczych ekranów, tylko uchwycenie tego, co już działa i tego, co należy dopracować, aby cały CRM wyglądał jak jeden produkt premium.

### Moduł referencyjny: oferta PDF

Status:
- obecnie najlepszy wizualnie moduł w systemie
- powinien być traktowany jako główne odniesienie dla tonu marki i kompozycji

Mocne strony:
- editorialowy układ z wyraźnym hero section
- dobra narracja sprzedażowa zamiast czysto systemowej prezentacji danych
- dużo oddechu i czytelne strefowanie informacji
- produkt jest pokazany jako obiekt premium, nie jako rekord CRM
- dobrze wykorzystane galerie, duże pola światła i spokojna hierarchia

Ryzyka:
- część rozwiązań jest zbyt odseparowana od reszty systemu i może sprawiać wrażenie osobnego mikro-brandu
- niektóre gradienty i światła są bardziej dekoracyjne niż systemowe

Wniosek:
- oferta PDF wyznacza kierunek estetyczny
- kolejne moduły powinny odziedziczyć jej dyscyplinę przestrzeni, proporcji i narracji, ale w uproszczonej formie odpowiedniej dla aplikacji roboczej

### Shell aplikacji i nawigacja

Status:
- dobra baza
- obecny shell jest już premium, ale nie jest jeszcze wystarczająco zdyscyplinowany

Mocne strony:
- glass navbar i lekkie powierzchnie budują nowoczesny ton
- dobrze dobrany promień, miękkie cienie i jasna baza
- nawigacja nie wygląda enterprise ani ciężko

Problemy:
- zbyt dużo wariantów tła rozmywa charakter marki
- aplikacja zaczyna komunikować personalizację nastroju zamiast spójności produktu
- za dużo różnych akcentów kolorystycznych dla ikon nawigacji osłabia efekt premium

Wniosek:
- shell trzeba uprościć
- docelowo ograniczyć liczbę motywów tła do jednego głównego i maksymalnie jednego dodatkowego
- aktywność i hierarchia powinny wynikać głównie z światła, kontrastu i typografii, a nie z mnożenia kolorów

### Dashboard

Status:
- estetycznie spójny z obecnym systemem
- wymaga mocniejszej hierarchii marketingowej

Mocne strony:
- dobre pierwsze wrażenie i spokojny ton
- sekcje nie są ciężkie

Problemy:
- zbyt podobne karty zaczynają się wizualnie zlewać
- ekran jest poprawny, ale nie buduje jeszcze wyraźnej narracji produktu premium

Wniosek:
- dashboard powinien być bardziej redakcyjny
- potrzeba silniejszego podziału na hero, statystyki, sygnały systemowe i aktualizacje

### Leads

Status:
- funkcjonalnie poprawny
- wizualnie bardziej operacyjny niż premium

Mocne strony:
- dobra baza do lekkiego kanbanu
- struktura nadaje się do dalszego dopracowania bez przebudowy logiki

Problemy:
- zbyt mało zróżnicowania pomiędzy warstwą kolumny, kartą i strefą akcji
- modal i formularze są czytelne, ale jeszcze nie mają tej samej klasy co oferta PDF

Wniosek:
- leads wymagają pracy nad warstwami, spacingiem i czytelnością interakcji
- kanban ma wyglądać jak ekskluzywne środowisko pracy, nie jak zbiór pojemników

### Pricing

Status:
- najbardziej narzędziowy i najmniej aspiracyjny wizualnie moduł

Mocne strony:
- czytelna funkcja operacyjna
- dobra baza pod systemowy redesign

Problemy:
- dominują odczucia arkuszowe i administracyjne
- brakuje spokojnej hierarchii oraz premium obudowy dla obszaru edycyjnego
- duża ilość tabelarycznych danych wymaga lepszego rytmu wizualnego, aby ekran nie męczył wzroku

Wniosek:
- pricing wymaga najmocniejszego liftingu w zakresie prezentacji
- trzeba zachować użyteczność, ale dodać więcej światła, modularności i kontroli nad gęstością informacji

### Commissions

Status:
- umiarkowanie spójny z obecnym systemem
- bliżej dobrego foundation niż finalnego premium polish

Mocne strony:
- sekcje są czytelne
- ogólny układ ma sens biznesowy i jest gotowy do dopracowania

Problemy:
- zbyt dużo standardowych bloków kartowych o podobnej wadze wizualnej
- brakuje wyraźniejszego rozdzielenia obszaru sterowania od obszaru danych

Wniosek:
- ten moduł nie wymaga rewolucji, tylko porządnego unifikowania z nowym language system

### Colors

Status:
- duży potencjał wizualny, obecnie wykorzystany tylko częściowo

Mocne strony:
- sama tematyka koloru naturalnie wspiera atrakcyjny design
- ekran ma logiczny podział na wybór palety i edycję szczegółów

Problemy:
- interfejs jest zbyt formularzowy jak na moduł, który powinien pracować także emocją wizualną
- brakuje lepszego wykorzystania próbek koloru, materiałowości i preview

Wniosek:
- colors to jeden z najlepszych kandydatów do pokazania premium redesignu w praktyce

### Users

Status:
- czytelny administracyjnie
- najsłabiej komunikuje aspiracyjny charakter produktu

Mocne strony:
- dobra przejrzystość formularza i listy
- poprawna ergonomia dla modułu administracyjnego

Problemy:
- ekran jest zbyt klasyczny, zbyt formularzowy i zbyt przewidywalny
- za mało oddechu pomiędzy sekcjami
- zbyt mało wyczuwalnej hierarchii pomiędzy akcją główną, informacją pomocniczą i listą kont

Wniosek:
- users wymaga przełożenia języka premium na obszar stricte administracyjny bez utraty prostoty

## 16. Wnioski strategiczne

Z perspektywy marki, marketingu i premium UX główna diagnoza jest następująca:

- system ma już premium intencję
- system nie ma jeszcze premium dyscypliny
- oferta PDF jest najbardziej dojrzałym modułem wizualnym
- reszta ekranów jest spójna kolorystycznie, ale za rzadko korzysta z równie świadomej kompozycji i hierarchii

To oznacza, że nie budujemy nowej estetyki od zera. Ujednolicamy istniejący język, upraszczamy go i przenosimy najlepsze cechy oferty PDF do pozostałych modułów.

Priorytety estetyczne:
- mniej dekoracyjności, więcej kontroli
- mniej wariantów, więcej spójności
- mniej równorzędnych kart, więcej wyraźnej hierarchii
- mniej wizualnego hałasu, więcej światła i oddechu

## 17. Roadmapa redesignu

### Etap 1. Ustalenie systemu globalnego

Cel:
- uproszczenie i usztywnienie wspólnego language system dla całej aplikacji

Zakres:
- uporządkowanie tokenów globalnych
- ograniczenie liczby motywów tła
- ujednolicenie cieni, borderów, promieni i stanów hover/focus
- wzmocnienie zasad typografii i odstępów

Efekt:
- każdy następny moduł będzie strojony już na wspólnej bazie, a nie lokalnymi wyjątkami

### Etap 2. Shell i nawigacja

Cel:
- nadać całej aplikacji bardziej luksusowy, spokojny i jednolity ton od pierwszego kontaktu

Zakres:
- uproszczenie navbaru
- lepsza hierarchia aktywnego elementu
- redukcja rozproszenia kolorystycznego w ikonach i presetach
- dopracowanie spacingu oraz top-level kontenerów

Efekt:
- premium charakter będzie odczuwalny niezależnie od aktywnej zakładki

### Etap 3. Moduły o największej różnicy jakości względem oferty PDF

Kolejność:
1. users
2. pricing
3. colors

Powód:
- te moduły najbardziej odstają od referencyjnego poziomu premium i najszybciej pokażą realny postęp jakościowy

Zakres:
- poprawa rytmu sekcji
- uproszczenie układów
- nadanie większej lekkości formularzom i panelom danych
- lepsza hierarchia nagłówków, statystyk i CTA

### Etap 4. Moduły średniego ryzyka wizualnego

Kolejność:
1. dashboard
2. commissions
3. leads

Powód:
- mają już poprawną bazę i powinny zostać dostrojone do finalnego systemu po ustaleniu kierunku na trudniejszych ekranach

Zakres:
- większa spójność z shell i nowymi komponentami bazowymi
- redukcja liczby wizualnie równorzędnych kart
- lepsze rozłożenie oddechu i warstw informacji

### Etap 5. Final polish i spójność końcowa

Cel:
- upewnić się, że system działa jako jeden produkt, a nie zestaw osobno stylizowanych widoków

Zakres:
- przegląd wszystkich nagłówków stron
- przegląd stat cards, tabel, formularzy, modali i badge'y
- korekty mikrointerakcji
- kontrola mobile i desktop spacingu

## 18. Zasady wykonawcze dla kolejnych prac

Podczas wdrożenia redesignu stosujemy następujące reguły:

- oferta PDF pozostaje referencją dla tonu premium, ale nie kopiujemy jej 1:1 do ekranów roboczych
- każdy ekran ma mieć jeden dominujący punkt wejścia wzrokowego
- każda sekcja ma mieć wyraźnie określoną wagę: hero, control, content, support
- nie dokładamy nowych ozdobników, jeśli problem można rozwiązać spacingiem, typografią albo uproszczeniem warstw
- jeśli dwa komponenty konkurują wizualnie o uwagę, jeden z nich musi zostać uspokojony
- jeśli ekran wygląda ładnie tylko na desktopie, rozwiązanie nie jest zakończone

## 19. Definicja sukcesu

Prace uznajemy za wykonane dobrze, gdy:

- użytkownik czuje spójność między ofertą PDF a resztą CRM
- ekran wygląda premium bez efektu przesadnego luxury UI
- wzrok naturalnie wie, gdzie wejść, co jest najważniejsze i gdzie wykonać akcję
- formularze i dane są lżejsze wizualnie, ale nie mniej czytelne
- aplikacja sprawia wrażenie produktu klasy automotive premium, a nie tylko poprawnie ostylowanego panelu administracyjnego

## 20. Roadmapa modułów Windows Client

Poniższa lista porządkuje dalsze prace już dla klienta Flutter na Windows, a nie dla webowego CRM.

### Stan obecny

- Dashboard: po dużym liftingu, wymaga jedynie późniejszych korekt proporcji i spójności z formularzami.
- Leady - widok kanban: po głębokim liftingu, wymaga tylko punktowych dopracowań po review użytkownika.
- Lead detail: kluczowy ekran operacyjny, musi być traktowany jako rozszerzenie zakładki leadów, nie osobny stylistycznie moduł.
- Oferty / PDF: funkcjonalnie rozbudowane, ale nadal bardziej robocze niż premium; to najwyższy priorytet po leadach.
- Użytkownicy: poprawne i czytelne, ale zbyt formularzowe i zbyt mało hierarchiczne wizualnie.
- Klienci: obecnie placeholder, do zaprojektowania jako realny moduł relacji i historii obsługi.
- Samochody: obecnie placeholder, do zaprojektowania jako realny moduł produktowy i modelowy.

### Kolejność dalszych prac

1. Domknąć lead detail tak, aby karta klienta wyglądała jak naturalne rozwinięcie widoku kanban.
2. Przebudować Oferty / PDF w tym samym języku warstw, spacingu i hierarchii co dashboard i leady.
3. Ujednolicić Users z nowym systemem formularzy, badge'ów i akcji drugiego planu.
4. Zamienić placeholder Klienci na właściwy moduł CRM oparty o historię relacji, statusy i aktywność.
5. Zamienić placeholder Samochody na właściwy moduł oferty modelowej z silniejszym aspektem produktowym.

### Zasady globalne dla klienta Windows

- jeden wspólny system inputów, dropdownów, kart i cieni dla wszystkich zakładek
- brak ciężkich sekcji osadzonych na dodatkowym sztucznym tle
- hero i górne sekcje mają prowadzić do działania, a nie zajmować większość uwagi
- formularze i listy mają być lżejsze optycznie niż dziś, ale bardziej precyzyjne w hierarchii
- placeholdery nie mogą pozostać neutralnymi makietami, muszą dostać docelowy charakter produktowy