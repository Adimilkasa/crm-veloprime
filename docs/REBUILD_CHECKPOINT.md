# Checkpoint przebudowy CRM VeloPrime

## Cel dokumentu

Ten plik sluzy do wznowienia pracy po przerwie.
Powinien zawierac tylko aktualny stan, bez rozbudowanego opisu historii.

## Ostatnia aktualizacja

- Data: 2026-04-04
- Etap aktywny: Etap 3 trwa - po wdrozeniu generatora oferty i modulow administratora dopracowujemy klienta hybrydowego oraz usuwamy ukryte synchronizacje i zbedne zapisy

## Ustalone na ten moment

- Desktop jest docelowym UI dla handlowca i administratora.
- Web pozostaje warstwa backendowa i uslugowa.
- Nie planujemy inwestowac w webowy CRM jako glowny interfejs pracy.
- Oferta, PDF, mail i publiczny link musza byc oparte o wspolny snapshot.
- Przebudowa ma obejmowac model katalogu, polityke cenowa, kolory, assety i generator oferty.
- Katalog ma byc zorganizowany jako marka -> model -> wersja sprzedazowa.
- Typ napedu jest zapisany na poziomie wersji, ale model ma pokazywac skrot informacji o dostepnych napedach.
- Doplata za kolor jest doliczana poza pula rabatowo-prowizyjna.
- Zrodlem prawdy dla cen w v1 sa kwoty netto, a brutto jest liczone automatycznie przy VAT `23%`.
- Dla hybrydy w v1 zapisujemy obowiazkowo moc glowna, pojemnosc baterii i pojemnosc silnika spalinowego.
- Zdjecia i materialy wizualne sa wspolne dla modelu, a PDF specyfikacji jest wybierany wedlug typu napedu wersji.
- Kategorie zdjec w v1 to: grafika glowna, zewnatrz, wnetrze, detale i premium.
- Zapisana oferta zawsze otwiera sie historycznie ze snapshotu. Jesli jest niewazna albo oparta o nieaktualny cennik, handlowiec dostaje komunikat o weryfikacji cen i musi recznie odswiezyc oferte na aktualnych danych.

## Co jest juz zrobione

