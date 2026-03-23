'use client'

import { useEffect, useMemo, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Palette, Plus, Save, Trash2 } from 'lucide-react'

type ColorOption = {
  name: string
  isBase: boolean
  surchargeGross: number | null
  surchargeNet: number | null
  sortOrder: number
}

type ColorPalette = {
  paletteKey: string
  brand: string
  model: string
  baseColorName: string
  optionalColorSurchargeGross: number | null
  optionalColorSurchargeNet: number | null
  colors: ColorOption[]
}

function createEmptyPalette(index: number): ColorPalette {
  return {
    paletteKey: `draft-${index}`,
    brand: '',
    model: '',
    baseColorName: '',
    optionalColorSurchargeGross: null,
    optionalColorSurchargeNet: null,
    colors: [
      {
        name: '',
        isBase: true,
        surchargeGross: 0,
        surchargeNet: 0,
        sortOrder: 0,
      },
    ],
  }
}

function parseNumber(value: string) {
  if (!value.trim()) {
    return null
  }

  const parsed = Number(value.replace(',', '.'))
  return Number.isFinite(parsed) ? parsed : null
}

export function ColorPalettesWorkspace({
  roleLabel,
  palettes,
  saveColorPalettesAction,
}: {
  roleLabel: string
  palettes: ColorPalette[]
  saveColorPalettesAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
}) {
  const router = useRouter()
  const [draftPalettes, setDraftPalettes] = useState<ColorPalette[]>(palettes)
  const [selectedPaletteKey, setSelectedPaletteKey] = useState<string>(palettes[0]?.paletteKey ?? '')
  const [feedback, setFeedback] = useState<{ type: 'error' | 'success'; message: string } | null>(null)

  useEffect(() => {
    setDraftPalettes(palettes)
    setSelectedPaletteKey(palettes[0]?.paletteKey ?? '')
  }, [palettes])

  const selectedPalette = draftPalettes.find((palette) => palette.paletteKey === selectedPaletteKey) ?? null
  const stats = useMemo(() => ({
    palettes: draftPalettes.length,
    colors: draftPalettes.reduce((total, palette) => total + palette.colors.length, 0),
  }), [draftPalettes])

  function updatePalette(paletteKey: string, updater: (palette: ColorPalette) => ColorPalette) {
    setDraftPalettes((current) => current.map((palette) => palette.paletteKey === paletteKey ? updater(palette) : palette))
  }

  function addPalette() {
    const nextPalette = createEmptyPalette(draftPalettes.length + 1)
    setDraftPalettes((current) => [...current, nextPalette])
    setSelectedPaletteKey(nextPalette.paletteKey)
  }

  function removePalette(paletteKey: string) {
    const next = draftPalettes.filter((palette) => palette.paletteKey !== paletteKey)
    setDraftPalettes(next)
    setSelectedPaletteKey(next[0]?.paletteKey ?? '')
  }

  function addColor() {
    if (!selectedPalette) {
      return
    }

    updatePalette(selectedPalette.paletteKey, (palette) => ({
      ...palette,
      colors: [...palette.colors, {
        name: '',
        isBase: false,
        surchargeGross: palette.optionalColorSurchargeGross,
        surchargeNet: palette.optionalColorSurchargeNet,
        sortOrder: palette.colors.length,
      }],
    }))
  }

  function removeColor(index: number) {
    if (!selectedPalette) {
      return
    }

    updatePalette(selectedPalette.paletteKey, (palette) => ({
      ...palette,
      colors: palette.colors.filter((_, colorIndex) => colorIndex !== index),
    }))
  }

  async function handleSave() {
    setFeedback(null)
    const formData = new FormData()
    formData.set('palettesJson', JSON.stringify(draftPalettes))
    const result = await saveColorPalettesAction(formData)

    if (!result.ok) {
      setFeedback({ type: 'error', message: result.error ?? 'Nie udało się zapisać palet kolorów.' })
      return
    }

    setFeedback({ type: 'success', message: 'Palety kolorów zostały zapisane.' })
    router.refresh()
  }

  return (
    <main className="grid gap-4">
      <section className="rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] px-4 py-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:px-5">
        <div className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
          <div className="min-w-0">
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Palety kolorow</div>
            <div className="mt-2 flex flex-col gap-2 xl:flex-row xl:items-center xl:gap-4">
              <h2 className="text-2xl font-semibold text-white">Konfiguracja lakierow do ofert</h2>
              <span className="inline-flex w-fit rounded-full border border-white/8 bg-white/[0.03] px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#aeb7c2]">
                Rola: {roleLabel}
              </span>
            </div>
          </div>

          <div className="flex flex-wrap gap-2 text-xs uppercase tracking-[0.16em] text-[#aeb7c2]">
            <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Palety: {stats.palettes}</span>
            <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Kolory: {stats.colors}</span>
          </div>
        </div>
      </section>

      <section className="grid gap-4 xl:grid-cols-[320px_minmax(0,1fr)]">
        <section className="grid gap-4 rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:p-5">
          <button type="button" onClick={addPalette} className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl border border-[rgba(216,180,90,0.4)] bg-[linear-gradient(135deg,#d8b45a,#b98b1d)] px-4 text-sm font-semibold text-[#111827] transition hover:brightness-105">
            <Plus className="h-4 w-4" />
            <span>Dodaj palete</span>
          </button>

          <div className="grid gap-3">
            {draftPalettes.map((palette) => (
              <button key={palette.paletteKey} type="button" onClick={() => setSelectedPaletteKey(palette.paletteKey)} className={[
                'rounded-[22px] border px-4 py-4 text-left transition',
                selectedPaletteKey === palette.paletteKey
                  ? 'border-[rgba(216,180,90,0.35)] bg-[rgba(216,180,90,0.08)] shadow-[0_12px_32px_rgba(0,0,0,0.18)]'
                  : 'border-white/8 bg-[rgba(18,24,33,0.78)] hover:border-white/16 hover:bg-[rgba(21,28,38,0.88)]',
              ].join(' ')}>
                <div className="text-[11px] uppercase tracking-[0.16em] text-[#8b96a3]">{palette.brand || 'Nowa marka'}</div>
                <div className="mt-2 text-sm font-semibold text-white">{palette.model || 'Nowy model'}</div>
                <div className="mt-3 text-sm text-[#c2cad4]">Bazowy: {palette.baseColorName || 'Do uzupelnienia'}</div>
              </button>
            ))}
          </div>
        </section>

        {selectedPalette ? (
          <section className="grid gap-4 rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:p-5">
            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-white">Marka</span>
                <input value={selectedPalette.brand} onChange={(event) => updatePalette(selectedPalette.paletteKey, (palette) => ({ ...palette, brand: event.target.value }))} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none" />
              </label>
              <label className="block">
                <span className="text-sm font-medium text-white">Model</span>
                <input value={selectedPalette.model} onChange={(event) => updatePalette(selectedPalette.paletteKey, (palette) => ({ ...palette, model: event.target.value }))} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none" />
              </label>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-white">Kolor bazowy</span>
                <input value={selectedPalette.baseColorName} onChange={(event) => updatePalette(selectedPalette.paletteKey, (palette) => ({ ...palette, baseColorName: event.target.value }))} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none" />
              </label>
              <label className="block">
                <span className="text-sm font-medium text-white">Domyslna doplata brutto</span>
                <input value={selectedPalette.optionalColorSurchargeGross ?? ''} onChange={(event) => updatePalette(selectedPalette.paletteKey, (palette) => ({ ...palette, optionalColorSurchargeGross: parseNumber(event.target.value) }))} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none" />
              </label>
            </div>

            <div className="grid gap-3 rounded-[24px] border border-white/8 bg-[#10161d] p-4">
              <div className="flex items-center justify-between gap-3">
                <div>
                  <div className="text-sm font-semibold text-white">Kolory w palecie</div>
                  <div className="text-sm text-[#9ba6b2]">Jeden kolor powinien byc bazowy z doplata 0 zl.</div>
                </div>
                <button type="button" onClick={addColor} className="inline-flex h-10 items-center justify-center gap-2 rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm font-medium text-white transition hover:bg-white/[0.08]">
                  <Plus className="h-4 w-4" />
                  <span>Dodaj kolor</span>
                </button>
              </div>

              {selectedPalette.colors.map((color, index) => (
                <div key={`${selectedPalette.paletteKey}-${index}`} className="grid gap-3 rounded-[20px] border border-white/8 bg-white/[0.03] p-4 md:grid-cols-[1.2fr_160px_120px_64px]">
                  <input value={color.name} onChange={(event) => updatePalette(selectedPalette.paletteKey, (palette) => ({ ...palette, colors: palette.colors.map((entry, colorIndex) => colorIndex === index ? { ...entry, name: event.target.value } : entry) }))} className="h-11 rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none" placeholder="Nazwa koloru" />
                  <input value={color.surchargeGross ?? ''} onChange={(event) => updatePalette(selectedPalette.paletteKey, (palette) => ({ ...palette, colors: palette.colors.map((entry, colorIndex) => colorIndex === index ? { ...entry, surchargeGross: parseNumber(event.target.value) } : entry) }))} className="h-11 rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none" placeholder="Brutto" />
                  <label className="flex h-11 items-center gap-2 rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white">
                    <input type="radio" checked={selectedPalette.baseColorName === color.name} onChange={() => updatePalette(selectedPalette.paletteKey, (palette) => ({ ...palette, baseColorName: color.name }))} />
                    <span>Bazowy</span>
                  </label>
                  <button type="button" onClick={() => removeColor(index)} className="inline-flex h-11 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.04] text-white transition hover:bg-white/[0.08]">
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              ))}
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
                <span>Zapisz palety</span>
              </button>
              <button type="button" onClick={() => removePalette(selectedPalette.paletteKey)} className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm font-medium text-white transition hover:bg-white/[0.08]">
                <Trash2 className="h-4 w-4" />
                <span>Usun palete</span>
              </button>
            </div>
          </section>
        ) : (
          <section className="rounded-[28px] border border-dashed border-white/10 bg-white/[0.03] px-4 py-20 text-center text-sm text-[#7f8a97]">
            Dodaj pierwsza palete albo wybierz istniejaca z listy.
          </section>
        )}
      </section>
    </main>
  )
}