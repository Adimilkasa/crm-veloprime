const CURRENT_MSIX_VERSION = '0.1.12.4'
const GITHUB_RELEASE_URL = `https://github.com/Adimilkasa/crm-veloprime/releases/download/v${CURRENT_MSIX_VERSION}/veloprime_hybrid_app_${CURRENT_MSIX_VERSION}.msix`

export async function GET() {
  const response = await fetch(GITHUB_RELEASE_URL, {
    redirect: 'follow',
    cache: 'no-store',
  })

  if (!response.ok || !response.body) {
    return new Response('Unable to fetch release package.', { status: 502 })
  }

  return new Response(response.body, {
    status: 200,
    headers: {
      'Content-Type': 'application/vnd.ms-appx',
      'Content-Disposition': `attachment; filename="veloprime_hybrid_app_${CURRENT_MSIX_VERSION}.msix"`,
      'Cache-Control': 'public, max-age=300',
    },
  })
}