'use client'

import { Printer } from 'lucide-react'

export function PrintPdfButton() {
  return (
    <button
      type="button"
      onClick={() => window.print()}
      className="inline-flex items-center gap-2 rounded-2xl border border-[rgba(201,161,59,0.3)] bg-[#c9a13b] px-4 py-2.5 text-sm font-semibold text-white shadow-[0_14px_28px_rgba(201,161,59,0.2)] transition hover:bg-[#b8932f]"
    >
      <Printer className="h-4 w-4" />
      <span>Drukuj / zapisz jako PDF</span>
    </button>
  )
}