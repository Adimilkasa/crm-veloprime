import nodemailer from 'nodemailer'
import 'server-only'

type SendTransactionalEmailInput = {
  to: string
  subject: string
  html: string
  text: string
  replyTo?: string | null
}

type EmailProvider =
  | { kind: 'smtp'; config: SmtpConfig }
  | { kind: 'resend' }

type SmtpConfig = {
  host: string
  port: number
  secure: boolean
  user: string
  pass: string
  from: string
}

function parseBooleanEnv(value: string | undefined) {
  const normalized = value?.trim().toLowerCase()

  if (!normalized) {
    return null
  }

  if (['1', 'true', 'yes', 'on'].includes(normalized)) {
    return true
  }

  if (['0', 'false', 'no', 'off'].includes(normalized)) {
    return false
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

function resolveSmtpConfig() {
  const host = process.env.SMTP_HOST?.trim()
  const portRaw = process.env.SMTP_PORT?.trim()
  const secureRaw = process.env.SMTP_SECURE?.trim()
  const user = process.env.SMTP_USER?.trim()
  const pass = process.env.SMTP_PASS?.trim()
  const from = resolveFromAddress()
  const hasAnySmtpValue = [host, portRaw, secureRaw, user, pass].some(Boolean)

  if (!hasAnySmtpValue) {
    return null
  }

  const missing: string[] = []

  if (!host) {
    missing.push('SMTP_HOST')
  }

  if (!portRaw) {
    missing.push('SMTP_PORT')
  }

  const port = portRaw ? Number(portRaw) : Number.NaN

  if (portRaw && (!Number.isInteger(port) || port <= 0)) {
    throw new Error('Nieprawidłowa konfiguracja SMTP. SMTP_PORT musi być dodatnią liczbą całkowitą.')
  }

  if (!secureRaw) {
    missing.push('SMTP_SECURE')
  }

  const secure = parseBooleanEnv(secureRaw)

  if (secureRaw && secure === null) {
    throw new Error('Nieprawidłowa konfiguracja SMTP. SMTP_SECURE musi mieć wartość true albo false.')
  }

  if (!user) {
    missing.push('SMTP_USER')
  }

  if (!pass) {
    missing.push('SMTP_PASS')
  }

  if (!from) {
    missing.push('OFFER_EMAIL_FROM')
  }

  if (missing.length > 0) {
    throw new Error(`Konfiguracja SMTP jest niepełna. Ustaw ${missing.join(', ')} w środowisku Vercel.`)
  }

  const resolvedHost = host!
  const resolvedSecure = secure!
  const resolvedUser = user!
  const resolvedPass = pass!
  const resolvedFrom = from!

  return {
    host: resolvedHost,
    port,
    secure: resolvedSecure,
    user: resolvedUser,
    pass: resolvedPass,
    from: resolvedFrom,
  } satisfies SmtpConfig
}

function resolveProvider(): EmailProvider | null {
  const smtpConfig = resolveSmtpConfig()

  if (smtpConfig) {
    return { kind: 'smtp', config: smtpConfig }
  }

  if (process.env.RESEND_API_KEY) {
    return { kind: 'resend' }
  }

  return null
}

async function sendViaSmtp(input: SendTransactionalEmailInput, config: SmtpConfig) {
  const transport = nodemailer.createTransport({
    host: config.host,
    port: config.port,
    secure: config.secure,
    auth: {
      user: config.user,
      pass: config.pass,
    },
  })
  const replyTo = normalizeReplyTo(input.replyTo)

  try {
    await transport.sendMail({
      from: config.from,
      to: input.to,
      subject: input.subject,
      html: input.html,
      text: input.text,
      ...(replyTo ? { replyTo } : {}),
    })
  } catch (error) {
    const details = error instanceof Error ? error.message : 'Nieznany błąd providera SMTP.'
    throw new Error(`Nie udało się wysłać maila z ofertą przez SMTP. ${details}`.trim())
  }
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
    throw new Error('Nie znaleziono skonfigurowanego providera maili. Ustaw SMTP_HOST, SMTP_PORT, SMTP_SECURE, SMTP_USER, SMTP_PASS oraz OFFER_EMAIL_FROM albo skonfiguruj RESEND_API_KEY.')
  }

  if (provider.kind === 'smtp') {
    await sendViaSmtp(input, provider.config)
    return
  }

  if (provider.kind === 'resend') {
    await sendViaResend(input)
  }
}