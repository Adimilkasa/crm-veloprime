import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  reactStrictMode: true,
  outputFileTracingIncludes: {
    '/api/client/offers/*/document': ['./grafiki/**/*', './spec/**/*'],
    '/assets/*': ['./grafiki/**/*', './spec/**/*'],
    '/offers/*/pdf': ['./grafiki/**/*', './spec/**/*'],
    '/offers/*/pdf/studio': ['./grafiki/**/*', './spec/**/*'],
  },
}

export default nextConfig
