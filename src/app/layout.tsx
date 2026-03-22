import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'CRM VeloPrime',
  description: 'Panel CRM dla handlowców VeloPrime',
}

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="pl">
      <body>{children}</body>
    </html>
  )
}
