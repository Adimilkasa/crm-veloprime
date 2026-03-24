import { stat } from 'node:fs/promises'
import path from 'node:path'

import { CarFront } from 'lucide-react'

import { listColorPalettes } from '@/lib/color-management'
import { getActivePricingSheet } from '@/lib/pricing-management'

type NewsItem = {
  id: string
  category: string
  title: string
  description: string
  meta: string
}

function formatDate(value: string | null) {
  if (!value) {
    return 'oczekuje na pierwszy zapis'
  }

  return new Intl.DateTimeFormat('pl-PL', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

function normalizeHeader(value: string) {
  return value.trim().toLowerCase()
}

function countUniqueModels(headers: string[], rows: string[][]) {
  const brandIndex = headers.findIndex((header) => normalizeHeader(header) === 'marka')
  const modelIndex = headers.findIndex((header) => normalizeHeader(header) === 'model')

  if (brandIndex === -1 || modelIndex === -1) {
    return 0
  }

  return new Set(
    rows
      .map((row) => `${row[brandIndex] ?? ''}::${row[modelIndex] ?? ''}`.trim().toLowerCase())
      .filter((value) => value !== '::')
  ).size
}

async function getFileModifiedAt(fileName: string) {
  try {
    const filePath = path.join(process.cwd(), 'data', fileName)
    const details = await stat(filePath)
    return details.mtime.toISOString()
  } catch {
    return null
  }
}

async function getDashboardNews() {
  const [pricingSheet, colorPalettes, colorPaletteUpdatedAt] = await Promise.all([
    getActivePricingSheet(),
    listColorPalettes(),
    getFileModifiedAt('byd-color-palettes.json'),
  ])

  const modelCount = countUniqueModels(pricingSheet.headers, pricingSheet.rows)
  const configurationCount = pricingSheet.rows.length

  const news: NewsItem[] = [
    {
      id: 'pricing',
      category: 'Cennik',
      title: pricingSheet.updatedAt
        ? 'Polityka cenowa została zaktualizowana'
        : 'Polityka cenowa czeka na pierwszy pełny zapis',
      description: pricingSheet.updatedAt
        ? `W bazie działa teraz ${configurationCount} konfiguracji. Generator ofert i CRM korzystają z tych samych danych.`
        : 'Po zapisaniu listy modeli i cen tutaj od razu pojawi się krótka informacja o zmianie.',
      meta: pricingSheet.updatedAt
        ? `${formatDate(pricingSheet.updatedAt)} • ${pricingSheet.updatedBy ?? 'System'}`
        : 'Brak historii zmian',
    },
    {
      id: 'models',
      category: 'Modele',
      title: modelCount > 0
        ? `W systemie dostępnych jest ${modelCount} modeli do pracy`
        : 'Lista modeli jest gotowa do uzupełnienia',
      description: modelCount > 0
        ? `Aktualna baza obejmuje ${configurationCount} konfiguracji. Po dodaniu nowego modelu handlowcy zobaczą go w generatorze ofert.`
        : 'Po zaimportowaniu polityki cenowej dashboard zacznie pokazywać krótkie komunikaty o nowych pozycjach.',
      meta: configurationCount > 0
        ? `${configurationCount} aktywnych konfiguracji`
        : 'Brak aktywnych konfiguracji',
    },
    {
      id: 'colors',
      category: 'Kolory',
      title: colorPalettes.length > 0
        ? `Palety kolorów obejmują ${colorPalettes.length} linii modelowych`
        : 'Palety kolorów czekają na konfigurację',
      description: colorPalettes.length > 0
        ? 'Każda zmiana lakierów i dopłat trafia bezpośrednio do kalkulacji oraz PDF-ów ofertowych.'
        : 'Po zapisaniu pierwszej palety dashboard zacznie pokazywać informacje o zmianach kolorystycznych.',
      meta: colorPaletteUpdatedAt
        ? `Ostatnia zmiana: ${formatDate(colorPaletteUpdatedAt)}`
        : 'Brak historii zmian',
    },
  ]

  return news
}

export default async function DashboardPage() {
  const news = await getDashboardNews()

  return (
    <main>
      <section className="rounded-[32px] border border-[#e8e2d3] bg-white p-6 shadow-[0_20px_60px_rgba(31,31,31,0.05)] lg:p-8">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Aktualności</div>
            <h2 className="mt-2 text-[24px] font-semibold text-[#1f1f1f] lg:text-[28px]">Najważniejsze zmiany w systemie</h2>
            <p className="mt-2 max-w-2xl text-sm leading-7 text-[#6b6b6b]">
              Ten moduł zbiera krótkie informacje o zmianach w modelach, cenniku i konfiguracji, tak aby nowa osoba mogła szybko zorientować się, co zostało zaktualizowane.
            </p>
          </div>
        </div>

        <div className="mt-6 grid gap-4 xl:grid-cols-3">
          {news.map((item) => (
            <article key={item.id} className="group rounded-[24px] border border-[#ece6d9] bg-[linear-gradient(180deg,#ffffff_0%,#fcfbf8_100%)] p-5 transition hover:-translate-y-[1px] hover:shadow-[0_18px_40px_rgba(31,31,31,0.06)]">
              <div className="flex items-center justify-between gap-3">
                <span className="inline-flex items-center gap-2 rounded-full border border-[rgba(201,161,59,0.20)] bg-[rgba(201,161,59,0.10)] px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.16em] text-[#8f6b18]">
                  <CarFront className="h-3.5 w-3.5" />
                  {item.category}
                </span>
              </div>
              <h3 className="mt-4 text-[18px] font-semibold leading-7 text-[#1f1f1f]">{item.title}</h3>
              <p className="mt-3 text-sm leading-7 text-[#666666]">{item.description}</p>
              <div className="mt-5 border-t border-[#f1ecdf] pt-4 text-sm text-[#8a826f]">{item.meta}</div>
            </article>
          ))}
        </div>
      </section>
    </main>
  )
}