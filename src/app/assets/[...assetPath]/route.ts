import { readFile } from 'node:fs/promises'
import path from 'node:path'

import { NextResponse } from 'next/server'

const ALLOWED_ROOTS = new Map([
  ['grafiki', path.join(process.cwd(), 'grafiki')],
  ['spec', path.join(process.cwd(), 'spec')],
])

function getContentType(filePath: string) {
  const extension = path.extname(filePath).toLowerCase()

  switch (extension) {
    case '.png':
      return 'image/png'
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg'
    case '.webp':
      return 'image/webp'
    case '.pdf':
      return 'application/pdf'
    default:
      return 'application/octet-stream'
  }
}

export async function GET(
  _request: Request,
  context: { params: Promise<{ assetPath: string[] }> }
) {
  const { assetPath } = await context.params

  if (!assetPath || assetPath.length < 2) {
    return NextResponse.json({ error: 'Asset path is incomplete.' }, { status: 400 })
  }

  const [root, ...rest] = assetPath
  const basePath = ALLOWED_ROOTS.get(root)

  if (!basePath) {
    return NextResponse.json({ error: 'Asset root is not allowed.' }, { status: 404 })
  }

  const absolutePath = path.resolve(basePath, ...rest)

  if (!absolutePath.startsWith(basePath)) {
    return NextResponse.json({ error: 'Invalid asset path.' }, { status: 400 })
  }

  try {
    const fileBuffer = await readFile(absolutePath)

    return new NextResponse(fileBuffer, {
      status: 200,
      headers: {
        'Content-Type': getContentType(absolutePath),
        'Cache-Control': 'no-store, max-age=0',
      },
    })
  } catch {
    return NextResponse.json({ error: 'Asset not found.' }, { status: 404 })
  }
}