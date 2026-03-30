import 'server-only'

type SendTransactionalEmailInput = {
  to: string
  subject: string
  html: string
  text: string
  replyTo?: string | null
}

function resolveProvider() {
  if (process.env.RESEND_API_KEY) {
    return 'resend' as const
  }

  return null
}

function resolveFromAddress() {
  return process.env.OFFER_EMAIL_FROM
    ?? process.env.RESEND_FROM_EMAIL
    ?? process.env.EMAIL_FROM
    ?? process.env.MAIL_FROM
    ?? null
}

function normalizeReplyTo(value?: string | null) {
  const normalized = value?.trim()
  return normalized && normalized.includes('@') ? normalized : null
}

async function sendViaResend(input: SendTransactionalEmailInput) {
  const apiKey = process.env.RESEND_API_KEY
  const from = resolveFromAddress()

  if (!apiKey || !from) {
    throw new Error('Brakuje konfiguracji maili. Ustaw RESEND_API_KEY oraz OFFER_EMAIL_FROM w środowisku Vercel.')
  }

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from,
      to: [input.to],
      subject: input.subject,
      html: input.html,
      text: input.text,
      ...(normalizeReplyTo(input.replyTo) ? { reply_to: normalizeReplyTo(input.replyTo) } : {}),
    }),
  })

  if (response.ok) {
    return
  }

  let details = response.statusText

  try {
    const payload = await response.json() as { message?: string; error?: { message?: string } }
    details = payload.message ?? payload.error?.message ?? details
  } catch {
    // ignore malformed provider response and fall back to status text
  }

  throw new Error(`Nie udało się wysłać maila z ofertą. ${details}`.trim())
}

export async function sendTransactionalEmail(input: SendTransactionalEmailInput) {
  const provider = resolveProvider()

  if (!provider) {
    throw new Error('Nie znaleziono skonfigurowanego providera maili. Ustaw RESEND_API_KEY oraz OFFER_EMAIL_FROM w Vercelu.')
  }

  if (provider === 'resend') {
    await sendViaResend(input)
  }
}