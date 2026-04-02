import { NextResponse } from 'next/server'

export async function POST() {
  return NextResponse.json(
    {
      ok: false,
      error: 'Synchronizacja legacy została wycofana. Katalog działa już wyłącznie na nowym modelu danych.',
    },
    { status: 410 }
  )
}