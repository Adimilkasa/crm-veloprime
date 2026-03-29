# VeloPrime Hybrid Client

Minimalny szkielet klienta Flutter pod Windows i Android tablet.

## Zakres obecnej wersji

- logowanie do obecnego API CRM
- zapamietanie cookie sesji po zalogowaniu
- pobranie `bootstrap` klienta lokalnego
- sprawdzenie zgodnosci wersji przez `compare`
- wymuszony ekran aktualizacji dla nieaktualnej wersji
- placeholder ekranu ofert

## Wymagania lokalne

- Flutter SDK
- Dart SDK

## Start

```bash
flutter pub get
flutter run -d windows
```

Lub dla Androida:

```bash
flutter run -d android
```

## Konfiguracja API

Domyslny adres API jest ustawiony w `lib/core/config/api_config.dart`.

Przed uruchomieniem ustaw poprawny adres centrali, np.:

- `http://127.0.0.1:3000`
- `https://crm.veloprime.pl`

## Uwagi

- Projekt zostal przygotowany recznie, bo Flutter SDK nie jest zainstalowany w biezacym srodowisku repo.
- Kolejny krok to uruchomienie `flutter pub get`, a potem rozbudowa ekranu ofert i lokalnej bazy danych.