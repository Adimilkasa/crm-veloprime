import { redirect } from 'next/navigation'

import { AppShell } from '@/components/layout/AppShell'
import { getSession } from '@/lib/auth'

export default async function AuthenticatedLayout({ children }: { children: React.ReactNode }) {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  return (
    <AppShell role={session.role} userName={session.fullName}>
      {children}
    </AppShell>
  )
}