import 'server-only'

import { del, put } from '@vercel/blob'

function sanitizeSegment(value: string) {
  return value
    .trim()
    .replace(/[^a-zA-Z0-9._-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
    .toLowerCase()
}

export function hasBlobStorage() {
  return Boolean(process.env.BLOB_READ_WRITE_TOKEN)
}

export function describeBlobStorageError(error: unknown) {
  const message = error instanceof Error ? error.message.trim() : String(error ?? '').trim()
  const normalized = message.toLowerCase()

  if (!message) {
    return 'Vercel Blob odrzucil zapis pliku. Sprawdz, czy BLOB_READ_WRITE_TOKEN jest poprawnym read-write tokenem dla store podpietego do tego projektu.'
  }

  if (normalized.includes('access denied') || normalized.includes('unauthorized') || normalized.includes('forbidden')) {
    return 'Vercel Blob odrzucil zapis pliku. Najczestsze przyczyny to nieprawidlowy BLOB_READ_WRITE_TOKEN, token z innego teamu albo store, lub token do store w trybie private, podczas gdy ta aplikacja zapisuje pliki jako public.'
  }

  return message
}

export function isBlobUrl(value: string | null | undefined) {
  return Boolean(value && /^https:\/\/.+/i.test(value) && value.includes('.public.blob.vercel-storage.com/'))
}

type UploadBlobInput = {
  modelCode: string
  category: string
  fileName: string
  file: File
  powertrainType?: string | null
  mimeType?: string | null
}

type UploadUserAvatarInput = {
  userId: string
  fileName: string
  file: File
  mimeType?: string | null
}

type UploadLeadAttachmentInput = {
  leadId: string
  fileName: string
  file: File
  mimeType?: string | null
}

export async function uploadModelAssetToBlob(input: UploadBlobInput) {
  const token = process.env.BLOB_READ_WRITE_TOKEN

  if (!token) {
    throw new Error('Brak konfiguracji Vercel Blob.')
  }

  const modelSegment = sanitizeSegment(input.modelCode)
  const categorySegment = sanitizeSegment(input.category || 'other')
  const powertrainSegment = input.powertrainType ? sanitizeSegment(input.powertrainType) : null
  const fileSegment = sanitizeSegment(input.fileName || 'asset')
  const prefix = powertrainSegment
    ? `crm-assets/${modelSegment}/${categorySegment}/${powertrainSegment}`
    : `crm-assets/${modelSegment}/${categorySegment}`
  const pathname = `${prefix}/${Date.now()}-${fileSegment}`

  return put(pathname, input.file, {
    access: 'public',
    token,
    addRandomSuffix: false,
    contentType: (input.mimeType ?? input.file.type) || undefined,
  })
}

export async function uploadUserAvatarToBlob(input: UploadUserAvatarInput) {
  const token = process.env.BLOB_READ_WRITE_TOKEN

  if (!token) {
    throw new Error('Brak konfiguracji Vercel Blob.')
  }

  const userSegment = sanitizeSegment(input.userId || 'user') || 'user'
  const fileSegment = sanitizeSegment(input.fileName || 'avatar') || 'avatar'
  const pathname = `crm-users/${userSegment}/avatar/${Date.now()}-${fileSegment}`

  return put(pathname, input.file, {
    access: 'public',
    token,
    addRandomSuffix: false,
    contentType: (input.mimeType ?? input.file.type) || undefined,
  })
}

export async function uploadLeadAttachmentToBlob(input: UploadLeadAttachmentInput) {
  const token = process.env.BLOB_READ_WRITE_TOKEN

  if (!token) {
    throw new Error('Brak konfiguracji Vercel Blob.')
  }

  const leadSegment = sanitizeSegment(input.leadId || 'lead') || 'lead'
  const fileSegment = sanitizeSegment(input.fileName || 'attachment') || 'attachment'
  const pathname = `crm-leads/${leadSegment}/attachments/${Date.now()}-${fileSegment}`

  return put(pathname, input.file, {
    access: 'public',
    token,
    addRandomSuffix: false,
    contentType: (input.mimeType ?? input.file.type) || undefined,
  })
}

export async function deleteBlobIfManaged(urlOrPath: string | null | undefined) {
  const token = process.env.BLOB_READ_WRITE_TOKEN

  if (!token || !isBlobUrl(urlOrPath)) {
    return
  }

  await del(urlOrPath!, { token })
}