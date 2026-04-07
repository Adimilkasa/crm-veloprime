'use client'

import { useEffect, useMemo, useRef, useState } from 'react'

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
  const touchStartXRef = useRef<number | null>(null)

  const allImages = useMemo(
    () => sections.flatMap((section) => section.images).filter((image, index, all) => all.indexOf(image) === index),
    [sections],
  )

  const activeImage = activeIndex === null ? null : allImages[activeIndex] ?? null

  function closeLightbox() {
    setActiveIndex(null)
  }

  function showPreviousImage() {
    setActiveIndex((current) => (current === null ? current : (current - 1 + allImages.length) % allImages.length))
  }

  function showNextImage() {
    setActiveIndex((current) => (current === null ? current : (current + 1) % allImages.length))
  }

  useEffect(() => {
    if (activeIndex === null) {
      return
    }

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        closeLightbox()
        return
      }

      if (event.key === 'ArrowRight') {
        showNextImage()
      }

      if (event.key === 'ArrowLeft') {
        showPreviousImage()
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [activeIndex, allImages.length])

  useEffect(() => {
    if (activeIndex === null) {
      return
    }

    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'

    return () => {
      document.body.style.overflow = previousOverflow
    }
  }, [activeIndex])

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

      {activeIndex !== null && activeImage ? (
        <div
          className="fixed inset-0 z-50 bg-[rgba(8,12,18,0.88)] backdrop-blur-md"
          role="dialog"
          aria-modal="true"
          aria-label={`Galeria zdjęć ${modelLabel}`}
          onClick={closeLightbox}
        >
          <div className="flex min-h-full items-center justify-center px-3 py-3 sm:px-5 sm:py-5 lg:px-8 lg:py-8">
            <div
              className="relative flex h-[min(100%,calc(100svh-1.5rem))] w-full max-w-6xl flex-col overflow-hidden rounded-[28px] border border-white/10 bg-[linear-gradient(180deg,rgba(17,24,39,0.96),rgba(10,14,22,0.98))] shadow-[0_32px_120px_rgba(0,0,0,0.46)] sm:h-[min(100%,calc(100svh-2.5rem))]"
              onClick={(event) => event.stopPropagation()}
            >
              <div className="flex items-center justify-between gap-3 border-b border-white/10 px-4 py-3 sm:px-5 sm:py-4">
                <div className="min-w-0">
                  <div className="text-[11px] font-semibold uppercase tracking-[0.18em] text-white/46">Galeria oferty</div>
                  <div className="mt-1 truncate text-[15px] font-medium text-white/88 sm:text-[16px]">{modelLabel}</div>
                </div>
                <div className="flex items-center gap-2">
                  <div className="rounded-full border border-white/10 bg-white/6 px-3 py-1.5 text-[11px] font-semibold uppercase tracking-[0.16em] text-white/66 sm:text-[12px]">
                    {activeIndex + 1} / {allImages.length}
                  </div>
                  <button
                    type="button"
                    onClick={closeLightbox}
                    className="inline-flex h-10 w-10 items-center justify-center rounded-full border border-white/10 bg-white/6 text-lg text-white transition hover:bg-white/12"
                    aria-label="Zamknij galerię"
                  >
                    ✕
                  </button>
                </div>
              </div>

              <div className="relative flex min-h-0 flex-1 items-center justify-center bg-[radial-gradient(circle_at_center,rgba(255,255,255,0.07),transparent_56%)] px-3 py-3 sm:px-5 sm:py-5">
                <button
                  type="button"
                  onClick={showPreviousImage}
                  className="absolute left-3 top-1/2 z-10 hidden h-12 w-12 -translate-y-1/2 items-center justify-center rounded-full border border-white/10 bg-[rgba(15,23,42,0.62)] text-[28px] text-white transition hover:bg-[rgba(15,23,42,0.82)] lg:inline-flex"
                  aria-label="Poprzednie zdjęcie"
                >
                  ‹
                </button>

                <div
                  className="flex h-full w-full items-center justify-center overflow-hidden rounded-[22px] bg-[linear-gradient(180deg,rgba(255,255,255,0.03),rgba(255,255,255,0.01))] ring-1 ring-white/8"
                  onTouchStart={(event) => {
                    touchStartXRef.current = event.changedTouches[0]?.clientX ?? null
                  }}
                  onTouchEnd={(event) => {
                    const startX = touchStartXRef.current
                    const endX = event.changedTouches[0]?.clientX ?? null
                    touchStartXRef.current = null

                    if (startX == null || endX == null) {
                      return
                    }

                    const delta = endX - startX
                    if (Math.abs(delta) < 48) {
                      return
                    }

                    if (delta < 0) {
                      showNextImage()
                      return
                    }

                    showPreviousImage()
                  }}
                >
                  {/* eslint-disable-next-line @next/next/no-img-element -- product gallery uses direct asset URLs */}
                  <img
                    src={activeImage}
                    alt={`${modelLabel} ${activeIndex + 1}`}
                    className="max-h-full w-auto max-w-full object-contain select-none"
                  />
                </div>

                <button
                  type="button"
                  onClick={showNextImage}
                  className="absolute right-3 top-1/2 z-10 hidden h-12 w-12 -translate-y-1/2 items-center justify-center rounded-full border border-white/10 bg-[rgba(15,23,42,0.62)] text-[28px] text-white transition hover:bg-[rgba(15,23,42,0.82)] lg:inline-flex"
                  aria-label="Następne zdjęcie"
                >
                  ›
                </button>
              </div>

              <div className="flex items-center justify-between gap-3 border-t border-white/10 px-4 py-3 sm:px-5 sm:py-4 lg:hidden">
                <button
                  type="button"
                  onClick={showPreviousImage}
                  className="inline-flex min-w-[96px] items-center justify-center rounded-full border border-white/10 bg-white/6 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-white/12"
                >
                  Wstecz
                </button>
                <div className="text-center text-[12px] font-medium text-white/62">
                  Przesuń palcem lub użyj przycisków
                </div>
                <button
                  type="button"
                  onClick={showNextImage}
                  className="inline-flex min-w-[96px] items-center justify-center rounded-full border border-white/10 bg-white/6 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-white/12"
                >
                  Dalej
                </button>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </>
  )
}