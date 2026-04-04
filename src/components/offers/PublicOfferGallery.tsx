'use client'

import { useEffect, useMemo, useState } from 'react'

export type PublicOfferGallerySection = {
  title: string
  images: string[]
}

export function PublicOfferGallery({
  modelLabel,
  sections,
}: {
  modelLabel: string
  sections: PublicOfferGallerySection[]
}) {
  const [activeIndex, setActiveIndex] = useState<number | null>(null)

  const allImages = useMemo(
    () => sections.flatMap((section) => section.images).filter((image, index, all) => all.indexOf(image) === index),
    [sections],
  )

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
        setActiveIndex((current) => (current === null ? current : (current + 1) % allImages.length))
      }

      if (event.key === 'ArrowLeft') {
        setActiveIndex((current) => (current === null ? current : (current - 1 + allImages.length) % allImages.length))
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [activeIndex, allImages.length])

  if (allImages.length === 0) {
    return (
      <div className="rounded-[30px] border border-white/75 bg-[linear-gradient(180deg,rgba(255,255,255,0.78),rgba(249,245,237,0.72))] px-6 py-12 text-[15px] leading-8 text-[#6e6e73] backdrop-blur-sm">
        Ta oferta nie ma jeszcze kompletnej galerii. Sam link pozostaje aktywny, a opiekun może uzupełnić materiały po rozmowie z klientem.
      </div>
    )
  }

  return (
    <>
      <div className="space-y-8 lg:space-y-10">
        {sections.map((section) => {
          const featured = section.images[0]
          const thumbnails = section.images.slice(1, 5)

          if (!featured) {
            return null
          }

          return (
            <div key={section.title} className="space-y-4">
              <div className="flex items-center justify-between gap-3">
                <h3 className="text-[22px] font-semibold tracking-[-0.03em] text-[#1d1d1f] sm:text-[24px]">{section.title}</h3>
                <div className="rounded-full border border-[rgba(190,147,62,0.18)] bg-white/78 px-3 py-1.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-[#8d6b2f]">
                  {section.images.length} ujęć
                </div>
              </div>

              <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_240px] lg:items-start">
                <button
                  type="button"
                  onClick={() => setActiveIndex(allImages.indexOf(featured))}
                  className="group relative block w-full overflow-hidden rounded-[30px] bg-[#e8eaed] text-left shadow-[0_18px_42px_rgba(15,23,42,0.08)]"
                >
                  {/* eslint-disable-next-line @next/next/no-img-element -- product gallery uses direct asset URLs */}
                  <img src={featured} alt={`${modelLabel} ${section.title}`} className="aspect-[16/10] w-full object-cover transition duration-500 group-hover:scale-[1.015]" />
                  <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(255,255,255,0.03)_0%,rgba(12,18,28,0.08)_54%,rgba(12,18,28,0.28)_100%)]" />
                  <div className="absolute inset-x-4 bottom-4 flex items-center justify-between gap-3">
                    <span className="rounded-full bg-white/16 px-3 py-1.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-white backdrop-blur-sm ring-1 ring-white/16">
                      {section.title}
                    </span>
                    <span className="rounded-full bg-[rgba(12,18,28,0.34)] px-3 py-1.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-white/86 backdrop-blur-sm">
                      Otwórz galerię
                    </span>
                  </div>
                </button>

                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-1">
                  {thumbnails.map((imageUrl, index) => (
                    <button
                      key={`${section.title}-${imageUrl}`}
                      type="button"
                      onClick={() => setActiveIndex(allImages.indexOf(imageUrl))}
                      className="group overflow-hidden rounded-[24px] bg-[#e8eaed] shadow-[0_12px_32px_rgba(15,23,42,0.06)] ring-1 ring-white/65"
                    >
                      {/* eslint-disable-next-line @next/next/no-img-element -- product gallery uses direct asset URLs */}
                      <img src={imageUrl} alt={`${modelLabel} ${section.title} ${index + 2}`} className="aspect-[4/3] w-full object-cover transition duration-300 group-hover:scale-[1.02]" />
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )
        })}
      </div>

      {activeIndex !== null ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-[rgba(12,18,28,0.92)] px-4 py-6" role="dialog" aria-modal="true">
          <button type="button" onClick={() => setActiveIndex(null)} className="absolute right-5 top-5 rounded-full bg-white/10 px-4 py-2 text-sm font-medium text-white transition hover:bg-white/16">
            Zamknij
          </button>
          <button
            type="button"
            onClick={() => setActiveIndex((activeIndex - 1 + allImages.length) % allImages.length)}
            className="absolute left-4 top-1/2 -translate-y-1/2 rounded-full bg-white/10 px-4 py-3 text-white transition hover:bg-white/16"
            aria-label="Poprzednie zdjęcie"
          >
            ‹
          </button>
          <div className="mx-auto max-w-6xl">
            {/* eslint-disable-next-line @next/next/no-img-element -- product gallery uses direct asset URLs */}
            <img src={allImages[activeIndex]} alt={`${modelLabel} ${activeIndex + 1}`} className="max-h-[78vh] w-auto max-w-full rounded-[30px] object-contain" />
            <div className="mt-4 text-center text-sm text-white/72">
              {activeIndex + 1} / {allImages.length}
            </div>
          </div>
          <button
            type="button"
            onClick={() => setActiveIndex((activeIndex + 1) % allImages.length)}
            className="absolute right-4 top-1/2 -translate-y-1/2 rounded-full bg-white/10 px-4 py-3 text-white transition hover:bg-white/16"
            aria-label="Następne zdjęcie"
          >
            ›
          </button>
        </div>
      ) : null}
    </>
  )
}