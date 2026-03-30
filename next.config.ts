import type { NextConfig } from 'next'

const sharedOfferAssetGlobs = [
  './client/veloprime_hybrid_app/assets/offers/grafiki/**/*',
  './client/veloprime_hybrid_app/assets/offers/spec/**/*',
]

const nextConfig: NextConfig = {
  reactStrictMode: true,
  outputFileTracingIncludes: {
    '/api/client/offers/*/document': sharedOfferAssetGlobs,
    '/assets/*': sharedOfferAssetGlobs,
    '/offers/*/pdf': sharedOfferAssetGlobs,
    '/offers/*/pdf/studio': sharedOfferAssetGlobs,
  },
}

export default nextConfig
