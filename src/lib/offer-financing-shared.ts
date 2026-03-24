import type { OfferCustomerType } from '@/lib/offer-calculations'

export type FinancingInputMode = 'AMOUNT' | 'PERCENT'

export type OfferFinancingInput = {
  termMonths: number | null
  downPaymentInputMode: FinancingInputMode
  downPaymentInputValue: number | null
  buyoutPercent: number | null
}

export type OfferFinancingSummary = {
  termMonths: number
  downPaymentInputMode: FinancingInputMode
  downPaymentInputValue: number
  downPaymentAmount: number
  downPaymentPercent: number
  buyoutPercent: number
  buyoutAmount: number
  financedAssetValue: number
  leaseTotalFactor: number
  totalLeaseCost: number
  estimatedInstallment: number
  disclaimerText: string
  calculationBaseLabel: string
}

const LEASE_TOTAL_FACTOR = 1.2
const BUYOUT_LIMITS: Record<number, number> = {
  24: 70,
  36: 60,
  48: 50,
  60: 40,
  71: 30,
}

export const FINANCING_DISCLAIMER = 'Przedstawione warunki finansowania mają charakter szacunkowy i poglądowy, nie stanowią wiążącej oferty w rozumieniu przepisów prawa oraz wymagają indywidualnej weryfikacji zdolności finansowej klienta.'

function roundMoney(value: number) {
  return Number(value.toFixed(2))
}

export function getBuyoutLimit(termMonths: number | null) {
  if (!termMonths) {
    return null
  }

  return BUYOUT_LIMITS[termMonths] ?? null
}

export function calculateOfferFinancing(input: {
  customerType: OfferCustomerType
  finalPriceGross: number | null
  finalPriceNet: number | null
  termMonths: number | null
  downPaymentInputMode: FinancingInputMode
  downPaymentInputValue: number | null
  buyoutPercent: number | null
}) {
  if (!input.termMonths || !input.downPaymentInputValue || !input.buyoutPercent) {
    return null
  }

  const buyoutLimit = getBuyoutLimit(input.termMonths)

  if (!buyoutLimit) {
    return { ok: false as const, error: 'Finansowanie wspiera tylko okresy 24, 36, 48, 60 i 71 miesięcy.' }
  }

  if (input.buyoutPercent < 0 || input.buyoutPercent > buyoutLimit) {
    return { ok: false as const, error: `Wykup dla ${input.termMonths} miesięcy nie może przekraczać ${buyoutLimit}%.` }
  }

  const financedAssetValue = input.customerType === 'BUSINESS' ? input.finalPriceNet : input.finalPriceGross

  if (financedAssetValue === null || financedAssetValue <= 0) {
    return { ok: false as const, error: 'Nie można policzyć finansowania bez końcowej ceny oferty.' }
  }

  const downPaymentAmount = roundMoney(input.downPaymentInputValue)
  const downPaymentPercent = roundMoney((downPaymentAmount / financedAssetValue) * 100)
  const buyoutAmount = roundMoney(financedAssetValue * (input.buyoutPercent / 100))
  const totalLeaseCost = roundMoney(financedAssetValue * LEASE_TOTAL_FACTOR)
  const estimatedInstallment = roundMoney((totalLeaseCost - downPaymentAmount - buyoutAmount) / input.termMonths)

  return {
    ok: true as const,
    summary: {
      termMonths: input.termMonths,
      downPaymentInputMode: 'AMOUNT',
      downPaymentInputValue: roundMoney(input.downPaymentInputValue),
      downPaymentAmount,
      downPaymentPercent,
      buyoutPercent: roundMoney(input.buyoutPercent),
      buyoutAmount,
      financedAssetValue: roundMoney(financedAssetValue),
      leaseTotalFactor: LEASE_TOTAL_FACTOR,
      totalLeaseCost,
      estimatedInstallment,
      disclaimerText: FINANCING_DISCLAIMER,
      calculationBaseLabel: input.customerType === 'BUSINESS' ? 'netto' : 'brutto',
    } satisfies OfferFinancingSummary,
  }
}