- Audytowano obecna architekture pricing, colors, assets, offers i updates.
- Potwierdzono lokalno-hybrydowy model pracy klienta desktopowego.
- Zdefiniowano potrzebe przeniesienia administracji do aplikacji desktopowej.
- Przygotowano zestaw dokumentow prowadzacych przebudowe.
- Ustalono tryb pracy: Copilot proponuje jeden etap, uzytkownik decyduje, a wdrozenie rusza dopiero po akceptacji.
- Dopracowano propozycje Etapu 1 obejmujaca model danych, polityke cenowa, kolory, assety i snapshot oferty.
- Rozpisano techniczny dokument Etapu 1 w `docs/REBUILD_STAGE1_MODEL.md`.
- Zapisano decyzje o hierarchii katalogu oraz o doplacie za kolor poza pula.
- Uproszczono model administratora: archiwizacja dziala na poziomie modelu, a formularz zostal rozdzielony na pola wpisywane recznie i pola techniczne liczone przez system.
- Zamknieto decyzje o cenach netto jako zrodle prawdy i o minimalnych danych technicznych hybrydy w v1.
- Zamknieto zasade dzialania oferty historycznej i swiadomego odswiezenia na nowym cenniku.
- Formalnie zamknieto Etap 1 jako zatwierdzony model docelowy dla dalszych prac.
- Dodano fundamenty kodowe nowego modelu w `prisma/schema.prisma` oraz `src/lib/sales-catalog-model.ts`, bez przepinania jeszcze runtime na nowe byty.
- Dodano `src/lib/sales-catalog-management.ts` jako wspolny adapter nowego katalogu po stronie backendu.
- Ofertowanie i synchronizacja prowizji korzystaja juz z adaptera katalogu z fallbackiem do legacy danych.
- Dodano migracje Prisma `20260401_add_sales_catalog_v2` dla nowych tabel katalogu, cen, kolorow i assetow.
- Dodano helper synchronizacji legacy danych do nowych tabel katalogu, kolorow i assetow; nie jest jeszcze wystawiony przez API administratora.
- Dodano `src/lib/catalog-admin.ts` jako wspolna warstwe administracji katalogiem, cenami, kolorami i assetami.
- Dodano endpointy administratora pod `src/app/api/client/catalog/**` dla workspace, marek, modeli, wersji, cen, kolorow, assetow i synchronizacji legacy.
- Backend przeszedl `npm run build` po wdrozeniu admin API.
- Bootstrap klienta zwraca teraz znormalizowany katalog marek, modeli, wersji, palet kolorow, podsumowan assetow i manifest publikacji.
- Publikacja `DATA` i `ASSETS` zapisuje snapshot rzeczywistego stanu katalogu i assetow, a porownanie wersji zwraca te dane klientowi.
- Zakladka `Polityka cenowa` w Flutterze zostala przebudowana do workspace administratora opartego o nowy katalog, z obsluga marek, modeli, wersji, rekordow cenowych i synchronizacji legacy.
- Ta sama zakladka zostala rozszerzona o sekcje kolorow modelu i materialow modelu, bez tworzenia osobnej zakladki administracyjnej.
- Workspace katalogu wymaga teraz jawnego wyboru marki, modelu i wersji zamiast cichego auto-wyboru pierwszych rekordow; dalsze sekcje pracuja w kontekście jednego aktywnego samochodu.
- Dialog dodawania materialow modelu obsluguje teraz wybor pliku z dysku oraz przeciagnij i upusc dla grafik i PDF specyfikacji.
- Administrator moze zarzadzac kolorami, doplatami, pakietem materialow oraz plikami materialow rozdzielonymi na kategorie i PDF specyfikacji zalezne od napedu.
- Shell Fluttera pokazuje ten moduł tylko administratorowi, zgodnie z uprawnieniami backendowego API katalogu.
- Flutter dostal tez osobny modul `Publikacje`, w ktorym administrator moze przegladac manifest aktualizacji oraz publikowac `DATA`, `ASSETS` i `APPLICATION` z poziomu aplikacji.
- Flutter analyzer dla przebudowanego pricingu nie pokazuje juz nowych bledow; pozostaly tylko stare infos `prefer_const_constructors` w shellu i placeholderze poza zakresem etapu.
- Flutter analyzer dla nowego modulu publikacji nie pokazuje nowych bledow; kod `1` wynika nadal tylko ze starych info-lintow `prefer_const_constructors` w shellu i placeholderze.
- Istniejaca zakladka oferty zostala przepieta na nowy wybor katalogowy marka -> model -> wersja -> kolor, z doplata koloru doliczana poza pula rabatowo-prowizyjna.
- Preview dokumentu, PDF, mail i publiczny link korzystaja ze wspolnego snapshotu oraz resolvera assetow zgodnego z katalogiem i typem napedu.
- Lokalny preview oferty zostal ujednolicony z nowa logika fallbacku assetow przez przekazywanie `catalogKey` i `powertrainType`.
- Smoke test lead -> oferta -> wersja PDF -> dokument -> strona PDF zakonczyl sie sukcesem na lokalnym serwerze.
- Publiczny link oferty zostal zweryfikowany na realnej ofercie smoke i zwraca poprawna strone dokumentu.
- Dodano developerski outbox maili dla lokalnego srodowiska; probna wysylka zapisuje wiadomosc do `.mail-outbox/` bez potrzeby konfiguracji SMTP.
- Smoke sync katalogu legacy -> bootstrap przeszedl poprawnie: `SYNC_OK brands=1 models=8 versions=14 pricing=14`.
- Web CRM przestal wykonywac ukryta synchronizacje prowizji przy samym otwarciu widoku; synchronizacja modeli do prowizji jest teraz jawna i wywolywana z akcji lub endpointu `POST /api/client/commissions`.
- Tworzenie i aktualizacja oferty nie synchronizuja juz calych list uzytkownikow i katalogu do bazy; zapis przygotowuje tylko wlasciciela oferty i jeden potrzebny rekord katalogowy.
- Publikacja `DATA` i `ASSETS` oraz bootstrap katalogu nie dubluja juz odczytow live katalogu, jezeli mozna bezpiecznie wykorzystac opublikowane snapshoty.
- Klient Flutter dostal jawna synchronizacje prowizji zgodna z backendem oraz odseparowane read-pathy leadow od flushu lokalnej kolejki zmian.
- Repozytorium leadow w Flutterze ogranicza teraz dodatkowe odczyty i zapisy `SharedPreferences` przez lokalny cache overview oraz zapisy tylko tam, gdzie rzeczywiscie sa potrzebne.

## Co pozostaje otwarte

- Kolejny duzy etap to testy porownawcze starej i nowej kalkulacji oraz plan publikacji pierwszej wersji po przebudowie.
- Po refaktorze owner sync dla ofert trzeba jeszcze domknac przypadek `assignManagedOfferLead(...)`, zeby przypisanie oferty do leada nie zakladalo milczaco, ze nowy owner istnieje juz w bazie.

## Nastepny zalecany krok

- Domknac bezpiecznie przypisanie ownera w `assignManagedOfferLead(...)`, a potem wrocic do kolejnego etapu po sciezce oferty: testow porownawczych starej i nowej kalkulacji oraz planu publikacji pierwszej wersji po przebudowie.

## Instrukcja wznowienia pracy

Przy kolejnej sesji nalezy:

1. przeczytac `docs/REBUILD_PLAN.md`
2. przeczytac `docs/REBUILD_DECISIONS.md`
3. przeczytac `docs/REBUILD_CHECKPOINT.md`
4. przygotowac propozycje tylko jednego kolejnego etapu
5. czekac na decyzje uzytkownika przed wdrozeniem