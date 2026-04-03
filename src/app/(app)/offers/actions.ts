'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'

import { getSession } from '@/lib/auth'
import { assignManagedOfferLead, createManagedOffer, createManagedOfferShare, createManagedOfferVersion, updateManagedOffer } from '@/lib/offer-management'

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
    customerName: String(formData.get('customerName') || ''),
    customerEmail: String(formData.get('customerEmail') || ''),
    customerPhone: String(formData.get('customerPhone') || ''),
    customerRegion: String(formData.get('customerRegion') || ''),
    title: String(formData.get('title') || ''),
    pricingCatalogKey: String(formData.get('pricingCatalogKey') || ''),
    selectedColorName: String(formData.get('selectedColorName') || ''),
    customerType: String(formData.get('customerType') || 'PRIVATE') as 'PRIVATE' | 'BUSINESS',
    discountValue: String(formData.get('discountValue') || ''),
    financingVariant: String(formData.get('financingVariant') || ''),
    financingTermMonths: String(formData.get('financingTermMonths') || ''),
    financingInputMode: 'AMOUNT',
    financingInputValue: String(formData.get('financingInputValue') || ''),
    financingBuyoutPercent: String(formData.get('financingBuyoutPercent') || ''),
    validUntil: String(formData.get('validUntil') || ''),
    notes: String(formData.get('notes') || ''),
  })

  if (!result.ok) {
    return result
  }

  revalidatePath('/offers')
  return { ok: true as const, offerId: result.offer.id }
}

export async function assignOfferLeadAction(formData: FormData) {
  const session = await requireSession()
  const result = await assignManagedOfferLead(session, {
    offerId: String(formData.get('offerId') || ''),
    leadId: String(formData.get('leadId') || ''),
  })

  if (!result.ok) {
    return result
  }

  revalidatePath('/offers')
  revalidatePath('/leads')
  return { ok: true as const }
}

export async function updateOfferAction(formData: FormData) {
  const session = await requireSession()
  const result = await updateManagedOffer(session, {
    offerId: String(formData.get('offerId') || ''),
    title: String(formData.get('title') || ''),
    status: String(formData.get('status') || 'DRAFT') as 'DRAFT' | 'SENT' | 'APPROVED' | 'REJECTED' | 'EXPIRED',
    customerName: String(formData.get('customerName') || ''),
    customerEmail: String(formData.get('customerEmail') || ''),
    customerPhone: String(formData.get('customerPhone') || ''),
    customerRegion: String(formData.get('customerRegion') || ''),
    pricingCatalogKey: String(formData.get('pricingCatalogKey') || ''),
    selectedColorName: String(formData.get('selectedColorName') || ''),
    customerType: String(formData.get('customerType') || 'PRIVATE') as 'PRIVATE' | 'BUSINESS',
    discountValue: String(formData.get('discountValue') || ''),
    financingVariant: String(formData.get('financingVariant') || ''),
    financingTermMonths: String(formData.get('financingTermMonths') || ''),
    financingInputMode: 'AMOUNT',
    financingInputValue: String(formData.get('financingInputValue') || ''),
    financingBuyoutPercent: String(formData.get('financingBuyoutPercent') || ''),
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
  const offerId = String(formData.get('offerId') || '')
  const result = await createManagedOfferVersion(session, offerId)

  if (!result.ok) {
    return result
  }

  const shareResult = await createManagedOfferShare(session, {
    offerId,
    versionId: result.version.id,
  })

  if (!shareResult.ok) {
    return shareResult
  }

  revalidatePath('/offers')
  return { ok: true as const, versionId: result.version.id, publicUrl: `/oferta/${shareResult.share.token}` }
}