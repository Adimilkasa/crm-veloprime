import { NextResponse } from 'next/server'

import { deleteBlobIfManaged, hasBlobStorage, uploadUserAvatarToBlob } from '@/lib/blob-storage'
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

  if (!allowedMimeTypes.has(upload.type)) {
    return NextResponse.json({ ok: false, error: 'Dozwolone są tylko pliki PNG, JPG, JPEG lub WEBP.' }, { status: 400 })
  }

  if (upload.size > maxAvatarSizeBytes) {
    return NextResponse.json({ ok: false, error: 'Zdjęcie profilu nie może przekraczać 1.5 MB.' }, { status: 400 })
  }

  const currentProfile = await getAuthUserProfile(session.sub)
  const originalFileName = upload.name || 'avatar'
  const safeFileName = sanitizeSegment(originalFileName) || 'avatar'
  const buffer = Buffer.from(await upload.arrayBuffer())

  let avatarUrl: string

  if (hasBlobStorage()) {
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

  const updated = await updateAuthUserAvatar({
    userId: session.sub,
    avatarUrl,
  })

  if (!updated) {
    return NextResponse.json({ ok: false, error: 'Nie udało się zapisać zdjęcia profilu.' }, { status: 404 })
  }

  if (currentProfile?.avatarUrl && currentProfile.avatarUrl !== avatarUrl) {
    await deleteBlobIfManaged(currentProfile.avatarUrl)
  }

  return NextResponse.json({ ok: true, profile: updated })
}

export async function DELETE() {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  const currentProfile = await getAuthUserProfile(session.sub)
  const updated = await updateAuthUserAvatar({ userId: session.sub, avatarUrl: null })

  if (!updated) {
    return NextResponse.json({ ok: false, error: 'Nie udało się zaktualizować profilu.' }, { status: 404 })
  }

  if (currentProfile?.avatarUrl) {
    await deleteBlobIfManaged(currentProfile.avatarUrl)
  }

  return NextResponse.json({ ok: true, profile: updated })
}