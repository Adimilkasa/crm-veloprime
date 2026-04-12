import type { OfferCustomerType } from '@/lib/offer-calculations'

export type FinancingInputMode = 'AMOUNT' | 'PERCENT'

export type FinancingCalculationEngine = 'PRESET' | 'INTERPOLATED' | 'ANNUITY_FALLBACK'

export type OfferFinancingInput = {
  termMonths: number | null
  downPaymentInputMode: FinancingInputMode
  downPaymentInputValue: number | null
  buyoutPercent: number | null
}

export type OfferFinancingSummary = {
  termMonths: number
  calculationEngine: FinancingCalculationEngine
  downPaymentInputMode: FinancingInputMode
  downPaymentInputValue: number
  downPaymentAmount: number
  downPaymentPercent: number
  buyoutPercent: number
  buyoutAmount: number
  financedAssetValue: number
  monthlyRate: number
  presentValue: number
  futureValue: number
  annuityPayment: number
  heuristicProfileCode: string
  estimatedInstallment: number
  disclaimerText: string
  calculationBaseLabel: string
}

const BUYOUT_LIMITS: Record<number, number> = {
  24: 70,
  36: 60,
  48: 50,
  60: 40,
  71: 30,
}

export const FINANCING_DISCLAIMER = 'Przedstawione warunki finansowania mają charakter szacunkowy i poglądowy, nie stanowią wiążącej oferty w rozumieniu przepisów prawa oraz wymagają indywidualnej weryfikacji zdolności finansowej klienta.'

const HEURISTIC_MONTHLY_RATES: Record<OfferCustomerType, Record<string, number>> = {
  BUSINESS: {
    'leasing operacyjny': 0.0074,
    'wynajem długoterminowy': 0.0081,
    default: 0.0078,
  },
  PRIVATE: {
    'kredyt': 0.0099,
    'leasing konsumencki': 0.0091,
    'wynajem': 0.0087,
    default: 0.0092,
  },
}

function roundMoney(value: number) {
  return Number(value.toFixed(2))
}

function roundRate(value: number) {
  return Number(value.toFixed(6))
}

function normalizeVariant(value: string | null | undefined) {
  return value?.trim().toLowerCase() ?? ''
}

function resolveDownPaymentAmount(input: {
  mode: FinancingInputMode
  value: number
  financedAssetValue: number
}) {
  if (input.mode === 'PERCENT') {
    return roundMoney(input.financedAssetValue * (input.value / 100))
  }

  return roundMoney(input.value)
}

function resolveHeuristicRate(input: {
  customerType: OfferCustomerType
  financingVariant?: string | null
  termMonths: number
  buyoutPercent: number
}) {
  const normalizedVariant = normalizeVariant(input.financingVariant)
  const rateTable = HEURISTIC_MONTHLY_RATES[input.customerType]
  const baseRate = rateTable[normalizedVariant] ?? rateTable.default
  const termAdjustment = input.termMonths >= 60 ? 0.00035 : input.termMonths >= 48 ? 0.0002 : 0
  const buyoutAdjustment = input.buyoutPercent > 50 ? 0.0002 : input.buyoutPercent > 30 ? 0.0001 : 0
  const monthlyRate = roundRate(baseRate + termAdjustment + buyoutAdjustment)

  return {
    monthlyRate,
    heuristicProfileCode: `${input.customerType}:${normalizedVariant || 'default'}:${input.termMonths}`,
  }
}

function calculateAnnuityInstallment(input: {
  presentValue: number
  futureValue: number
  monthlyRate: number
  termMonths: number
}) {
  const discountFactor = (1 + input.monthlyRate) ** input.termMonths
  const numerator = input.monthlyRate * (input.presentValue - (input.futureValue / discountFactor))
  const denominator = 1 - ((1 + input.monthlyRate) ** (-input.termMonths))

  if (denominator === 0) {
    return null
  }

  return roundMoney(numerator / denominator)
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
  financingVariant?: string | null
  termMonths: number | null
  downPaymentInputMode: FinancingInputMode
  downPaymentInputValue: number | null
  buyoutPercent: number | null
}) {
  if (
    input.termMonths === null
    || input.downPaymentInputValue === null
    || input.buyoutPercent === null
  ) {
    return null
  }

  if (input.downPaymentInputValue < 0) {
    return { ok: false as const, error: 'Wpłata własna nie może być ujemna.' }
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

  const downPaymentAmount = resolveDownPaymentAmount({
    mode: input.downPaymentInputMode,
    value: input.downPaymentInputValue,
    financedAssetValue,
  })

  if (downPaymentAmount >= financedAssetValue) {
    return { ok: false as const, error: 'Wpłata własna musi być niższa od końcowej ceny oferty.' }
  }

  const downPaymentPercent = roundMoney((downPaymentAmount / financedAssetValue) * 100)
  const buyoutAmount = roundMoney(financedAssetValue * (input.buyoutPercent / 100))
  const presentValue = roundMoney(financedAssetValue - downPaymentAmount)
  const futureValue = buyoutAmount

  if (futureValue >= presentValue) {
    return { ok: false as const, error: 'Wykup musi być niższy od kwoty pozostającej do finansowania po wpłacie własnej.' }
  }

  const { monthlyRate, heuristicProfileCode } = resolveHeuristicRate({
    customerType: input.customerType,
    financingVariant: input.financingVariant,
    termMonths: input.termMonths,
    buyoutPercent: input.buyoutPercent,
  })
  const annuityPayment = calculateAnnuityInstallment({
    presentValue,
    futureValue,
    monthlyRate,
    termMonths: input.termMonths,
  })

  if (annuityPayment === null || annuityPayment < 0) {
    return { ok: false as const, error: 'Nie udało się policzyć raty dla wskazanego scenariusza finansowania.' }
  }

  return {
    ok: true as const,
    summary: {
      termMonths: input.termMonths,
      calculationEngine: 'ANNUITY_FALLBACK',
      downPaymentInputMode: input.downPaymentInputMode,
      downPaymentInputValue: roundMoney(input.downPaymentInputValue),
      downPaymentAmount,
      downPaymentPercent,
      buyoutPercent: roundMoney(input.buyoutPercent),
      buyoutAmount,
      financedAssetValue: roundMoney(financedAssetValue),
      monthlyRate,
      presentValue,
      futureValue,
      annuityPayment,
      heuristicProfileCode,
      estimatedInstallment: annuityPayment,
      disclaimerText: FINANCING_DISCLAIMER,
      calculationBaseLabel: input.customerType === 'BUSINESS' ? 'netto' : 'brutto',
    } satisfies OfferFinancingSummary,
  }
}