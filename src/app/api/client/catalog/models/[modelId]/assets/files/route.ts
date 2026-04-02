import { readJsonRecord, jsonFromServiceResult, requireAdminApiSession } from '@/lib/api-route-helpers'
import { uploadModelAssetToBlob, hasBlobStorage } from '@/lib/blob-storage'
import { createSalesAssetFile } from '@/lib/catalog-admin'
import { db } from '@/lib/db'

function sanitizeSegment(value: string) {
  return value
    .trim()
    .replace(/[^a-zA-Z0-9._-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
    .toLowerCase()
}

async function storeUploadedFile(modelId: string, formData: FormData) {
  const upload = formData.get('file')

  if (!(upload instanceof File)) {
    return { ok: false as const, error: 'Nie znaleziono pliku do wysłania.' }
  }

  const category = String(formData.get('category') ?? '').trim().toUpperCase()
  const powertrainType = String(formData.get('powertrainType') ?? '').trim().toUpperCase()
  const requestedFileName = String(formData.get('fileName') ?? '').trim()
  const mimeType = String(formData.get('mimeType') ?? '').trim() || upload.type || undefined

  const originalFileName = requestedFileName || upload.name || 'asset'
  const safeFileName = sanitizeSegment(originalFileName)

  if (!safeFileName) {
    return { ok: false as const, error: 'Nie udało się ustalić nazwy pliku.' }
  }

  const model = db
    ? await db.salesModel.findUnique({
        where: { id: modelId },
        select: { code: true },
      })
    : null

  const arrayBuffer = await upload.arrayBuffer()
  const fileBuffer = Buffer.from(arrayBuffer)
  const categorySegment = sanitizeSegment(category || 'other') || 'other'
  const modelSegment = sanitizeSegment(model?.code ?? modelId) || sanitizeSegment(modelId) || 'model'
  const powertrainSegment = powertrainType ? sanitizeSegment(powertrainType) : ''

  let storedPath = requestedFileName || safeFileName
  let fileDataBase64: string | null = fileBuffer.toString('base64')

  if (hasBlobStorage()) {
    const blob = await uploadModelAssetToBlob({
      modelCode: model?.code ?? modelId,
      category,
      fileName: safeFileName,
      file: upload,
      powertrainType: powertrainType || null,
      mimeType,
    })

    storedPath = blob.url
    fileDataBase64 = null
  } else {
    storedPath = powertrainSegment.length > 0
      ? `uploads/${modelSegment}/${categorySegment}/${powertrainSegment}/${safeFileName}`
      : `uploads/${modelSegment}/${categorySegment}/${safeFileName}`
  }

  return {
    ok: true as const,
    payload: {
      category,
      powertrainType: powertrainType || null,
      fileName: requestedFileName || safeFileName,
      filePath: storedPath,
      fileDataBase64,
      mimeType,
      sortOrder: formData.get('sortOrder'),
    },
  }
}

export async function POST(request: Request, context: { params: Promise<{ modelId: string }> }) {
  const session = await requireAdminApiSession()

  if (!session.ok) {
    return session.response
  }

  const { modelId } = await context.params
  const contentType = request.headers.get('content-type') ?? ''

  if (contentType.includes('multipart/form-data')) {
    if (!db) {
      return Response.json(
        { ok: false, error: 'Upload materiałów wymaga aktywnego połączenia z bazą danych.' },
        { status: 503 },
      )
    }

    const formData = await request.formData()
    const upload = await storeUploadedFile(modelId, formData)

    if (!upload.ok) {
      return Response.json({ ok: false, error: upload.error }, { status: 400 })
    }

    const result = await createSalesAssetFile(modelId, upload.payload)
    return jsonFromServiceResult(result, (assetBundle) => ({ assetBundle }), 201)
  }

  const body = await readJsonRecord(request)

  if (!body.ok) {
    return body.response
  }

  const result = await createSalesAssetFile(modelId, body.body)
  return jsonFromServiceResult(result, (assetBundle) => ({ assetBundle }), 201)
}