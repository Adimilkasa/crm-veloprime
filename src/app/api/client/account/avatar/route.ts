import { NextResponse } from 'next/server'

import { deleteBlobIfManaged, describeBlobStorageError, hasBlobStorage, uploadUserAvatarToBlob } from '@/lib/blob-storage'
import { getAuthUserProfile, getSession, updateAuthUserAvatar } from '@/lib/auth'

const allowedMimeTypes = new Set(['image/png', 'image/jpeg', 'image/webp'])
const maxAvatarSizeBytes = 1500000

function sanitizeSegment(value: string) {
  return value
    .trim()
    .replace(/[^a-zA-Z0-9._-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
    .toLowerCase()
}

function buildDataUrl(file: File, buffer: Buffer) {
  const mimeType = file.type || 'image/jpeg'
  return `data:${mimeType};base64,${buffer.toString('base64')}`
}

function buildMissingProfileError(sessionUserId: string) {
  return `Nie znaleziono profilu zalogowanego użytkownika (${sessionUserId}). Zdjęcie nie może zostać powiązane z kontem.`
}

export async function POST(request: Request) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const formData = await request.formData()
  const upload = formData.get('file')

  if (!(upload instanceof File)) {
    return NextResponse.json({ ok: false, error: 'Nie znaleziono pliku do wysłania.' }, { status: 400 })
  }

  if (upload.size <= 0) {
    return NextResponse.json({ ok: false, error: 'Wybrany plik jest pusty.' }, { status: 400 })
  }

  if (!allowedMimeTypes.has(upload.type)) {
    return NextResponse.json({ ok: false, error: 'Dozwolone są tylko pliki PNG, JPG, JPEG lub WEBP.' }, { status: 400 })
  }

  if (upload.size > maxAvatarSizeBytes) {
    return NextResponse.json({ ok: false, error: 'Zdjęcie profilu nie może przekraczać 1.5 MB.' }, { status: 400 })
  }

  const currentProfile = await getAuthUserProfile(session.sub)
  if (!currentProfile) {
    return NextResponse.json({ ok: false, error: buildMissingProfileError(session.sub) }, { status: 404 })
  }

  const originalFileName = upload.name || 'avatar'
  const safeFileName = sanitizeSegment(originalFileName) || 'avatar'
  const buffer = Buffer.from(await upload.arrayBuffer())
  const usesBlobStorage = hasBlobStorage()

  let avatarUrl: string

  try {
    if (usesBlobStorage) {
      const blob = await uploadUserAvatarToBlob({
        userId: session.sub,
        fileName: safeFileName,
        file: upload,
        mimeType: upload.type,
      })
      avatarUrl = blob.url
    } else {
      avatarUrl = buildDataUrl(upload, buffer)
    }
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        error: usesBlobStorage
          ? `Nie udało się wysłać zdjęcia profilu do Vercel Blob. ${describeBlobStorageError(error)}`
          : `Nie udało się przygotować zdjęcia profilu do zapisu lokalnego. ${error instanceof Error ? error.message : String(error ?? '')}`,
      },
      { status: 500 },
    )
  }

  let updated: Awaited<ReturnType<typeof updateAuthUserAvatar>>

  try {
    updated = await updateAuthUserAvatar({
      userId: session.sub,
      avatarUrl,
    })
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        error: `Zdjęcie zostało przesłane, ale nie udało się zapisać pola avatarUrl w profilu użytkownika (${session.sub}). ${error instanceof Error ? error.message : String(error ?? '')}`,
      },
      { status: 500 },
    )
  }

  if (!updated) {
    return NextResponse.json(
      { ok: false, error: `Nie udało się zapisać zdjęcia profilu dla użytkownika ${session.sub}.` },
      { status: 404 },
    )
  }

  let warning: string | null = null
  if (currentProfile?.avatarUrl && currentProfile.avatarUrl !== avatarUrl) {
    try {
      await deleteBlobIfManaged(currentProfile.avatarUrl)
    } catch (error) {
      warning = `Nowe zdjęcie zostało zapisane, ale nie udało się usunąć poprzedniego pliku. ${error instanceof Error ? error.message : String(error ?? '')}`
    }
  }

  return NextResponse.json({ ok: true, profile: updated, warning })
}

export async function DELETE() {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const currentProfile = await getAuthUserProfile(session.sub)
  if (!currentProfile) {
    return NextResponse.json({ ok: false, error: buildMissingProfileError(session.sub) }, { status: 404 })
  }

  let updated: Awaited<ReturnType<typeof updateAuthUserAvatar>>

  try {
    updated = await updateAuthUserAvatar({ userId: session.sub, avatarUrl: null })
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        error: `Nie udało się wyczyścić pola avatarUrl w profilu użytkownika (${session.sub}). ${error instanceof Error ? error.message : String(error ?? '')}`,
      },
      { status: 500 },
    )
  }

  if (!updated) {
    return NextResponse.json({ ok: false, error: 'Nie udało się zaktualizować profilu.' }, { status: 404 })
  }

  let warning: string | null = null
  if (currentProfile?.avatarUrl) {
    try {
      await deleteBlobIfManaged(currentProfile.avatarUrl)
    } catch (error) {
      warning = `Zdjęcie zostało odpięte od profilu, ale nie udało się usunąć pliku z magazynu. ${error instanceof Error ? error.message : String(error ?? '')}`
    }
  }

  return NextResponse.json({ ok: true, profile: updated, warning })
}