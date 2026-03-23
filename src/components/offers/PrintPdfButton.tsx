'use client'

import { Printer } from 'lucide-react'

export function PrintPdfButton() {
  return (
    <button
      type="button"
      onClick={() => window.print()}
      className="inline-flex items-center gap-2 rounded-full border border-[#d2c19d] bg-[#171d23] px-4 py-2 text-sm font-medium text-white transition hover:bg-[#252d36]"
    >
      <Printer className="h-4 w-4" />
      <span>Drukuj / zapisz jako PDF</span>
    </button>
  )
}