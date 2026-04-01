# Rebuild Migration Runbook

Runbook dla pierwszego przejscia z legacy cennika i manifestu assetow na nowy katalog sprzedazowy.

## Cel

- zsynchronizowac obecne dane legacy do nowego modelu katalogu
- potwierdzic, ze bootstrap i workspace katalogu zwracaja spojne dane
- potwierdzic, ze sciezka oferty, PDF, link publiczny i mail dalej dzialaja po przebudowie

## Kolejnosc lokalnej weryfikacji

1. uruchom serwer developerski `npm run dev`
2. uruchom synchronizacje legacy i smoke katalogu: `npm run smoke:catalog-sync`
3. uruchom smoke oferty PDF: `powershell -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\smoke-lead-offer-pdf.ps1 -BaseUrl http://127.0.0.1:3000`
4. uruchom smoke udostepnienia i wysylki oferty

## Oczekiwany wynik

- sync legacy zwraca dodatnie liczniki marek, modeli, wersji i cen
- `/api/client/catalog/workspace` zwraca dodatnie statystyki katalogu
- `/api/client/bootstrap` zawiera sekcje `catalog`, `pricingOptions` oraz manifest `DATA` i `ASSETS`
- smoke PDF przechodzi poprawnie
- publiczny link oferty otwiera sie poprawnie
- lokalny mail w dev zapisuje sie do `.mail-outbox/` albo trafia do skonfigurowanego providera

## Uwaga o mailu lokalnym

Jesli lokalnie nie skonfigurowano SMTP ani Resend, tryb developerski zapisuje wiadomosc do `.mail-outbox/` w root repozytorium. Produkcja nadal wymaga jawnej konfiguracji providera.