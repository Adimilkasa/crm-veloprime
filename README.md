# CRM VeloPrime

Osobny projekt CRM dla zespołu sprzedaży VeloPrime.

## Stack

- Next.js
- TypeScript
- Tailwind CSS
- App Router
- Prisma

## Start

```bash
npm install
npm run dev
```

## Environment

Skopiuj `.env.example` do `.env` i ustaw `DATABASE_URL` przed podpinaniem bazy danych.

## Założenia wersji startowej

- osobny panel pod subdomenę typu `crm.veloprime.pl`
- gotowość pod logowanie i role
- fundament pod leady, bazę samochodów, konfigurację cen i oferty PDF

## Role planowane

- Administrator
- Dyrektor
- Manager
- Handlowiec

## Dokumentacja domenowa

- `docs/SALES_CALCULATION_MODEL.md` - model kalkulacji sprzedaży, hierarchii prowizyjnej i reguł oferty

## Moduły robocze

- `/pricing` - baza polityki cenowej i katalog modeli
- `/commissions` - prowizje dyrektora i managera synchronizowane z katalogiem modeli
