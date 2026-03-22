'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

import { getSession } from '@/lib/auth'
import {
  addManagedLeadDetailEntry,
  assignManagedLeadSalesperson,
  createManagedLead,
  createManagedLeadStage,
  moveManagedLeadToStage,
} from '@/lib/lead-management'

async function requireSession() {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  return session
}

export async function createLeadAction(formData: FormData) {
  const session = await requireSession()

  const result = await createManagedLead(session, {
    source: String(formData.get('source') || ''),
    fullName: String(formData.get('fullName') || ''),
    email: String(formData.get('email') || ''),
    phone: String(formData.get('phone') || ''),
    interestedModel: String(formData.get('interestedModel') || ''),
    region: String(formData.get('region') || ''),
    message: String(formData.get('message') || ''),
    stageId: String(formData.get('stageId') || ''),
    salespersonId: String(formData.get('salespersonId') || ''),
  })

  if (!result.ok) {
    redirect(`/leads?error=${encodeURIComponent(result.error)}`)
  }

  revalidatePath('/leads')
  redirect('/leads?success=created')
}

export async function moveLeadStageAction(formData: FormData) {
  const session = await requireSession()
  const leadId = String(formData.get('leadId') || '')
  const stageId = String(formData.get('stageId') || '')
  const result = await moveManagedLeadToStage(session, leadId, stageId)

  if (!result.ok) {
    redirect(`/leads?error=${encodeURIComponent(result.error)}`)
  }

  revalidatePath('/leads')
  redirect('/leads?success=stage')
}

export async function assignLeadSalespersonAction(formData: FormData) {
  const session = await requireSession()
  const leadId = String(formData.get('leadId') || '')
  const salespersonId = String(formData.get('salespersonId') || '')
  const result = await assignManagedLeadSalesperson(session, leadId, salespersonId)

  if (!result.ok) {
    redirect(`/leads?error=${encodeURIComponent(result.error)}`)
  }

  revalidatePath('/leads')
  redirect('/leads?success=assigned')
}

export async function createLeadStageAction(formData: FormData) {
  const session = await requireSession()
  const result = await createManagedLeadStage(session, {
    name: String(formData.get('name') || ''),
    color: String(formData.get('color') || ''),
    kind: (String(formData.get('kind') || 'OPEN') as 'OPEN' | 'WON' | 'LOST'),
  })

  if (!result.ok) {
    redirect(`/leads?error=${encodeURIComponent(result.error)}`)
  }

  revalidatePath('/leads')
  redirect('/leads?success=stage-created')
}

export async function addLeadInformationAction(formData: FormData) {
  const session = await requireSession()
  const result = await addManagedLeadDetailEntry(session, {
    leadId: String(formData.get('leadId') || ''),
    kind: 'INFO',
    label: String(formData.get('label') || ''),
    value: String(formData.get('value') || ''),
  })

  if (!result.ok) {
    return result
  }

  revalidatePath('/leads')
  return { ok: true as const }
}

export async function addLeadCommentAction(formData: FormData) {
  const session = await requireSession()
  const result = await addManagedLeadDetailEntry(session, {
    leadId: String(formData.get('leadId') || ''),
    kind: 'COMMENT',
    value: String(formData.get('value') || ''),
  })

  if (!result.ok) {
    return result
  }

  revalidatePath('/leads')
  return { ok: true as const }
}