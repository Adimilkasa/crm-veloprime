'use client'

import { useEffect, useMemo, useRef, useState } from 'react'
import { useRouter } from 'next/navigation'
import { ClipboardPaste, Database, Eraser, Plus, Save, TableProperties, Trash2 } from 'lucide-react'

type PricingSheet = {
  headers: string[]
  rows: string[][]
  updatedAt: string | null
  updatedBy: string | null
}

function formatDate(value: string | null) {
  if (!value) {
    return 'Brak importu ręcznego'
  }

  return new Intl.DateTimeFormat('pl-PL', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

function getColumnLabel(index: number) {
  let nextIndex = index
  let label = ''

  while (nextIndex >= 0) {
    label = String.fromCharCode((nextIndex % 26) + 65) + label
    nextIndex = Math.floor(nextIndex / 26) - 1
  }

  return label
}

function getColumnWidth(header: string, rows: string[][], columnIndex: number) {
  const longestCellLength = rows.reduce((maxLength, row) => {
    const valueLength = (row[columnIndex] || '').trim().length
    return Math.max(maxLength, valueLength)
  }, header.trim().length)

  const estimatedWidth = 56 + longestCellLength * 7
  return Math.min(Math.max(estimatedWidth, 112), 232)
}

export function PricingWorkspace({
  roleLabel,
  sheet,
  importPricingSheetAction,
  savePricingSheetAction,
  clearPricingSheetAction,
}: {
  roleLabel: string
  sheet: PricingSheet
  importPricingSheetAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
  savePricingSheetAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
  clearPricingSheetAction: () => Promise<{ ok: boolean; error?: string }>
}) {
  const router = useRouter()
  const importFormRef = useRef<HTMLFormElement>(null)
  const [feedback, setFeedback] = useState<{ type: 'error' | 'success'; message: string } | null>(null)
  const [headers, setHeaders] = useState<string[]>(sheet.headers.length > 0 ? sheet.headers : ['Kolumna 1', 'Kolumna 2'])
  const [rows, setRows] = useState<string[][]>(
    sheet.rows.length > 0
      ? sheet.rows.map((row) => {
          const nextRow = [...row]

          while (nextRow.length < (sheet.headers.length || 2)) {
            nextRow.push('')
          }

          return nextRow.slice(0, sheet.headers.length || 2)
        })
      : [new Array(Math.max(sheet.headers.length, 2)).fill('')]
  )

  useEffect(() => {
    const nextHeaders = sheet.headers.length > 0 ? sheet.headers : ['Kolumna 1', 'Kolumna 2']
    setHeaders(nextHeaders)
    setRows(
      sheet.rows.length > 0
        ? sheet.rows.map((row) => {
            const nextRow = [...row]

            while (nextRow.length < nextHeaders.length) {
              nextRow.push('')
            }

            return nextRow.slice(0, nextHeaders.length)
          })
        : [new Array(nextHeaders.length).fill('')]
    )
  }, [sheet.headers, sheet.rows])

  const stats = useMemo(() => ({
    columns: headers.length,
    rows: rows.filter((row) => row.some((cell) => cell.trim().length > 0)).length,
  }), [headers, rows])

  const columnWidths = useMemo(
    () => headers.map((header, index) => getColumnWidth(header, rows, index)),
    [headers, rows]
  )

  function updateHeader(index: number, value: string) {
    setHeaders((current) => current.map((header, headerIndex) => (headerIndex === index ? value : header)))
  }

  function updateCell(rowIndex: number, columnIndex: number, value: string) {
    setRows((current) => current.map((row, currentRowIndex) => (
      currentRowIndex === rowIndex
        ? row.map((cell, currentColumnIndex) => (currentColumnIndex === columnIndex ? value : cell))
        : row
    )))
  }

  function addColumn() {
    const nextIndex = headers.length + 1
    setHeaders((current) => [...current, `Kolumna ${nextIndex}`])
    setRows((current) => current.map((row) => [...row, '']))
  }

  function removeColumn(index: number) {
    if (headers.length <= 2) {
      setFeedback({ type: 'error', message: 'Arkusz musi mieć przynajmniej dwie kolumny.' })
      return
    }

    setHeaders((current) => current.filter((_, currentIndex) => currentIndex !== index))
    setRows((current) => current.map((row) => row.filter((_, currentIndex) => currentIndex !== index)))
  }

  function addRow() {
    setRows((current) => [...current, new Array(headers.length).fill('')])
  }

  function removeRow(index: number) {
    if (rows.length <= 1) {
      setRows([new Array(headers.length).fill('')])
      return
    }

    setRows((current) => current.filter((_, currentIndex) => currentIndex !== index))
  }

  async function handleImport(formData: FormData) {
    setFeedback(null)
    const result = await importPricingSheetAction(formData)

    if (!result.ok) {
      setFeedback({ type: 'error', message: result.error || 'Nie udało się zaimportować danych.' })
      return
    }

    setFeedback({ type: 'success', message: 'Tabela została zaimportowana z Excela do arkusza CRM.' })
    importFormRef.current?.reset()
    router.refresh()
  }

  async function handleSave() {
    setFeedback(null)
    const formData = new FormData()
    formData.set('headersJson', JSON.stringify(headers))
    formData.set('rowsJson', JSON.stringify(rows))

    const result = await savePricingSheetAction(formData)

    if (!result.ok) {
      setFeedback({ type: 'error', message: result.error || 'Nie udało się zapisać danych.' })
      return
    }

    setFeedback({ type: 'success', message: 'Baza samochodów została zapisana.' })
    router.refresh()
  }

  async function handleClear() {
    setFeedback(null)
    const result = await clearPricingSheetAction()

    if (!result.ok) {
      setFeedback({ type: 'error', message: result.error || 'Nie udało się wyczyścić bazy.' })
      return
    }

    setFeedback({ type: 'success', message: 'Baza cenowa została wyczyszczona.' })
    router.refresh()
  }

  return (
    <main className="grid gap-4">
      <section className="rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] px-4 py-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:px-5">
        <div className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
          <div className="min-w-0">
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Polityka cenowa</div>
            <div className="mt-2 flex flex-col gap-2 xl:flex-row xl:items-center xl:gap-4">
              <h2 className="text-2xl font-semibold text-white">Wewnętrzna baza samochodów do ofert</h2>
              <span className="inline-flex w-fit rounded-full border border-white/8 bg-white/[0.03] px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#aeb7c2]">
                Rola: {roleLabel}
              </span>
            </div>
            <p className="mt-3 max-w-4xl text-sm leading-6 text-[#9ba6b2]">
              To jest pierwszy krok zamiast integracji z Google Sheets. Edytujesz arkusz bezpośrednio w CRM,
              wklejasz wartości do konkretnych pól i zapisujesz bazę wejściową do późniejszego generatora ofert.
            </p>
          </div>

          <div className="flex flex-wrap gap-2 text-xs uppercase tracking-[0.16em] text-[#aeb7c2]">
            <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Kolumny: {stats.columns}</span>
            <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Wiersze: {stats.rows}</span>
            <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Aktualizacja: {formatDate(sheet.updatedAt)}</span>
          </div>
        </div>
      </section>

      <section className="grid gap-4 xl:grid-cols-[360px_minmax(0,1fr)]">
        <div className="grid gap-4">
          <form ref={importFormRef} action={handleImport} className="grid gap-4 rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:p-5">
            <div className="flex items-center gap-3">
              <ClipboardPaste className="h-5 w-5 text-[#f3d998]" />
              <div>
                <div className="text-sm font-semibold text-white">Import na start z Excela</div>
                <div className="text-sm text-[#9ba6b2]">Wklej cały zakres z arkusza razem z nagłówkami, a potem edytuj dalej ręcznie w tabeli.</div>
              </div>
            </div>

            <textarea
              name="sheetInput"
              rows={8}
              className="w-full rounded-[24px] border border-white/10 bg-[#111821] px-4 py-4 font-mono text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]"
              placeholder={['Stock\tMarka\tModel\tWersja\tCena brutto', 'VP-001\tBYD\tSeal 6 DM-i\tComfort\t184900', 'VP-002\tBYD\tSeal U\tDesign\t203500'].join('\n')}
            />

            <button type="submit" className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl border border-[rgba(216,180,90,0.4)] bg-[linear-gradient(135deg,#d8b45a,#b98b1d)] px-4 text-sm font-semibold text-[#111827] transition hover:brightness-105">
              <Database className="h-4 w-4" />
              <span>Importuj do arkusza</span>
            </button>
          </form>

          <section className="grid gap-4 rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:p-5">
            <div className="flex items-center gap-3">
              <TableProperties className="h-5 w-5 text-[#f3d998]" />
              <div>
                <div className="text-sm font-semibold text-white">Edytuj bazę w polach</div>
                <div className="text-sm text-[#9ba6b2]">Klikasz w komórkę, wklejasz wartość i zapisujesz całą tabelę.</div>
              </div>
            </div>

            <div className="rounded-[24px] border border-white/8 bg-white/[0.03] p-4 text-sm leading-6 text-[#c2cad4]">
              Możesz zacząć od importu całej tabeli, a potem pracować jak na prostym Excelu: dodawać kolumny,
              dodawać wiersze, usuwać zbędne pozycje i ręcznie wklejać dane do konkretnych pól.
            </div>

            {feedback ? (
              <div className={[
                'rounded-2xl px-4 py-3 text-sm',
                feedback.type === 'success'
                  ? 'border border-emerald-400/20 bg-emerald-500/10 text-emerald-200'
                  : 'border border-red-400/20 bg-red-500/10 text-red-200',
              ].join(' ')}>
                {feedback.message}
              </div>
            ) : null}

            <div className="flex flex-wrap gap-3">
              <button type="button" onClick={handleSave} className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl border border-[rgba(216,180,90,0.4)] bg-[linear-gradient(135deg,#d8b45a,#b98b1d)] px-4 text-sm font-semibold text-[#111827] transition hover:brightness-105">
                <Save className="h-4 w-4" />
                <span>Zapisz bazę</span>
              </button>
              <button type="button" onClick={addRow} className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm font-medium text-white transition hover:bg-white/[0.08]">
                <Plus className="h-4 w-4" />
                <span>Dodaj wiersz</span>
              </button>
              <button type="button" onClick={addColumn} className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm font-medium text-white transition hover:bg-white/[0.08]">
                <Database className="h-4 w-4" />
                <span>Dodaj kolumnę</span>
              </button>
              <button type="button" onClick={handleClear} className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm font-medium text-white transition hover:bg-white/[0.08]">
                <Eraser className="h-4 w-4" />
                <span>Wyczyść tabelę</span>
              </button>
            </div>
          </section>

          <section className="rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:p-5">
            <div className="flex items-center gap-3">
              <Database className="h-5 w-5 text-[#f3d998]" />
              <div>
                <div className="text-sm font-semibold text-white">Co już daje ten krok</div>
                <div className="text-sm text-[#9ba6b2]">Budujemy bazę wejściową pod ofertowanie bez zależności od zewnętrznego arkusza.</div>
              </div>
            </div>
            <div className="mt-4 grid gap-2 text-sm text-[#c2cad4]">
              <div>1. Możesz ręcznie wklejać i poprawiać dane w konkretnych komórkach.</div>
              <div>2. Sam decydujesz o układzie kolumn i liczbie wierszy.</div>
              <div>3. W kolejnym kroku wspólnie ustalimy, które pola trafią do generatora oferty.</div>
            </div>
          </section>
        </div>

        <section className="rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:p-5">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Arkusz bazy</div>
              <div className="mt-1 text-sm text-[#9ba6b2]">Widok roboczy jak prosty Excel. Ostatnia aktualizacja: {formatDate(sheet.updatedAt)}</div>
            </div>
            <div className="text-xs uppercase tracking-[0.16em] text-[#aeb7c2]">Autor: {sheet.updatedBy ?? 'Seed systemowy'}</div>
          </div>

          <div className="mt-4 overflow-auto rounded-[10px] border border-white/10 bg-[#0f141b] shadow-[0_8px_24px_rgba(0,0,0,0.22)]">
            <table className="min-w-full border-collapse font-mono text-sm text-[#d8dee7]">
              <thead className="sticky top-0 z-20 bg-[#1a222d]">
                <tr>
                  <th className="sticky left-0 top-0 z-30 w-[64px] border border-white/10 bg-[#151c25] px-3 py-1 text-center text-[10px] uppercase tracking-[0.18em] text-[#7f8a97]">
                    Sheet
                  </th>
                  {headers.map((_, index) => (
                    <th
                      key={`letter-${index}`}
                      className="border border-white/10 bg-[#151c25] px-3 py-1 text-center text-[11px] font-semibold uppercase tracking-[0.18em] text-[#9ea8b5]"
                      style={{ width: `${columnWidths[index]}px`, minWidth: `${columnWidths[index]}px` }}
                    >
                      {getColumnLabel(index)}
                    </th>
                  ))}
                </tr>
                <tr>
                  <th className="sticky left-0 top-[29px] z-30 border border-white/10 bg-[#1a222d] px-3 py-1.5 text-left text-[11px] uppercase tracking-[0.18em] text-[#7f8a97]">#</th>
                  {headers.map((header, index) => (
                    <th
                      key={`${header}-${index}`}
                      className="border border-white/10 bg-[#1a222d] px-2 py-1 text-left text-[11px] uppercase tracking-[0.18em] text-[#f3d998]"
                      style={{ width: `${columnWidths[index]}px`, minWidth: `${columnWidths[index]}px` }}
                    >
                      <div className="flex items-center gap-2">
                        <input
                          value={header}
                          onChange={(event) => updateHeader(index, event.target.value)}
                          className="w-full border border-white/10 bg-[#111821] px-2 py-[3px] text-[11px] leading-4 font-semibold uppercase tracking-[0.12em] text-white outline-none transition focus:border-[rgba(216,180,90,0.45)] focus:ring-1 focus:ring-[rgba(216,180,90,0.35)]"
                        />
                        <button type="button" onClick={() => removeColumn(index)} className="inline-flex h-8 w-8 shrink-0 items-center justify-center border border-white/10 bg-white/[0.03] text-[#d5dce5] transition hover:bg-white/[0.08]">
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.length > 0 ? rows.map((row, rowIndex) => (
                  <tr key={`row-${rowIndex}`} className="bg-[#0f141b] even:bg-[#121922] hover:bg-[#151d27]">
                    <td className="sticky left-0 z-10 border border-white/10 bg-inherit px-2 py-1 align-middle text-[11px] uppercase tracking-[0.16em] text-[#7f8a97]">
                      <div className="flex items-center justify-between gap-2">
                        <span className="min-w-[16px] text-center">{rowIndex + 1}</span>
                        <button type="button" onClick={() => removeRow(rowIndex)} className="inline-flex h-6 w-6 items-center justify-center border border-white/10 bg-white/[0.03] text-[#d5dce5] transition hover:bg-white/[0.08]">
                          <Trash2 className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    </td>
                    {headers.map((_, columnIndex) => (
                      <td
                        key={`cell-${rowIndex}-${columnIndex}`}
                        className="border border-white/10 p-0 align-top text-sm text-[#d8dee7]"
                        style={{ width: `${columnWidths[columnIndex]}px`, minWidth: `${columnWidths[columnIndex]}px` }}
                      >
                        <input
                          value={row[columnIndex] || ''}
                          onChange={(event) => updateCell(rowIndex, columnIndex, event.target.value)}
                          className={[
                            'w-full border-0 bg-transparent px-2.5 py-[3px] text-sm leading-4 text-[#f5f7fa] outline-none transition',
                            'focus:bg-[#1b2430] focus:ring-2 focus:ring-inset focus:ring-[rgba(216,180,90,0.25)]',
                          ].join(' ')}
                        />
                      </td>
                    ))}
                  </tr>
                )) : (
                  <tr>
                    <td colSpan={Math.max(headers.length + 1, 2)} className="bg-[#0f141b] px-4 py-16 text-center text-sm text-[#7f8a97]">
                      Tabela jest pusta. Dodaj wiersz lub kolumnę i uzupełnij dane bezpośrednio w polach.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>
      </section>
    </main>
  )
}