CREATE TYPE "FinancingCalculationEngine" AS ENUM ('PRESET', 'INTERPOLATED', 'ANNUITY_FALLBACK');

ALTER TABLE "OfferFinancing"
ADD COLUMN     "calculationEngine" "FinancingCalculationEngine" NOT NULL DEFAULT 'ANNUITY_FALLBACK',
ADD COLUMN     "monthlyRate" DECIMAL(9,6),
ADD COLUMN     "presentValue" DECIMAL(12,2),
ADD COLUMN     "futureValue" DECIMAL(12,2),
ADD COLUMN     "annuityPayment" DECIMAL(12,2),
ADD COLUMN     "heuristicProfileCode" TEXT;