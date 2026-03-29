# Hybrid Client Implementation Plan

## Cel

Zbudowac nowego klienta instalowanego lokalnie dla Windows i Android tablet, przy zachowaniu obecnego CRM jako centrali i zrodla prawdy.

## Zasady architektury

- Centrala odpowiada za logowanie, uprawnienia, publikacje wersji, walidacje finalizacji, historie i audyt.
- Klient lokalny odpowiada za UI, prezentacje, szkice ofert, robocze kalkulacje i lokalne generowanie PDF po zatwierdzeniu.
- Synchronizacja jest osobnym mechanizmem odpowiedzialnym za wersje danych, zasobow i aplikacji.

## Podzial na etapy

### Etap 1 - Przygotowanie centrali

Zakres:

- Uporzadkowanie kontraktow logowania i sesji.
- Dodanie centralnego modelu publikacji dla `DATA`, `ASSETS`, `APPLICATION`.
- Przygotowanie kontraktu walidacji finalizacji oferty.
- Przygotowanie kontraktu pobierania danych do klienta lokalnego.

Efekt:

- Obecny CRM zaczyna pelnic role backendu dla nowego klienta.

### Etap 2 - MVP klienta Flutter

Zakres:

- Logowanie.
- Ekran aktualizacji.
- Lokalna synchronizacja danych.
- Lista modeli i konfiguracja oferty.
- Robocza kalkulacja.
- Finalizacja z walidacja centralna.
- Lokalne generowanie PDF.

Efekt:

- Pierwsza dzialajaca aplikacja handlowa dla Windows i Android tablet.

### Etap 3 - Warstwa premium

Zakres:

- Rozbudowane prezentacje modeli.
- Galerie i materialy marketingowe.
- Dopracowany UX dla tabletu.
- Lepsze animacje i stany synchronizacji.

### Etap 4 - Rozbudowa ekosystemu

Zakres:

- Integracje.
- Automatyczne maile.
- Dodatkowe moduly CRM.
- Nowe workflow i powiadomienia.

## Pierwszy sprint techniczny

Priorytet:

1. Model wersjonowania publikacji.
2. Model publikacji paczek aktualizacji.
3. Model walidacji finalizacji oferty.
4. Model pobierania danych do klienta lokalnego.
5. Dopiero potem szkielet klienta Flutter.

## Co wchodzi do MVP v1

- Logowanie i autoryzacja.
- Obowiazkowe sprawdzenie aktualizacji przy logowaniu.
- Dodatkowe sprawdzenie aktualizacji przy finalizacji oferty.
- Ekran aktualizacji z pelnoekranowym stanem oczekiwania.
- Katalog modeli.
- Konfiguracja i szkic oferty.
- Robocza kalkulacja lokalna.
- Walidacja finalna przez centrale.
- Lokalne generowanie PDF po zatwierdzeniu.

## Co swiadomie odkladamy

- Discord.
- Automatyczne maile.
- Rozbudowane statystyki.
- Dodatkowe moduly CRM poza glowna sciezka ofertowa.
- Telefon jako osobne urzadzenie docelowe.

## Typy publikacji

- `DATA` - cenniki, modele, warianty, reguly rabatowe, reguly prowizyjne.
- `ASSETS` - grafiki, galerie, opisy marketingowe.
- `APPLICATION` - UI, logika, poprawki bledow, nowe funkcje.

## Zasady aktualizacji

- Aktualizacja wykryta przy logowaniu jest obowiazkowa.
- Aktualizacja wykryta w trakcie pracy nie blokuje szkicu, ale blokuje finalizacje oferty.
- PDF jest generowany lokalnie dopiero po centralnym zatwierdzeniu oferty.
- System przechowuje wewnetrzny identyfikator zatwierdzenia do audytu.

## Kolejnosc wdrozenia

1. Centrala i kontrakty.
2. Synchronizacja i wersjonowanie.
3. MVP klienta ofertowego.
4. UX premium i dodatki.