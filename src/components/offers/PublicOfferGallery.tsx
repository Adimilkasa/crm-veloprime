'use client'

import { useEffect, useState } from 'react'

export function PublicOfferGallery({
  modelLabel,
  gallery,
}: {
  modelLabel: string
  gallery: string[]
}) {
  const [activeIndex, setActiveIndex] = useState<number | null>(null)

  useEffect(() => {
    if (activeIndex === null) {
      return
    }

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        setActiveIndex(null)
        return
      }

      if (event.key === 'ArrowRight') {
        setActiveIndex((current) => {
          if (current === null) {
            return current
          }

          return (current + 1) % gallery.length
        })
      }

      if (event.key === 'ArrowLeft') {
        setActiveIndex((current) => {
          if (current === null) {
            return current
          }

          return (current - 1 + gallery.length) % gallery.length
        })
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [activeIndex, gallery.length])

  if (gallery.length === 0) {
    return (
      <div className="rounded-[26px] border border-dashed border-[rgba(20,33,61,0.14)] bg-[linear-gradient(180deg,#f8fbfe_0%,#f5f8fc_100%)] px-6 py-10 text-sm leading-8 text-[#5f6d87]">
        Ta oferta nie ma jeszcze kompletnej galerii. Sam link pozostaje aktywny, a opiekun może uzupełnić materiały lub dosłać dodatkową prezentację produktu.
      </div>
    )
  }

  const featured = gallery[0]
  const secondary = gallery.slice(1, 5)

  return (
    <>
      <div className="grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
        <button
          type="button"
          onClick={() => setActiveIndex(0)}
          className="group relative overflow-hidden rounded-[28px] border border-[rgba(20,33,61,0.08)] bg-[#eef3f9] text-left shadow-[0_18px_50px_rgba(17,32,67,0.08)]"
        >
          {/* eslint-disable-next-line @next/next/no-img-element -- product gallery uses static asset URLs */}
          <img src={featured} alt={modelLabel} className="h-[300px] w-full object-cover transition duration-300 group-hover:scale-[1.01] sm:h-[340px]" />
          <div className="pointer-events-none absolute inset-x-0 bottom-0 bg-[linear-gradient(180deg,transparent_0%,rgba(10,20,37,0.78)_100%)] p-5 text-white">
            <div className="flex items-end justify-between gap-4">
              <div>
                <div className="text-[11px] font-semibold uppercase tracking-[0.24em] text-white/65">Galeria modelu</div>
                <div className="mt-2 text-sm font-semibold sm:text-base">Kliknij, aby otworzyć pełną galerię</div>
              </div>
              <div className="rounded-full border border-white/15 bg-white/10 px-3 py-2 text-xs font-semibold text-white/82">
                {gallery.length} zdjęć
              </div>
            </div>
          </div>
        </button>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-1">
          {secondary.map((imageUrl, index) => (
            <button
              key={imageUrl}
              type="button"
              onClick={() => setActiveIndex(index + 1)}
              className="group relative overflow-hidden rounded-[24px] border border-[rgba(20,33,61,0.08)] bg-[#eef3f9] text-left shadow-[0_16px_40px_rgba(17,32,67,0.07)]"
            >
              {/* eslint-disable-next-line @next/next/no-img-element -- product gallery uses static asset URLs */}
              <img src={imageUrl} alt={`${modelLabel} ${index + 2}`} className="h-[148px] w-full object-cover transition duration-300 group-hover:scale-[1.02] sm:h-[164px]" />
              <div className="pointer-events-none absolute left-3 top-3 rounded-full border border-white/18 bg-[rgba(9,18,33,0.5)] px-2.5 py-1 text-[11px] font-semibold text-white/82">
                {index + 2}
              </div>
            </button>
          ))}
        </div>
      </div>

      {gallery.length > 5 ? (
        <div className="mt-4 flex flex-wrap gap-3">
          {gallery.slice(5).map((imageUrl, index) => (
            <button
              key={imageUrl}
              type="button"
              onClick={() => setActiveIndex(index + 5)}
              className="group relative overflow-hidden rounded-[22px] border border-[rgba(20,33,61,0.08)] bg-[#eef3f9] text-left shadow-[0_14px_34px_rgba(17,32,67,0.06)]"
            >
              {/* eslint-disable-next-line @next/next/no-img-element -- product gallery uses static asset URLs */}
              <img src={imageUrl} alt={`${modelLabel} ${index + 6}`} className="h-[92px] w-[132px] object-cover transition duration-300 group-hover:scale-[1.02]" />
              <div className="pointer-events-none absolute left-3 top-3 rounded-full border border-white/18 bg-[rgba(9,18,33,0.5)] px-2.5 py-1 text-[11px] font-semibold text-white/82">
                {index + 6}
              </div>
            </button>
          ))}
        </div>
      ) : null}

      {activeIndex !== null ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-[rgba(7,14,26,0.9)] px-4 py-6" role="dialog" aria-modal="true">
          <button type="button" onClick={() => setActiveIndex(null)} className="absolute right-5 top-5 rounded-full border border-white/15 bg-white/10 px-4 py-2 text-sm font-medium text-white transition hover:bg-white/16">
            Zamknij
          </button>
          <button
            type="button"
            onClick={() => setActiveIndex((activeIndex - 1 + gallery.length) % gallery.length)}
            className="absolute left-4 top-1/2 -translate-y-1/2 rounded-full border border-white/15 bg-white/10 px-4 py-3 text-white transition hover:bg-white/16"
            aria-label="Poprzednie zdjęcie"
          >
            ‹
          </button>
          <div className="mx-auto max-w-6xl">
            {/* eslint-disable-next-line @next/next/no-img-element -- product gallery uses static asset URLs */}
            <img src={gallery[activeIndex]} alt={`${modelLabel} ${activeIndex + 1}`} className="max-h-[78vh] w-auto max-w-full rounded-[28px] object-contain shadow-[0_30px_120px_rgba(0,0,0,0.35)]" />
            <div className="mt-4 text-center text-sm text-white/74">
              {activeIndex + 1} / {gallery.length}
            </div>
          </div>
          <button
            type="button"
            onClick={() => setActiveIndex((activeIndex + 1) % gallery.length)}
            className="absolute right-4 top-1/2 -translate-y-1/2 rounded-full border border-white/15 bg-white/10 px-4 py-3 text-white transition hover:bg-white/16"
            aria-label="Następne zdjęcie"
          >
            ›
          </button>
        </div>
      ) : null}
    </>
  )
}