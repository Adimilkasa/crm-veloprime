import { NextResponse } from 'next/server'

import {
  describeBlobStorageError,
  deleteBlobIfManaged,
  hasBlobStorage,
  uploadLeadAttachmentToBlob,
} from '@/lib/blob-storage'
import { getSession } from '@/lib/auth'
import { addManagedLeadAttachment } from '@/lib/lead-management'

const maxAttachmentSizeBytes = 15 * 1024 * 1024

function sanitizeSegment(value: string) {
  return value
    .trim()
    .replace(/[^a-zA-Z0-9._-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
    .toLowerCase()
}

export async function POST(
  request: Request,
  context: { params: Promise<{ leadId: string }> },
) {
  const session = await getSession()

  if (!session) {
    return NextResponse.json({ ok: false, error: 'Brak aktywnej sesji.' }, { status: 401 })
  }

  if (!hasBlobStorage()) {
    return NextResponse.json(
      { ok: false, error: 'Upload załączników wymaga skonfigurowanego Vercel Blob po stronie serwera. To nie jest ograniczenie uprawnień handlowca.' },
      { status: 503 },
    )
  }

  const { leadId } = await context.params
  const formData = await request.formData()
  const upload = formData.get('file')

  if (!(upload instanceof File)) {
    return NextResponse.json({ ok: false, error: 'Nie znaleziono pliku do wysłania.' }, { status: 400 })
  }

  if (upload.size <= 0) {
    return NextResponse.json({ ok: false, error: 'Wybrany plik jest pusty.' }, { status: 400 })
  }

  if (upload.size > maxAttachmentSizeBytes) {
    return NextResponse.json(
      { ok: false, error: 'Załącznik nie może przekraczać 15 MB.' },
      { status: 400 },
    )
  }

  const originalFileName = String(formData.get('fileName') ?? '').trim() || upload.name || 'attachment'
  const safeFileName = sanitizeSegment(originalFileName) || 'attachment'

  let blobUrl: string | null = null

  try {
    const blob = await uploadLeadAttachmentToBlob({
      leadId,
      fileName: safeFileName,
      file: upload,
      mimeType: upload.type,
    })
    blobUrl = blob.url

    const result = await addManagedLeadAttachment(session, {
      leadId,
      fileName: originalFileName,
      fileUrl: blob.url,
      mimeType: upload.type || null,
      sizeBytes: upload.size,
    })

    if (!result.ok) {
      await deleteBlobIfManaged(blobUrl)
      return NextResponse.json({ ok: false, error: result.error }, { status: 400 })
    }

    return NextResponse.json({ ok: true, attachment: result.attachment }, { status: 201 })
  } catch (error) {
    if (blobUrl) {
      await deleteBlobIfManaged(blobUrl)
    }

    return NextResponse.json(
      { ok: false, error: describeBlobStorageError(error) || 'Nie udało się wysłać załącznika.' },
      { status: 500 },
    )
  }
}