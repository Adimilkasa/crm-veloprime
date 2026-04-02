import type { Metadata } from 'next'
import { Inter } from 'next/font/google'

import './globals.css'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
})

export const metadata: Metadata = {
  title: 'CRM VeloPrime',
  description: 'Panel CRM dla handlowców VeloPrime',
  icons: {
    icon: '/app-icon.png',
    apple: '/app-icon.png',
    shortcut: '/app-icon.png',
  },
}

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="pl">
      <body className={inter.variable}>{children}</body>
    </html>
  )
}
