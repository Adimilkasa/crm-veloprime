ALTER TABLE "Offer"
ADD COLUMN "leadId" TEXT;

CREATE INDEX "Offer_leadId_idx" ON "Offer"("leadId");

ALTER TABLE "Offer"
ADD CONSTRAINT "Offer_leadId_fkey"
FOREIGN KEY ("leadId") REFERENCES "Lead"("id")
ON DELETE SET NULL ON UPDATE CASCADE;