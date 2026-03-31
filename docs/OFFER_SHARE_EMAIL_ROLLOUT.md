# Offer Share Rollout

Checklist wdrożeniowy dla publicznych linków ofert i wysyłki email z aplikacji.

## Zakres

- publiczny link do wersji oferty pod `/oferta/[token]`
- wysyłka maila do klienta przez `POST /api/client/offers/:offerId/send-email`
- migracja Prisma `20260330_add_offer_version_shares`

## Wymagane zmienne środowiskowe

Na Vercelu ustaw:

- `DATABASE_URL`
- `OFFER_EMAIL_FROM`

Jeden z providerów wysyłki:

- Zoho SMTP:
	- `SMTP_HOST`
	- `SMTP_PORT`
	- `SMTP_SECURE`
	- `SMTP_USER`
	- `SMTP_PASS`
- albo Resend:
	- `RESEND_API_KEY`

Bez `DATABASE_URL` build pominie `prisma migrate deploy`, a bez danych mailowych endpoint wysyłki zwróci błąd konfiguracji.

## Kolejność wdrożenia

1. Zweryfikuj lokalnie `npm run build`.
2. Wypchnij zmiany do GitHub zgodnie z workflow `GitHub -> Vercel`.
3. Sprawdź log buildu Vercel i potwierdź, że uruchomił się krok `prisma migrate deploy`.
4. Potwierdź w bazie obecność pól `OfferVersion.shareToken`, `sharedAt`, `shareExpiresAt`.
5. Zaloguj się do CRM i wygeneruj wersję oferty z aktywnym linkiem online.
6. Z poziomu aplikacji użyj akcji `Wyslij na email`.

## Smoke test po wdrożeniu

1. Otwórz ofertę w aplikacji i skopiuj link publiczny.
2. Sprawdź, czy `/oferta/[token]` otwiera poprawny widok klienta.
3. Wyślij ofertę na testowy adres email.
4. Potwierdź, że mail zawiera przycisk i poprawny link do oferty online.
5. Potwierdź, że oferta ma status `SENT`.
6. Jeśli oferta jest przypięta do leada, potwierdź przejście etapu na `Oferta przekazana`.

## Najczęstsze blokery

- Brak `DATABASE_URL`: migracja nie wykona się podczas buildu.
- Brak `OFFER_EMAIL_FROM`: wysyłka maila zakończy się błędem konfiguracji.
- Dla Zoho SMTP brakuje któregoś z `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `SMTP_USER`, `SMTP_PASS`.
- Dla Resend brakuje `RESEND_API_KEY`.
- Brak adresu email klienta na ofercie: aplikacja nie wyśle wiadomości.
- Wygasła oferta: publiczny link pokaże stan wygasły zamiast pełnego widoku.