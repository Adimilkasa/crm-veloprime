import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json(
    {
      ok: false,
      error: 'Status synchronizacji legacy nie jest już dostępny. Katalog działa wyłącznie na nowym modelu danych.',
    },
    { status: 410 }
  )
}