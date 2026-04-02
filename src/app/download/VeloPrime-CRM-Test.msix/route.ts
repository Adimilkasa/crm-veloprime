import { readFile } from 'node:fs/promises'
import path from 'node:path'

const APPINSTALLER_PATH = path.join(process.cwd(), 'public', 'download', 'VeloPrime-CRM-Test.appinstaller')

async function resolveMsixUrl() {
  const appInstallerXml = await readFile(APPINSTALLER_PATH, 'utf8')
  const uriMatch = appInstallerXml.match(/<MainPackage\b[^>]*\bUri="([^"]+)"/i)

  if (!uriMatch?.[1]) {
    throw new Error('Missing MainPackage Uri in VeloPrime-CRM-Test.appinstaller')
  }

  const msixUrl = uriMatch[1]

  if (msixUrl.endsWith('/download/VeloPrime-CRM-Test.msix')) {
    throw new Error('MainPackage Uri points back to the Vercel redirect route')
  }

  return msixUrl
}

export async function GET() {
  const msixUrl = await resolveMsixUrl()

  return new Response(null, {
    status: 307,
    headers: {
      Location: msixUrl,
      'Cache-Control': 'public, max-age=300',
      'X-VeloPrime-Msix-Mode': 'redirect-appinstaller-mainpackage',
    },
  })
}