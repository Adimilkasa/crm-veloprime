import { redirect } from 'next/navigation'

import { saveColorPalettesAction } from '@/app/(app)/colors/actions'
import { ColorPalettesWorkspace } from '@/components/colors/ColorPalettesWorkspace'
import { getSession } from '@/lib/auth'
import { getColorPaletteWorkspace } from '@/lib/color-management'
import { getRoleDefinition } from '@/lib/rbac'

export default async function ColorsPage() {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  const result = await getColorPaletteWorkspace(session)

  if (!result.ok) {
    redirect('/dashboard')
  }

  const roleDefinition = getRoleDefinition(session.role)

  return (
    <ColorPalettesWorkspace
      roleLabel={roleDefinition.label}
      palettes={result.palettes}
      saveColorPalettesAction={saveColorPalettesAction}
    />
  )
}