'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

import { getSession } from '@/lib/auth'
import { createManagedOffer, createManagedOfferVersion, updateManagedOffer } from '@/lib/offer-management'

async function requireSession() {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  return session
}

export async function createOfferAction(formData: FormData) {
  const session = await requireSession()
  const result = await createManagedOffer(session, {
    leadId: String(formData.get('leadId') || ''),
    title: String(formData.get('title') || ''),
    pricingCatalogKey: String(formData.get('pricingCatalogKey') || ''),
    customerType: String(formData.get('customerType') || 'PRIVATE') as 'PRIVATE' | 'BUSINESS',
    discountValue: String(formData.get('discountValue') || ''),
    financingVariant: String(formData.get('financingVariant') || ''),
    validUntil: String(formData.get('validUntil') || ''),
    notes: String(formData.get('notes') || ''),
  })

  if (!result.ok) {
    return result
  }

  revalidatePath('/offers')
  return { ok: true as const, offerId: result.offer.id }
}

export async function updateOfferAction(formData: FormData) {
  const session = await requireSession()
  const result = await updateManagedOffer(session, {
    offerId: String(formData.get('offerId') || ''),
    title: String(formData.get('title') || ''),
    status: String(formData.get('status') || 'DRAFT') as 'DRAFT' | 'SENT' | 'APPROVED' | 'REJECTED' | 'EXPIRED',
    pricingCatalogKey: String(formData.get('pricingCatalogKey') || ''),
    customerType: String(formData.get('customerType') || 'PRIVATE') as 'PRIVATE' | 'BUSINESS',
    discountValue: String(formData.get('discountValue') || ''),
    financingVariant: String(formData.get('financingVariant') || ''),
    validUntil: String(formData.get('validUntil') || ''),
    notes: String(formData.get('notes') || ''),
  })

  if (!result.ok) {
    return result
  }

  revalidatePath('/offers')
  return { ok: true as const }
}

export async function createOfferVersionAction(formData: FormData) {
  const session = await requireSession()
  const result = await createManagedOfferVersion(session, String(formData.get('offerId') || ''))

  if (!result.ok) {
    return result
  }

  revalidatePath('/offers')
  return { ok: true as const }
}