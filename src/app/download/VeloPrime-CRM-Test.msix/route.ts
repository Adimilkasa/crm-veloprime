const CURRENT_MSIX_VERSION = '0.1.12.4'
const GITHUB_RELEASE_URL = `https://github.com/Adimilkasa/crm-veloprime/releases/download/v${CURRENT_MSIX_VERSION}/veloprime_hybrid_app_${CURRENT_MSIX_VERSION}.msix`

export async function GET() {
  return new Response(null, {
    status: 307,
    headers: {
      Location: GITHUB_RELEASE_URL,
      'Cache-Control': 'public, max-age=300',
    },
  })
}