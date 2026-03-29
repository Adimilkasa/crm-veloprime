'use client'

import { useState } from 'react'
import { Download, LoaderCircle } from 'lucide-react'

const COLOR_STYLE_PROPERTIES = [
  'color',
  'backgroundColor',
  'borderTopColor',
  'borderRightColor',
  'borderBottomColor',
  'borderLeftColor',
  'outlineColor',
  'textDecorationColor',
  'caretColor',
  'columnRuleColor',
  'fill',
  'stroke',
] as const

function usesUnsupportedColor(value: string) {
  return value.includes('oklab(') || value.includes('oklch(') || value.includes('color-mix(')
}

function sanitizeClonedPdfDocument(sourceRoot: HTMLElement, clonedDocument: Document) {
  const clonedRoot = clonedDocument.getElementById('offer-pdf-document')

  if (!clonedRoot) {
    return
  }

  clonedDocument.documentElement.classList.add('pdf-export-mode')
  clonedDocument.body.classList.add('pdf-export-mode')
  clonedRoot.setAttribute('data-pdf-export', 'true')
  clonedRoot.style.width = '190mm'
  clonedRoot.style.maxWidth = '190mm'
  clonedRoot.style.margin = '0 auto'
  clonedRoot.style.borderRadius = '0'
  clonedRoot.style.boxShadow = 'none'
  clonedRoot.style.overflow = 'visible'

  const sourceNodes = [sourceRoot, ...Array.from(sourceRoot.querySelectorAll<HTMLElement>('*'))]
  const clonedNodes = [clonedRoot as HTMLElement, ...Array.from(clonedRoot.querySelectorAll<HTMLElement>('*'))]
  const totalNodes = Math.min(sourceNodes.length, clonedNodes.length)

  for (let index = 0; index < totalNodes; index += 1) {
    const sourceNode = sourceNodes[index]
    const clonedNode = clonedNodes[index]
    const computedStyle = window.getComputedStyle(sourceNode)

    for (const property of COLOR_STYLE_PROPERTIES) {
      const propertyName = property.replace(/[A-Z]/g, (letter) => `-${letter.toLowerCase()}`)
      const value = computedStyle[property]

      if (typeof value === 'string' && usesUnsupportedColor(value)) {
        clonedNode.style.setProperty(propertyName, computedStyle.getPropertyValue(propertyName))
      }
    }
  }
}

type Html2PdfOptions = {
  margin: [number, number, number, number]
  filename: string
  image: {
    type: 'jpeg'
    quality: number
  }
  pagebreak: {
    mode: string[]
    before: string[]
  }
  html2canvas: {
    scale: number
    useCORS: boolean
    backgroundColor: string
    onclone: (clonedDocument: Document) => void
  }
  jsPDF: {
    unit: 'mm'
    format: 'a4'
    orientation: 'portrait'
  }
}

export function PrintPdfButton() {
  const [isDownloading, setIsDownloading] = useState(false)

  async function handleDownload() {
    const documentElement = document.getElementById('offer-pdf-document')

    if (!documentElement || isDownloading) {
      return
    }

    setIsDownloading(true)

    try {
      const html2pdfModule = await import('html2pdf.js')
      const html2pdf = html2pdfModule.default
      const offerNumber = documentElement.getAttribute('data-offer-number') || 'oferta-veloprime'
      const options: Html2PdfOptions = {
        margin: [8, 8, 8, 8],
        filename: `${offerNumber}.pdf`,
        image: { type: 'jpeg', quality: 0.98 },
        pagebreak: {
          mode: ['css'],
          before: ['.pdf-page + .pdf-page'],
        },
        html2canvas: {
          scale: 2,
          useCORS: true,
          backgroundColor: '#ffffff',
          onclone: (clonedDocument: Document) => {
            sanitizeClonedPdfDocument(documentElement, clonedDocument)
          },
        },
        jsPDF: {
          unit: 'mm',
          format: 'a4',
          orientation: 'portrait',
        },
      }

      await html2pdf()
        .set(options)
        .from(documentElement)
        .save()
    } finally {
      setIsDownloading(false)
    }
  }

  return (
    <button
      type="button"
      onClick={() => {
        void handleDownload()
      }}
      disabled={isDownloading}
      className="inline-flex items-center gap-2 rounded-2xl border border-[rgba(201,161,59,0.3)] bg-[#c9a13b] px-4 py-2.5 text-sm font-semibold text-white shadow-[0_14px_28px_rgba(201,161,59,0.2)] transition hover:bg-[#b8932f]"
    >
      {isDownloading ? <LoaderCircle className="h-4 w-4 animate-spin" /> : <Download className="h-4 w-4" />}
      <span>{isDownloading ? 'Przygotowywanie PDF...' : 'Pobierz PDF'}</span>
    </button>
  )
}